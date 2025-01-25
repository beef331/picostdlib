import ../lib/lwip_apps
import ../pico/cyw43_arch
import ./common
import ./dns

export common

export MqttConnectClientInfoT
export MqttConnectionStatusT
export ErrEnumT
export LwipIanaPortNumber

{.emit: "// picostdlib import: pico_lwip_mqtt".}

when not defined(release) or defined(debugMqtt):
  template debugv(text: string) = echo text
else:
  template debugv(text: string) = discard

type
  MqttClient* = ref object
    client: ptr MqttClientT
    connectionCb: MqttConnectionCb
    # requests: array[MQTT_REQ_MAX_IN_FLIGHT, MqttRequest]
    inpubCb: MqttInpubCb
    inpubTopic: string
    inpubBuf: string
    inpubBufOffset: uint32
    isConnecting*: bool
    tlsConfig: ptr AltcpTlsConfig

  MqttClientConfig* = object
    clientId*: string
    user*: string
    password*: string
    keepAlive*: uint16
    willTopic*: string
    willMsg*: string
    willQos*: MqttQos
    willRetain*: bool
    tls*: bool

  MqttQos* {.size: sizeof(uint8).} = enum
    Qos0
    Qos1
    Qos2

  # MqttRequest* = object
  #   topic: string
  #   cb: MqttRequestCb

  MqttConnectionCb* = proc (connStatus: MqttConnectionStatusT)
  # MqttRequestCb* = proc (err: ErrEnumT)
  MqttInpubCb* = proc (topic: string; payload: string)

proc `=destroy`*(self: typeof(MqttClient()[])) =
  debugv("Destroying MQTT client")
  let selfptr = self.addr
  selfptr.connectionCb = nil
  # selfptr.requests.reset()
  selfptr.inpubCb = nil
  selfptr.inpubTopic.reset()
  selfptr.inpubBuf.reset()
  # selfptr.config.reset()
  if self.client != nil:
    mqttDisconnect(self.client)
    mqttClientFree(self.client)
    selfptr.client = nil
  if self.tlsConfig != nil:
    altcpTlsFreeConfig(self.tlsConfig)
    selfptr.tlsConfig = nil

proc newMqttClient*(): MqttClient =
  result = MqttClient()
  result.client = mqttClientNew()

proc mqttConnectionCb(client: ptr MqttClientT; arg: pointer; status: MqttConnectionStatusT) {.cdecl.} =
  assert(arg != nil)
  let self = cast[MqttClient](arg)
  assert(self.client == client)
  debugv(":mqtt connection status: " & $status)
  self.isConnecting = false
  let cb = self.connectionCb
  if status != MQTT_CONNECT_ACCEPTED:
    self.connectionCb = nil
  if cb != nil:
    cb(status)

# proc mqttRequestCb(arg: pointer; err: ErrT) {.cdecl.} =
#   assert(arg != nil)
#   let request = cast[ptr MqttRequest](arg)
#   assert(request != nil)
#   debugv(":mqtt request " & $cast[ErrEnumT](err))
#   if request.cb != nil:
#     request.cb(err.ErrEnumT)
#     request.cb = nil

proc mqttInpubCb(arg: pointer; topic: cstring; totLen: uint32) {.cdecl.} =
  assert(arg != nil)
  let self = cast[MqttClient](arg)
  debugv(":mqtt inpub topic " & $topic & " size " & $totLen)
  if self.inpubCb != nil:
    self.inpubTopic = $topic
    self.inpubBufOffset = 0
    self.inpubBuf.setLen(totLen)

proc mqttDataCb(arg: pointer; data: ptr uint8; len: uint16; flags: uint8) {.cdecl.} =
  assert(arg != nil)
  let self = cast[MqttClient](arg)
  debugv(":mqtt inpub data size " & $len)
  if self.inpubCb != nil:
    copyMem(self.inpubBuf[self.inpubBufOffset].addr, data, len)
    self.inpubBufOffset += len
    if (flags and MQTT_DATA_FLAG_LAST) == 1:
      self.inpubCb(self.inpubTopic, self.inpubBuf)
      self.inpubTopic.reset()
      self.inpubBuf.reset()
      self.inpubBufOffset = 0

proc isConnected*(self: MqttClient): bool =
  if self.client == nil: return false
  withLwipLock:
    return mqttClientIsConnected(self.client).bool

proc connect*(self: MqttClient; ipaddr: ptr IpAddrT; port: Port = Port(LWIP_IANA_PORT_MQTT); config: MqttClientConfig): bool =
  if self.connectionCb == nil or self.isConnecting or self.isConnected():
    return false
  var clientInfo = MqttConnectClientInfoT()
  if config.clientId.len > 0:
    clientInfo.clientId = config.clientId.cstring
  if config.user.len > 0:
    clientInfo.clientUser = config.user.cstring
  if config.password.len > 0:
    clientInfo.clientPass = config.password.cstring
  clientInfo.keepAlive = config.keepAlive
  if config.willTopic.len > 0:
    clientInfo.willTopic = config.willTopic.cstring
    if config.willMsg.len > 0:
      clientInfo.willMsg = config.willMsg.cstring
    if config.willMsg.len > 0:
      clientInfo.willMsg = config.willMsg.cstring
    # clientInfo.willMsgLen = config.willMsg.len.uint8
    clientInfo.willQos = config.willQos.uint8
    clientInfo.willRetain = config.willRetain.uint8

  if config.tls and self.tlsConfig == nil:
    self.tlsConfig = altcpTlsCreateConfigClient(nil, 0)
    clientInfo.tlsConfig = self.tlsConfig

  withLwipLock:
    debugv(":mqtt connecting to " & $ipaddr & ":" & $port)
    self.isConnecting = true
    let err = mqttClientConnect(self.client, ipaddr, port.uint16, mqttConnectionCb, cast[pointer](self), clientInfo.unsafeAddr).ErrEnumT
    if err != ErrOk:
      debugv(":mqtt connect error: " & $err)
      return false
  return true

proc connect*(self: MqttClient; host: string; port: Port = Port(LWIP_IANA_PORT_MQTT); config: MqttClientConfig): bool =
  if self.connectionCb == nil or self.isConnecting or self.isConnected():
    return false

  var remoteAddr = IpAddrT()
  let isIp = ipAddrAton(host.cstring, remoteAddr.addr).bool

  if isIp:
    return self.connect(remoteAddr.addr, port, config)
  let res = getHostByName(host, remoteAddr)
  if res:
    return self.connect(remoteAddr.addr, port, config)
  return false

proc disconnect*(self: MqttClient) =
  withLwipLock:
    self.isConnecting = false
    mqttDisconnect(self.client)

proc setInpubCallback*(self: MqttClient; cb: MqttInpubCb) =
  self.inpubCb = cb
  if cb != nil:
    mqttSetInpubCallback(self.client, mqttInpubCb, mqttDataCb, cast[pointer](self))
  else:
    mqttSetInpubCallback(self.client, nil, nil, nil)

proc setConnectionCallback*(self: MqttClient; cb: MqttConnectionCb) =
  self.connectionCb = cb

proc subscribe*(self: MqttClient; topic: string; qos: MqttQos = Qos0): bool =
  withLwipLock:
    debugv(":mqtt subscribe " & topic)
    let err = mqttSubscribe(self.client, topic, qos.uint8, nil, nil).ErrEnumT
    if err != ErrOk:
      debugv(":mqtt subscribe error " & topic & ": " & $err)
      return false
  return true

proc unsubscribe*(self: MqttClient; topic: string): bool =
  withLwipLock:
    debugv(":mqtt unsubscribing " & topic)
    let err = mqttUnsubscribe(self.client, topic.cstring, nil, nil).ErrEnumT
    if err != ErrOk:
      debugv(":mqtt unsubscribe error: " & $err)
      return false
  return true

proc publish*(self: MqttClient; topic: string; payload: string; qos: MqttQos = Qos0; retain: bool = false): bool =
  withLwipLock:
    debugv(":mqtt publish " & topic & " payload:")
    debugv(payload)

    let err = mqttPublish(self.client, topic.cstring, payload.cstring, payload.len.uint16, qos.uint8, retain.uint8, nil, nil).ErrEnumT
    if err != ErrOk:
      debugv(":mqtt publish error: " & $err)
      return false
  return true
