import std/posix
import ./util/datetime
export datetime

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_aon_timer/include".}
{.push header: "pico/aon_timer.h".}

## High Level "Always on Timer" Abstraction
##
## \if rp2040_specific
## This library uses the RTC on RP2040.
## \endif
## \if rp2350_specific
## This library uses the Powman Timer on RP2350.
## \endif
##
## This library supports both `aon_timer_xxx_calendar()` methods which use a calendar date/time (as struct tm),
## and `aon_timer_xxx()` methods which use a linear time value relative an internal reference time (via struct timespec).
##
## \if rp2040_specific
## \anchor rp2040_caveats
## On RP2040 the non 'calendar date/time' methods must convert the linear time value to a calendar date/time internally; these methods are:
##
## * \ref aon_timer_start_with_timeofday
## * \ref aon_timer_start
## * \ref aon_timer_set_time
## * \ref aon_timer_get_time
## * \ref aon_timer_enable_alarm
##
## This conversion is handled by the \ref pico_localtime_r method. By default, this pulls in the C library `local_time_r` method
## which can lead to a big increase in binary size. The default implementation of `pico_localtime_r` is weak, so it can be overridden
## if a better/smaller alternative is available, otherwise you might consider the method variants ending in `_calendar()` instead on RP2040.
## \endif
##
## \if rp2350_specific
## \anchor rp2350_caveats
## On RP2350 the 'calendar date/time' methods  must convert the calendar date/time to a linear time value internally; these methods are:
##
## * \ref aon_timer_start_calendar
## * \ref aon_timer_set_time_calendar
## * \ref aon_timer_get_time_calendar
## * \ref aon_timer_enable_alarm_calendar
##
## This conversion is handled by the \ref pico_mktime method. By default, this pulls in the C library `mktime` method
## which can lead to a big increase in binary size. The default implementation of `pico_mktime` is weak, so it can be overridden
## if a better/smaller alternative is available, otherwise you might consider the method variants not ending in `_calendar()` instead on RP2350.

type
  AonTimerAlarmHandler* {.importc: "aon_timer_alarm_handler_t".} = proc () {.cdecl.}

proc aonTimerStartWithTimeofday*(ts: ptr Timespec) {.importc: "aon_timer_start_with_timeofday".}
  ## Start the AON timer running using the result from the gettimeofday() function as the current time
  ##
  ## \if rp2040_specific
  ## See \ref rp2040_caveats "caveats" for using this method on RP2040
  ## \endif
  ##
  ## \ingroup pico_aon_timer

proc aonTimerStart*(ts: ptr Timespec): bool {.importc: "aon_timer_start".}
  ## Start the AON timer running using the specified timespec as the current time
  ##
  ## \if rp2040_specific
  ## See \ref rp2040_caveats "caveats" for using this method on RP2040
  ## \endif
  ##
  ## \param ts the time to set as 'now'
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_start_calendar

proc aonTimerStartCalendar*(t: ptr Tm): bool {.importc: "aon_timer_start_calendar".}
  ## Start the AON timer running using the specified calendar date/time as the current time
  ##
  ## \if rp2350_specific
  ## See \ref rp2350_caveats "caveats" for using this method on RP2350
  ## \endif
  ##
  ## \ingroup pico_aon_timer
  ## \param tm the calendar date/time to set as 'now'
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_start

proc aonTimerStop*() {.importc: "aon_timer_stop".}
  ## Stop the AON timer

proc aonTimerSetTime*(ts: ptr Timespec): bool {.importc: "aon_timer_set_time".}
  ## Set the current time of the AON timer
  ##
  ## \if rp2040_specific
  ## See \ref rp2040_caveats "caveats" for using this method on RP2040
  ## \endif
  ##
  ## \param ts the new current time
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_set_time_calendar

proc aonTimerSetTimeCalendar*(ts: ptr Tm): bool {.importc: "aon_timer_set_time_calendar".}
  ## Set the current time of the AON timer to the given calendar date/time
  ##
  ## \if rp2350_specific
  ## See \ref rp2350_caveats "caveats" for using this method on RP2350
  ## \endif
  ##
  ## \param tm the new current time
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_set_time

proc aonTimerGetTime*(ts: ptr Timespec): bool {.importc: "aon_timer_get_time".}
  ## Get the current time of the AON timer
  ##
  ## \if rp2040_specific
  ## See \ref rp2040_caveats "caveats" for using this method on RP2040
  ## \endif
  ##
  ## \param ts out value for the current time
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_get_time_calendar

proc aonTimerGetTimeCalendar*(ts: ptr Tm): bool {.importc: "aon_timer_get_time_calendar".}
  ## Get the current time of the AON timer as a calendar date/time
  ##
  ## \if rp2350_specific
  ## See \ref rp2350_caveats "caveats" for using this method on RP2350
  ## \endif
  ##
  ## \param tm out value for the current calendar date/time
  ## \return true on success, false if internal time format conversion failed
  ## \sa aon_timer_get_time

proc aonTimerGetResolution*(ts: ptr Timespec) {.importc: "aon_timer_get_resolution".}
  ## Get the resolution of the AON timer
  ##
  ## \param ts out value for the resolution of the AON timer

proc aonTimerEnableAlarm*(ts: ptr Timespec; handler: AonTimerAlarmHandler; wakeupFromLowPower: bool): AonTimerAlarmHandler {.importc: "aon_timer_enable_alarm".}
  ## Enable an AON timer alarm for a specified time
  ##
  ## \if rp2350_specific
  ## On RP2350 the alarm will fire if it is in the past
  ## \endif
  ## \if rp2040_specific
  ## On RP2040 the alarm will not fire if it is in the past.
  ##
  ## See \ref rp2040_caveats "caveats" for using this method on RP2040
  ## \endif
  ##
  ## \param ts the alarm time
  ## \param handler a callback to call when the timer fires (can be NULL for wakeup_from_low_power = true)
  ## \param wakeup_from_low_power true if the AON timer is to be used to wake up from a DORMANT state
  ## \return on success the old handler (or NULL if there was none)
  ##         or PICO_ERROR_INVALID_ARG if internal time format conversion failed
  ## \sa pico_localtime_r

proc aonTimerEnableAlarmCalendar*(tm: ptr Tm; handler: AonTimerAlarmHandler; wakeupFromLowPower: bool): AonTimerAlarmHandler {.importc: "aon_timer_enable_alarm_calendar".}
  ## Enable an AON timer alarm for a specified calendar date/time
  ##
  ## \if rp2350_specific
  ## On RP2350 the alarm will fire if it is in the past
  ##
  ## See \ref rp2350_caveats "caveats" for using this method on RP2350
  ## \endif
  ##
  ## \if rp2040_specific
  ## On RP2040 the alarm will not fire if it is in the past.
  ## \endif
  ##
  ## \param tm the alarm calendar date/time
  ## \param handler a callback to call when the timer fires (can be NULL for wakeup_from_low_power = true)
  ## \param wakeup_from_low_power true if the AON timer is to be used to wake up from a DORMANT state
  ## \return on success the old handler (or NULL if there was none)
  ##         or PICO_ERROR_INVALID_ARG if internal time format conversion failed
  ## \sa pico_localtime_r

proc aonTimerDisableAlarm*() {.importc: "aon_timer_disable_alarm".}
  ## Disable the currently enabled AON timer alarm if any

proc aonTimerIsRunning*(): bool {.importc: "aon_timer_is_running".}
  ## return true if the AON timer is running
  ## 
  ## \return true if the AON timer is running

proc aonTimerGetIrqNum*(): uint {.importc: "aon_timer_get_irq_num".}

{.pop.}
