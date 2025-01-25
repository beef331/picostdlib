import picostdlib
import picostdlib/pico/cyw43_arch
import picostdlib/net/mqttclient


const WIFI_SSID {.strdefine.} = ""
const WIFI_PASSWORD {.strdefine.} = ""


const MQTT_HOST {.strdefine.} = "test.mosquitto.org"
const MQTT_PORT {.intdefine.} = 8883

const MQTT_CLIENT_ID {.strdefine.} = "PicoW"
const MQTT_USER {.strdefine.} = ""
const MQTT_PASS {.strdefine.} = ""
const MQTT_USE_TLS {.booldefine.} = true

const MQTT_TOPIC {.strdefine.} = "picostdlib/mqttclient"


proc runMqttClientTest() =
  var client = newMqttClient()

  let clientConfig = MqttClientConfig(
    clientId: MQTT_CLIENT_ID,
    user: MQTT_USER,
    password: MQTT_PASS,
    keepAlive: 60,
    tls: MQTT_USE_TLS
  )

  client.setConnectionCallback(proc (connStatus: MqttConnectionStatusT) =
    if connStatus == MqttConnectionStatusT.MqttConnectAccepted:
      echo "connected!"

      discard client.subscribe(MQTT_TOPIC, Qos1)
      discard client.publish(MQTT_TOPIC, "hello world!", Qos1)
    else:
      echo "couldnt connect! status: " & $connStatus
      client = nil
  )

  client.setInpubCallback(proc (topic: string; payload: string) =
    echo "got topic " & topic
    echo "got payload:"
    echo payload

    client.setConnectionCallback(nil)
    client.setInpubCallback(nil)
    client.disconnect()
    client = nil # client is destroyed here
  )

  echo "connecting to ", MQTT_HOST

  if client.connect(MQTT_HOST, Port(MQTT_PORT), clientConfig):
    echo "connecting..."
  else:
    echo "failed to connect to mqtt server"
    client = nil

  # fast blink while connecting/connected
  while client != nil:
    Cyw43WlGpioLedPin.put(High)
    sleepMs(100)
    Cyw43WlGpioLedPin.put(Low)
    sleepMs(100)

proc mqttClientExample*() =
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

  runMqttClientTest()

  # cyw43ArchDeinit()


when isMainModule:
  discard stdioInitAll()

  mqttClientExample()

  while true:
    Cyw43WlGpioLedPin.put(High)
    sleepMs(500)
    Cyw43WlGpioLedPin.put(Low)
    sleepMs(500)
