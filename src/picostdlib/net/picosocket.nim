import std/macros
import ../lib/lwip
import ./dns
import ../pico/cyw43_arch
import ./common
import ../asyncdispatch

export common, asyncdispatch

when not defined(release) or defined(debugSocket):
  template debugv(text: string) = echo text
else:
  template debugv(text: string) = discard

macro ptr2ref(arg: pointer; T: typedesc; name: untyped) =
  return quote do:
    assert(arg != nil)
    let `name` = cast[`T`](`arg`)

type

  SocketType* = enum
    SOCK_STREAM = 1 # Sequenced, reliable, connection-based byte streams
    SOCK_DGRAM = 2 # Connectionless, unreliable datagrams of fixed maximum length.
    SOCK_RAW = 3 # Raw protocol interface.

  SocketState* = enum
    STATE_INVALID
    STATE_NEW
    STATE_LISTENING
    STATE_CONNECTING
    STATE_CONNECTED
    STATE_PEER_CLOSED
    STATE_ACTIVE_UDP

  Socket*[kind: static[SocketType]] = ref object
    when kind == SOCK_STREAM:
      pcb: ptr AltcpPcb
    elif kind == SOCK_DGRAM:
      pcb: ptr UdpPcb
    elif kind == SOCK_RAW:
      pcb: ptr RawPcb
    else:
      pcb: void
    timeoutMs: int
    blocking: bool
    rxBuf: ptr Pbuf
    rxBufOffset: uint16

    secure: bool
    sendWaiting: bool
    state: SocketState
    err: ErrEnumT
    written: uint

    recvCb*: proc (len: uint16; totLen: uint16)

    connectCb: SocketConnectCb

  SocketAny*[kind: static[SocketType]] = Socket[kind]

  SocketConnectCb* = proc (success: bool)

func getBasePcb*(self: Socket[SOCK_STREAM]): ptr TcpPcb =
  if not self.pcb.isNil:
    if not self.pcb.state.isNil:
      return cast[ptr TcpPcb](self.pcb.state)
func getBasePcb*(self: Socket[SOCK_DGRAM]): ptr UdpPcb {.inline.} =
  return self.pcb
func getBasePcb*(self: Socket[SOCK_RAW]): ptr RawPcb {.inline.} =
  return self.pcb

proc altcpClosePollCb(arg: pointer; pcb: ptr AltcpPcb): ErrT {.cdecl.} =
  # Connection has not been cleanly closed so just abort it to free up memory
  debugv(":poll closing")
  altcpPoll(pcb, nil, 0)
  altcpAbort(pcb)
  return ErrOk.ErrT

proc `=destroy`*(self: typeof(Socket[SOCK_STREAM]()[])) =
  withLwipLock:
    if self.pcb != nil:
      altcpArg(self.pcb, nil)
      altcpSent(self.pcb, nil)
      altcpRecv(self.pcb, nil)
      altcpErr(self.pcb, nil)
      if self.pcb.getTcpState != LISTEN:
        altcpPoll(self.pcb, altcpClosePollCb, uint8(self.timeoutMs div 500))
      else:
        altcpPoll(self.pcb, nil, 0)
      # try close with timeout, otherwise abort
      let err = altcpClose(self.pcb).ErrEnumT
      if err != ErrOk:
        debugv(":destroy close err " & $err)
        altcpAbort(self.pcb)
    if self.rxBuf != nil:
      discard pbufFree(self.rxBuf)
  debugv(":destroyed")

proc `=destroy`*(self: typeof(Socket[SOCK_DGRAM]()[])) =
  withLwipLock:
    if self.pcb != nil:
      udpRecv(self.pcb, nil, nil)
      udpRemove(self.pcb)
    if self.rxBuf != nil:
      discard pbufFree(self.rxBuf)
  debugv(":destroyed")

proc `=destroy`*(self: typeof(Socket[SOCK_RAW]()[])) =
  withLwipLock:
    if self.pcb != nil:
      rawRecv(self.pcb, nil, nil)
      rawRemove(self.pcb)
    if self.rxBuf != nil:
      discard pbufFree(self.rxBuf)
  debugv(":destroyed")

proc setNoDelay*(self: var Socket[SOCK_STREAM]; nodelay: bool) =
  if self.pcb == nil:
    return
  withLwipLock:
    if nodelay:
      altcpNagleDisable(self.pcb)
    else:
      altcpNagleEnable(self.pcb)

proc getNoDelay*(self: Socket[SOCK_STREAM]): bool =
  if self.pcb == nil:
    return false
  return altcpNagleDisabled(self.pcb).bool

func getError*(self: SocketAny): ErrEnumT {.inline.}  =
  return self.err

func getState*(self: SocketAny): SocketState {.inline.} =
  return self.state

func setTimeout*(self: var SocketAny; timeoutMs: Natural) {.inline.} =
  self.timeoutMs = timeoutMs

func getTimeout*(self: SocketAny): Natural {.inline.} =
  return self.timeoutMs

func getRemoteAddress*(self: SocketAny): ptr IpAddrT =
  if self.pcb.isNil:
    return nil
  return self.getBasePcb().remote_ip.addr

func getRemotePort*(self: SocketAny): Port =
  if self.pcb.isNil:
    return 0.Port
  return self.getBasePcb().remote_port.Port

func getLocalAddress*(self: SocketAny): ptr IpAddrT =
  if self.pcb.isNil:
    return nil
  return self.getBasePcb().local_ip.addr

func getLocalPort*(self: SocketAny): Port =
  if self.pcb.isNil:
    return 0.Port
  return self.getBasePcb().local_port.Port

proc setSecure*(self: Socket[SOCK_STREAM]; sniHostname: string = "") =
  assert(self.pcb != nil)
  if self.secure: return
  self.pcb = altcpTlsWrap(altcpTlsCreateConfigClient(nil, 0), self.pcb)
  assert(self.pcb != nil)
  let sslCtx = cast[ptr MbedtlsSslContext](altcpTlsContext(self.pcb))
  # Set SNI
  debugv(":mbedtls sni " & sniHostname)
  if sniHostname != "" and mbedtlsSslSetHostname(sslCtx, sniHostname.cstring) != 0:
    debugv(":mbedtls ssl set hostname failed!")
  self.secure = true

proc discardReceived(self: SocketAny) =
  withLwipLock:
    if self.rxBuf == nil:
      return
    let totLen = self.rxBuf.totLen
    debugv(":discard " & $totLen)
    discard pbufFree(self.rxBuf)
    self.rxBuf = nil
    self.rxBufOffset = 0
    if self.pcb != nil:
      when self.kind == SOCK_STREAM:
        altcpRecved(self.pcb, totLen)

proc abort*(self: Socket[SOCK_STREAM]): ErrEnumT =
  withLwipLock:
    if self.pcb != nil:
      # self.discardReceived()
      debugv(":abort")
      altcpArg(self.pcb, nil)
      altcpSent(self.pcb, nil)
      altcpRecv(self.pcb, nil)
      altcpErr(self.pcb, nil)
      altcpPoll(self.pcb, nil, 0)
      altcpAbort(self.pcb)
      self.pcb = nil
      GC_unref(self)
  self.connectCb = nil
  self.recvCb = nil
  return ErrAbrt

proc close*(self: Socket[SOCK_STREAM]): ErrEnumT =
  result = ErrOk
  if self.pcb != nil:
    self.discardReceived()
    withLwipLock:
      self.state = STATE_PEER_CLOSED
      debugv(":close")
      altcpArg(self.pcb, nil)
      altcpSent(self.pcb, nil)
      altcpRecv(self.pcb, nil)
      altcpErr(self.pcb, nil)
      altcpPoll(self.pcb, nil, 0)
      result = altcpClose(self.pcb).ErrEnumT
      if result != ErrOk:
        debugv(":close err " & $result)
        altcpAbort(self.pcb)
        result = ErrAbrt
      GC_unref(self)
      self.pcb = nil
  self.connectCb = nil
  self.recvCb = nil

# lwip callbacks
proc altcpErrCb(arg: pointer; err: ErrT) {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_STREAM], self)
  let err = cast[ErrEnumT](err)
  debugv(":error " & $err)
  altcpArg(self.pcb, nil)
  altcpSent(self.pcb, nil)
  altcpRecv(self.pcb, nil)
  altcpErr(self.pcb, nil)
  self.err = err
  self.pcb = nil
  GC_unref(self)

proc altcpPollCb(arg: pointer; pcb: ptr AltcpPcb): ErrT {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_STREAM], self)
  assert(pcb == self.pcb)
  debugv(":poll - timed out")
  return self.close().ErrT

proc altcpConnectCb(arg: pointer; pcb: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_STREAM], self)
  let err = cast[ErrEnumT](err)
  assert(pcb == self.pcb)
  debugv(":connect " & $err)
  self.err = err
  self.state = if err == ErrOk: STATE_CONNECTED else: STATE_PEER_CLOSED
  self.connectCb(err == ErrOk)
  self.connectCb = nil
  return ErrOk.ErrT

proc altcpSentCb(arg: pointer; pcb: ptr AltcpPcb; len: uint16): ErrT {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_STREAM], self)
  assert(pcb == self.pcb)
  debugv(":sent " & $len)
  self.written -= len
  return ErrOk.ErrT

proc altcpRecvCb(arg: pointer; pcb: ptr AltcpPcb; pb: ptr Pbuf; err: ErrT): ErrT {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_STREAM], self)
  # let err = cast[ErrEnumT](err)
  assert(pcb == self.pcb)
  debugv(":recv")
  if pb == nil:
    # connection closed by peer
    debugv(":remote closed pb=" & $cast[uint](self.rxBuf) & " sz=" & $(if self.rxBuf.isNil: -1 else: self.rxBuf.totLen.int))
    self.state = STATE_PEER_CLOSED
    if self.rxBuf != nil and self.rxBuf.totLen > 0:
      # there is still something to read
      if self.recvCb != nil:
        self.recvCb(0, self.rxBuf.totLen)
      return ErrOk.ErrT
    else:
      # nothing in receive buffer,
      # peer closed = nothing can be written:
      # closing in the legacy way
      return self.abort().ErrT
  if self.rxBuf != nil:
    debugv(":recv " & $pb.totLen & " (" & $self.rxBuf.totLen & " total)")
    pbufCat(self.rxBuf, pb)
    debugv(":recv (" & $self.rxBuf.totLen & " total)")
    # altcpRecved is called in consume()
  else:
    debugv(":recv " & $pb.totLen & " (new)")
    self.rxBuf = pb
    self.rxBufOffset = 0
  if self.recvCb != nil:
    self.recvCb(pb.totLen, self.rxBuf.totLen)
  return ErrOk.ErrT

proc udpRecvCb(arg: pointer; pcb: ptr UdpPcb; pb: ptr Pbuf; ipAddr: ptr IpAddrT; port: uint16) {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_DGRAM], self)
  assert(pcb == self.pcb)
  let port = Port(port)
  debugv(":udprecv " & $pb.totLen & " " & $ipAddr & ":" & $port)
  discard pbufFree(pb)

proc rawRecvCb(arg: pointer; pcb: ptr RawPcb; pb: ptr Pbuf; ipAddr: ptr IpAddrT): uint8 {.cdecl.} =
  ptr2ref(arg, Socket[SOCK_RAW], self)
  assert(pcb == self.pcb)
  debugv(":rawrecv " & $pb.totLen & " " & $ipAddr)
  discard pbufFree(pb)
  return 1

proc flush*(self: Socket[SOCK_STREAM]): bool =
  if self.pcb == nil:
    return false
  withLwipLock:
    if self.written > 0:
      debugv(":flushing " & $self.written)
    let err = altcpOutput(self.pcb)
    if err != ErrOk.ErrT:
      debugv(":flushfail " & $err)
      return false
    return true

proc write*(self: Socket[SOCK_STREAM]; data: string): int =
  if self.pcb == nil:
    return -1
  if data.len == 0:
    return 0
  withLwipLock:
    var remaining = data.len
    var err = ErrOk
    var written = 0
    while remaining > 0:
      var available = altcpSndbuf(self.pcb).int
      if remaining <= available:
        debugv(":write final " & $remaining & " " & $available)
        err = altcpWrite(self.pcb, data[written].unsafeAddr, remaining.uint16, TCP_WRITE_FLAG_COPY).ErrEnumT
        written += remaining
        if err != ErrOk:
          debugv(":writefail " & $err)
          return -1
        else:
          self.written += remaining.uint
          return written
      else:
        let chunk = min(available, remaining)
        if chunk == 0:
          if not self.flush():
            return -1
        else:
          debugv(":write chunk " & $chunk & " " & $available)
          err = altcpWrite(self.pcb, data[written].unsafeAddr, chunk.uint16, TCP_WRITE_FLAG_COPY or TCP_WRITE_FLAG_MORE).ErrEnumT
          written += chunk
          remaining -= chunk
          if err != ErrOk:
            debugv(":writefail " & $err)
            return -1
          else:
            self.written += chunk.uint

  return written

proc available*(self: SocketAny): uint16 =
  if self.rxBuf.isNil:
    return 0
  return self.rxBuf.totLen - self.rxBufOffset

proc isConnected*(self: Socket[SOCK_STREAM]): bool =
  return not self.pcb.isNil and (self.state == STATE_CONNECTED or self.available() > 0)

proc read*(self: Socket[SOCK_STREAM]; size: uint16; buf: ptr char = nil): int =
  debugv(":read " & $size)

  if self.rxBuf == nil:
    let timedOut = cyw43WaitCondition(self.timeoutMs, self.state != STATE_CONNECTED or self.rxBuf != nil)
    if timedOut:
      return -1

    if self.state == STATE_PEER_CLOSED:
      if self.available() == 0:
        return 0
    elif self.state != STATE_CONNECTED:
      return -1
    echo "picosocket.read: there may be bytes available: ", self.available()
    return 0

  withLwipLock:
    var remaining = self.rxBuf.len - self.rxBufOffset
    let size = min(size, remaining)

    if buf != nil:
      let copySize = pbufCopyPartial(self.rxBuf, buf, size, self.rxBufOffset)
      debugv(":read copy " & $copySize)
      assert(size == copySize)

    remaining -= size

    if remaining == 0:
      if self.rxBuf.next != nil:
        debugv(":read next " & $size & ", " & $self.rxBuf.len & ", " & $self.rxBuf.totLen)
        let next = self.rxBuf.next
        pbufRef(self.rxBuf.next)
        discard pbufFree(self.rxBuf)
        self.rxBuf = next
        self.rxBufOffset = 0
      else:
        debugv(":read emptied " & $size & ", " & $self.rxBuf.len)
        discard pbufFree(self.rxBuf)
        self.rxBuf = nil
        self.rxBufOffset = 0
    else:
      debugv(":read " & $size & ", " & $self.rxBuf.len & ", " & $self.rxBuf.totLen)
      self.rxBufOffset += size

    if self.pcb != nil:
      altcpRecved(self.pcb, size)
    return size.int

proc readStr*(self: Socket[SOCK_STREAM]; size: uint16): string =
  if size == 0: return
  result = newString(size)
  var l = self.read(size, result[0].addr)
  if l < 0: l = 0
  result.setLen(l)

proc connect*(self: Socket[SOCK_STREAM]; ipaddr: ptr IpAddrT; port: Port; callback: SocketConnectCb): bool =
  # note: not using `const ip_addr_t* addr` because
  # - `ip6_addr_assign_zone()` below modifies `*addr`
  # - caller's parameter `WiFiClient::connect` is a local copy
  # when lwipIpv6:
  #   # Set zone so that link local addresses use the default interface
  #   if ipIsV6(ipaddr.addr) and ip6AddrLacksZone(ip2Ip6(ipaddr.addr), IP6_UNKNOWN):
  #     ip6AddrAssignZone(ip2Ip6(ipaddr.addr), IP6_UNKNOWN, netifDefault)

  if self.pcb.isNil:
    return false

  withLwipLock:
    if self.state != STATE_NEW:
      return false

    altcpSetprio(self.pcb, TCP_PRIO_MIN)
    altcpArg(self.pcb, cast[pointer](self))
    altcpErr(self.pcb, altcpErrCb)
    altcpRecv(self.pcb, altcpRecvCb)
    altcpSent(self.pcb, altcpSentCb)
    altcpPoll(self.pcb, altcpPollCb, uint8(self.timeoutMs div 500))
    self.state = STATE_CONNECTING
    self.connectCb = callback

    debugv(":connect " & $ipaddr & " " & $port)
    self.err = altcpConnect(self.pcb, ipaddr, port.uint16, altcpConnectCb).ErrEnumT
    if self.err != ErrOk:
      self.state = STATE_NEW
      callback(true)
      return false

    # let timedOut = cyw43WaitCondition(self.timeoutMs, self.state != STATE_CONNECTING)

    if self.pcb == nil:
      debugv(":connect aborted")
      callback(false)
      return false

    # if timedOut:
    #   debugv(":connect time out")
    #   discard self.abort()
    #   return false

    if self.err != ErrOk:
      debugv(":connect error " & $self.err)
      discard self.abort()
      callback(false)
      return false

    self.state = STATE_CONNECTED

    if self.err != ErrOk:
      return false
    GC_ref(self)
  return true

proc connect*(self: Socket[SOCK_DGRAM]; ipaddr: IpAddrT; port: Port; callback: SocketConnectCb): bool =
  assert(self.pcb != nil)
  self.err = udpConnect(self.pcb, ipaddr.unsafeAddr, port.uint16).ErrEnumT
  if self.err != ErrOk:
    return false
  GC_ref(self)
  return true

proc connect*(self: Socket[SOCK_RAW]; ipaddr: IpAddrT; _: Port = Port(0); callback: SocketConnectCb): bool =
  assert(self.pcb != nil)
  self.err = rawConnect(self.pcb, ipaddr.unsafeAddr).ErrEnumT
  if self.err != ErrOk:
    return false
  GC_ref(self)
  return true

proc connect*(self: SocketAny; host: string; port: Port; callback: SocketConnectCb): bool =
  ## Connect using ip address or hostname as string
  assert(self.pcb != nil)

  var remoteAddr = IpAddrT()
  let isIp = ipAddrAton(host.cstring, remoteAddr.addr).bool

  # when self.kind == SOCK_STREAM:
  #   let sniHostname = if not isIp and sniHostname.len == 0: host else: sniHostname


  if isIp:
    return self.connect(remoteAddr.addr, port, callback)
  let res = getHostByName(host, (proc (hostname: string; ipaddr: ptr IpAddrT) =
    if ipaddr.isNil:
      callback(false)
    else:
      discard self.connect(ipaddr, port, callback)
    GC_unref(self)
  ))
  if not res:
    return false
  GC_ref(self)
  return true

proc connect*(self: SocketAny; host: string; port: Port): owned Future[bool] =
  var retFuture = newFuture[bool]("picosocket.connect")
  if not self.connect(host, port, retFuture.complete): retFuture.complete(false)
  return retFuture


# proc connect*(self: Socket[SOCK_RAW]; host: string): bool {.inline.} =
#   # raw sockets have no port
#   self.connect(host, Port(0))

proc init*(self: SocketAny; timeoutMs: Natural; blocking: bool; ipProto: uint8) =
  assert(self.pcb == nil)
  assert(self.state in [STATE_NEW, STATE_PEER_CLOSED])

  self.state = STATE_NEW
  self.timeoutMs = timeoutMs
  self.rxBuf = nil
  self.rxBufOffset = 0
  self.blocking = blocking
  self.secure = false

  when self.kind == SOCK_STREAM:
    var allocator: AltcpAllocatorT
    allocator.alloc = altcpTcpAlloc
    allocator.arg = nil
    self.pcb = altcpNewIpType(allocator.addr, IPADDR_TYPE_ANY.ord)
    assert(self.pcb != nil)
    altcpArg(self.pcb, cast[pointer](self))
    altcpErr(self.pcb, altcpErrCb)
  elif self.kind == SOCK_DGRAM:
    self.pcb = udpNew()
    assert(self.pcb != nil)
    self.state = STATE_ACTIVE_UDP
    udpRecv(self.pcb, udpRecvCb, cast[pointer](self))
  elif self.kind == SOCK_RAW:
    self.pcb = rawNew(ipProto)
    assert(self.pcb != nil)
    rawRecv(self.pcb, rawRecvCb, cast[pointer](self))

  debugv(":init " & $self.kind)

proc newSocket*(kind: static[SocketType]; timeoutMs: Natural = 30_000; blocking: bool = true; ipProto: uint8 = 0): Socket[kind] =
  result = Socket[kind](state: STATE_NEW)
  result.init(timeoutMs, blocking, ipProto)

when defined(runtests) or defined(nimcheck):
  # block:
  #   var t = newSocket(SOCK_STREAM)
  #   discard t.connect("google.com", Port(80))

  # block:
  #   var u = newSocket(SOCK_DGRAM)
  #   discard u.connect("127.0.0.1", Port(0))

  # block:
  #   var r = newSocket(SOCK_RAW)
  #   discard r.connect("127.0.0.1")
  discard
