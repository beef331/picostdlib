import std/uri
import std/strutils
import picostdlib
import picostdlib/[
  pico/cyw43_arch,
  net/picosocket
]

const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""

const HTTP_URL {.strdefine.} = "https://eu.httpbin.org/headers"
const HTTP_URL_PARSED = HTTP_URL.parseUri

const HOSTNAME = HTTP_URL_PARSED.hostname
const TCP_USE_TLS = HTTP_URL_PARSED.scheme.toLower() == "https"
const TCP_PORT = if TCP_USE_TLS: Port(443) else: Port(80)

const HTTP_PATH = (if HTTP_URL_PARSED.path == "": "/" else: HTTP_URL_PARSED.path) & (if HTTP_URL_PARSED.query != "": "?" & HTTP_URL_PARSED.query else: "")
const HTTP_REQUEST = "GET " & HTTP_PATH & " HTTP/1.1\r\n" &
                     "Host: " & HOSTNAME & "\r\n" &
                     "Connection: close\r\n" &
                     "\r\n"

proc runTcpClientTest() =
  var client {.cursor.} = newSocket(SOCK_STREAM)

  echo "connecting to ", HOSTNAME, ":", TCP_PORT
  when TCP_USE_TLS:
    client.setSecure(HOSTNAME)
  let conn = client.connect(HOSTNAME, TCP_PORT, proc (success: bool) =
    if client.getState() != STATE_CONNECTED or not success:
      echo "error connecting!!"
      return

    echo "connected!"
    echo client.getState()
    if client.write(HTTP_REQUEST) != HTTP_REQUEST.len:
      echo "failed to write http request"
      return
  )
  client.recvCb = proc(len: uint16; totLen: uint16) =
    if len == 0:
      # closed
      echo "connection closed"
      return
    echo (len, totLen)
    var buf = newString(200)
    while client.available() > 0:
      buf.setLen(200)
      let readLen = client.read(buf.len.uint16, buf[0].addr)
      if readLen <= 0:
        break
      buf.setLen(readLen)
      echo buf

  echo "connected? ", conn, " ", client.getState()

proc tcpClientExample*() =
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
    return
  else:
    echo "Connected"

  Cyw43WlGpioLedPin.put(Low)

  echo "ip: ", cyw43State.netif[0].ip_addr, " mask: ", cyw43State.netif[0].netmask, " gateway: ", cyw43State.netif[0].gw
  echo "hostname: ", cast[cstring](cyw43State.netif[0].hostname)

  runTcpClientTest()

  # cyw43ArchDeinit()


when isMainModule:
  discard stdioInitAll()

  tcpClientExample()

  while true:
    Cyw43WlGpioLedPin.put(High)
    sleepMs(100)
    Cyw43WlGpioLedPin.put(Low)
    sleepMs(100)
