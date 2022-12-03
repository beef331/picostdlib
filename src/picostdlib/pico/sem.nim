import types
import lock_core

{.push header: "pico/sem.h".}

type
  Semaphore* {.bycopy, importc: "semaphore_t".} = object
    core* {.importc.}: LockCore
    permits* {.importc.}: int16
    max_permits* {.importc.}: int16

proc semInit*(sem: ptr Semaphore; initialPermits: int16; maxPermits: int16) {.importc: "sem_init".}
  ## ```
  ##   ! \brief  Initialise a semaphore structure
  ##     \ingroup sem
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \param initial_permits How many permits are initially acquired
  ##    \param max_permits  Total number of permits allowed for this semaphore
  ## ```

proc semAvailable*(sem: ptr Semaphore): cint {.importc: "sem_available".}
  ## ```
  ##   ! \brief  Return number of available permits on the semaphore
  ##     \ingroup sem
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \return The number of permits available on the semaphore.
  ## ```

proc semRelease*(sem: ptr Semaphore): bool {.importc: "sem_release".}
  ## ```
  ##   ! \brief  Release a permit on a semaphore
  ##     \ingroup sem
  ##   
  ##    Increases the number of permits by one (unless the number of permits is already at the maximum).
  ##    A blocked sem_acquire will be released if the number of permits is increased.
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \return true if the number of permits available was increased.
  ## ```

proc semReset*(sem: ptr Semaphore; permits: int16) {.importc: "sem_reset".}
  ## ```
  ##   ! \brief  Reset semaphore to a specific number of available permits
  ##     \ingroup sem
  ##   
  ##    Reset value should be from 0 to the max_permits specified in the init function
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \param permits the new number of available permits
  ## ```

proc semAcquireBlocking*(sem: ptr Semaphore) {.importc: "sem_acquire_blocking".}
  ## ```
  ##   ! \brief  Acquire a permit from the semaphore
  ##     \ingroup sem
  ##   
  ##    This function will block and wait if no permits are available.
  ##   
  ##    \param sem Pointer to semaphore structure
  ## ```

proc semAcquireTimeoutMs*(sem: ptr Semaphore; timeoutMs: uint32): bool {.importc: "sem_acquire_timeout_ms".}
  ## ```
  ##   ! \brief  Acquire a permit from a semaphore, with timeout
  ##     \ingroup sem
  ##   
  ##    This function will block and wait if no permits are available, until the
  ##    defined timeout has been reached. If the timeout is reached the function will
  ##    return false, otherwise it will return true.
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \param timeout_ms Time to wait to acquire the semaphore, in milliseconds.
  ##    \return false if timeout reached, true if permit was acquired.
  ## ```

proc semAcquireTimeoutUs*(sem: ptr Semaphore; timeoutUs: uint32): bool {.importc: "sem_acquire_timeout_us".}
  ## ```
  ##   ! \brief  Acquire a permit from a semaphore, with timeout
  ##     \ingroup sem
  ##   
  ##    This function will block and wait if no permits are available, until the
  ##    defined timeout has been reached. If the timeout is reached the function will
  ##    return false, otherwise it will return true.
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \param timeout_us Time to wait to acquire the semaphore, in microseconds.
  ##    \return false if timeout reached, true if permit was acquired.
  ## ```

proc semAcquireBlockUntil*(sem: ptr Semaphore; until: AbsoluteTime): bool {.importc: "sem_acquire_block_until".}
  ## ```
  ##   ! \brief Wait to acquire a permit from a semaphore until a specific time
  ##     \ingroup sem
  ##   
  ##    This function will block and wait if no permits are available, until the
  ##    specified timeout time. If the timeout is reached the function will
  ##    return false, otherwise it will return true.
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \param until The time after which to return if the sem is not available.
  ##    \return true if permit was acquired, false if the until time was reached before
  ##    acquiring.
  ## ```

proc semTryAcquire*(sem: ptr Semaphore): bool {.importc: "sem_try_acquire".}
  ## ```
  ##   ! \brief Attempt to acquire a permit from a semaphore without blocking
  ##     \ingroup sem
  ##   
  ##    This function will return false without blocking if no permits are
  ##    available, otherwise it will acquire a permit and return true.
  ##   
  ##    \param sem Pointer to semaphore structure
  ##    \return true if permit was acquired.
  ## ```

{.pop.}
