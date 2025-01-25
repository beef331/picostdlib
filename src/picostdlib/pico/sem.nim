import ./types
import ./lock_core

export types, lock_core

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_sync/include".}
{.push header: "pico/sem.h".}

type
  Semaphore* {.bycopy, importc: "semaphore_t".} = object
    core* {.importc: "core".}: LockCore
    permits* {.importc: "permits".}: int16
    maxPermits* {.importc: "max_permits".}: int16

proc init*(sem: ptr Semaphore; initialPermits: int16; maxPermits: int16) {.importc: "sem_init".}
  ## Initialise a semaphore structure
  ##
  ## \param sem Pointer to semaphore structure
  ## \param initial_permits How many permits are initially acquired
  ## \param max_permits  Total number of permits allowed for this semaphore

proc available*(sem: ptr Semaphore): cint {.importc: "sem_available".}
  ## Return number of available permits on the semaphore
  ##
  ## \param sem Pointer to semaphore structure
  ## \return The number of permits available on the semaphore.

proc release*(sem: ptr Semaphore): bool {.importc: "sem_release".}
  ## Release a permit on a semaphore
  ##
  ## Increases the number of permits by one (unless the number of permits is already at the maximum).
  ## A blocked sem_acquire will be released if the number of permits is increased.
  ##
  ## \param sem Pointer to semaphore structure
  ## \return true if the number of permits available was increased.

proc reset*(sem: ptr Semaphore; permits: int16) {.importc: "sem_reset".}
  ## Reset semaphore to a specific number of available permits
  ##
  ## Reset value should be from 0 to the max_permits specified in the init function
  ##
  ## \param sem Pointer to semaphore structure
  ## \param permits the new number of available permits

proc acquireBlocking*(sem: ptr Semaphore) {.importc: "sem_acquire_blocking".}
  ## Acquire a permit from the semaphore
  ##
  ## This function will block and wait if no permits are available.
  ##
  ## \param sem Pointer to semaphore structure

proc acquireTimeoutMs*(sem: ptr Semaphore; timeoutMs: uint32): bool {.importc: "sem_acquire_timeout_ms".}
  ## Acquire a permit from a semaphore, with timeout
  ##
  ## This function will block and wait if no permits are available, until the
  ## defined timeout has been reached. If the timeout is reached the function will
  ## return false, otherwise it will return true.
  ##
  ## \param sem Pointer to semaphore structure
  ## \param timeout_ms Time to wait to acquire the semaphore, in milliseconds.
  ## \return false if timeout reached, true if permit was acquired.

proc acquireTimeoutUs*(sem: ptr Semaphore; timeoutUs: uint32): bool {.importc: "sem_acquire_timeout_us".}
  ## Acquire a permit from a semaphore, with timeout
  ##
  ## This function will block and wait if no permits are available, until the
  ## defined timeout has been reached. If the timeout is reached the function will
  ## return false, otherwise it will return true.
  ##
  ## \param sem Pointer to semaphore structure
  ## \param timeout_us Time to wait to acquire the semaphore, in microseconds.
  ## \return false if timeout reached, true if permit was acquired.

proc acquireBlockUntil*(sem: ptr Semaphore; until: AbsoluteTime): bool {.importc: "sem_acquire_block_until".}
  ## Wait to acquire a permit from a semaphore until a specific time
  ##
  ## This function will block and wait if no permits are available, until the
  ## specified timeout time. If the timeout is reached the function will
  ## return false, otherwise it will return true.
  ##
  ## \param sem Pointer to semaphore structure
  ## \param until The time after which to return if the sem is not available.
  ## \return true if permit was acquired, false if the until time was reached before
  ## acquiring.

proc tryAcquire*(sem: ptr Semaphore): bool {.importc: "sem_try_acquire".}
  ## Attempt to acquire a permit from a semaphore without blocking
  ##
  ## This function will return false without blocking if no permits are
  ## available, otherwise it will acquire a permit and return true.
  ##
  ## \param sem Pointer to semaphore structure
  ## \return true if permit was acquired.

{.pop.}
