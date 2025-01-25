import std/os, std/macros

const releaseFollowsCmake = true

# used by futhark to find .h config files
when not defined(piconimCsourceDir):
  switch("define", "piconimCsourceDir:" & getCurrentDir() / "csource")

switch("define", "cyw43ArchBackend:threadsafe_background")

## https://www.freertos.org/a00111.html
## Default to heap 3 - wraps the standard malloc() and free() for thread safety.
# switch("os", "freertos")
# switch("define", "freertosKernelHeap:FreeRTOS-Kernel-Heap3")

## filesystem modules - uncomment to enable
# --define:pico_filesystem
# --define:pico_filesystem_default # includes flash, littlefs and fs_init
# --define:pico_filesystem_blockdevice_flash
# --define:pico_filesystem_blockdevice_heap
# --define:pico_filesystem_blockdevice_loopback
# --define:pico_filesystem_blockdevice_sd
# --define:pico_filesystem_filesystem_littlefs
# --define:pico_filesystem_filesystem_fat


#:: INTERNALS ::#

macro staticInclude(path: static[string]): untyped =
  newTree(nnkIncludeStmt, newLit(path))

# find picostdlib package path
const picostdlibPath = static:
  when dirExists(getCurrentDir() / "src" / "picostdlib"):
    getCurrentDir() / "src" / "picostdlib"
  else:
    const (path, code) = gorgeEx("piconim path")
    when code != 0:
      ""
    else:
      path

when picostdlibPath != "":
  echo picostdlibPath
  staticInclude(picostdlibPath / "build_utils" / "include.nims")

switch("mm", "arc")
switch("deepcopy", "on")
switch("threads", "off")
# switch("hints", "off")
# switch("debugger", "native")

when false:
  # experimental, let Nim call the C compiler
  # cmake does the linking
  switch("app", "staticlib")
  switch("noMain", "off")
  switch("gcc.exe", "arm-none-eabi-gcc")
  switch("passC", "-mcpu=cortex-m0plus")
  switch("passC", "-mthumb")
  switch("out", "$nimcache/$projectName.a")
  switch("passC", "-flto")
else:
  # default is to genereate C files
  switch("compileOnly", "on")

switch("nimcache", cmakeBinaryDir / projectName() / "nimcache")

switch("define", "checkAbi")
switch("define", "nimMemAlignTiny")
# switch("define", "useMalloc")
switch("define", "nimAllocPagesViaMalloc")
switch("define", "nimPage512")

# when using cpp backend
# see for similar issue: https://github.com/nim-lang/Nim/issues/17040
switch("define", "nimEmulateOverflowChecks")

# for futhark to work
switch("maxLoopIterationsVM", "100000000")

# redefine in case strdefine was empty
switch("define", "cmakeBinaryDir:" & cmakeBinaryDir)
