import ./types
import ../hardware/timer
export types, timer

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_time/include".}
{.push header: "pico/time.h".}

type
  AlarmId* {.importc: "alarm_id_t".} = distinct int32
    ## The identifier for an alarm
    ##
    ## \note this identifier is signed because -1 is used as an error condition when creating alarms
    ##
    ## \note alarm ids may be reused, however for convenience the implementation makes an attempt to defer
    ## reusing as long as possible. You should certainly expect it to be hundreds of ids before one is
    ## reused, although in most cases it is more. Nonetheless care must still be taken when cancelling
    ## alarms or other functionality based on alarms when the alarm may have expired, as eventually
    ## the alarm id may be reused for another alarm.
    ##

  AlarmCallback* {.importc: "alarm_callback_t".} = proc (id: AlarmId, userData: pointer): int64 {.cdecl.}
    ## User alarm callback
    ##
    ## \param id the alarm_id as returned when the alarm was added
    ## \param user_data the user data passed when the alarm was added
    ## \return <0 to reschedule the same alarm this many us from the time the alarm was previously scheduled to fire
    ## \return >0 to reschedule the same alarm this many us from the time this method returns
    ## \return 0 to not reschedule the alarm

  AlarmPool* {.importc: "struct alarm_pool".} = object

  RepeatingTimer* {.bycopy, importc: "struct repeating_timer".} = object
    ## Information about a repeating timer
    delay_us* {.importc: "delay_us".}: int64
    pool* {.importc: "pool".}: ptr AlarmPool
    alarm_id* {.importc: "alarm_id".}: AlarmId
    callback* {.importc: "callback".}: RepeatingTimerCallback
    user_data* {.importc: "user_data".}: pointer

  RepeatingTimerCallback* {.importc: "repeating_timer_callback_t".} = proc (rt: ptr RepeatingTimer): bool {.cdecl.}
    ## Callback for a repeating timer
    ##
    ## \param rt repeating time structure containing information about the repeating time. user_data is of primary important to the user
    ## \return true to continue repeating, false to stop.

let
  atTheEndOfTime* {.importc: "at_the_end_of_time".}: AbsoluteTime
    ## The timestamp representing the end of time; this is actually not the maximum possible
    ## timestamp, but is set to 0x7fffffff_ffffffff microseconds to avoid sign overflows with time
    ## arithmetic. This is almost 300,000 years, so should be sufficient.

  nilTime* {.importc: "nil_time".}: AbsoluteTime
    ## The timestamp representing a null timestamp

proc `==`*(a, b: AlarmId): bool {.borrow.}
proc `$`*(a: AlarmId): string {.borrow.}


## MODULE TIMESTAMP

proc getAbsoluteTime*(): AbsoluteTime {.importc: "get_absolute_time".}
  ## Return a representation of the current time.
  ##
  ## Returns an opaque high fidelity representation of the current time
  ## sampled during the call.
  ##
  ## **Returns:** the absolute time (now) of the hardware timer

proc toMsSinceBoot*(t: AbsoluteTime): uint32 {.importc: "to_ms_since_boot".}
  ## Convert a timestamp into a number of milliseconds since boot.
  ## \param t an absolute_time_t value to convert
  ## \return the number of milliseconds since boot represented by t
  ## \sa to_us_since_boot()

proc delayedByUs*(t: AbsoluteTime; us: uint64): AbsoluteTime {.importc: "delayed_by_us".}
  ## Return a timestamp value obtained by adding a number of microseconds to another timestamp
  ##
  ## \param t the base timestamp
  ## \param us the number of microseconds to add
  ## \return the timestamp representing the resulting time

proc delayedByMs*(t: AbsoluteTime; ms: uint32): AbsoluteTime {.importc: "delayed_by_ms".}
  ## Return a timestamp value obtained by adding a number of milliseconds to another timestamp
  ##
  ## \param t the base timestamp
  ## \param ms the number of milliseconds to add
  ## \return the timestamp representing the resulting time

proc makeTimeoutTimeUs*(us: uint64): AbsoluteTime {.importc: "make_timeout_time_us".}
  ## Convenience method to get the timestamp a number of microseconds from the current time
  ##
  ## \param us the number of microseconds to add to the current timestamp
  ## \return the future timestamp

proc makeTimeoutTimeMs*(ms: uint32): AbsoluteTime {.importc: "make_timeout_time_ms".}
  ## Convenience method to get the timestamp a number of milliseconds from the current time
  ##
  ## \param ms the number of milliseconds to add to the current timestamp
  ## \return the future timestamp

proc diffUs*(`from`: AbsoluteTime; to: AbsoluteTime): int64 {.importc: "absolute_time_diff_us".}
  ## Return the difference in microseconds between two timestamps
  ##
  ## \note be careful when diffing against large timestamps (e.g. \ref at_the_end_of_time)
  ## as the signed integer may overflow.
  ##
  ## \param from the first timestamp
  ## \param to the second timestamp
  ## \return the number of microseconds between the two timestamps (positive if to is after from except
  ## in case of overflow)

proc min*(a, b: AbsoluteTime): AbsoluteTime {.importc: "absolute_time_min".}
  ## Return the earlier of two timestamps
  ##
  ## \param a the first timestamp
  ## \param b the second timestamp
  ## \return the earlier of the two timestamps

proc isAtTheEndOfTime*(t: AbsoluteTime): bool {.importc: "is_at_the_end_of_time".}
  ## Determine if the given timestamp is "at_the_end_of_time"
  ##
  ## \param t the timestamp
  ## \return true if the timestamp is at_the_end_of_time
  ## \sa at_the_end_of_time

proc isNilTime*(t: AbsoluteTime): bool {.importc: "is_nil_time".}
  ## Determine if the given timestamp is nil
  ##
  ## \param t the timestamp
  ## \return true if the timestamp is nil
  ## \sa nil_time


## MODULE SLEEP

proc sleepUntil*(target: AbsoluteTime) {.importc: "sleep_until".}
  ## Wait until after the given timestamp to return
  ##
  ## \note  This method attempts to perform a lower power (WFE) sleep
  ##
  ## \param target the time after which to return
  ## \sa sleep_us()
  ## \sa busy_wait_until()

proc sleepUs*(us: uint64) {.importc: "sleep_us".}
  ## Wait for the given number of microseconds before returning.
  ##
  ## Note: This procedure attempts to perform a lower power sleep (using WFE) as much as possible.
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **us**     the number of microseconds to sleep

proc sleepMs*(ms: uint32) {.importc: "sleep_ms".}
  ## Wait for the given number of milliseconds before returning.
  ##
  ## Note: This procedure attempts to perform a lower power sleep (using WFE) as much as possible.
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **ms**     the number of milliseconds to sleep

proc bestEffortWfeOrTimeout*(timeoutTimestamp: AbsoluteTime): bool {.importc: "best_effort_wfe_or_timeout".}
  ## Helper method for blocking on a timeout
  ##
  ## This method will return in response to an event (as per __wfe) or
  ## when the target time is reached, or at any point before.
  ##
  ## This method can be used to implement a lower power polling loop waiting on
  ## some condition signalled by an event (__sev()).
  ##
  ## This is called \a best_effort because under certain circumstances (notably the default timer pool
  ## being disabled or full) the best effort is simply to return immediately without a __wfe, thus turning the calling
  ## code into a busy wait.
  ##
  ## Example usage:
  ## ```c
  ## bool my_function_with_timeout_us(uint64_t timeout_us) {
  ##     absolute_time_t timeout_time = make_timeout_time_us(timeout_us);
  ##     do {
  ##         // each time round the loop, we check to see if the condition
  ##         // we are waiting on has happened
  ##         if (my_check_done()) {
  ##             // do something
  ##             return true;
  ##         }
  ##         // will try to sleep until timeout or the next processor event
  ##     } while (!best_effort_wfe_or_timeout(timeout_time));
  ##     return false; // timed out
  ## }
  ## ```
  ##
  ## @param timeout_timestamp the timeout time
  ## @return true if the target time is reached, false otherwise


## MODULE ALARM

proc alarmPoolInitDefault*() {.importc: "alarm_pool_init_default".}
  ## Create the default alarm pool (if not already created or disabled)

proc alarmPoolGetDefault*(): ptr AlarmPool {.importc: "alarm_pool_get_default".}
  ## The default alarm pool used when alarms are added without specifying an alarm pool,
  ##        and also used by the SDK to support lower power sleeps and timeouts.
  ##
  ## \sa #PICO_TIME_DEFAULT_ALARM_POOL_HARDWARE_ALARM_NUM

proc alarmPoolCreate*(hardwareAlarmNum: HardwareAlarmNum; maxTimers: cuint): ptr AlarmPool {.importc: "alarm_pool_create".}
  ## Create an alarm pool
  ##
  ## The alarm pool will call callbacks from an alarm IRQ Handler on the core of this function is called from.
  ##
  ## In many situations there is never any need for anything other than the default alarm pool, however you
  ## might want to create another if you want alarm callbacks on core 1 or require alarm pools of
  ## different priority (IRQ priority based preemption of callbacks)
  ##
  ## \note This method will hard assert if the hardware alarm is already claimed.
  ##
  ## \param hardware_alarm_num the hardware alarm to use to back this pool
  ## \param max_timers the maximum number of timers
  ##        \note For implementation reasons this is limited to PICO_PHEAP_MAX_ENTRIES which defaults to 255
  ## \sa alarm_pool_get_default()
  ## \sa hardware_claiming

proc alarmPoolCreateWithUnusedHardwareAlarm*(maxTimers: cuint): ptr AlarmPool {.importc: "alarm_pool_create_with_unused_hardware_alarm".}
  ## Create an alarm pool, claiming an used hardware alarm to back it.
  ##
  ## The alarm pool will call callbacks from an alarm IRQ Handler on the core of this function is called from.
  ##
  ## In many situations there is never any need for anything other than the default alarm pool, however you
  ## might want to create another if you want alarm callbacks on core 1 or require alarm pools of
  ## different priority (IRQ priority based preemption of callbacks)
  ##
  ## \note This method will hard assert if the there is no free hardware to claim.
  ##
  ## \param max_timers the maximum number of timers
  ##     \note For implementation reasons this is limited to PICO_PHEAP_MAX_ENTRIES which defaults to 255
  ## \sa alarm_pool_get_default()
  ## \sa hardware_claiming

proc hardwareAlarmNum*(pool: ptr AlarmPool): HardwareAlarmNum {.importc: "alarm_pool_hardware_alarm_num".}
  ## Return the hardware alarm used by an alarm pool
  ## \param pool the pool
  ## \return the hardware alarm used by the pool

proc destroy*(pool: ptr AlarmPool) {.importc: "alarm_pool_destroy".}
  ## Destroy the alarm pool, cancelling all alarms and freeing up the underlying hardware alarm
  ## \param pool the pool

proc addAlarmAt*(pool: ptr AlarmPool; time: AbsoluteTime; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "alarm_pool_add_alarm_at".}
  ## Add an alarm callback to be called at a specific time
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the callback (this determines which hardware alarm is used, and which core calls the callback)
  ## @param time the timestamp when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls before or during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id for an active (at the time of return) alarm
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc addAlarmAtForceInContext*(pool: ptr AlarmPool; time: AbsoluteTime; callback: AlarmCallback; userData: pointer): AlarmId {.importc: "alarm_pool_add_alarm_at_force_in_context".}
  ## Add an alarm callback to be called at or after a specific time
  ##
  ## The callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. Unlike \ref alarm_pool_add_alarm_at, this method
  ## guarantees to call the callback from that core even if the time is during this method call or in the past.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the callback (this determines which hardware alarm is used, and which core calls the callback)
  ## @param time the timestamp when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @return >0 the alarm id for an active (at the time of return) alarm
  ## @return -1 if there were no alarm slots available


proc addAlarmInUs*(pool: ptr AlarmPool; us: uint64; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "alarm_pool_add_alarm_in_us".}
  ## Add an alarm callback to be called after a delay specified in microseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the callback (this determines which hardware alarm is used, and which core calls the callback)
  ## @param us the delay (from now) in microseconds when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc addAlarmInMs*(pool: ptr AlarmPool; ms: uint32; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "alarm_pool_add_alarm_in_ms".}
  ## Add an alarm callback to be called after a delay specified in milliseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the callback (this determines which hardware alarm is used, and which core calls the callback)
  ## @param ms the delay (from now) in milliseconds when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls before or during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc cancelAlarm*(pool: ptr AlarmPool; alarmId: AlarmId): bool {.importc: "alarm_pool_cancel_alarm".}
  ## Cancel an alarm
  ##
  ## \param pool the alarm_pool containing the alarm
  ## \param alarm_id the alarm
  ## \return true if the alarm was cancelled, false if it didn't exist
  ## \sa alarm_id_t for a note on reuse of IDs

proc addAlarmAt*(time: AbsoluteTime; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "add_alarm_at".}
  ## Add an alarm callback to be called at a specific time
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core of the default alarm pool (generally core 0). If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param time the timestamp when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls before or during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc addAlarmInUs*(us: uint64; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "add_alarm_in_us".}
  ## Add an alarm callback to be called after a delay specified in microseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core of the default alarm pool (generally core 0). If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param us the delay (from now) in microseconds when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc addAlarmInMs*(ms: uint32; callback: AlarmCallback; userData: pointer; fireIfPast: bool): AlarmId {.importc: "add_alarm_in_ms".}
  ## Add an alarm callback to be called after a delay specified in milliseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core of the default alarm pool (generally core 0). If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param ms the delay (from now) in milliseconds when (after which) the callback should fire
  ## @param callback the callback function
  ## @param user_data user data to pass to the callback function
  ## @param fire_if_past if true, and the alarm time falls during this call before the alarm can be set,
  ##                     then the callback should be called during (by) this function instead
  ## @return >0 the alarm id
  ## @return 0 if the alarm time passed before or during the call AND there is no active alarm to return the id of.
  ##           The latter can either happen because fire_if_past was false (i.e. no timer was ever created),
  ##           or if the callback <i>was</i> called during this method but the callback cancelled itself by returning 0
  ## @return -1 if there were no alarm slots available

proc cancel*(alarmId: AlarmId): bool {.importc: "cancel_alarm".}
  ## Cancel an alarm from the default alarm pool
  ## \param alarm_id the alarm
  ## \return true if the alarm was cancelled, false if it didn't exist
  ## \sa alarm_id_t for a note on reuse of IDs


## MODULE REPEATING TIMER

proc addRepeatingTimerUs*(pool: ptr AlarmPool; delayUs: int64; callback: RepeatingTimerCallback; userData: pointer; `out`: ptr RepeatingTimer): bool {.importc: "alarm_pool_add_repeating_timer_us".}
  ## Add a repeating timer that is called repeatedly at the specified interval in microseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the repeating timer (this determines which hardware alarm is used, and which core calls the callback)
  ## @param delay_us the repeat delay in microseconds; if >0 then this is the delay between one callback ending and the next starting; if <0 then this is the negative of the time between the starts of the callbacks. The value of 0 is treated as 1
  ## @param callback the repeating timer callback function
  ## @param user_data user data to pass to store in the repeating_timer structure for use by the callback.
  ## @param out the pointer to the user owned structure to store the repeating timer info in. BEWARE this storage location must outlive the repeating timer, so be careful of using stack space
  ## @return false if there were no alarm slots available to create the timer, true otherwise.

proc addRepeatingTimerMs*(pool: ptr AlarmPool; delayMs: int32; callback: RepeatingTimerCallback; userData: pointer; `out`: ptr RepeatingTimer): bool {.importc: "alarm_pool_add_repeating_timer_ms".}
  ## Add a repeating timer that is called repeatedly at the specified interval in milliseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core the alarm pool was created on. If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param pool the alarm pool to use for scheduling the repeating timer (this determines which hardware alarm is used, and which core calls the callback)
  ## @param delay_ms the repeat delay in milliseconds; if >0 then this is the delay between one callback ending and the next starting; if <0 then this is the negative of the time between the starts of the callbacks. The value of 0 is treated as 1 microsecond
  ## @param callback the repeating timer callback function
  ## @param user_data user data to pass to store in the repeating_timer structure for use by the callback.
  ## @param out the pointer to the user owned structure to store the repeating timer info in. BEWARE this storage location must outlive the repeating timer, so be careful of using stack space
  ## @return false if there were no alarm slots available to create the timer, true otherwise.

proc addRepeatingTimerUs*(delayUs: int64; callback: RepeatingTimerCallback; userData: pointer; `out`: ptr RepeatingTimer): bool {.importc: "add_repeating_timer_us".}
  ## Add a repeating timer that is called repeatedly at the specified interval in microseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core of the default alarm pool (generally core 0). If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param delay_us the repeat delay in microseconds; if >0 then this is the delay between one callback ending and the next starting; if <0 then this is the negative of the time between the starts of the callbacks. The value of 0 is treated as 1
  ## @param callback the repeating timer callback function
  ## @param user_data user data to pass to store in the repeating_timer structure for use by the callback.
  ## @param out the pointer to the user owned structure to store the repeating timer info in. BEWARE this storage location must outlive the repeating timer, so be careful of using stack space
  ## @return false if there were no alarm slots available to create the timer, true otherwise.

proc addRepeatingTimerMs*(delayMs: int32; callback: RepeatingTimerCallback; userData: pointer; `out`: ptr RepeatingTimer): bool {.importc: "add_repeating_timer_ms".}
  ## Add a repeating timer that is called repeatedly at the specified interval in milliseconds
  ##
  ## Generally the callback is called as soon as possible after the time specified from an IRQ handler
  ## on the core of the default alarm pool (generally core 0). If the callback is in the past or happens before
  ## the alarm setup could be completed, then this method will optionally call the callback itself
  ## and then return a return code to indicate that the target time has passed.
  ##
  ## \note It is safe to call this method from an IRQ handler (including alarm callbacks), and from either core.
  ##
  ## @param delay_ms the repeat delay in milliseconds; if >0 then this is the delay between one callback ending and the next starting; if <0 then this is the negative of the time between the starts of the callbacks. The value of 0 is treated as 1 microsecond
  ## @param callback the repeating timer callback function
  ## @param user_data user data to pass to store in the repeating_timer structure for use by the callback.
  ## @param out the pointer to the user owned structure to store the repeating timer info in. BEWARE this storage location must outlive the repeating timer, so be careful of using stack space
  ## @return false if there were no alarm slots available to create the timer, true otherwise.

proc cancel*(timer: ptr RepeatingTimer): bool {.importc: "cancel_repeating_timer".}
  ## Cancel a repeating timer
  ## \param timer the repeating timer to cancel
  ## \return true if the repeating timer was cancelled, false if it didn't exist
  ## \sa alarm_id_t for a note on reuse of IDs

{.pop.}


## Nim helpers

proc `-`*(timeLeft, timeRight: AbsoluteTime): int64 {.inline.} =
  diffUs(timeRight, timeLeft)

proc `==`*(timeLeft, timeRight: AbsoluteTime): bool {.inline.} =
  timeLeft - timeRight == 0

proc `<=`*(timeLeft, timeRight: AbsoluteTime): bool {.inline.} =
  timeLeft - timeRight <= 0

proc `<`*(timeLeft, timeRight: AbsoluteTime): bool {.inline.} =
  timeLeft - timeRight < 0

