import picostdlib/[gpio, time, tusb]

type TimestampMicros = uint64

const
  LedBlinkIntervalNotMounted = 250'u64
  LedBlinkIntervalMounted = 1000'u64
  LedBlinkIntervalSuspended = 2500'u64

  # We have 1 serial (CDC) and 1 HID interface, so each have id 0.
  usbser = 0.UsbSerialInterface
  hid = 0.UsbHidInterface

var ledBlinkInterval: uint64 # ms

# Report IDs as defined by the report descriptor, see `desc_hid_report` in the
# usb_descriptors.c file.
type HidReportId {.pure.} = enum
  keyboard = 1,
  mouse = 2,
  gamepad = 3,

proc sendHidReport(id: HidReportId) =
  var
    hasKbPress {.global.}: bool
    hasGpPress {.global.}: bool

  if not hid.ready(): return

  let btn = getBoardButton()

  case id:
  of HidReportId.keyboard:
    if btn:
      discard hid.sendKeyboardReport(id.uint8, {}, keyA)
      hasKbPress = true
    else:
      if hasKbPress:
        # Need to send an empty report to tell host that key isn't pressed anymore
        discard hid.sendKeyboardReport(id.uint8, {})
        hasKbPress = false
  of HidReportId.mouse:
    if btn:
      # Move mouse down and right
      discard hid.sendMouseReport(id.uint8, buttons = {}, x = 5, y = 5, horizontal = 0, vertical = 0)
    else:
      # Empty mouse report. Does nothing except continue the callback chain
      # for the gamepad report.
      discard hid.sendMouseReport(id.uint8, buttons = {}, x = 0, y = 0, horizontal = 0, vertical = 0)
  of HidReportId.gamepad:
    if btn:
      discard hid.sendGamepadReport(
        id.uint8,
        x = 0, y = 0, z = 0, rz = 0, rx = 0, ry = 0,
        hat = GamepadHatPosition.centered,
        buttons = {GamepadButton.b8}
      )
      hasGpPress = true
    else:
      if hasGpPress:
        # Need to send an empty report to tell host that key isn't pressed anymore
        discard hid.sendGamepadReport(
          id.uint8,
          x = 0, y = 0, z = 0, rz = 0, rx = 0, ry = 0,
          hat = GamepadHatPosition.centered,
          buttons = {}
        )
        hasGpPress = false

proc blinkLedTask(elapsed: TimestampMicros) =
  var
    nextChange {.global.} = ledBlinkInterval * 1000
    ledState {.global.}: bool

  if nextChange > elapsed:
    nextChange = nextChange - elapsed
  else:
    DefaultLedPin.put (if ledState: Low else: High)
    ledState = not ledState
    nextChange = ledBlinkInterval * 1000

proc hidTask(elapsed: TimestampMicros) =
  # Send the first report. The others will be sent sequentially by the
  # report complete callback.
  sendHidReport(HidReportId.keyboard)

proc cdcHelloTask(elapsed: TimestampMicros) =
  usbser.writeLine "Hello, world"

proc cdcEchoTask(elapsed: TimestampMicros) =
  if usbser.available > 0:
    let s = usbser.readString(256)
    if s.len > 0:
      usbser.writeLine("pico echo: " & s)

# Implement a simple scheduler to run tasks at varying frequency
type SchedulerEntry = object
  period: TimestampMicros
  elapsed: TimestampMicros
  taskproc: proc(elapsed: TimestampMicros)

template schTask(task: proc(elapsed: TimestampMicros), rateHz: int): untyped =
  SchedulerEntry(period: 1_000_000 div rateHz, taskProc: task, elapsed: 0)

# Task callable, task rate in hz
var SchedulerTable = [
  # Update LED rate every 10 ms, based on selected blink rate
  schTask(blinkLedTask, 100),

  # Check for button state and send HID report if necessary, every 10 ms
  schTask(hidTask, 100),

  # Print out "hello, word" every 1 s
  # NOTE: Host need to set DTR bit on serial port, otherwise data
  # is not sent.
  schTask(cdcHelloTask, 1),

  # Check for incoming data on USB serial and echo it back, every 10 ms
  # NOTE: Host need to set DTR bit on serial port, otherwise data
  # is not sent.
  schTask(cdcEchoTask, 100),
]

proc setup() =
  ledBlinkInterval = LedBlinkIntervalNotMounted

  DefaultLedPin.init()
  DefaultLedPin.setDir(Out)

  # TinyUSB initialization
  discard usbInit()
  boardInit()

proc main() =
  var prevTime: TimestampMicros = 0
  while true:
    # Need to call this often to respond to USB events
    usbDeviceTask()

    # Scheduler loop
    let
      now = timeUs64()
      dt = now - prevTime
    for entry in SchedulerTable.mitems:
      if entry.elapsed > entry.period:
        entry.taskproc(entry.elapsed)
        entry.elapsed = 0
      entry.elapsed = entry.elapsed + dt
    prevTime = now

setup()
main()

# USB Callbacks

# hidGetReport and hidSetReport must be defined, here we do nothing
hidGetReportCallback(instance, reportId, reportType, buffer, reqLen):
  discard

hidSetReportCallback(instance, reportId, reportType, buffer, reqLen):
  discard

# These callbacks are optional.
# Set the LED blink based on USB state.
mountCallback:
  ledBlinkInterval = LedBlinkIntervalMounted

unmountCallback:
  ledBlinkInterval = LedBlinkIntervalNotMounted

suspendCallback(wakeUpEnabled):
  ledBlinkInterval = LedBlinkIntervalSuspended

resumeCallback:
  ledBlinkInterval = LedBlinkIntervalMounted

# Called when an HID report is successfully sent.
# Used here to send multiple reports in sequence.
hidReportCompleteCallback(itf, report, len):
  # Note: report[0] is the report ID.
  if report[0] < HidReportId.high.ord:
    let nextReport = (report[0] + 1).HidReportId
    sendHidReport(nextReport)

# Device descriptor callback must be defined
const Usb_Ep0_Size = 64'u8 # Must match CFG_TUD_ENDPOINT0_SIZE value in tusb_config.h
setDeviceDescriptor:
  UsbDeviceDescriptor(
    len: sizeof(UsbDeviceDescriptor).uint8,
    descType: UsbDescriptorType.device,
    binCodeUsb: 0x0200,

    # These class/subclass/protocol values required for CDC
    # See TinyUSB examples for more info.
    class: UsbDeviceClass.misc,
    subclass: UsbMiscSubclass.common,
    protocol: UsbMiscProtocol.iad,

    maxPacketSize: Usb_Ep0_Size,
    vendorId: 0xCAFE,
    productId: 0x4005,
    binaryCodeDev: 0x0100,
    manufacturer: 1,
    product: 2,
    serialNumber: 3,
    numConfigurations: 1
  )
