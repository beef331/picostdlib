import std/strutils

import picostdlib
import picostdlib/pico/cyw43_arch

proc scanResult(env: pointer; res: ptr Cyw43EvScanResultT): cint {.cdecl.} =
  if not res.isNil:
    var ssid = newString(res.ssidLen)
    copyMem(ssid[0].addr, res.ssid[0].addr, res.ssidLen)
    echo(
      "ssid: ", ssid,
      " rssi: ", res.rssi,
      " chan: ", res.channel,
      " bssid: ", res.bssid[0].toHex, ":", res.bssid[1].toHex, ":", res.bssid[2].toHex, ":", res.bssid[3].toHex, ":", res.bssid[4].toHex, ":", res.bssid[5].toHex,
      " sec: ", res.authMode
    )
  return 0

proc wifiScanExample*() =

  if cyw43ArchInit() != PicoErrorNone:
    echo "Wifi init failed!"
    return

  echo "Wifi init successful!"

  Cyw43WlGpioLedPin.put(High)

  cyw43ArchEnableStaMode()

  var scanOptions: Cyw43WifiScanOptionsT
  let err = cyw43WifiScan(cyw43State.addr, scanOptions.addr, nil, scanResult)
  if err == 0:
    echo "Performing wifi scan"
    while cyw43WifiScanActive(cyw43State.addr):
      tightLoopContents()
      sleepMs(10)
  else:
    echo "Failed to start wifi scan: ", err

  echo "Finished scan!"

  Cyw43WlGpioLedPin.put(Low)

  cyw43ArchDeinit()

when isMainModule:
  discard stdioInitAll()

  wifiScanExample()

  while true: tightLoopContents()
