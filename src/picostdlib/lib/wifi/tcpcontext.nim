#
# ClientContext.h - TCP connection handling on top of lwIP
#
# Copyright (c) 2014 Ivan Grokhotkov. All rights reserved.
# This file is part of the esp8266 core for Arduino environment.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# Adapted from https://github.com/earlephilhower/arduino-pico/blob/master/libraries/WiFi/src/include/ClientContext.h
#

import std/strutils
import std/streams

import ../../pico/time
import ../../pico/cyw43_arch
import ../lwip
import ../../net/dns

export lwip, dns, streams

const
  WIFICLIENT_MAX_PACKET_SIZE*: uint = TCP_MSS
  WIFICLIENT_MAX_FLUSH_WAIT_MS*: uint = 300
  TCP_DEFAULT_KEEPALIVE_IDLE_SEC*: uint32 = 7200   # 2 hours
  TCP_DEFAULT_KEEPALIVE_INTERVAL_SEC*: uint32 = 75 # 75 sec
  TCP_DEFAULT_KEEPALIVE_COUNT*: uint32 = 9         # fault after 9 failures

proc getDefaultPrivateGlobalSyncValue*(): bool = false

when not defined(release):
  proc debugv(formatstr: cstring) {.importc: "printf", varargs, header: "<stdio.h>".}
else:
  proc debugv(formatstr: cstring) {.varargs, inline.} = discard

proc millis(): auto = toMsSinceBoot(getAbsoluteTime())

type
  Port* = distinct uint16

  TcpContext* = object
    pcb: ptr AltcpPcb
    rxBuf: ptr Pbuf
    rxBufOffset: uint
    datasource: ptr byte #= nil
    datalen: uint        #= 0
    written: uint        #= 0
    timeoutMs: uint      #= 5000
    opStartTime: uint    #= 0
    sendWaiting: bool    #= false
    connectPending: bool #= false
    connectedErr: ErrEnumT
    connected: bool
    sync: bool
    stream*: ClientStream

  ClientStream* = ref ClientStreamObj
  ClientStreamObj* = object of Stream
    client: pointer # pointer to TcpContext, Altcpfunctions causes compile error if type is ptr TcpContext

proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}

func getPcb*(self: TcpContext): ptr AltcpPcb = self.pcb

func getTcpPcb*(self: TcpContext): ptr TcpPcb =
  if not self.pcb.isNil:
    if not self.pcb.state.isNil:
      return cast[ptr TcpPcb](self.pcb.state)

proc discardReceived(self: var TcpContext) =
  debugv(":dsrcv %d\n", if not self.rxBuf.isNil: self.rxBuf.totLen else: 0)
  if self.rxBuf.isNil:
    return
  if not self.pcb.isNil:
    altcpRecved(self.pcb, self.rxBuf.totLen)
  withLwipLock:
    discard pbufFree(self.rxBuf)
  self.rxBuf = nil
  self.rxBufOffset = 0

proc abort*(self: var TcpContext): ErrEnumT =
  if not self.pcb.isNil:
    self.discardReceived()
    debugv(":abort\n")
    altcpArg(self.pcb, nil)
    altcpSent(self.pcb, nil)
    altcpRecv(self.pcb, nil)
    altcpErr(self.pcb, nil)
    altcpPoll(self.pcb, nil, 0)
    altcpAbort(self.pcb)
    self.pcb = nil

  return ErrAbrt

proc close*(self: var TcpContext): ErrEnumT =
  result = ErrOk
  if not self.pcb.isNil:
    self.discardReceived()
    debugv(":close\n")
    altcpArg(self.pcb, nil)
    altcpSent(self.pcb, nil)
    altcpRecv(self.pcb, nil)
    altcpErr(self.pcb, nil)
    altcpPoll(self.pcb, nil, 0)
    result = altcpClose(self.pcb).ErrEnumT
    if result != ErrOk:
      debugv(":tc err %d\n", result)
      altcpAbort(self.pcb)
      result = ErrAbrt
    self.pcb = nil

func availableForWrite*(self: TcpContext): uint =
  return if not self.pcb.isNil: altcpSndbuf(self.pcb) else: 0

proc setNoDelay*(self: var TcpContext; nodelay: bool) =
  if self.pcb.isNil:
    return
  withLwipLock:
    if nodelay:
      altcpNagleDisable(self.pcb)
    else:
      altcpNagleEnable(self.pcb)

func getNoDelay*(self: TcpContext): bool =
  if self.pcb.isNil:
    return false
  return altcpNagleDisabled(self.pcb).bool

proc setTimeout*(self: var TcpContext; timeoutMs: Natural) =
  self.timeoutMs = timeoutMs.uint32

func getTimeout*(self: TcpContext): Natural =
  self.timeoutMs.Natural

func getRemoteAddress*(self: TcpContext): ptr IpAddrT =
  if self.pcb.isNil:
    return nil
  return self.pcb.altcpGetIp(local = false.cint)

func getRemotePort*(self: TcpContext): uint16 =
  if self.pcb.isNil:
    return 0
  return self.pcb.altcpGetPort(local = false.cint)

func getLocalAddress*(self: TcpContext): ptr IpAddrT =
  if self.pcb.isNil:
    return nil
  return self.pcb.altcpGetIp(local = true.cint)

func getLocalPort*(self: TcpContext): uint16 =
  if self.pcb.isNil:
    return 0
  return self.pcb.altcpGetPort(local = true.cint)

func getSize*(self: TcpContext): uint =
  if self.rxBuf.isNil:
    return 0
  return self.rxBuf.totLen - self.rxBufOffset

func available*(self: TcpContext): int =
  self.getSize().int

func hasData*(self: TcpContext): bool =
  not self.rxBuf.isNil

proc connected*(self: TcpContext): bool =
  not self.pcb.isNil and (self.connected or self.available() > 0)

proc consume(self: var TcpContext; size: uint) =
  let left: int = self.rxBuf.len.int - self.rxBufOffset.int - size.int
  if left > 0:
    self.rxBufOffset += size
  elif self.rxBuf.next.isNil:
    debugv(":c0 %d, %d\n", size, self.rxBuf.totLen)
    let head = self.rxBuf
    self.rxBuf = nil
    self.rxBufOffset = 0
    withLwipLock:
      discard pbufFree(head)
  else:
    debugv(":c %d, %d, %d\n", size, self.rxBuf.len, self.rxBuf.totLen)
    let head = self.rxBuf
    self.rxBuf = self.rxBuf.next
    self.rxBufOffset = 0
    withLwipLock:
      pbufRef(self.rxBuf)
      discard pbufFree(head)

  if not self.pcb.isNil:
    withLwipLock:
      altcpRecved(self.pcb, size.uint16)

proc isTimeout(self: var TcpContext): bool =
  return millis() - self.opStartTime > self.timeoutMs

# proc state*(self: TcpContext): TcpState =
#   result = self.pcb.getTcpState()
#   echo ":state ", result
#   let ctx = cast[ptr MbedtlsSslContext](altcpTlsContext(self.pcb))
#   echo ":tlsstate ", ctx.state.MbedtlsSslStates
#   if result in {CLOSE_WAIT, CLOSING}:
#     result = CLOSED

proc waitUntilAcked*(self: var TcpContext; maxWaitMs: uint = WIFICLIENT_MAX_FLUSH_WAIT_MS): bool =
  ##  https://github.com/esp8266/Arduino/pull/3967#pullrequestreview-83451496
  ##  option 1 done
  ##  option 2 / _write_some() not necessary since _datasource is always nullptr here

  if self.pcb.isNil:
    return true

  var prevsndbuf = -1
  ##  wait for peer's acks to flush lwIP's output buffer
  var lastSent: uint32
  while true:
    if millis() - lastSent > maxWaitMs:
      debugv(":wustmo\n")
      ## All data was not flushed, timeout hit
      return false
    if self.pcb.isNil:
      return false
    withLwipLock:
      discard altcpOutput(self.pcb)
    var sndbuf: int
    withLwipLock:
      sndbuf = altcpSndbuf(self.pcb).int
    if sndbuf != prevsndbuf:
      ##  send buffer has changed (or first iteration)
      prevsndbuf = sndbuf
      ## We just sent a bit, move timeout forward
      lastSent = millis()
    if not self.connected or (sndbuf == TCP_SND_BUF.int):
      ##  peer has closed or all bytes are sent and acked
      ##  ((TCP_SND_BUF-sndbuf) is the amount of un-acked bytes)
      break
  ## All data flushed
  return true

proc read*(self: var TcpContext): char =
  if self.rxBuf.isNil:
    return 0.char
  result = cast[ptr UncheckedArray[char]](self.rxBuf.payload)[self.rxBufOffset]
  self.consume(1)

proc read*(self: var TcpContext; dst_in: ptr byte; size_in: uint): uint =
  if self.rxBuf.isNil or size_in == 0:
    return 0
  let maxSize = self.rxBuf.totLen - self.rxBufOffset
  var size = min(size_in, maxSize)
  var dst = dst_in
  debugv(":rd %d, %d, %d\n", size, self.rxBuf.totLen, self.rxBufOffset)
  var sizeRead = 0
  while size > 0:
    let bufSize = self.rxBuf.len - self.rxBufOffset
    var copySize = min(size, bufSize)
    if copySize == 0:
      break
    debugv(":rdi %d, %d\n", bufSize, copySize)
    withLwipLock:
      copySize = pbufCopyPartial(self.rxBuf, dst, copySize.uint16, self.rxBufOffset.uint16)
    dst = cast[ptr byte](cast[uint](dst) + copySize)
    self.consume(copySize)
    dec(size, copySize)
    inc(sizeRead, copySize)
  return sizeRead.uint

proc read*(self: var TcpContext; dst: var string): uint =
  if dst.len > 0:
    result = self.read(cast[ptr byte](dst[0].addr), dst.len.uint)
  dst.setLen(result)

func peek*(self: TcpContext): char =
  if self.rxBuf.isNil:
    return 0.char
  return cast[ptr UncheckedArray[char]](self.rxBuf.payload)[self.rxBufOffset]

func peekBytes*(self: TcpContext; dst: ptr byte; size_in: uint): uint =
  if self.rxBuf.isNil:
    return 0
  let maxSize: uint = self.rxBuf.totLen - self.rxBufOffset
  let size = if (size_in < maxSize): size_in else: maxSize
  debugv(":pd %d, %d, %d\n", size, self.rxBuf.totLen, self.rxBufOffset)
  let bufSize: uint = self.rxBuf.len - self.rxBufOffset
  let copySize: uint = if size < bufSize: size else: bufSize
  debugv(":rpi %d, %d\n", bufSize, copySize)
  copyMem(dst, cast[pointer](cast[uint](self.rxBuf.payload) + self.rxBufOffset), copySize)
  return copySize

proc peekBuffer*(self: var TcpContext): ptr UncheckedArray[char] =
  if self.rxBuf.isNil:
    return nil
  return cast[ptr UncheckedArray[char]](cast[uint](self.rxBuf.payload) + self.rxBufOffset)

proc peekAvailable*(self: var TcpContext): uint =
  if self.rxBuf.isNil:
    return 0
  return self.rxBuf.len - self.rxBufOffset

proc peekConsume*(self: var TcpContext; consume: uint) =
  self.consume(consume)

proc writeSome(self: var TcpContext): bool =
  if self.datasource.isNil or self.pcb.isNil:
    return false
  debugv(":wr %d %d\n", self.datalen - self.written, self.written)
  var hasWritten = false
  var scale = 0
  while self.written < self.datalen:
    if not self.connected:
      return false
    let remaining = self.datalen - self.written
    var nextChunkSize: uint = 0
    if self.pcb.isNil:
      return false
    withLwipLock:
      nextChunkSize = min(uint(altcpSndbuf(self.pcb)), remaining)
    ## Potentially reduce transmit size if we are tight on memory, but only if it doesn't return a 0 chunk size
    if nextChunkSize > (1 shl scale).uint:
      nextChunkSize = nextChunkSize shr scale
    if not nextChunkSize.bool:
      break
    var buf = cast[ptr byte](cast[uint](self.datasource) + self.written)
    var flags: uint8 = 0
    if nextChunkSize < remaining:
      flags = flags or TCP_WRITE_FLAG_MORE
      ##  do not tcp-PuSH (yet)
    if not self.sync:
      flags = flags or TCP_WRITE_FLAG_COPY
    if self.pcb.isNil:
      return false
    var err: ErrT
    withLwipLock:
      err = altcpWrite(self.pcb, buf, nextChunkSize.uint16, flags)
    debugv(":wrc %d %d %d\n", nextChunkSize, remaining, err)
    if err == ErrOk.ErrT:
      inc(self.written, nextChunkSize.int)
      hasWritten = true
    elif err == ErrMem.ErrT:
      if scale < 4:
        ## Retry sending at 1/2 the chunk size
        inc(scale)
      else:
        break
    else:
      ## ErrMem(-1) is a valid error meaning
      ##  "come back later". It leaves state() opened
      break
  if hasWritten and not self.pcb.isNil:
    ##  lwIP's tcp_output doc: "Find out what we can send and send it"
    ##  *with respect to Nagle*
    ##  more info: https://lists.gnu.org/archive/html/lwip-users/2017-11/msg00134.html
    withLwipLock:
      discard altcpOutput(self.pcb)
  return hasWritten

proc writeSomeFromCb(self: var TcpContext) =
  if self.sendWaiting:
    self.sendWaiting = false

proc writeFromSource(self: var TcpContext; ds: ptr byte; dl: uint): uint =
  assert(self.datasource.isNil)
  assert(not self.sendWaiting)
  self.datasource = ds
  self.datalen = dl
  self.written = 0
  self.opStartTime = millis()
  while true:
    if self.writeSome():
      self.opStartTime = millis()
    if self.written == self.datalen or self.isTimeout() or not self.connected:
      if self.isTimeout():
        debugv(":wtmo\n")
      self.datasource = nil
      self.datalen = 0
      break
    self.sendWaiting = true
    ##  will resume on timeout or when _write_some_from_cb or _notify_error fires
    ##  give scheduled functions a chance to run (e.g. Ethernet uses recurrent)
    pollDelay(self.timeoutMs, self.sendWaiting)
    self.sendWaiting = false
    if not true:
      break
  if self.sync:
    discard self.waitUntilAcked()
  return self.written

proc write*(self: var TcpContext; ds: ptr byte; dl: uint): uint =
  if self.pcb.isNil:
    return 0
  return self.writeFromSource(ds, dl)

proc write*(self: var TcpContext; ds: string): uint =
  if ds.len > 0:
    return self.write(cast[ptr byte](ds[0].unsafeAddr), ds.len.uint)

proc flush*(self: var TcpContext; maxWaitMs: uint = WIFICLIENT_MAX_FLUSH_WAIT_MS): bool =
  return self.waitUntilAcked(maxWaitMs)

proc stop*(self: var TcpContext; maxWaitMs: uint = WIFICLIENT_MAX_FLUSH_WAIT_MS): bool =
  result = self.flush(maxWaitMs)
  if self.close() != ErrOk:
    result = false

proc keepAlive*(self: var TcpContext;
               idleSec: uint32 = TCP_DEFAULT_KEEPALIVE_IDLE_SEC;
               intvSec: uint32 = TCP_DEFAULT_KEEPALIVE_INTERVAL_SEC;
               count: uint32 = TCP_DEFAULT_KEEPALIVE_COUNT) =
  if idleSec > 0 and intvSec > 0 and count > 0:
    self.pcb.altcpKeepaliveEnable(idleSec, intvSec * 1000, count * 1000)
  else:
    self.pcb.altcpKeepaliveDisable()

func isKeepAliveEnabled*(self: TcpContext): bool =
  return self.getTcpPcb().ipGetOption(SOF_KEEPALIVE).bool

func getKeepAliveIdle*(self: TcpContext): uint32 =
  return if self.isKeepAliveEnabled(): (self.getTcpPcb().keepIdle + 500) div 1000 else: 0

func getKeepAliveInterval*(self: TcpContext): uint32 =
  return if self.isKeepAliveEnabled(): (self.getTcpPcb().keepIntvl + 500) div 1000 else: 0

func getKeepAliveCount*(self: TcpContext): uint32 =
  return if self.isKeepAliveEnabled(): self.getTcpPcb().keepCnt else: 0

func getSync*(self: TcpContext): bool = self.sync

proc setSync*(self: var TcpContext; sync: bool) = self.sync = sync

proc notifyError(self: var TcpContext) =
  if self.connectPending or self.sendWaiting:
    ##  resume connect or _write_from_source
    self.sendWaiting = false
    self.connectPending = false
    self.connected = false
    ## esp_schedule();

proc acked(self: var TcpContext; pcb: ptr AltcpPcb; len: uint16): ErrEnumT =
  debugv(":ack %d\n", len)
  self.writeSomeFromCb()
  return ErrOk

proc recv(self: var TcpContext; pcb: ptr AltcpPcb; pb: ptr Pbuf; err: ErrEnumT): ErrEnumT =
  if pb.isNil:
    ##  connection closed by peer
    debugv(":rcl pb=%p sz=%d\n", self.rxBuf, if not self.rxBuf.isNil: self.rxBuf.totLen.int else: -1)
    self.notifyError()
    if not self.rxBuf.isNil and self.rxBuf.totLen > 0:
      ##  there is still something to read
      return ErrOk
    else:
      ##  nothing in receive buffer,
      ##  peer closed = nothing can be written:
      ##  closing in the legacy way
      discard self.abort()
      return ErrAbrt
  if not self.rxBuf.isNil:
    debugv(":rch %d, %d\n", self.rxBuf.totLen, pb.totLen)
    withLwipLock:
      pbufCat(self.rxBuf, pb)
  else:
    debugv(":rn %d\n", pb.totLen)
    self.rxBuf = pb
    self.rxBufOffset = 0
  return ErrOk

proc error(self: var TcpContext; err: ErrT) =
  debugv(":er %d 0x%08lx\n", err, cast[uint32](self.datasource))
  withLwipLock:
    altcpArg(self.pcb, nil)
    altcpSent(self.pcb, nil)
    altcpRecv(self.pcb, nil)
    altcpErr(self.pcb, nil)
  self.pcb = nil
  self.notifyError()

proc connected(self: var TcpContext; pcb: ptr AltcpPcb; err: ErrEnumT): ErrEnumT =
  assert(pcb == self.pcb)
  self.connectedErr = err
  if self.connectPending:
    # resume connect
    self.connectPending = false
  return ErrOk

proc poll(self: var TcpContext; pcb: ptr AltcpPcb): ErrEnumT =
  debugv(":poll - timed out\n")
  # self.writeSomeFromCb()
  return self.close()

proc sRecv(arg: pointer; tpcb: ptr AltcpPcb; pb: ptr Pbuf; err: ErrT): ErrT {.cdecl.} =
  if not arg.isNil:
    return cast[ptr TcpContext](arg)[].recv(tpcb, pb, err.ErrEnumT).ErrT
  else:
    return ErrOk.ErrT

proc sError(arg: pointer; err: ErrT) {.cdecl.} =
  if not arg.isNil:
    cast[ptr TcpContext](arg)[].error(err)

proc sPoll(arg: pointer; tpcb: ptr AltcpPcb): ErrT {.cdecl.} =
  if not arg.isNil:
    return cast[ptr TcpContext](arg)[].poll(tpcb).ErrT
  else:
    return ErrOk.ErrT

proc sAcked(arg: pointer; tpcb: ptr AltcpPcb; len: uint16): ErrT {.cdecl.} =
  if not arg.isNil:
    return cast[ptr TcpContext](arg)[].acked(tpcb, len).ErrT
  else:
    return ErrOk.ErrT

proc sConnected(arg: pointer; pcb: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.} =
  if not arg.isNil:
    return cast[ptr TcpContext](arg)[].connected(pcb, err.ErrEnumT).ErrT
  else:
    return ErrOk.ErrT

proc connect*(self: var TcpContext; ipaddr: IpAddrT; port: Port): bool =
  ##  note: not using `const ip_addr_t* addr` because
  ##  - `ip6_addr_assign_zone()` below modifies `*addr`
  ##  - caller's parameter `WiFiClient::connect` is a local copy
  when defined(lwipIpv6):
    ## Set zone so that link local addresses use the default interface
    if ip_Is_V6(ipaddr) and ip6AddrLacksZone(ip2Ip6(ipaddr), ip6Unknown):
      ip6AddrAssignZone(ip2Ip6(ipaddr), ip6Unknown, netifDefault)

  if self.pcb.isNil or self.connected:
    return false

  withLwipLock:
    self.connectedErr = altcpConnect(self.pcb, ipaddr.unsafeAddr, port.uint16, sConnected).ErrEnumT
  if self.connectedErr != ErrOk:
    return false

  self.connectPending = true
  self.opStartTime = millis()
  ##  will resume on timeout or when _connected or _notify_error fires
  ##  give scheduled functions a chance to run (e.g. Ethernet uses recurrent)
  pollDelay(self.timeoutMs, self.connectPending)
  let timeout = self.connectPending
  self.connectPending = false

  if self.pcb.isNil:
    debugv(":cabrt\n")
    return false

  if timeout:
    debugv(":ctmo\n")
    discard self.abort()
    return false

  if self.connectedErr != ErrOk:
    debugv(":cerr %d\n", self.connectedErr)
    discard self.abort()
    return false

  self.connected = true

  return true

proc connect*(self: var TcpContext; hostname: string; port: Port): bool =
  ## Convenience method to connect using hostname
  ## If using HTTPS/TLS, be sure to set SNI first!
  var remoteAddr: IpAddrT
  if getHostByName(hostname, remoteAddr, self.timeoutMs):
    return self.connect(remoteAddr, port)

# Stream callbacks
proc client(cs: ClientStreamObj): ptr TcpContext {.inline.} =
  cast[ptr TcpContext](cs.client)
proc csClose(s: Stream) =
  if not ClientStream(s).client.isNil:
    discard ClientStream(s).client()[].stop()
    ClientStream(s).client = nil
proc csAtEnd(s: Stream): bool =
  let client = ClientStream(s).client()
  if client.isNil:
    return true
  return client[].getSize() == 0
proc csGetPosition(s: Stream): int =
  let client = ClientStream(s).client()
  if client.isNil or client[].rxBuf.isNil:
    return 0
  return client[].rxBufOffset.int
proc csSetPosition(s: Stream; pos: int) =
  let client = ClientStream(s).client()
  if client.isNil or client[].rxBuf.isNil:
    return
  client[].rxBufOffset = pos.uint
proc csReadData(s: Stream; buffer: pointer; bufLen: int): int =
  if ClientStream(s).client.isNil:
    return 0
  return ClientStream(s).client()[].read(cast[ptr byte](buffer), uint bufLen).int
proc csReadDataStr(s: Stream; buffer: var string; slice: Slice[int]): int =
  if ClientStream(s).client.isNil:
    return 0
  return ClientStream(s).client()[].read(cast[ptr byte](buffer[slice.a].addr), uint slice.b + 1 - slice.a).int
proc csWriteData(s: Stream; buffer: pointer; bufLen: int) =
  if ClientStream(s).client.isNil:
    return
  let ok = ClientStream(s).client()[].write(cast[ptr byte](buffer), uint bufLen).int == bufLen
  discard ok
proc csPeekData(s: Stream; buffer: pointer; bufLen: int): int =
  if ClientStream(s).client.isNil:
    return 0
  return ClientStream(s).client()[].peekBytes(cast[ptr byte](buffer), uint bufLen).int
proc csReadLine(s: Stream; line: var string): bool =
  if ClientStream(s).client.isNil:
    return false
  let client = ClientStream(s).client()
  if client[].rxBuf.isNil or client[].getSize() == 0:
    return false
  var pos = client[].rxBuf.pbufMemfind("\n", client[].rxBufOffset)
  if pos != PBUF_NOT_FOUND:
    pos -= client[].rxBufOffset.uint16
    if pos > 0:
      line.setLen(pos + 1)
      result = client[].read(line) == pos + 1
      line.stripLineEnd()
      return result
    else:
      client[].consume(1)
      line.setLen(0)
      return client[].getSize() > 0
  else:
    line.setLen(client[].getSize())
    if line.len > 0:
      return client[].read(line).int == line.len
    else:
      return false
proc csFlush(s: Stream) =
  if ClientStream(s).client.isNil:
    return
  let client = ClientStream(s).client()
  discard client[].flush()

proc init*(self: var TcpContext; pcb: ptr AltcpPcb; timeoutMs: uint = 30_000) = # ; discardCb: DiscardCbT = nil; discardCbArg: pointer = nil
  assert(not pcb.isNil)
  self.pcb = pcb
  self.rxBuf = nil
  self.rxBufOffset = 0
  # self.discardCb = discardCb
  # self.discardCbArg = discardCbArg
  # self.refcnt = 0
  # self.next = nil
  self.timeoutMs = timeoutMs
  self.sync = getDefaultPrivateGlobalSyncValue()

  withLwipLock:
    altcpSetprio(self.pcb, TCP_PRIO_MIN)
    altcpArg(self.pcb, self.addr)
    altcpRecv(self.pcb, sRecv)
    altcpSent(self.pcb, sAcked)
    altcpErr(self.pcb, sError)
    altcpPoll(self.pcb, sPoll, 20)

  new(self.stream)
  self.stream.client = self.addr
  self.stream.closeImpl = csClose
  self.stream.atEndImpl = csAtEnd
  self.stream.setPositionImpl = csSetPosition
  self.stream.getPositionImpl = csGetPosition
  self.stream.readDataImpl = csReadData
  self.stream.readDataStrImpl = csReadDataStr
  self.stream.readLineImpl = csReadLine
  self.stream.peekDataImpl = csPeekData
  self.stream.writeDataImpl = csWriteData
  self.stream.flushImpl = csFlush

  # keep-alive not enabled by default
  # self.keepAlive()

# proc initTcpContext*(pcb: ptr AltcpPcb#[; discardCb: DiscardCbT = nil; discardCbArg: pointer = nil]#): owned TcpContext =
#   result.init(pcb#[, discardCb, discardCbArg]#)

proc init*(self: var TcpContext; tls: bool = false; sniHostname: string = "") =
  var allocator: AltcpAllocatorT
  allocator.alloc = altcpTcpAlloc
  allocator.arg = nil
  var pcb = altcpNewIpType(allocator.addr, IPADDR_TYPE_ANY.ord)

  if tls:
    pcb = altcpTlsWrap(altcpTlsCreateConfigClient(nil, 0), pcb)
    let sslCtx = cast[ptr MbedtlsSslContext](altcpTlsContext(pcb))
    ## Set SNI
    if sniHostname != "" and mbedtlsSslSetHostname(sslCtx, sniHostname) != 0:
      debugv(":mbedtls set hostname failed!\n")

  self.init(pcb)
