import picostdlib
import picostdlib/[
  pico/cyw43_arch,
  net/httpclient
]

const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""

# to test chunked encoding: "https://httpbin.org/stream-bytes/5000?chunk_size=3000"
const HTTP_URL {.strdefine.} = "https://httpbin.org/headers"

proc runHttpClientTest() =
  var client = newHttpClient()

  echo "http client created."

  client.setUrl(HTTP_URL)

  client.get(proc (res: HttpResponse) =
    echo "http code: ", res.code
    echo res
  )

  client.recvCb = proc (data: string) =
    echo "body: ", repr data

  sleepMs(60*1000)

proc httpClientExample*() =
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

  echo "ip: ", cyw43State.netif[0].ipAddr, " mask: ", cyw43State.netif[0].netmask, " gateway: ", cyw43State.netif[0].gw
  echo "hostname: ", cast[cstring](cyw43State.netif[0].hostname)

  runHttpClientTest()

  cyw43ArchDeinit()


when isMainModule:
  discard stdioInitAll()

  httpClientExample()

  while true: tightLoopContents()
