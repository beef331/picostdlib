## From pico-extras repository
##
## Ring Oscillator (ROSC) API
##
## A Ring Oscillator is an on-chip oscillator that requires no external crystal. Instead, the output is generated from a series of
## inverters that are chained together to create a feedback loop. RP2040 boots from the ring oscillator initially, meaning the
## first stages of the bootrom, including booting from SPI flash, will be clocked by the ring oscillator. If your design has a
## crystal oscillator, you’ll likely want to switch to this as your reference clock as soon as possible, because the frequency is
## more accurate than the ring oscillator.
##

import ./base, ./clocks
export base, clocks

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_regs/include".}
{.push header: "hardware/regs/rosc.h".}

let
  ROSC_CTRL_ENABLE_BITS* {.importc: "ROSC_CTRL_ENABLE_BITS".}: uint32
  ROSC_CTRL_ENABLE_LSB* {.importc: "ROSC_CTRL_ENABLE_LSB".}: uint32
  ROSC_CTRL_ENABLE_VALUE_DISABLE* {.importc: "ROSC_CTRL_ENABLE_VALUE_DISABLE".}: uint32
  ROSC_CTRL_ENABLE_VALUE_ENABLE* {.importc: "ROSC_CTRL_ENABLE_VALUE_ENABLE".}: uint32
  ROSC_DIV_VALUE_PASS* {.importc: "ROSC_DIV_VALUE_PASS".}: uint32
  ROSC_DORMANT_VALUE_DORMANT* {.importc: "ROSC_DORMANT_VALUE_DORMANT".}: uint32
  ROSC_FREQA_PASSWD_LSB* {.importc: "ROSC_FREQA_PASSWD_LSB".}: uint32
  ROSC_FREQA_PASSWD_VALUE_PASS* {.importc: "ROSC_FREQA_PASSWD_VALUE_PASS".}: uint32
  ROSC_FREQB_PASSWD_LSB* {.importc: "ROSC_FREQB_PASSWD_LSB".}: uint32
  ROSC_FREQB_PASSWD_VALUE_PASS* {.importc: "ROSC_FREQB_PASSWD_VALUE_PASS".}: uint32
  ROSC_STATUS_BADWRITE_BITS* {.importc: "ROSC_STATUS_BADWRITE_BITS".}: uint32
  ROSC_STATUS_STABLE_BITS* {.importc: "ROSC_STATUS_STABLE_BITS".}: uint32

{.pop.}

{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_structs/include".}
{.push header: "hardware/structs/rosc.h".}

type
  RoscHw* {.importc: "rosc_hw_t".} = object
    ctrl* {.importc: "ctrl".}: IoRw32
    freqa* {.importc: "freqa".}: IoRw32
    freqb* {.importc: "freqb".}: IoRw32
    dormant* {.importc: "dormant".}: IoRw32
    divider* {.importc: "div".}: IoRw32
    phase* {.importc: "phase".}: IoRw32
    status* {.importc: "status".}: IoRw32
    randombit* {.importc: "randombit".}: IoRo32
    count* {.importc: "count".}: IoRw32

let roscHw* {.importc: "rosc_hw".}: ptr RoscHw

{.pop.}

proc roscClearBadWrite() {.inline.} =
  hwClearBits(roscHw.status.addr, ROSC_STATUS_BADWRITE_BITS)

proc roscWriteOkay(): bool {.inline.} =
  return (roscHw.status and ROSC_STATUS_BADWRITE_BITS) == 0

proc roscWrite(address: var IoRw32; value: uint32) =
  roscClearBadWrite()
  assert(roscWriteOkay())
  address = value
  assert(roscWriteOkay())

proc roscSetFreq*(code: uint32) =
  ## Set frequency of the Ring Oscillator
  ##
  ## \param code The drive strengths. See the RP2040 datasheet for information on this value.
  roscWrite(roscHw.freqa, (ROSC_FREQA_PASSWD_VALUE_PASS shl ROSC_FREQA_PASSWD_LSB) or (code and 0xffff'u32))
  roscWrite(roscHw.freqb, (ROSC_FREQB_PASSWD_VALUE_PASS shl ROSC_FREQB_PASSWD_LSB) or (code shr 16'u32))


proc roscSetRange*(freqRange: uint) =
  ## Set range of the Ring Oscillator
  ##
  ## Frequency range. Frequencies will vary with Process, Voltage & Temperature (PVT).
  ## Clock output will not glitch when changing the range up one step at a time.
  ##
  ## \param range 0x01 Low, 0x02 Medium, 0x03 High, 0x04 Too High.
  # Range should use enumvals from the headers and thus have the password correct
  roscWrite(roscHw.ctrl, (ROSC_CTRL_ENABLE_VALUE_ENABLE shl ROSC_CTRL_ENABLE_LSB) or freqRange.uint32)

proc roscDisable*() =
  ## Disable the Ring Oscillator
  var tmp = roscHw.ctrl
  tmp = tmp and (not ROSC_CTRL_ENABLE_BITS)
  tmp = tmp or (ROSC_CTRL_ENABLE_VALUE_DISABLE shl ROSC_CTRL_ENABLE_LSB)
  roscWrite(roscHw.ctrl, tmp)
  # Wait for stable to go away
  while (roscHw.status and ROSC_STATUS_STABLE_BITS) != 0: discard

proc roscEnable*() =
  # Re-enable the rosc
  roscWrite(roscHw.ctrl, ROSC_CTRL_ENABLE_BITS)
  # Wait for it to become stable once restarted
  while (roscHw.status and ROSC_STATUS_STABLE_BITS) != ROSC_STATUS_STABLE_BITS: discard


proc roscSetDormant*() =
  ## Put Ring Oscillator into dormant mode.
  ##
  ## The ROSC supports a dormant mode,which stops oscillation until woken up up by an asynchronous interrupt.
  ## This can either come from the RTC, being clocked by an external clock, or a GPIO pin going high or low.
  ## If no IRQ is configured before going into dormant mode the ROSC will never restart.
  ##
  ## PLLs should be stopped before selecting dormant mode.
  # WARNING: This stops the rosc until woken up by an irq
  roscWrite(roscHw.dormant, ROSC_DORMANT_VALUE_DORMANT)
  # Wait for it to become stable once woken up
  while (roscHw.status and ROSC_STATUS_STABLE_BITS) == 0: discard

proc nextRoscCode*(code: uint32): uint32 =
  ## Given a ROSC delay stage code, return the next-numerically-higher code.
  ## Top result bit is set when called on maximum ROSC code.
  return ((code or 0x08888888'u32) + 1'u32) and 0xf7777777'u32

iterator roscCodes*(): uint32 =
  var code: uint32 = 0
  while code <= 0x77777777'u32:
    yield code
    code = nextRoscCode(code)

proc roscSetDiv*(divider: uint32) =
  assert(divider <= 31 and divider >= 1)
  roscWrite(roscHw.divider, ROSC_DIV_VALUE_PASS + divider);

proc roscFindFreq*(lowMHz: uint32; highMHz: uint32): uint =
  # TODO: This could be a lot better
  roscSetDiv(1)
  for code in roscCodes():
    roscSetFreq(code)
    let roscMHz = frequencyCountKHz(ClocksFc0Src.RoscClksrc) div 1000
    if (roscMHz >= lowMHz) and (roscMHz <= highMHz):
      return roscMHz

  return 0

