import ../hardware/sync
export sync

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_sync/include".}
{.push header: "pico/critical_section.h".}

type
  CriticalSection* {.importc: "critical_section_t".} = object
    spinLock* {.importc: "spin_lock".}: ptr SpinLock
    save* {.importc: "save".}: uint32

proc init*(critSec: ptr CriticalSection) {.importc: "critical_section_init".}
  ## Initialise a critical_section structure allowing the system to assign a spin lock number
  ##
  ## The critical section is initialized ready for use, and will use a (possibly shared) spin lock
  ## number assigned by the system. Note that in general it is unlikely that you would be nesting
  ## critical sections, however if you do so youmust* use \ref critical_section_init_with_lock_num
  ## to ensure that the spin locks used are different.
  ##
  ## \param crit_sec Pointer to critical_section structure

proc initWithLockNum*(critSec: ptr CriticalSection; lockNum: LockNum) {.importc: "critical_section_init_with_lock_num".}
  ## Initialise a critical_section structure assigning a specific spin lock number
  ##
  ## \param crit_sec Pointer to critical_section structure
  ## \param lock_num the specific spin lock number to use

proc enterBlocking*(critSec: ptr CriticalSection) {.importc: "critical_section_enter_blocking".}
  ## Enter a critical_section
  ##
  ## If the spin lock associated with this critical section is in use, then this
  ## method will block until it is released.
  ##
  ## \param crit_sec Pointer to critical_section structure

proc exit*(critSec: ptr CriticalSection) {.importc: "critical_section_exit".}
  ## Release a critical_section
  ##
  ## \param crit_sec Pointer to critical_section structure

proc deinit*(critSec: ptr CriticalSection) {.importc: "critical_section_deinit".}
  ## De-Initialise a critical_section created by the critical_section_init method
  ##
  ## This method is only used to free the associated spin lock allocated via
  ## the critical_section_init method (it should not be used to de-initialize a spin lock
  ## created via critical_section_init_with_lock_num). After this call, the critical section is invalid
  ##
  ## \param crit_sec Pointer to critical_section structure

{.pop.}
