
import ../pico/cyw43_arch

type
  Port* = distinct uint16
  TcpClient* = object
    pcb: ptr AltcpPcb
    data: string
    rxBuffer: string
  DnsResult = object
    available: int
    remoteAddr: IpAddrT

proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}

# proc `=destroy`*(self: TcpClient) =
#   withLwipLock:
#     if not self.pcb.isNil:
#       altcpAbort(self.pcb)
#     `=destroy`(self.data)
#     `=destroy`(self.rxBuffer)

func getTcpPcb(altcpPcb: ptr AltcpPcb): ptr TcpPcb =
  return cast[ptr TcpPcb](altcpPcb.state)

proc onDnsFound(name: cstring; ipaddr: ptr IpAddrT; arg: pointer) {.cdecl.} =
  let dnsResult = cast[ptr DnsResult](arg)
  if not ipaddr.isNil:
    dnsResult.remoteAddr = ipaddr[]
    dnsResult.available = 1
  else:
    dnsResult.available = -1

proc onConnect(arg: pointer; pcb: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.} =
  if err == ErrOk.ord:
    echo "Socket connected"
  else:
    echo "Could not connect to socket err ", err
  return err

proc onError(arg: pointer; err: ErrT) {.cdecl.} =
  let tcpClient = cast[ptr TcpClient](arg)
  if tcpClient.isNil: return
  withLwipLock:
    if not tcpClient.pcb.isNil:
      if err != ErrAbrt.ord:
        echo "Error received from tcp socket. err = ", err
        tcpClient.pcb.altcpAbort()
        tcpClient.pcb = nil

proc onRecv(arg: pointer; pcb: ptr AltcpPcb; pbuf: ptr Pbuf; err: ErrT): ErrT {.cdecl.} =
  let tcpClient = cast[ptr TcpClient](arg)
  result = ErrOk.ord
  withLwipLock:
    if tcpClient.isNil:
      pcb.altcpAbort()
      result = ErrAbrt.ord
    elif pcb.isNil or tcpClient.pcb != pcb:
      tcpClient.rxBuffer.setLen(0)
      if not pbuf.isNil:
        discard pbuf.pbufFree()
      tcpClient.pcb = nil
      pcb.altcpAbort()
      result = ErrAbrt.ord
    elif not pbuf.isNil:
      let oldLen = tcpClient.rxBuffer.len.uint
      let newLen = oldLen + pbuf.totLen.uint
      tcpClient.rxBuffer.setLen(newLen)
      let pbufLen = pbuf.pbufCopyPartial(tcpClient.rxBuffer[oldLen].addr, pbuf.totLen, 0)
      tcpClient.rxBuffer.setLen(oldLen + pbufLen)
      if newLen != oldLen + pbufLen:
        echo "pbuf len diff! ", (oldLen, pbufLen, oldLen + pbufLen, newLen)
      pcb.altcpRecved(pbufLen)
      discard pbuf.pbufFree()
    else:
      echo "Disconnected from remote"
      tcpClient.pcb.altcpAbort()
      tcpClient.pcb = nil
      result = ErrAbrt.ord

proc onPoll(arg: pointer; pcb: ptr AltcpPcb): ErrT {.cdecl.} =
  let tcpClient = cast[ptr TcpClient](arg)
  result = ErrOk.ord
  withLwipLock:
    if not tcpClient.isNil and not pcb.isNil and tcpClient.pcb == pcb:
      result = pcb.altcpOutput()

proc close*(self: var TcpClient) =
  withLwipLock:
    if not self.pcb.isNil:
      self.pcb.altcpAbort()

proc connect*(self: var TcpClient; host: string; port: Port; tls: bool = false; sniHostname: string = ""): bool =
  var dnsResult: DnsResult
  if dnsGethostbyname(host, dnsResult.remoteAddr.addr, onDnsFound, dnsResult.addr) == ErrInprogress.ord:
    dnsResult.available = 0
    while true:
      cyw43Wait(1000)
      withLwipLock:
        if dnsResult.available == 1:
          break
        elif dnsResult.available < 0:
          echo "Could not find dns"
          return false
  withLwipLock:
    var allocator: AltcpAllocatorT
    allocator.alloc = altcpTcpAlloc
    allocator.arg = nil
    self.pcb = altcpNewIpType(allocator.addr, IPADDR_TYPE_ANY.ord)

    if tls:
      self.pcb = altcpTlsWrap(altcpTlsCreateConfigClient(nil, 0), self.pcb)
      let sslCtx = cast[ptr MbedtlsSslContext](altcpTlsContext(self.pcb))
      ## Set SNI
      if sniHostname.len != 0 and mbedtlsSslSetHostname(sslCtx, sniHostname) != 0:
        echo "mbedtls ssl set hostname failed!"
        self.pcb.altcpAbort()
        self.pcb = nil
        return false

    echo "Connecting to ", $dnsResult.remoteAddr, " port ", port, " (", cast[uint](self.addr), ")"
    self.pcb.altcpArg(self.addr)
    self.pcb.altcpPoll(onPoll, 10)
    self.pcb.altcpRecv(onRecv)
    self.pcb.altcpErr(onError)
    let res = self.pcb.altcpConnect(dnsResult.remoteAddr.addr, port.uint16, onConnect)
    if res != ErrOk.ord:
      echo "Failed to connect! ", res
      self.pcb.altcpAbort()
      self.pcb = nil
      return false
  return true

proc isConnected*(self: var TcpClient): int =
  if self.rxBuffer.len > 0: return 1
  if self.pcb.isNil: return -1
  withLwipLock:
    case self.pcb.getTcpPcb().state:
    of ESTABLISHED: return 2
    of SYN_SENT, SYN_RCVD: return 1
    of CLOSED, CLOSING, CLOSE_WAIT: return -1
    else: return 1

proc poll*(self: var TcpClient; timeoutUs: Natural): int =
  cyw43Wait(timeoutUs)
  withLwipLock:
    return if self.rxBuffer.len == 0: 0 else: 1

proc write*(self: var TcpClient; data: openArray[byte]|openArray[char]|string): int =
  var err: ErrT

  if self.pcb.isNil or self.pcb.altcpSndBuf() == 0:
    echo "Could not send data through connection since its not ready yet"
    return -1

  withLwipLock:
    err = self.pcb.altcpWrite(data[0].addr, data.len.uint16, 0)
    if err != ErrOk.ord:
      echo "Failed to write to socket"
      return -1
    return data.len

proc read*(self: var TcpClient): int =
  withLwipLock:
    if self.rxBuffer.len != 0:
      if self.data.len > 0:
        self.data.add(self.rxBuffer)
      else:
        self.data = self.rxBuffer
    result = self.rxBuffer.len
    self.rxBuffer = ""
