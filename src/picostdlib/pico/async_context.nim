import ./time
export time

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_async_context/include".}
{.push header: "pico/async_context.h".}

let
  ASYNC_CONTEXT_FLAG_CALLBACK_FROM_NON_IRQ* {.importc: "ASYNC_CONTEXT_FLAG_CALLBACK_FROM_NON_IRQ".}: uint16
  ASYNC_CONTEXT_FLAG_CALLBACK_FROM_IRQ* {.importc: "ASYNC_CONTEXT_FLAG_CALLBACK_FROM_IRQ".}: uint16
  ASYNC_CONTEXT_FLAG_POLLED* {.importc: "ASYNC_CONTEXT_FLAG_POLLED".}: uint16

type
  AsyncContext* {.importc: "async_context_t".} = object
    ## Base structure type of all async_contexts. For details about its use, see \ref pico_async_context.
    ##
    ## Individual async_context_types with additional state, should contain this structure at the start.
    contextType {.importc: "type".}: ptr AsyncContextType
    whenPendingList {.importc: "when_pending_list".}: ptr AsyncWhenPendingWorker
    atTimeList {.importc: "at_time_list".}: ptr AsyncAtTimeWorker
    nextTime {.importc: "next_time".}: AbsoluteTime
    flags {.importc: "flags".}: uint16
    coreNum {.importc: "core_num".}: uint8

  AsyncAtTimeWorker* {.importc: "async_at_time_worker_t".} = object
    ## A "timeout" instance used by an async_context
    ##
    ## A "timeout" represents some future action that must be taken at a specific time.
    ## Its methods are called from the async_context under lock at the given time
    ##
    ## \see async_context_add_worker_at
    ## \see async_context_add_worker_in_ms
    next {.importc: "next".}: ptr AsyncAtTimeWorker
      ## private link list pointer
    doWork* {.importc: "do_work".}: proc (context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker) {.cdecl.}
      ## Method called when the timeout is reached; may not be NULL
      ##
      ## Note, that when this method is called, the timeout has been removed from the async_context, so
      ## if you want the timeout to repeat, you should re-add it during this callback
      ## @param context
      ## @param timeout
    nextTime* {.importc: "next_time".}: AbsoluteTime
      ## The next timeout time; this should only be modified during the above methods
      ## or via async_context methods
    userData* {.importc: "user_data".}: pointer
      ## User data associated with the timeout instance

  AsyncWhenPendingWorker* {.importc: "async_when_pending_worker_t".} = object
    ## A "worker" instance used by an async_context
    ##
    ## A "worker" represents some external entity that must do work in response
    ##  to some external stimulus (usually an IRQ).
    ## Its methods are called from the async_context under lock at the given time
    ##
    ## \see async_context_add_worker_at
    ## \see async_context_add_worker_in_ms
    next {.importc: "next".}: ptr AsyncWhenPendingWorker
      ## private link list pointer
    doWork* {.importc: "do_work".}: proc (context: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.cdecl.}
      ## Called by the async_context when the worker has been marked as having "work pending"
      ## @param context the async_context
      ## @param worker the function to be called when work is pending
    workPending* {.importc: "work_pending".}: bool
      ## True if the worker need do_work called
    userData* {.importc: "user_data".}: pointer
      ## User data associated with the worker instance

  AsyncContextType* {.importc: "async_context_type_t".} = object
    ## Implementation of an async_context type, providing methods common to that type
    `type`* {.importc: "type".}: uint16
    # see wrapper functions for documentation
    acquireLockBlocking* {.importc: "acquire_lock_blocking".}: proc (self: ptr AsyncContext) {.cdecl.}
    releaseLock* {.importc: "release_lock".}: proc (self: ptr AsyncContext) {.cdecl.}
    lockCheck* {.importc: "lock_check".}: proc (self: ptr AsyncContext) {.cdecl.}
    executeSync* {.importc: "execute_sync".}: proc (self: ptr AsyncContext; `func`: proc (param: pointer): uint32 {.cdecl.}; param: pointer) {.cdecl.}
    addAtTimeWorker* {.importc: "add_at_time_worker".}: proc (self: ptr AsyncContext; worker: ptr AsyncAtTimeWorker) {.cdecl.}
    removeAtTimeWorker* {.importc: "remove_at_time_worker".}: proc (self: ptr AsyncContext; worker: ptr AsyncAtTimeWorker) {.cdecl.}
    addWhenPendingWorker* {.importc: "add_when_pending_worker".}: proc (self: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.cdecl.}
    removeWhenPendingWorker* {.importc: "remove_when_pending_worker".}: proc (self: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.cdecl.}
    setWorkPending* {.importc: "set_work_pending".}: proc (self: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.cdecl.}
    poll* {.importc: "poll".}: proc (self: ptr AsyncContext) {.cdecl.} # may be NULL
    waitUntil* {.importc: "wait_until".}: proc (self: ptr AsyncContext; until: AbsoluteTime) {.cdecl.}
    waitForWorkUntil* {.importc: "wait_for_work_until".}: proc (self: ptr AsyncContext; until: AbsoluteTime) {.cdecl.}
    deinit* {.importc: "deinit".}: proc (self: ptr AsyncContext) {.cdecl.}

proc acquireLockBlocking*(context: ptr AsyncContext) {.importc: "async_context_acquire_lock_blocking".}
  ## Acquire the async_context lock
  ##
  ## The owner of the async_context lock is the logic owner of the async_context
  ## and other work related to this async_context will not happen concurrently.
  ##
  ## This method may be called in a nested fashion by the the lock owner.
  ##
  ## \note the async_context lock is nestable by the same caller, so an internal count is maintained
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ##
  ## \see async_context_release_lock

proc releaseLock*(context: ptr AsyncContext) {.importc: "async_context_release_lock".}
  ## Release the async_context lock
  ##
  ## \note the async_context lock may be called in a nested fashion, so an internal count is maintained. On the outermost
  ## release, When the outermost lock is released, a check is made for work which might have been skipped while the lock was held,
  ## and any such work may be performed during this call IF the call is made from the same core that the async_context belongs to.
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ##
  ## \see async_context_acquire_lock_blocking

proc lockCheck*(context: ptr AsyncContext) {.importc: "async_context_lock_check".}
  ## Assert if the caller does not own the lock for the async_context
  ## \note this method is thread-safe
  ##
  ## \param context the async_context

proc executeSync*(context: ptr AsyncContext; `func`: proc (param: pointer): uint32 {.cdecl.}; param: pointer): uint32 {.importc: "async_context_execute_sync".}
  ## Execute work synchronously on the core the async_context belongs to.
  ##
  ## This method is intended for code external to the async_context (e.g. another thread/task) to
  ## execute a function with the same guarantees (single core, logical thread of execution) that
  ## async_context workers are called with.
  ##
  ## \note you should NOT call this method while holding the async_context's lock
  ##
  ## \param context the async_context
  ## \param func the function to call
  ## \param param the paramter to pass to the function
  ## \return the return value from func

proc addAtTimeWorker*(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker): bool {.importc: "async_context_add_at_time_worker".}
  ## Add an "at time" worker to a context
  ##
  ## An "at time" worker will run at or after a specific point in time, and is automatically when (just before) it runs.
  ##
  ## The time to fire is specified in the next_time field of the worker.
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "at time" worker to add
  ## \return true if the worker was added, false if the worker was already present.

proc addAtTimeWorkerAt*(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker; at: AbsoluteTime): bool {.importc: "async_context_add_at_time_worker_at".}
  ## Add an "at time" worker to a context
  ##
  ## An "at time" worker will run at or after a specific point in time, and is automatically when (just before) it runs.
  ##
  ## The time to fire is specified by the at parameter.
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "at time" worker to add
  ## \param at the time to fire at
  ## \return true if the worker was added, false if the worker was already present.

proc addAtTimeWorkerInMs*(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker; ms: uint32): bool {.importc: "async_context_add_at_time_worker_in_ms".}
  ## Add an "at time" worker to a context
  ##
  ## An "at time" worker will run at or after a specific point in time, and is automatically when (just before) it runs.
  ##
  ## The time to fire is specified by a delay via the ms parameter
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "at time" worker to add
  ## \param ms the number of milliseconds from now to fire after
  ## \return true if the worker was added, false if the worker was already present.

proc removeAtTimeWorker*(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker): bool {.importc: "async_context_remove_at_time_worker".}
  ## Remove an "at time" worker from a context
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "at time" worker to remove
  ## \return true if the worker was removed, false if the instance not present.

proc addWhenPendingWorker*(context: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker): bool {.importc: "async_context_add_when_pending_worker".}
  ## Add a "when pending" worker to a context
  ##
  ## An "when pending" worker will run when it is pending (can be set via \ref async_context_set_work_pending), and
  ## is NOT automatically removed when it runs.
  ##
  ## The time to fire is specified by a delay via the ms parameter
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "when pending" worker to add
  ## \return true if the worker was added, false if the worker was already present.

proc removeWhenPendingWorker*(context: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker): bool {.importc: "async_context_remove_when_pending_worker".}
  ## Remove a "when pending" worker from a context
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe. and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param worker the "when pending" worker to remove
  ## \return true if the worker was removed, false if the instance not present.

proc setWorkPending*(context: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.importc: "async_context_set_work_pending".}
  ## Mark a "when pending" worker as having work pending
  ##
  ## The worker will be run from the async_context at a later time.
  ##
  ## \note this method may be called from any context including IRQs
  ##
  ## \param context the async_context
  ## \param worker the "when pending" worker to mark as pending.

proc poll*(context: ptr AsyncContext) {.importc: "async_context_poll".}
  ## Perform any pending work for polling style async_context
  ##
  ## For a polled async_context (e.g. \ref async_context_poll) the user is responsible for calling this method
  ## periodically to perform any required work.
  ##
  ## This method may immediately perform outstanding work on other context types, but is not required to.
  ##
  ## \param context the async_context

proc waitUntil*(context: ptr AsyncContext; until: AbsoluteTime) {.importc: "async_context_wait_until".}
  ## sleep until the specified time in an async_context callback safe way
  ##
  ## \note for async_contexts that provide locking (not async_context_poll), this method is threadsafe, and may be called from within any
  ## worker method called by the async_context or from any other non-IRQ context.
  ##
  ## \param context the async_context
  ## \param until the time to sleep until

proc waitForWorkUntil*(context: ptr AsyncContext; until: AbsoluteTime) {.importc: "async_context_wait_for_work_until".}
  ## Block until work needs to be done or the specified time has been reached
  ##
  ## \note this method should not be called from a worker callback
  ##
  ## \param context the async_context
  ## \param until the time to return at if no work is required

proc waitForWorkMs*(context: ptr AsyncContext; ms: uint32) {.importc: "async_context_wait_for_work_ms".}
  ## Block until work needs to be done or the specified number of milliseconds have passed
  ##
  ## \note this method should not be called from a worker callback
  ##
  ## \param context the async_context
  ## \param ms the number of milliseconds to return after if no work is required

proc coreNum*(context: ptr AsyncContext): cuint {.importc: "async_context_core_num".}
  ## Return the processor core this async_context belongs to
  ##
  ## \param context the async_context
  ## \return the physical core number

proc deinit*(context: ptr AsyncContext) {.importc: "async_context_deinit".}
  ## End async_context processing, and free any resources
  ##
  ## Note the user should clean up any resources associated with workers
  ## in the async_context themselves.
  ##
  ## Asynchronous (non-polled) async_contexts guarantee that no
  ## callback is being called once this method returns.
  ##
  ## \param context the async_context

{.pop.}

import ./mutex
import ./sem

{.push header: "pico/async_context_threadsafe_background.h".}

type
  AsyncContextThreadsafeBackgroundConfig* {.importc: "async_context_threadsafe_background_config_t".} = object
    ## Configuration object for async_context_threadsafe_background instances.
    low_priority_irq_handler_priority*: uint8
      ## the priority of the low priority IRQ
    custom_alarm_pool*: ptr AlarmPool

  AsyncContextThreadsafeBackground* {.importc: "async_context_threadsafe_background_t".} = object
    core*: AsyncContext
    alarm_pool*: ptr AlarmPool # this must be on the same core as core_num
    last_set_alarm_time*: AbsoluteTime
    lock_mutex*: RecursiveMutex
    work_needed_sem*: Semaphore
    alarm_id*: AlarmId

    # #if ASYNC_CONTEXT_THREADSAFE_BACKGROUND_MULTI_CORE
    force_alarm_id*: AlarmId
    alarm_pool_owned*: bool
    # #endif

    low_priority_irq_num*: uint8
    alarm_pending*: bool

proc init*(self: ptr AsyncContextThreadsafeBackground; config: ptr AsyncContextThreadsafeBackgroundConfig): bool {.importc: "async_context_threadsafe_background_init".}
  ## Initialize an async_context_threadsafe_background instance using the specified configuration
  ##
  ## If this method succeeds (returns true), then the async_context is available for use
  ## and can be de-initialized by calling async_context_deinit().
  ##
  ## \param self a pointer to async_context_threadsafe_background structure to initialize
  ## \param config the configuration object specifying characteristics for the async_context
  ## \return true if initialization is successful, false otherwise

proc asyncContextThreadsafeBackgroundDefaultConfig*(): AsyncContextThreadsafeBackgroundConfig {.importc: "async_context_threadsafe_background_default_config".}
  ## Return a copy of the default configuration object used by \ref async_context_threadsafe_background_init_with_defaults()
  ##
  ## The caller can then modify just the settings it cares about, and call \ref async_context_threadsafe_background_init()
  ## \return the default configuration object

proc initWithDefaults*(self: ptr AsyncContextThreadsafeBackground): bool {.importc: "async_context_threadsafe_background_init_with_defaults".}
  ## Initialize an async_context_threadsafe_background instance with default values
  ##
  ## If this method succeeds (returns true), then the async_context is available for use
  ## and can be de-initialized by calling async_context_deinit().
  ##
  ## \param self a pointer to async_context_threadsafe_background structure to initialize
  ## \return true if initialization is successful, false otherwise

{.pop.}


{.push header: "pico/async_context_poll.h".}

type
  AsyncContextPoll* {.importc: "async_context_poll_t".} = object
    core*: AsyncContext
    sem*: Semaphore

proc initWithDefaults*(self: ptr AsyncContextPoll): bool {.importc: "async_context_poll_init_with_defaults".}
  ## Initialize an async_context_poll instance with default values
  ##
  ## If this method succeeds (returns true), then the async_context is available for use
  ## and can be de-initialized by calling async_context_deinit().
  ##
  ## \param self a pointer to async_context_poll structure to initialize
  ## \return true if initialization is successful, false otherwise

template init*(self: ptr AsyncContextPoll): bool = initWithDefaults(self)

{.pop.}

when defined(freertos):
  import ../lib/freertos

  {.push header: "async_context_freertos.h".}

  let
    ASYNC_CONTEXT_DEFAULT_FREERTOS_TASK_PRIORITY* {.importc: "ASYNC_CONTEXT_DEFAULT_FREERTOS_TASK_PRIORITY".}: clong
    ASYNC_CONTEXT_DEFAULT_FREERTOS_TASK_STACK_SIZE* {.importc: "ASYNC_CONTEXT_DEFAULT_FREERTOS_TASK_STACK_SIZE".}: cuint

  type
    AsyncContextFreertosConfig* {.importc: "async_context_freertos_config_t".} = object
      task_priority*: UBaseTypeT
        ## Task priority for the async_context task
      task_stack_size*: csize_t
        ## Stack size for the async_context task

      # #if configUSE_CORE_AFFINITY && configNUM_CORES > 1
      task_core_id*: UBaseTypeT
        ## the core ID (see \ref portGET_CORE_ID()) to pin the task to.
        ## This is only relevant in SMP mode.

    AsyncContextFreertos* {.importc: "async_context_freertos_t".} = object
      core*: AsyncContext
      lock_mutex*: SemaphoreHandleT
      work_needed_sem*: SemaphoreHandleT
      timer_handle*: TimerHandleT
      task_handle*: TaskHandleT
      nesting*: uint8
      task_should_exit*: bool

  proc init*(self: ptr AsyncContextFreertos; config: ptr AsyncContextFreertosConfig): bool {.importc: "async_context_freertos_init".}
    ## Initialize an async_context_freertos instance using the specified configuration
    ##
    ## If this method succeeds (returns true), then the async_context is available for use
    ## and can be de-initialized by calling async_context_deinit().
    ##
    ## \param self a pointer to async_context_freertos structure to initialize
    ## \param config the configuration object specifying characteristics for the async_context
    ## \return true if initialization is successful, false otherwise

  proc asyncContextFreertosDefaultConfig*(): AsyncContextFreertosConfig {.importc: "async_context_freertos_default_config".}
    ## Return a copy of the default configuration object used by \ref async_context_freertos_init_with_defaults()
    ##
    ## The caller can then modify just the settings it cares about, and call \ref async_context_freertos_init()
    ## \return the default configuration object

  proc initWithDefaults*(self: AsyncContextFreertos): bool {.importc: "async_context_freertos_init_with_defaults".}
    ## Initialize an async_context_freertos instance with default values
    ## \ingroup async_context_freertos
    ##
    ## If this method succeeds (returns true), then the async_context is available for use
    ## and can be de-initialized by calling async_context_deinit().
    ##
    ## \param self a pointer to async_context_freertos structure to initialize
    ## \return true if initialization is successful, false otherwise

  {.pop.}
