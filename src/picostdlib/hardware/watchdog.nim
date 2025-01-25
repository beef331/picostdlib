import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_watchdog/include".}
{.push header: "hardware/watchdog.h".}

let PARAM_ASSERTIONS_ENABLED_WATCHDOG* {.importc: "PARAM_ASSERTIONS_ENABLED_WATCHDOG".}: bool

proc watchdogReboot*(pc: uint32; sp: uint32; delayMs: uint32) {.importc: "watchdog_reboot".}
  ## Define actions to perform at watchdog timeout
  ##
  ## \note If \ref watchdog_start_tick value does not give a 1MHz clock to the watchdog system, then the \p delay_ms
  ## parameter will not be in milliseconds. See the datasheet for more details.
  ##
  ## By default the SDK assumes a 12MHz XOSC and sets the \ref watchdog_start_tick appropriately.
  ##
  ## \param pc If Zero, a standard boot will be performed, if non-zero this is the program counter to jump to on reset.
  ## \param sp If \p pc is non-zero, this will be the stack pointer used.
  ## \param delay_ms Initial load value. Maximum value 8388, approximately 8.3s.

proc watchdogStartTick*(cycles: cuint) {.importc: "watchdog_start_tick".}
  ## Start the watchdog tick
  ##
  ## \param cycles This needs to be a divider that when applied to the XOSC input, produces a 1MHz clock. So if the XOSC is
  ## 12MHz, this will need to be 12.

proc watchdogUpdate*() {.importc: "watchdog_update".}
  ## Reload the watchdog counter with the amount of time set in watchdog_enable

proc watchdogEnable*(delayMs: uint32; pauseOnDebug: bool) {.importc: "watchdog_enable".}
  ## Enable the watchdog
  ##
  ## \note If \ref watchdog_start_tick value does not give a 1MHz clock to the watchdog system, then the \p delay_ms
  ## parameter will not be in milliseconds. See the datasheet for more details.
  ##
  ## By default the SDK assumes a 12MHz XOSC and sets the \ref watchdog_start_tick appropriately.
  ##
  ## This method sets a marker in the watchdog scratch register 4 that is checked by \ref watchdog_enable_caused_reboot.
  ## If the device is subsequently reset via a call to watchdog_reboot (including for example by dragging a UF2
  ## onto the RPI-RP2), then this value will be cleared, and so \ref watchdog_enable_caused_reboot will
  ## return false.
  ##
  ## \param delay_ms Number of milliseconds before watchdog will reboot without watchdog_update being called. Maximum of 8388, which is approximately 8.3 seconds
  ## \param pause_on_debug If the watchdog should be paused when the debugger is stepping through code

proc watchdogCausedReboot*(): bool {.importc: "watchdog_caused_reboot".}
  ## Did the watchdog cause the last reboot?
  ##
  ## @return true If the watchdog timer or a watchdog force caused the last reboot
  ## @return false If there has been no watchdog reboot since the last power on reset. A power on reset is typically caused by a power cycle or the run pin (reset button) being toggled.

proc watchdogEnableCausedReboot*(): bool {.importc: "watchdog_enable_caused_reboot".}
  ## Did watchdog_enable cause the last reboot?
  ##
  ## Perform additional checking along with \ref watchdog_caused_reboot to determine if a watchdog timeout initiated by
  ## \ref watchdog_enable caused the last reboot.
  ##
  ## This method checks for a special value in watchdog scratch register 4 placed there by \ref watchdog_enable.
  ## This would not be present if a watchdog reset is initiated by \ref watchdog_reboot or by the RP2040 bootrom
  ## (e.g. dragging a UF2 onto the RPI-RP2 drive).
  ##
  ## @return true If the watchdog timer or a watchdog force caused (see \ref watchdog_caused_reboot) the last reboot
  ##              and the watchdog reboot happened after \ref watchdog_enable was called
  ## @return false If there has been no watchdog reboot since the last power on reset, or the watchdog reboot was not caused
  ##               by a watchdog timeout after \ref watchdog_enable was called.
  ##               A power on reset is typically caused by a power cycle or the run pin (reset button) being toggled.

proc watchdogGetCount*(): uint32 {.importc: "watchdog_get_count".}
  ## Returns the number of microseconds before the watchdog will reboot the chip.
  ##
  ## @return The number of microseconds before the watchdog will reboot the chip.

{.pop.}
