# USB Device API

import ./helpers
{.localPassC: "-I" & picoSdkPath & "/lib/tinyusb/src".}
{.push header: "tusb.h".}
type UsbSpeed* {.pure, importc: "tusb_speed_t".} = enum Full, Low, High

proc usbInit*(): bool {.importc: "tusb_init".}
## Initialize USB stack. This proc must be called exactly once during program
## initialization.

proc usbInitialized*: bool {.importc: "tusb_inited".}
## Check if USB stack is initialized.

# I don't think we need this. None of the TinyUSB examples ever use it.
# proc usbDeviceInit*: bool {.importc: "tud_init".}
# ## Initialize USB Device stack

proc usbDeviceTask* {.importc: "tud_task".}
## Task function to be called frequently in main loop.

proc usbDeviceConnected*: bool {.importc: "tud_connected".}
## Check if device is connected (may not mounted/configured yet)
## True if just got out of Bus Reset and received the very first data from host

proc usbDeviceMounted*: bool {.importc: "tud_mounted".}
## Check if device is connected and configured

proc usbDeviceSuspended*: bool {.importc: "tud_suspended".}
## Check if device is suspended

proc usbDeviceRemoteWakeup*: bool {.importc: "tud_remote_wakeup".}
## Remote wake up host, only if suspended and enabled by host

proc usbDeviceDisconnect*: bool {.importc: "tud_disconnect".}
## Enable pull-up resistor on D+ D-
## Return false on unsupported MCUs

proc usbDeviceConnect*: bool {.importc: "tud_connect".}
## Disable pull-up resistor on D+ D-
## Return false on unsupported MCUs

{.pop.}

# Board API

{.push header: "bsp/board.h".}
proc boardInit*() {.importc: "board_init", header: "bsp/board.h".}
## Initialize on-board peripherals : led, button, uart and USB

proc board_button_read(): uint32 {.importc: "board_button_read", header: "bsp/board.h".}
{.pop.}

proc getBoardButton*: bool {.inline.} = board_button_read() > 0
## Read state on onboard BOOTSEL button on RPi Pico. Returns `true` if button
## is pressed.

# HID Device API

type KeyboardKeypress* {.size: 1.} = enum
  ## HID usage codes for the Keyboard Usage Page.
  keyNone = 0x00
  keyA = 0x04
  keyB = 0x05
  keyC = 0x06
  keyD = 0x07
  keyE = 0x08
  keyF = 0x09
  keyG = 0x0A
  keyH = 0x0B
  keyI = 0x0C
  keyJ = 0x0D
  keyK = 0x0E
  keyL = 0x0F
  keyM = 0x10
  keyN = 0x11
  keyO = 0x12
  keyP = 0x13
  keyQ = 0x14
  keyR = 0x15
  keyS = 0x16
  keyT = 0x17
  keyU = 0x18
  keyV = 0x19
  keyW = 0x1A
  keyX = 0x1B
  keyY = 0x1C
  keyZ = 0x1D
  key1 = 0x1E
  key2 = 0x1F
  key3 = 0x20
  key4 = 0x21
  key5 = 0x22
  key6 = 0x23
  key7 = 0x24
  key8 = 0x25
  key9 = 0x26
  key0 = 0x27
  keyEnter = 0x28
  keyEscape = 0x29
  keyBackspace = 0x2A
  keyTab = 0x2B
  keySpace = 0x2C
  keyMinus = 0x2D
  keyEqual = 0x2E
  keyBracketLeft = 0x2F
  keyBracketRight = 0x30
  keyBackslash = 0x31
  keyEurope1 = 0x32
  keySemicolon = 0x33
  keyApostrophe = 0x34
  keyGrave = 0x35
  keyComma = 0x36
  keyPeriod = 0x37
  keySlash = 0x38
  keyCapsLock = 0x39
  keyF1 = 0x3A
  keyF2 = 0x3B
  keyF3 = 0x3C
  keyF4 = 0x3D
  keyF5 = 0x3E
  keyF6 = 0x3F
  keyF7 = 0x40
  keyF8 = 0x41
  keyF9 = 0x42
  keyF10 = 0x43
  keyF11 = 0x44
  keyF12 = 0x45
  keyPrintScreen = 0x46
  keyScrollLock = 0x47
  keyPause = 0x48
  keyInsert = 0x49
  keyHome = 0x4A
  keyPageUp = 0x4B
  keyDelete = 0x4C
  keyEnd = 0x4D
  keyPageDown = 0x4E
  keyArrowRight = 0x4F
  keyArrowLeft = 0x50
  keyArrowDown = 0x51
  keyArrowUp = 0x52
  keyNumLock = 0x53
  keyKeypadDivide = 0x54
  keyKeypadMultiply = 0x55
  keyKeypadSubtract = 0x56
  keyKeypadAdd = 0x57
  keyKeypadEnter = 0x58
  keyKeypad1 = 0x59
  keyKeypad2 = 0x5A
  keyKeypad3 = 0x5B
  keyKeypad4 = 0x5C
  keyKeypad5 = 0x5D
  keyKeypad6 = 0x5E
  keyKeypad7 = 0x5F
  keyKeypad8 = 0x60
  keyKeypad9 = 0x61
  keyKeypad0 = 0x62
  keyKeypadDecimal = 0x63
  keyEurope2 = 0x64
  keyApplication = 0x65
  keyPower = 0x66
  keyKeypadEqual = 0x67
  keyF13 = 0x68
  keyF14 = 0x69
  keyF15 = 0x6A
  keyF16 = 0x6B
  keyF17 = 0x6C
  keyF18 = 0x6D
  keyF19 = 0x6E
  keyF20 = 0x6F
  keyF21 = 0x70
  keyF22 = 0x71
  keyF23 = 0x72
  keyF24 = 0x73
  keyExecute = 0x74
  keyHelp = 0x75
  keyMenu = 0x76
  keySelect = 0x77
  keyStop = 0x78
  keyAgain = 0x79
  keyUndo = 0x7A
  keyCut = 0x7B
  keyCopy = 0x7C
  keyPaste = 0x7D
  keyFind = 0x7E
  keyMute = 0x7F
  keyVolumeUp = 0x80
  keyVolumeDown = 0x81
  keyLockingCapsLock = 0x82
  keyLockingNumLock = 0x83
  keyLockingScrollLock = 0x84
  keyKeypadComma = 0x85
  keyKeypadEqualSign = 0x86
  keyKanji1 = 0x87
  keyKanji2 = 0x88
  keyKanji3 = 0x89
  keyKanji4 = 0x8A
  keyKanji5 = 0x8B
  keyKanji6 = 0x8C
  keyKanji7 = 0x8D
  keyKanji8 = 0x8E
  keyKanji9 = 0x8F
  keyLang1 = 0x90
  keyLang2 = 0x91
  keyLang3 = 0x92
  keyLang4 = 0x93
  keyLang5 = 0x94
  keyLang6 = 0x95
  keyLang7 = 0x96
  keyLang8 = 0x97
  keyLang9 = 0x98
  keyAlternateErase = 0x99
  keySysreqAttention = 0x9A
  keyCancel = 0x9B
  keyClear = 0x9C
  keyPrior = 0x9D
  keyReturn = 0x9E
  keySeparator = 0x9F
  keyOut = 0xA0
  keyOper = 0xA1
  keyClearAgain = 0xA2
  keyCrselProps = 0xA3
  keyExsel = 0xA4

type KeyModifier* {.pure, size: 1.} = enum
  ## HID Keyboard modifier codes, to be used as set.
  lCtrl, lShift, lAlt, lGui, rCtrl, rShift, rAlt, rGui

type KeyboardLed* {.pure, importc: "hid_keyboard_led_bm_t".} = enum
  numLock, capsLock, scrollLock, compose, kana

type GamepadButton* {.pure.} = enum
  ## Represent up to 32 buttons for HID gamepad input reports
  b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15, b16,
  b17, b18, b19, b20, b21, b22, b23, b24, b25, b26, b27, b28, b29, b30, b31

type GamepadHatPosition* {.pure, size: 1.} = enum
  ## Represent position of HID gamepad Hat or D-Pad.
  centered  = 0
  up        = 1
  upRight   = 2
  right     = 3
  downRight = 4
  down      = 5
  downLeft  = 6
  left      = 7
  upLeft    = 8

type MouseButton* {.pure, size: 1.} = enum
  ## Represents 5 standards buttons for HID mouse input reports
  left, right, middle, back, forward

{.push header: "tusb.h".}
type
  HidReportType* {.pure, importc: "hid_report_type_t".} = enum
    ## HID Request Report Type
    invalid, input, output, feature

  HidProtocol* {.pure, importc: "hid_protocol_type_t".} = enum
    none, mouse, keyboard

  HidSubClass* {.pure, importc: "hid_subclass_type_t".} = enum
    none, boot

  HidDescriptorType* {.pure, importc: "hid_descriptor_type_t".} = enum
    hid = 0x21, report = 0x22, physical = 0x23

  HidRequestType* {.pure, importc: "hid_request_type_t".} = enum
    getReport = 0x01,
    getIdle = 0x02,
    getProtocol = 0x03,
    setReport = 0x09,
    setIdle = 0x0a,
    setProtocol = 0x0b

  HidCountryCode* {.pure, importc: "hid_country_code_t".} = enum
    notSupported,
    arabic,
    belgian,
    canadianBilingual,
    canadianFrench,
    czechRepublic,
    dannish,
    finnish,
    french,
    german,
    greek,
    hebrew,
    hungary,
    international,
    italian,
    japanKatakana
    korean,
    latinAmerican,
    netherlandsDutch,
    norwegian,
    persianFarsi,
    poland,
    portuguese,
    russia,
    slovakia,
    spanish,
    sweedish,
    swissFrench,
    swissGerman,
    switzerland,
    taiwan,
    turkishQ,
    uk,
    us,
    yugoslavia,
    turkish_f

  MouseReport* {.packed, importc: "hid_mouse_report_t".} = object
    buttons*: set[MouseButton]
    x*, y*, wheel*, pan*: int8

  KeyboardReport* {.importc: "hid_keyboard_report_t", packed.} = object
    modifier*: set[KeyModifier]
    reserved: uint8
    keycode*: array[6, KeyboardKeypress]
{.pop.}

static:
  assert sizeof(set[KeyModifier]) == 1

type UsbHidInterface* = distinct range[0'u8 .. uint8.high]
## Used to represent the HID interface number, as configured by `CFG_TUD_HID`.
## Eg. if `CFG_TUD_HID` is `1`, then only `0.UsbHidInterface` would be valid.
## If `CFG_TUD_HID` is `2`, then we could use `0.UsbHidInterface` and
## `1.UsbHidInterface`.
##
## Note: A single HID interface can send multiple report types, eg, keyboard
## and mouse. See the `id` parameter in the HID API procs for the report id.

{.push header: "tusb.h".}

proc ready*(itf: UsbHidInterface): bool {.importc: "tud_hid_n_ready".}
  ## Check if the interface is ready to use

proc sendReport*(itf: UsbHidInterface, id: byte, report: pointer, len: byte):
    bool {.importc: "tud_hid_n_report".}
  ## Send input report to host.
  ##
  ## **Parameters:**
  ##
  ## ==========  ===================
  ## **itf**     HID interface index
  ## **id**      Report index for the interface.
  ## **report**  Pointer to raw byte array containing report data (must
  ##             conform to the report descriptor)
  ## **len**     Report data array length

proc sendKeyboardReport(itf: UsbHidInterface, id: byte, modifier: uint8,
    keycode: ptr uint8): bool {.importc: "tud_hid_n_keyboard_report".}

proc sendMouseReport*(itf: UsbHidInterface, id: byte,
    buttons: set[MouseButton], x, y, vertical, horizontal: int8): bool
    {.importc: "tud_hid_n_mouse_report".}
  ## Convenient helper to send mouse report if application
  ## use template layout report as defined by hid_mouse_report_t
  ## **Parameters:**
  ##
  ## ==========                  ===================
  ## **itf**                     HID interface index.
  ## **id**                      Report index for the interface.
  ## **buttons**                 Which buttons are currently pressed.
  ## **x, y**                    Relative x and y displacement since previous
  ##                             report.
  ## **horizontal, vertical**    Relative horizontal and vertical scroll since
  ##                             previous report.

proc sendGamepadReport*(itf: UsbHidInterface, id: uint8,
    x, y, z, rz, rx, ry: int8, hat: GamepadHatPosition,
    buttons: set[GamepadButton]): bool
    {.importc: "tud_hid_n_gamepad_report".}
  ## Gamepad: convenient helper to send gamepad report if application
  ## use template layout report TUD_HID_REPORT_DESC_GAMEPAD
  ##
  ## ==========   ===================
  ## **itf**      HID interface index.
  ## **id**       Report index for the interface.
  ## **buttons**  Which buttons are currently pressed.
  ## **x, y**     Left analog stick position
  ## **z, rz**    Right analog stick position
  ## **rx, ry**   Left and right analog trigger position
  ## **hat**      Position of gamepad hat or D-Pad
{.pop.}

proc sendMouseReport*(itf: UsbHidInterface, id: byte, report: MouseReport): bool =
  ## Convenient helper to send mouse report if application
  ## use template layout report as defined by hid_mouse_report_t
  ## **Parameters:**
  ##
  ## ==========                  ===================
  ## **itf**                     HID interface index.
  ## **id**                      Report index for the interface.
  ## **report**                  `MouseReport` object to send.
  sendReport(itf, id, report.unsafeAddr, sizeof(MouseReport).uint8)

proc sendKeyboardReport*(itf: UsbHidInterface, id: byte, modifiers: set[KeyModifier],
    key0, key1, key2, key3, key4, key5: KeyboardKeypress = keyNone): bool =
  ## Convenient helper to send keyboard report if application
  ## uses template layout report as defined by hid_keyboard_report_t
  ##
  ## ==========     ===================
  ## **itf**        HID interface index.
  ## **id**         Report index for the interface.
  ## **modifiers**  Currently pressed modifier keys
  ## **key0-5**     Up to 6 keys currently pressed

  let keyArr = [key0, key1, key2, key3, key4, key5]
  result = sendKeyboardReport(itf, id, cast[uint8](modifiers), cast[ptr uint8](keyArr.unsafeAddr))

proc sendKeyboardReport*(itf: UsbHidInterface, id: byte, modifiers: set[KeyModifier],
    keys: array[6, KeyboardKeypress]): bool =
  ## Convenient helper to send keyboard report if application
  ## uses template layout report as defined by hid_keyboard_report_t
  ##
  ## ==========     ===================
  ## **itf**        HID interface index.
  ## **id**         Report index for the interface.
  ## **modifiers**  Currently pressed modifier keys
  ## **keys**       Up to 6 keys currently pressed (use `keyNone` if fewer keys are desired)

  var k = keys
  result = sendKeyboardReport(itf, id, cast[uint8](modifiers), cast[ptr uint8](k[0].addr))

proc sendKeyboardReport*(itf: UsbHidInterface, id: byte, report: KeyboardReport): bool =
  ## Convenient helper to send keyboard report if application
  ## uses template layout report as defined by hid_keyboard_report_t
  ##
  ## ==========     ===================
  ## **itf**        HID interface index.
  ## **id**         Report index for the interface.
  ## **report**     `KeyReport` object to send.
  sendReport(itf, id, report.unsafeAddr, sizeof(KeyboardReport).uint8)


# CDC

type CdcStopBits* {.size: 1, pure.} = enum Bits1, Bits1p5, Bits2

type CdcParity* {.size: 1, pure.} = enum None, Odd, Even, Mark, Space

type CdcDataBits* {.size: 1, pure.} = enum Bits5, Bits6, Bits7, Bits8, Bits16

type CdcLineCoding* {.importc: "cdc_line_coding_t", packed, completeStruct.} = object
  bitRate: uint32
  stopBits: CdcStopBits #  0: 1 stop bit - 1: 1.5 stop bits - 2: 2 stop bits
  parity: CdcParity     #  0: None - 1: Odd - 2: Even - 3: Mark - 4: Space
  dataBits: CdcDataBits #  can be 5, 6, 7, 8 or 16
static:
  assert CdcLineCoding.sizeof == 7

# CDC API

{.push header: "tusb.h".}
#  Check if terminal is connected to this port
proc cdcConnected(itf: uint8): bool {.importc: "tud_cdc_n_connected".}

#  Get current line state. Bit 0:  DTR (Data Terminal Ready), Bit 1: RTS (Request to Send)
#proc cdcGetLineState*(itf: uint8): uint8 {.importc: "tud_cdc_n_get_line_state".}

#  Get current line encoding: bit rate, stop bits parity etc ..
#proc cdcGetLineCoding*(itf: uint8; coding: ptr CdcLineCoding) {.importc: "tud_cdc_n_get_line_coding".}

#  Set special character that will trigger tud_cdc_rx_wanted_cb() callback on receiving
#proc cdcSetWantedChar*(itf: uint8; wanted: char) {.importc: "tud_cdc_n_set_wanted_char".}

#  Get the number of bytes available for reading
proc cdcAvailable(itf: uint8): uint32 {.importc: "tud_cdc_n_available".}

#  Read received bytes
proc cdcRead(itf: uint8; buffer: pointer; bufsize: uint32): uint32 {.importc: "tud_cdc_n_read".}

#  Read a byte, return -1 if there is none
#
#proc cdcReadChar*(itf: uint8): int32 {.inline, importc: "tud_cdc_n_read_char".}

#  Clear the received FIFO
#proc cdcReadFlush*(itf: uint8) {.importc: "tud_cdc_n_read_flush".}

#  Get a byte from FIFO at the specified position without removing it
#proc cdcPeek*(itf: uint8; ui8: ptr uint8): bool {.importc: "tud_cdc_n_peek".}

#  Write bytes to TX FIFO, data may remain in the FIFO for a while
proc cdcWrite*(itf: uint8; buffer: pointer; bufsize: uint32): uint32 {.importc: "tud_cdc_n_write".}

#  Write a byte
proc cdcWriteChar(itf: uint8; ch: char): uint32 {.inline, importc: "tud_cdc_n_write_char".}

#  Write a null-terminated string
#proc cdcWriteStr*(itf: uint8; str: cstring): uint32 {.inline, importc: "tud_cdc_n_write_str".}

#  Force sending data if possible, return number of forced bytes
proc cdcWriteFlush*(itf: uint8): uint32 {.importc: "tud_cdc_n_write_flush".}

#  Return the number of bytes (characters) available for writing to TX FIFO buffer in a single n_write operation.
#proc cdcWriteAvailable*(itf: uint8): uint32 {.importc: "tud_cdc_n_write_available".}

#  Clear the transmit FIFO
#proc cdcWriteClear*(itf: uint8): bool {.importc: "tud_cdc_n_write_clear".}
{.pop.}

# Nim stream-like API for USB CDC (serial)

type UsbSerialInterface* = distinct range[0'u8 .. 127'u8]
## Used to represent the CDC interface number, as configured by `CFG_TUD_CDC`.
## Eg. if `CFG_TUD_CDC` is `1`, then only `0.UsbSerialInterface` would be valid.
## If `CFG_TUD_CDC` is `2`, then we could use `0.UsbSerialInterface` and
## `1.UsbSerialInterface`.

proc available*(itf: UsbSerialInterface): uint32 {.inline.} =
  ## Get the number of bytes available for reading
  cdcAvailable(itf.uint8)

proc atEnd*(itf: UsbSerialInterface): bool {.inline.} =
  ## Returns `true` if there is currently no data available for reading.
  cdcAvailable(itf.uint8) == 0

proc connected*(itf: UsbSerialInterface): bool {.inline.} =
  ## Check if terminal is connected to this port
  ##
  ## Note: this actually checks for DTR bit, which is up to the host
  ## application to set.
  cdcConnected(itf.uint8)

proc readBytes*(itf: UsbSerialInterface, n: Positive = 1): seq[uint8] {.inline.} =
  ## Read up to `n` bytes from interface.
  ##
  ## Note: the length of the returned seq may be lower if fewer bytes were
  ## actually read.
  result = newSeq[uint8](n)
  let actualNumBytes = cdcRead(itf.uint8, result[0].unsafeAddr, n.uint32)
  result.setLen(actualNumBytes)

proc readString*(itf: UsbSerialInterface, n: Positive = 1): string {.inline.} =
  ## Read a string of up to `n` characters from interface.
  ##
  ## Note: the length of the returned string may be lower if fewer bytes were
  ## actually read.
  result = newString(n)
  let actualNumBytes = cdcRead(itf.uint8, result[0].unsafeAddr, n.uint32)
  result.setLen(actualNumBytes)

template writeData(itf: uint8, data: string or openArray[uint8]) =
  var
    i = 0
    remain = data.len
  while remain > 0 and cdcConnected(itf):
    let buffer = data[i].unsafeAddr
    let wrcount = cdcWrite(itf, buffer, remain.uint32).int
    i.inc wrcount
    remain.dec wrcount
    usbDeviceTask()
    discard cdcWriteFlush(itf)

proc write*(itf: UsbSerialInterface, s: string) {.inline.} =
  ## Write a string to interface.
  ##
  ## Note: automatically handles chunked writing if the transmit
  ## buffer fills up.
  writeData(itf.uint8, s)

proc write*(itf: UsbSerialInterface, s: openArray[uint8]) {.inline.} =
  ## Write a sequence of bytes to the interface.
  ##
  ## Note: automatically handles chunked writing if the transmit
  ## buffer fills up.
  writeData(itf.uint8, s)

proc write*(itf: UsbSerialInterface, c: char) {.inline.} =
  # Write a single character to the interface.
  discard cdcWriteChar(itf.uint8, c)

proc writeLine*(itf: UsbSerialInterface, s: string) {.inline.} =
  ## Write a string to interface, followed by `LF` character.
  ##
  ## Note: automatically handles chunked writing if the transmit
  ## buffer fills up.
  itf.write(s)
  itf.write('\n')

proc flush*(itf: UsbSerialInterface) {.inline.} =
  ## Force sending any data remaining in transmit FIFO
  discard cdcWriteFlush(itf.uint8)

# Device Descriptor configuration

type
  UsbDeviceClass* {.size: sizeof(cchar), pure.} = enum
    unspecified = 0
    audio = 1
    cdc = 2
    hid = 3
    reserved_4 = 4
    physical = 5
    image = 6
    printer = 7
    msc = 8
    hub = 9
    cdc_data = 10
    smart_card = 11
    reserved_12 = 12
    content_security = 13
    video = 14
    personal_healthcare = 15
    audio_video = 16
    diagnostic = 0xdc
    wireless_controller = 0xe0
    misc = 0xef
    application_specific = 0xfe
    vendor_specific = 0xff

  UsbMiscSubclass* {.size: sizeof(cchar), pure.} = enum
    none = 0
    common = 2

  UsbMiscProtocol* {.size: sizeof(cchar), pure.} = enum
    none = 0
    iad = 1

  UsbDescriptorType* {.size: sizeof(cchar), pure.} = enum
    device = 0x01
    configuration = 0x02
    dtString = 0x03
    dtInterface = 0x04
    endpoint = 0x05
    qualifier = 0x06
    otherSpeedConfig = 0x07
    interfacePower = 0x08
    otg = 0x09
    debug = 0x0A
    interfaceAssociation = 0x0B
    bos = 0x0f
    deviceCapabillity = 0x10
    functional = 0x21
    csConfig = 0x22
    csString = 0x23
    csInterface = 0x24
    csEndPoint = 0x25
    superSpeedEndpointComp = 0x30
    superSpeedIsoEndpointComp = 0x31

{.push header: "tusb.h".}
type
  UsbDeviceDescriptor* {.packed, importc: "tusb_desc_device_t", completeStruct.} = object
    len*: byte
    descType*: UsbDescriptorType
    binCodeUsb*: uint16
    class*: UsbDeviceClass
    subclass*: UsbMiscSubclass
    protocol*: UsbMiscProtocol
    maxPacketSize*: byte
    vendorId*: uint16
    productId*: uint16
    binaryCodeDev*: uint16
    manufacturer*, product*, serialNumber*, numConfigurations*: byte

  BinaryDeviceStore* {.packed, importc: "tusb_desc_configuration_t", completeStruct.} = object
    len*: uint8
    descType*: uint8
    totalLength*: uint16
    numInterfaces*: uint8
    configurationValue*: uint8
    configuration*: uint8
    attributes*: uint8
    maxPower*: uint8
{.pop.}

static:
  assert UsbDeviceDescriptor.sizeof == 18, "Incorrect type size"
  assert BinaryDeviceStore.sizeof == 9, "Incorrect type size"

# Templates for callback definitions

var calledMountCallback {.compileTime.} = false
template mountCallback*(body: untyped): untyped =
  ## Set the callback to be invoked when device is mounted (configured)
  ##
  ## This template is optional but must be called at most once.
  static:
    when calledMountCallback:
      {.error: "called mountCallback twice".}
    calledMountCallback = true
  proc tudMountCb{.exportC: "tud_mount_cb", codegendecl: "$1 $2$3".} =
    body

var calledUnmountCallback {.compileTime.} = false
template unmountCallback*(body: untyped): untyped =
  ## Set the callback to be invoked when device is unmounted
  ##
  ## This template is optional but must be called at most once.
  static:
    when calledUnmountCallback:
      {.error: "called unmountCallback twice".}
    calledUnmountCallback = true
  proc tudUnmountCb{.exportC: "tud_umount_cb", codegendecl: "$1 $2$3".} =
    body

var calledSuspendCallback {.compileTime.} = false
template suspendCallback*(boolName, body: untyped): untyped =
  ## Set the callback to beinvoked when usb bus is suspended
  ##
  ## According to USB spec, within 7ms, device must draw a current less than 2.5
  ## mA from bus.
  ##
  ## This template is optional but must be called at most once.
  static:
    when calledSuspendCallback:
      {.error: "called suspendCallback twice".}
    calledSuspendCallback = true
  proc tudSuspendCb(boolName: bool) {.exportC: "tud_suspend_cb", codegendecl: "$1 $2$3".} =
    body

var calledResumeCallback {.compileTime.} = false
template resumeCallback*(body: untyped): untyped =
  ## Set the callback to be invoked when device is resumed from suspend
  ##
  ## This template is optional but must be called at most once.
  static:
    when calledResumeCallback:
      {.error: "called resumeCallback twice".}
    calledResumeCallback = true
  proc tudResumeCb*{.exportC: "tud_resume_cb", codegendecl: "$1 $2$3".} =
    body

var calledSetDeviceDescriptor {.compileTime.} = false
template setDeviceDescriptor*(dd: static[UsbDeviceDescriptor]) =
  ## Set the device descriptor to be returned on a GET_DEVICE_DESCRIPTOR request
  ##
  ## This template generates a proc that returns a pointer to the descriptor.
  ## This template must be called exactly once in the application code.
  static:
    when calledSetDeviceDescriptor:
      {.error: "Device descriptor set more than once".}
    calledSetDeviceDescriptor = true
  let desc = dd
  proc tudDescriptorDeviceCb: ptr uint8 {.exportC: "tud_descriptor_device_cb",
      codegendecl: "uint8_t const * $2$3".} =
    result = cast[ptr uint8](desc.unsafeAddr)

var calledDeviceDescriptorConfigurationCallback {.compileTime.} = false
template deviceDescriptorConfigurationCallback*(index, body) =
  static:
    when calledDeviceDescriptorConfigurationCallback:
      {.error: "called deviceDescriptorConfigurationCallback twice".}
    calledDeviceDescriptorConfigurationCallback = true
  proc tudDescriptorConfigCb(index: byte): ptr int8 {.exportC: "tud_descriptor_configuration_cb",
      codegendecl: "uint8_t const * $2$3".} =
    body

var calledDeviceDescriptorStringCallback {.compileTime.} = false
template deviceDescriptorStringCallback*(index, langId, body) =
  static:
    when calledDeviceDescriptorStringCallback:
      {.error: "called deviceDescriptorStringCallback twice".}
    calledDeviceDescriptorStringCallback = true
  proc tudDescriptorStringCb(index: byte, langId: uint16): ptr uint16 {.
      exportC: "tud_descriptor_string_cb", codegendecl: "uint16_t const * $2$3".} =
    body

var calledHidGetReportCallback {.compileTime.} = false
template hidGetReportCallback*(instance, reportId, reportType, buffer, reqLen, body) =
  ## Set the callback to be invoked when an HID GET_REPORT control request is received.
  ##
  ## This is valid for HID device interfaces only. Application must fill buffer
  ## with a valid input report and return its length. Return zero will cause the
  ## stack to STALL request.
  ##
  ## This template must be called exactly once in the application code if an
  ## HID interface is defined (CFG_TUD_HID > 0).
  static:
    when calledHidGetReportCallback:
      {.error: "called hidGetReportCallback twice".}
    calledHidGetReportCallback = true
  proc tudGetReportCb(instance: uint8, reportId: uint8, reportType: HidReportType,
      buffer: ptr uint8, reqLen: uint16): uint16 {.exportC: "tud_hid_get_report_cb", cdecl.} =
    body

var calledHidSetReportCallback {.compileTime.} = false
template hidSetReportCallback*(instance, reportId, reportType, buffer, reqLen, body) =
  ## Set the callback to be invoked when a SET_REPORT control request is received
  ## or when receiving data on OUT endpoint ( Report ID = 0, Type = 0 )
  ##
  ## This template must be called exactly once in the application code if an
  ## HID interface is defined (CFG_TUD_HID > 0).
  static:
    when calledHidSetReportCallback:
      {.error: "called hidSetReportCallback twice".}
    calledHidSetReportCallback = true
  proc tudSetReportCb(instance: uint8, reportId: uint8, reportType: HidReportType,
      buffer: UncheckedArray[byte], reqLen: uint16)
      # Need to use .codegendecl for the `uint8 const*` typedef
      {.exportC, codegendecl: "void tud_hid_set_report_cb(uint8_t instance, uint8_t report_id, hid_report_type_t report_type, uint8_t const* buffer, uint16_t bufsize)".} =
    body

var calledHidReportCompleteCallback {.compileTime.} = false
template hidReportCompleteCallback*(itf, report, len, body) =
  ## Set the callback to be invoked when a HID input report is successfully send to host.
  ##
  ## Application can use this to send the next report
  ## Note: For composite reports, report[0] is report ID
  ## This template is optional but must be called at most once.
  static:
    when calledHidReportCompleteCallback:
      {.error: "called hidReportCompleteCallback twice".}
    calledHidReportCompleteCallback = true
  proc tud_hid_report_complete_cb(itf: uint8, report: UncheckedArray[uint8], len: uint8)
      {.exportc, codegendecl: "void tud_hid_report_complete_cb(uint8_t instance, uint8_t const* report, uint8_t len)".} =
    body

var calledHidDescriptorReportCallback {.compileTime.} = false
template hidDescriptorReportCallback*(body) =
  static:
    when calledHidDescriptorReportCallback:
      {.error: "called hidDescriptorReportCallback twice".}
    calledHidDescriptorReportCallback = true
  proc tudDescriptorReportCb: ptr uint8 {.exportC: "tud_hid_descriptor_report_cb",
      codegendecl: "uint8_t const * $2$3".} =
    body
