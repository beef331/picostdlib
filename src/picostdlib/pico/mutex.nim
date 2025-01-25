import ./types
import ./lock_core

export types, lock_core

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_sync/include".}
{.push header: "pico/mutex.h".}

type
  RecursiveMutex* {.bycopy, importc: "recursive_mutex_t".} = object
    ## recursive mutex instance
    core* {.importc: "core".}: LockCore
    owner* {.importc: "owner".}: LockOwnerId      # owner id LOCK_INVALID_OWNER_ID for unowned
    enterCount* {.importc: "enter_count".}: uint8 # ownership count

  Mutex* {.bycopy, importc: "mutex_t".} = object
    ## regular (non recursive) mutex instance
    core* {.importc: "core".}: LockCore
    owner* {.importc: "owner".}: LockOwnerId # owner id LOCK_INVALID_OWNER_ID for unowned


proc init*(mtx: ptr Mutex) {.importc: "mutex_init".}
  ## Initialise a mutex structure
  ##
  ## \param mtx Pointer to mutex structure

proc init*(mtx: ptr RecursiveMutex) {.importc: "recursive_mutex_init".}
  ## Initialise a recursive mutex structure
  ##
  ## A recursive mutex may be entered in a nested fashion by the same owner
  ##
  ## \param mtx Pointer to recursive mutex structure

proc enterBlocking*(mtx: ptr Mutex) {.importc: "mutex_enter_blocking".}
  ## Take ownership of a mutex
  ##
  ## This function will block until the caller can be granted ownership of the mutex.
  ## On return the caller owns the mutex
  ##
  ## \param mtx Pointer to mutex structure

proc enterBlocking*(mtx: ptr RecursiveMutex) {.importc: "recursive_mutex_enter_blocking".}
  ## Take ownership of a recursive mutex
  ##
  ## This function will block until the caller can be granted ownership of the mutex.
  ## On return the caller owns the mutex
  ##
  ## \param mtx Pointer to recursive mutex structure

proc tryEnter*(mtx: ptr Mutex; ownerOut: ptr uint32): bool {.importc: "mutex_try_enter".}
  ## Attempt to take ownership of a mutex
  ##
  ## If the mutex wasn't owned, this will claim the mutex for the caller and return true.
  ## Otherwise (if the mutex was already owned) this will return false and the
  ## caller will NOT own the mutex.
  ##
  ## \param mtx Pointer to mutex structure
  ## \param owner_out If mutex was already owned, and this pointer is non-zero, it will be filled in with the owner id of the current owner of the mutex
  ## \return true if mutex now owned, false otherwise

proc tryEnterBlockUntil*(mtx: ptr Mutex; until: AbsoluteTime): bool {.importc: "mutex_try_enter_block_until".}
  ## Attempt to take ownership of a mutex until the specified time
  ##
  ## If the mutex wasn't owned, this method will immediately claim the mutex for the caller and return true.
  ## If the mutex is owned by the caller, this method will immediately return false,
  ## If the mutex is owned by someone else, this method will try to claim it until the specified time, returning
  ## true if it succeeds, or false on timeout
  ##
  ## \param mtx Pointer to mutex structure
  ## \param until The time after which to return if the caller cannot be granted ownership of the mutex
  ## \return true if mutex now owned, false otherwise

proc tryEnter*(mtx: ptr RecursiveMutex; ownerOut: ptr uint32): bool {.importc: "recursive_mutex_try_enter".}
  ## Attempt to take ownership of a recursive mutex
  ##
  ## If the mutex wasn't owned or was owned by the caller, this will claim the mutex and return true.
  ## Otherwise (if the mutex was already owned by another owner) this will return false and the
  ## caller will NOT own the mutex.
  ##
  ## \param mtx Pointer to recursive mutex structure
  ## \param owner_out If mutex was already owned by another owner, and this pointer is non-zero,
  ##                  it will be filled in with the owner id of the current owner of the mutex
  ## \return true if the recursive mutex (now) owned, false otherwise

proc enterTimeoutMs*(mtx: ptr Mutex; timeoutMs: uint32): bool {.importc: "mutex_enter_timeout_ms".}
  ## Wait for mutex with timeout
  ##
  ## Wait for up to the specific time to take ownership of the mutex. If the caller
  ## can be granted ownership of the mutex before the timeout expires, then true will be returned
  ## and the caller will own the mutex, otherwise false will be returned and the caller will NOT own the mutex.
  ##
  ## \param mtx Pointer to mutex structure
  ## \param timeout_ms The timeout in milliseconds.
  ## \return true if mutex now owned, false if timeout occurred before ownership could be granted

proc enterTimeoutMs*(mtx: ptr RecursiveMutex; timeoutMs: uint32): bool {.importc: "recursive_mutex_enter_timeout_ms".}
  ## Wait for recursive mutex with timeout
  ##
  ## Wait for up to the specific time to take ownership of the recursive mutex. If the caller
  ## already has ownership of the mutex or can be granted ownership of the mutex before the timeout expires,
  ## then true will be returned and the caller will own the mutex, otherwise false will be returned and the caller
  ## will NOT own the mutex.
  ##
  ## \param mtx Pointer to recursive mutex structure
  ## \param timeout_ms The timeout in milliseconds.
  ## \return true if the recursive mutex (now) owned, false if timeout occurred before ownership could be granted

proc enterTimeoutUs*(mtx: ptr Mutex; timeoutUs: uint32): bool {.importc: "mutex_enter_timeout_us".}
  ## Wait for mutex with timeout
  ##
  ## Wait for up to the specific time to take ownership of the mutex. If the caller
  ## can be granted ownership of the mutex before the timeout expires, then true will be returned
  ## and the caller will own the mutex, otherwise false will be returned and the caller
  ## will NOT own the mutex.
  ##
  ## \param mtx Pointer to mutex structure
  ## \param timeout_us The timeout in microseconds.
  ## \return true if mutex now owned, false if timeout occurred before ownership could be granted

proc enterTimeoutUs*(mtx: ptr RecursiveMutex; timeoutUs: uint32): bool {.importc: "recursive_mutex_enter_timeout_us".}
  ## Wait for recursive mutex with timeout
  ##
  ## Wait for up to the specific time to take ownership of the recursive mutex. If the caller
  ## already has ownership of the mutex or can be granted ownership of the mutex before the timeout expires,
  ## then true will be returned and the caller will own the mutex, otherwise false will be returned and the caller
  ## will NOT own the mutex.
  ##
  ## \param mtx Pointer to mutex structure
  ## \param timeout_us The timeout in microseconds.
  ## \return true if the recursive mutex (now) owned, false if timeout occurred before ownership could be granted

proc enterBlockUntil*(mtx: ptr Mutex; until: AbsoluteTime): bool {.importc: "mutex_enter_block_until".}
  ## Wait for mutex until a specific time
  ##
  ## Wait until the specific time to take ownership of the mutex. If the caller
  ## can be granted ownership of the mutex before the timeout expires, then true will be returned
  ## and the caller will own the mutex, otherwise false will be returned and the caller
  ## will NOT own the mutex.
  ##
  ## \param mtx Pointer to mutex structure
  ## \param until The time after which to return if the caller cannot be granted ownership of the mutex
  ## \return true if mutex now owned, false if timeout occurred before ownership could be granted

proc enterBlockUntil*(mtx: ptr RecursiveMutex; until: AbsoluteTime): bool {.importc: "recursive_mutex_enter_block_until".}
  ## Wait for mutex until a specific time
  ##
  ## Wait until the specific time to take ownership of the mutex. If the caller
  ## already has ownership of the mutex or can be granted ownership of the mutex before the timeout expires,
  ## then true will be returned and the caller will own the mutex, otherwise false will be returned and the caller
  ## will NOT own the mutex.
  ##
  ## \param mtx Pointer to recursive mutex structure
  ## \param until The time after which to return if the caller cannot be granted ownership of the mutex
  ## \return true if the recursive mutex (now) owned, false if timeout occurred before ownership could be granted

proc exit*(mtx: ptr Mutex) {.importc: "mutex_exit".}
  ## Release ownership of a mutex
  ##
  ## \param mtx Pointer to mutex structure

proc exit*(mtx: ptr RecursiveMutex) {.importc: "recursive_mutex_exit".}
  ## Release ownership of a recursive mutex
  ##
  ## \param mtx Pointer to recursive mutex structure

proc isInitialized*(mtx: ptr Mutex): bool {.importc: "mutex_is_initialized".}
  ## Test for mutex initialized state
  ##
  ## \param mtx Pointer to mutex structure
  ## \return true if the mutex is initialized, false otherwise

proc isInitialized*(mtx: ptr RecursiveMutex): bool {.importc: "recursive_mutex_is_initialized".}
  ## Test for recursive mutex initialized state
  ##
  ## \param mtx Pointer to recursive mutex structure
  ## \return true if the recursive mutex is initialized, false otherwise

{.pop.}
