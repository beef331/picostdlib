import ./sync
export sync

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_multicore/include".}
{.push header: "pico/multicore.h".}

type
  MulticoreEntryPoint* = proc() {.cdecl.}

proc multicoreResetCore1*() {.importc: "multicore_reset_core1".}
  ## Reset core 1
  ##
  ## This function can be used to reset core 1 into its initial state (ready for launching code against via \ref multicore_launch_core1 and similar methods)
  ##
  ## \note this function should only be called from core 0

proc multicoreLaunchCore1*(entry: MulticoreEntryPoint) {.importc: "multicore_launch_core1".}
  ## Run code on core 1
  ##
  ## Wake up (a previously reset) core 1 and enter the given function on core 1 using the default core 1 stack (below core 0 stack).
  ##
  ## core 1 must previously have been reset either as a result of a system reset or by calling \ref multicore_reset_core1
  ##
  ## core 1 will use the same vector table as core 0
  ##
  ## \param entry Function entry point
  ## \see multicore_reset_core1

proc multicoreLaunchCore1WithStack*(entry: MulticoreEntryPoint; stackBottom: ptr uint32; stackSizeBytes: csize_t) {.importc: "multicore_launch_core1_with_stack".}
  ## Launch code on core 1 with stack
  ##
  ## Wake up (a previously reset) core 1 and enter the given function on core 1 using the passed stack for core 1
  ##
  ## core 1 must previously have been reset either as a result of a system reset or by calling \ref multicore_reset_core1
  ##
  ## core 1 will use the same vector table as core 0
  ##
  ## \param entry Function entry point
  ## \param stack_bottom The bottom (lowest address) of the stack
  ## \param stack_size_bytes The size of the stack in bytes (must be a multiple of 4)
  ## \see multicore_reset_core1

proc multicoreLaunchCore1Raw*(entry: MulticoreEntryPoint; sp: ptr uint32; vectorTable: uint32) {.importc: "multicore_launch_core1_raw".}
  ## Launch code on core 1 with no stack protection
  ##
  ## Wake up (a previously reset) core 1 and start it executing with a specific entry point, stack pointer
  ## and vector table.
  ##
  ## This is a low level function that does not provide a stack guard even if USE_STACK_GUARDS is defined
  ##
  ## core 1 must previously have been reset either as a result of a system reset or by calling \ref multicore_reset_core1
  ##
  ## \param entry Function entry point
  ## \param sp Pointer to the top of the core 1 stack
  ## \param vector_table address of the vector table to use for core 1
  ## \see multicore_reset_core1

## \defgroup multicore_fifo fifo
## Functions for the inter-core FIFOs
##
## The RP2040 contains two FIFOs for passing data, messages or ordered events between the two cores. Each FIFO is 32 bits
## wide, and 8 entries deep. One of the FIFOs can only be written by core 0, and read by core 1. The other can only be written
## by core 1, and read by core 0.
##
## \note The inter-core FIFOs are a very precious resource and are frequently used for SDK functionality (e.g. during
## core 1 launch or by the \ref multicore_lockout functions). Additionally they are often required for the exclusive use
## of an RTOS (e.g. FreeRTOS SMP). For these reasons it is suggested that you do not use the FIFO for your own purposes
## unless none of the above concerns apply; the majority of cases for transferring data between cores can be eqaully
## well handled  by using a \ref queue

proc multicoreFifoRvalid*(): bool {.importc: "multicore_fifo_rvalid".}
  ## Check the read FIFO to see if there is data available (sent by the other core)
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## \return true if the FIFO has data in it, false otherwise

proc multicoreFifoWready*(): bool {.importc: "multicore_fifo_wready".}
  ## Check the write FIFO to see if it has space for more data
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## @return true if the FIFO has room for more data, false otherwise

proc multicoreFifoPushBlocking*(data: uint32) {.importc: "multicore_fifo_push_blocking".}
  ## Push data on to the write FIFO (data to the other core).
  ##
  ## This function will block until there is space for the data to be sent.
  ## Use multicore_fifo_wready() to check if it is possible to write to the
  ## FIFO if you don't want to block.
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## \param data A 32 bit value to push on to the FIFO

proc multicoreFifoPushTimeoutUs*(data: uint32; timeoutUs: uint64): bool {.importc: "multicore_fifo_push_timeout_us".}
  ## Push data on to the write FIFO (data to the other core) with timeout.
  ##
  ## This function will block until there is space for the data to be sent
  ## or the timeout is reached
  ##
  ## \param data A 32 bit value to push on to the FIFO
  ## \param timeout_us the timeout in microseconds
  ## \return true if the data was pushed, false if the timeout occurred before data could be pushed

proc multicoreFifoPopBlocking*(): uint32 {.importc: "multicore_fifo_pop_blocking".}
  ## Pop data from the read FIFO (data from the other core).
  ##
  ## This function will block until there is data ready to be read
  ## Use multicore_fifo_rvalid() to check if data is ready to be read if you don't
  ## want to block.
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## \return 32 bit data from the read FIFO.

proc multicoreFifoPopTimeoutUs*(timeoutUs: uint64; `out`: ptr uint32): bool {.importc: "multicore_fifo_pop_timeout_us".}
  ## Pop data from the read FIFO (data from the other core) with timeout.
  ##
  ## This function will block until there is data ready to be read or the timeout is reached
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## \param timeout_us the timeout in microseconds
  ## \param out the location to store the popped data if available
  ## \return true if the data was popped and a value copied into `out`, false if the timeout occurred before data could be popped

proc multicoreFifoDrain*() {.importc: "multicore_fifo_drain".}
  ## Discard any data in the read FIFO
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs

proc multicoreFifoClearIrq*() {.importc: "multicore_fifo_clear_irq".}
  ## Clear FIFO interrupt
  ##
  ## Note that this only clears an interrupt that was caused by the ROE or WOF flags.
  ## To clear the VLD flag you need to use one of the 'pop' or 'drain' functions.
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs
  ##
  ## \see multicore_fifo_get_status

proc multicoreFifoGetStatus*(): uint32 {.importc: "multicore_fifo_get_status".}
  ## Get FIFO statuses
  ##
  ## \return The statuses as a bitfield
  ##
  ## Bit | Description
  ## ----|------------
  ## 3 | Sticky flag indicating the RX FIFO was read when empty (ROE). This read was ignored by the FIFO.
  ## 2 | Sticky flag indicating the TX FIFO was written when full (WOF). This write was ignored by the FIFO.
  ## 1 | Value is 1 if this core’s TX FIFO is not full (i.e. if FIFO_WR is ready for more data)
  ## 0 | Value is 1 if this core’s RX FIFO is not empty (i.e. if FIFO_RD is valid)
  ##
  ## See the note in the \ref multicore_fifo section for considerations regarding use of the inter-core FIFOs

## \defgroup multicore_lockout lockout
## Functions to enable one core to force the other core to pause execution in a known state.
##
## Sometimes it is useful to enter a critical section on both cores at once. On a single
## core system a critical section can trivially be entered by disabling interrupts, however on a multi-core
## system that is not sufficient, and unless the other core is polling in some way, then it will need to be interrupted
## in order to cooperatively enter a blocked state.
##
## These "lockout" functions use the inter core FIFOs to cause an interrupt on one core from the other, and manage
## waiting for the other core to enter the "locked out" state.
##
## The usage is that the "victim" core ... i.e the core that can be "locked out" by the other core calls
## \ref multicore_lockout_victim_init to hook the FIFO interrupt. Note that either or both cores may do this.
##
## \note When "locked out" the victim core is paused (it is actually executing a tight loop with code in RAM) and has interrupts disabled.
## This makes the lockout functions suitable for use by code that wants to write to flash (at which point no code may be executing
## from flash)
##
## The core which wishes to lockout the other core calls \ref multicore_lockout_start_blocking or
## \ref multicore_lockout_start_timeout_us to interrupt the other "victim" core and wait for it to be in a
## "locked out" state. Once the lockout is no longer needed it calls \ref multicore_lockout_end_blocking or
## \ref multicore_lockout_end_timeout_us to release the lockout and wait for confirmation.
##
## \note Because multicore lockout uses the intercore FIFOs, the FIFOs <b>cannot</b> be used for any other purpose

proc multicoreLockoutVictimInit*() {.importc: "multicore_lockout_victim_init".}
  ## Initialize the current core such that it can be a "victim" of lockout (i.e. forced to pause in a known state by the other core)
  ##
  ## This code hooks the intercore FIFO IRQ, and the FIFO may not be used for any other purpose after this.

proc multicoreLockoutVictimIsInitialized*(coreNum: cuint): bool {.importc: "multicore_lockout_victim_is_initialized".}
  ## Determine if \ref multicore_victim_init() has been called on the specified core.
  ##
  ## \note this state persists even if the core is subsequently reset; therefore you are advised to
  ## always call \ref multicore_lockout_victim_init() again after resetting a core, which had previously
  ## been initialized.
  ##
  ## \param core_num the core number (0 or 1)
  ## \return true if \ref multicore_victim_init() has been called on the specified core, false otherwise.

proc multicoreLockoutStartBlocking*() {.importc: "multicore_lockout_start_blocking".}
  ## Request the other core to pause in a known state and wait for it to do so
  ##
  ## The other (victim) core must have previously executed \ref multicore_lockout_victim_init()
  ##
  ## \note multicore_lockout_start_ functions are not nestable, and must be paired with a call to a corresponding
  ## \ref multicore_lockout_end_blocking

proc multicoreLockoutStartTimeoutUs*(timeoutUs: uint64): bool {.importc: "multicore_lockout_start_timeout_us".}
  ## Request the other core to pause in a known state and wait up to a time limit for it to do so
  ##
  ## The other core must have previously executed \ref multicore_lockout_victim_init()
  ##
  ## \note multicore_lockout_start_ functions are not nestable, and must be paired with a call to a corresponding
  ## \ref multicore_lockout_end_blocking
  ##
  ## \param timeout_us the timeout in microseconds
  ## \return true if the other core entered the locked out state within the timeout, false otherwise

proc multicoreLockoutEndBlocking*() {.importc: "multicore_lockout_end_blocking".}
  ## Release the other core from a locked out state amd wait for it to acknowledge
  ##
  ## \note The other core must previously have been "locked out" by calling a multicore_lockout_start_ function
  ## from this core

proc multicoreLockoutEndTimeoutUs*(timeoutUs: uint64): bool {.importc: "multicore_lockout_end_timeout_us".}
  ## Release the other core from a locked out state amd wait up to a time limit for it to acknowledge
  ##
  ## The other core must previously have been "locked out" by calling a `multicore_lockout_start_` function
  ## from this core
  ##
  ## \note be very careful using small timeout values, as a timeout here will leave the "lockout" functionality
  ## in a bad state. It is probably preferable to use \ref multicore_lockout_end_blocking anyway as if you have
  ## already waited for the victim core to enter the lockout state, then the victim core will be ready to exit
  ## the lockout state very quickly.
  ##
  ## \param timeout_us the timeout in microseconds
  ## \return true if the other core successfully exited locked out state within the timeout, false otherwise

{.pop.}
