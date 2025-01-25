import std/uri

import picostdlib
import picostdlib/[
  pico/cyw43_arch,
  lib/lwip
]
# import picostdlib/lib/lwip/[altcp_tls, dns]
# import picostdlib/lib/mbedtls/ssl

const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""
const URL {.strdefine.} = "https://eu.httpbin.org/headers"

const URL_PARSED = URL.parseUri

const TLS_CLIENT_SERVER       = URL_PARSED.hostname
const TLS_CLIENT_HTTP_REQUEST = "GET " & URL_PARSED.path & "?" & URL_PARSED.query & " HTTP/1.1\r\n" &
                                "Host: " & TLS_CLIENT_SERVER & "\r\n" &
                                "Connection: close\r\n" &
                                "\r\n"
const TLS_CLIENT_TIMEOUT_SECS = 15

type
  TlsClient = object
    pcb: ptr AltcpPcb
    complete: bool

var tlsConfig: ptr AltcpTlsConfig = nil

proc tlsClientClose(arg: pointer): ErrT {.cdecl.} =
  let state = cast[ptr TlsClient](arg)
  result = ERR_OK.ErrT

  state.complete = true

  if not state.pcb.isNil:
    state.pcb.altcpArg(nil)
    state.pcb.altcpPoll(nil, 0)
    state.pcb.altcpRecv(nil)
    state.pcb.altcpErr(nil)
    result = state.pcb.altcpClose()
    if result != ERR_OK.ErrT:
      echo "close failed ", $result.ErrEnumT, ", calling abort"
      state.pcb.altcpAbort()

    state.pcb = nil

proc tlsClientConnected(arg: pointer; pcb: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.} =
  let state = cast[ptr TlsClient](arg)
  if err != ERR_OK.ErrT:
    echo "connect failed ", $err.ErrEnumT
    return tlsClientClose(state)

  echo "connected to server, sending request"
  let errWrite = state.pcb.altcpWrite(TLS_CLIENT_HTTP_REQUEST.cstring, TLS_CLIENT_HTTP_REQUEST.len.uint16, TCP_WRITE_FLAG_COPY)
  if errWrite != ERR_OK.ErrT:
    echo "error writing data, err=", $errWrite.ErrEnumT
    return tlsClientClose(state)

  return ERR_OK.ErrT

proc tlsClientPoll(arg: pointer; pcb: ptr AltcpPcb): ErrT {.cdecl.} =
  echo "timed out"
  return tlsClientClose(arg)

proc tlsClientErr(arg: pointer; err: ErrT) {.cdecl.} =
  let state = cast[ptr TlsClient](arg)
  echo "tlsClientErr ", $err.ErrEnumT
  state.pcb = nil

proc tlsClientRecv(arg: pointer; pcb: ptr AltcpPcb; p: ptr Pbuf; err: ErrT): ErrT {.cdecl.} =
  let state = cast[ptr TlsClient](arg)
  if p.isNil:
    echo "connection closed"
    return tlsClientClose(state)

  if p.totLen > 0:
    var buf = newString(p.totLen)
    discard p.pbufCopyPartial(buf[0].addr, p.totLen, 0)
    echo "data recieved: ", buf
    pcb.altcpRecved(p.totLen)

  discard p.pbufFree()

  return ERR_OK.ErrT

proc tlsClientConnectToServerIp(ipaddr: ptr IpAddrT; state: ptr TlsClient) {.cdecl.} =
  let port: uint16 = 443

  echo "connecting to server IP ", $ipaddr, " port ", port

  var err = state.pcb.altcpConnect(ipaddr, port, tlsClientConnected)
  if err != ERR_OK.ErrT:
    echo "error initiating connect, err=", $err.ErrEnumT
    discard tlsClientClose(state)

proc tlsClientDnsFound(hostname: cstring; ipaddr: ptr IpAddrT; arg: pointer) {.cdecl.} =
  if not ipaddr.isNil:
    echo "DNS resolving complete"
    tlsClientConnectToServerIp(ipaddr, cast[ptr TlsClient](arg))

  else:
    echo "error resolving hostname ", cast[cstring](hostname)
    discard tlsClientClose(arg)

proc tlsClientOpen(hostname: cstring; arg: pointer): bool =
  var err: ErrT
  var serverIp: IpAddrT
  let state = cast[ptr TlsClient](arg)

  state.pcb = altcpTlsNew(tlsConfig, IPADDR_TYPE_ANY.ord)
  if state.pcb.isNil:
    echo "failed to create pcb"
    return false

  state.pcb.altcpArg(state)
  state.pcb.altcpPoll(tlsClientPoll, TLS_CLIENT_TIMEOUT_SECS)
  state.pcb.altcpRecv(tlsClientRecv)
  state.pcb.altcpErr(tlsClientErr)

  ## Set SNI
  discard mbedtlsSslSetHostname(cast[ptr MbedtlsSslContext](altcpTlsContext(state.pcb)), hostname)

  echo "resolving ", hostname

  cyw43ArchLwipBegin()

  err = dnsGethostbyname(hostname, addr(serverIp), tlsClientDnsFound, state)

  if err == ERR_OK.ErrT:
    tlsClientConnectToServerIp(addr(serverIp), state)
  elif err != ERR_INPROGRESS.ErrT:
    echo "error initiating DNS resolving, err=", $err.ErrEnumT
    discard tlsClientClose(state)

  cyw43ArchLwipEnd()

  return err == ERR_OK.ErrT or err == ERR_INPROGRESS.ErrT

proc tlsClientExample*() =
  if cyw43ArchInit() != PicoErrorNone:
    echo "Wifi init failed!"
    return

  echo "Wifi init successful!"

  Cyw43WlGpioLedPin.put(High)

  cyw43ArchEnableStaMode()

  var ssid = WIFI_SSID
  if ssid == "":
    stdout.write("Enter Wifi SSID: ")
    stdout.flushFile()
    ssid = stdinReadLine()

  var password = WIFI_PASSWORD
  if password == "":
    stdout.write("Enter Wifi password: ")
    stdout.flushFile()
    password = stdinReadLine()

  echo "Connecting to Wifi ", ssid

  let err = cyw43ArchWifiConnectTimeoutMs(ssid.cstring, password.cstring, AuthWpa2AesPsk, 30000)
  if err != PicoErrorNone:
    echo "Failed to connect! Error: ", $err
  else:
    echo "Connected"

  Cyw43WlGpioLedPin.put(Low)

  echo "ip: ", cyw43State.netif[0].ipAddr, " mask: ", cyw43State.netif[0].netmask, " gateway: ", cyw43State.netif[0].gw
  echo "hostname: ", cast[cstring](cyw43State.netif[0].hostname)

  echo "Opening TLS connection..."

  tlsConfig = altcpTlsCreateConfigClient(nil, 0)

  let state = new(TlsClient)
  state.complete = false

  if not tlsClientOpen(TLS_CLIENT_SERVER.cstring, state[].addr):
    return

  while not state.complete:
    tightLoopContents()
    sleepMs(10)

  echo "Completed!"

  altcpTlsFreeConfig(tlsConfig)
  tlsConfig = nil

  cyw43ArchDeinit()


when isMainModule:
  discard stdioInitAll()

  tlsClientExample()

  while true: tightLoopContents()
