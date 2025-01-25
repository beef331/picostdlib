import ../hardware/sync
export sync

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_sync/include".}
{.push header: "pico/lock_core.h".}

type
  LockOwnerId* {.importc: "lock_owner_id_t".} = int8

  LockCore* {.bycopy, importc: "lock_core_t".} = object
    ## Base implementation for locking primitives protected by a spin lock. The spin lock is only used to protect
    ## access to the remaining lock state (in primitives using lock_core); it is never left locked outside
    ## of the function implementations
    spin_lock* {.importc: "spin_lock".}: ptr SpinLock
      ## spin lock protecting this lock's state

proc init*(core: ptr LockCore; lockNum: cuint) {.importc: "lock_init".}
  ## Initialise a lock structure
  ##
  ## Inititalize a lock structure, providing the spin lock number to use for protecting internal state.
  ##
  ## \param core Pointer to the lock_core to initialize
  ## \param lock_num Spin lock number to use for the lock. As the spin lock is only used internally to the locking primitive
  ##                 method implementations, this does not need to be globally unique, however could suffer contention

{.pop.}
