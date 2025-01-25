##
## Copyright (c) 2022, The littlefs authors.
## Copyright (c) 2017, Arm Limited. All rights reserved.
##
## Redistribution and use in source and binary forms, with or without modification,
## are permitted provided that the following conditions are met:
##
## -  Redistributions of source code must retain the above copyright notice, this
##    list of conditions and the following disclaimer.
## -  Redistributions in binary form must reproduce the above copyright notice, this
##    list of conditions and the following disclaimer in the documentation and/or
##    other materials provided with the distribution.
## -  Neither the name of ARM nor the names of its contributors may be used to
##    endorse or promote products derived from this software without specific prior
##    written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
## ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
## WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
## DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
## ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
## (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
## LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
## ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
## (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
{.hint[XDeclaredButNotUsed]: off.}
{.hint[User]: off.}

import std/os, std/strutils
import ../pico/[platform, types]
import ../hardware/[flash, sync]

export flash, types

const littlefsInclude = currentSourcePath.replace('\\', DirSep).parentDir / ".." / "vendor" / "pico-vfs" / "vendor" / "littlefs"

{.compile: littlefsInclude / "lfs.c".}
{.compile: littlefsInclude / "lfs_util.c".}

when defined(nimcheck):
  include ../futharkgen/futhark_littlefs
else:
  import ../helpers
  import futhark

  importc:
    outputPath futharkGenDir / "futhark_littlefs.nim"

    compilerArg "--target=arm-none-eabi"
    compilerArg "-mthumb"
    compilerArg "-mcpu=cortex-m0plus"
    compilerArg "-fsigned-char"
    compilerArg "-fshort-enums" # needed to get the right enum size

    sysPath futhark.getClangIncludePath()
    sysPath armSysrootInclude
    sysPath armInstallInclude
    path littlefsInclude

    renameCallback futharkRenameCallback

    "lfs.h"


# Nim helpers

import std/times
export times

type
  LittleFS* = object
    lfs: LfsT
    lfsConfig: LfsConfig
    mounted: bool
    start: uint32
    size: uint32
    autoFormat*: bool
    timeCallback*: proc (): Datetime

proc picoLfsRead(c: ptr LfsConfig; blk: LfsBlockT; off: LfsOffT; buffer: pointer; size: LfsSizeT): cint {.cdecl.} =
  let me = cast[ptr LittleFS](c.context)

  let address = XipBase + me.start + (blk * c.block_size) + off

  copyMem(buffer, cast[pointer](address), size)
  return LfsErrOk.ord

proc picoLfsProg(c: ptr LfsConfig; blk: LfsBlockT; off: LfsOffT; buffer: pointer; size: LfsSizeT): cint {.cdecl.} =
  let me = cast[ptr LittleFS](c.context)

  let address = me.start + (blk * c.block_size) + off

  let ints = saveAndDisableInterrupts()
  # rp2040.idleOtherCore();
  flashRangeProgram(address, cast[ptr uint8](buffer), size)
  # rp2040.resumeOtherCore();
  restoreInterrupts(ints)
  return LfsErrOk.ord

proc picoLfsErase(c: ptr LfsConfig; blk: LfsBlockT): cint {.cdecl.} =
  let me = cast[ptr LittleFS](c.context)

  let address = me.start + (blk * c.block_size)

  let ints = saveAndDisableInterrupts()
  # rp2040.idleOtherCore();
  flashRangeErase(address, c.block_size)
  # rp2040.resumeOtherCore();
  restoreInterrupts(ints)
  return LfsErrOk.ord

proc picoLfsSync(c: ptr LfsConfig): cint {.cdecl.} =
  # NOOP
  discard c
  return LfsErrOk.ord


proc init*(self: var LittleFS; start, size: uint32) =
  self.mounted = false
  self.start = start - XipBase
  self.size = size
  assert(start mod 4096 == 0, "Start address must be a multiple of 4096")
  assert(start > FlashBinaryEnd, "Start address is inside flash binary space")
  zeroMem(self.lfs.addr, sizeof(LfsT))
  zeroMem(self.lfsConfig.addr, sizeof(LfsConfig))

  self.lfsConfig.context = cast[pointer](self.addr)
  self.lfsConfig.read = picoLfsRead
  self.lfsConfig.prog = picoLfsProg
  self.lfsConfig.erase = picoLfsErase
  self.lfsConfig.sync = picoLfsSync
  self.lfsConfig.read_size = FlashPageSize
  self.lfsConfig.prog_size = FlashPageSize
  self.lfsConfig.block_size = FlashBlockSize
  self.lfsConfig.block_count = self.size div self.lfsConfig.block_size
  self.lfsConfig.block_cycles = 16
  self.lfsConfig.cache_size = FlashPageSize
  self.lfsConfig.lookahead_size = FlashPageSize
  self.lfsConfig.compact_thresh = 0
  self.lfsConfig.read_buffer = nil
  self.lfsConfig.prog_buffer = nil
  self.lfsConfig.lookahead_buffer = nil
  self.lfsConfig.name_max = 0
  self.lfsConfig.file_max = 0
  self.lfsConfig.attr_max = 0
  self.lfsConfig.metadata_max = 0
  self.lfsConfig.inline_max = 0

when (NimMajor, NimMinor) >= (2, 0):
  proc `=destroy`*(self: LittleFS) =
    if self.mounted:
      discard lfs_unmount(self.lfs.unsafeAddr)
else:
  proc `=destroy`*(self: var LittleFS) =
    if self.mounted:
      discard lfs_unmount(self.lfs.unsafeAddr)

proc tryMount(self: var LittleFS): bool =
  if self.mounted:
    discard lfs_unmount(self.lfs.addr)
    self.mounted = false

  zeroMem(self.lfs.addr, sizeof(LfsT))
  let rc = lfs_mount(self.lfs.addr, self.lfsConfig.addr)
  if rc == 0:
    self.mounted = true
  return self.mounted

proc format*(self: var LittleFS): bool =
  if self.size == 0:
    return false

  let wasMounted = self.mounted
  if self.mounted:
    discard lfs_unmount(self.lfs.addr)
    self.mounted = false

  zeroMem(self.lfs.addr, sizeof(LfsT))
  var rc = lfs_format(self.lfs.addr, self.lfsConfig.addr)
  if rc != 0:
    return false

  if not self.timeCallback.isNil and self.tryMount():
    var t = self.timeCallback()
    rc = lfs_setattr(self.lfs.addr, "/", 'c'.uint8, t.addr, sizeof(t).LfsSizeT)
    if rc != 0:
      return false

    rc = lfs_setattr(self.lfs.addr, "/", 't'.uint8, t.addr, sizeof(t).LfsSizeT)
    if rc != 0:
      return false

    discard lfs_unmount(self.lfs.addr)
    self.mounted = false

  if wasMounted:
    return self.tryMount()

  return true

proc mount*(self: var LittleFS): bool =
  if self.mounted:
    return true

  if self.size <= 0:
    # LittleFS size is <= zero
    return false

  if self.tryMount():
    return true

  if not self.autoFormat or not self.format():
    return false

  return self.tryMount()

proc unmount*(self: var LittleFS) =
  if not self.mounted:
    return
  discard lfs_unmount(self.lfs.addr)
  self.mounted = false

proc exists*(self: var LittleFS; path: string): bool =
  if not self.mounted or path.len == 0:
    return false
  var info: LfsInfo
  let rc = lfs_stat(self.lfs.addr, path, info.addr)
  return rc == 0

proc rename*(self: var LittleFS; pathFrom, pathTo: string): bool =
  if not self.mounted or pathFrom.len == 0 or pathTo.len == 0 or pathFrom == pathTo:
    return false

  let rc = lfs_rename(self.lfs.addr, pathFrom, pathTo)
  if rc != 0:
    return false

  return true

proc remove*(self: var LittleFS; path: string): bool =
  if not self.mounted or path.len == 0:
    return false

  let rc = lfs_remove(self.lfs.addr, path)
  return rc == 0

proc mkdir*(self: var LittleFS; path: string): bool =
  if not self.mounted or path.len == 0:
    return false

  let rc = lfs_mkdir(self.lfs.addr, path)
  return rc == 0

proc rmdir*(self: var LittleFS; path: string): bool =
  self.remove(path) # Same call on LittleFS
