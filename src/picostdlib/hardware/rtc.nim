import ../pico/types
export types

import ../helpers
when picoIncludeRtcDatetime:
  {.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_rtc/include".}
  {.push header: "hardware/rtc.h".}

  type
    RtcCallback* {.importc: "rtc_callback_t".} = proc () {.cdecl.}

  proc rtcInit*() {.importc: "rtc_init".}
    ## Initialise the RTC system

  proc rtcSetDatetime*(t: ptr DatetimeT): bool {.importc: "rtc_set_datetime".}
    ## Set the RTC to the specified time
    ##
    ## \note Note that after setting the RTC date and time, a subsequent read of the values (e.g. via rtc_get_datetime()) may not
    ## reflect the new setting until up to three cycles of the potentially-much-slower RTC clock domain have passed. This represents a period
    ## of 64 microseconds with the default RTC clock configuration.
    ##
    ## \param t Pointer to a \ref datetime_t structure contains time to set
    ## \return true if set, false if the passed in datetime was invalid.

  proc rtcGetDatetime*(t: ptr DatetimeT): bool {.importc: "rtc_get_datetime".}
    ## Get the current time from the RTC
    ##
    ## \param t Pointer to a \ref datetime_t structure to receive the current RTC time
    ## \return true if datetime is valid, false if the RTC is not running.

  proc rtcRunning*(): bool {.importc: "rtc_running".}
    ## Is the RTC running?

  proc rtcSetAlarm*(t: ptr DatetimeT; userCallback: RtcCallback) {.importc: "rtc_set_alarm".}
    ## Set a time in the future for the RTC to call a user provided callback
    ##
    ## \param t Pointer to a \ref datetime_t structure containing a time in the future to fire the alarm. Any values set to -1 will not be matched on.
    ## \param user_callback pointer to a \ref rtc_callback_t to call when the alarm fires

  proc rtcEnableAlarm*() {.importc: "rtc_enable_alarm".}
    ## Enable the RTC alarm (if inactive)

  proc rtcDisableAlarm*() {.importc: "rtc_disable_alarm".}
    ## Disable the RTC alarm (if active)

  {.pop.}
