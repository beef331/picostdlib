import std/times, std/volatile
import picostdlib
import picostdlib/[
  hardware/rtc,
  pico/cyw43_arch,
  lib/lwip_apps
]

{.emit: "// picostdlib import: pico_lwip_sntp".}

const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""
const NTP_SERVER {.strdefine.} = "pool.ntp.org"

var sntpTimeSynced = false
var syncedTimeAt = nilTime

proc sntpSetSystemTime(sec: uint32) {.exportc: "__sntp_set_system_time", cdecl.} =
  syncedTimeAt = getAbsoluteTime()
  var dt = createDatetime()
  let t = fromUnix(sec.int64).utc()
  dt.year = t.year.int16
  dt.month = t.month.int8
  dt.day = t.monthday.int8
  dt.dotw = int8(getDayOfWeek(t.monthday, t.month, t.year).ord + 1) mod 7
  dt.hour = t.hour.int8
  dt.min = t.minute.int8
  dt.sec = t.second.int8
  if rtcSetDatetime(dt.addr):
    volatileStore(sntpTimeSynced.addr, true)

proc runNtpTest() =
  rtcInit()

  sntpSetservername(0, NTP_SERVER.cstring)

  sntpSetoperatingmode(SntpOPmodePoll)
  sntpInit()

  while not volatileLoad(sntpTimeSynced.addr):
    tightLoopContents()
    sleepMs(10)

  var dt = createDatetime()
  if rtcGetDatetime(dt.addr):
    echo "Current RTC time: ", dt
  else:
    echo "No datetime set!"

  # we are done
  sntpStop()

proc ntpClientExample*() =
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

  runNtpTest()

  cyw43ArchDeinit()


when isMainModule:
  discard stdioInitAll()

  ntpClientExample()

  while true: tightLoopContents()
