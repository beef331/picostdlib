import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_divider/include".}
{.push header: "hardware/divider.h".}

type
  HwDivmodResult* = uint64
  HwDividerState* = array[4, uint32]


proc hwDividerDivmodS32Start*(a, b: int32) {.importc: "hw_divider_divmod_s32_start".}
  ## Start a signed asynchronous divide
  ##
  ## Start a divide of the specified signed parameters. You should wait for 8 cycles (__div_pause()) or wait for the ready bit to be set
  ## (hwDividerWaitReady()) prior to reading the results.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======

proc hwDividerDivmodU32Start*(a, b: uint32) {.importc: "hw_divider_divmod_u32_start".}
  ## Start a unsigned asynchronous divide
  ##
  ## Start a divide of the specified signed parameters. You should wait for 8 cycles (__div_pause()) or wait for the ready bit to be set
  ## (hwDividerWaitReady()) prior to reading the results.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======

proc hwDividerWaitReady*() {.importc: "hw_divider_wait_ready".}
  ## Wait for a divide to complete

proc hwDividerResultNowait*(): HwDivmodResult {.importc: "hw_divider_result_nowait".}
  ## Return result of HW divide, nowait
  ##
  ## This is UNSAFE in that the calculation may not have been completed.
  ##
  ## **returns** Current result. Most significant 32 bits are the remainder, lower 32 bits are the quotient.

proc hwDividerResultWait*(): HwDivmodResult {.importc: "hw_divider_result_wait".}
  ## Return result of last asynchronous HW divide
  ##
  ## This function waits for the result to be ready by calling hwDividerWaitReady().
  ##
  ## **returns** Current result. Most significant 32 bits are the remainder, lower 32 bits are the quotient.

proc hwDividerU32QuotientWait*(): uint32 {.importc: "hw_divider_u32_quotient_wait".}
  ## Return result of last asynchronous HW divide, unsigned quotient only
  ##
  ## This function waits for the result to be ready by calling hwDividerWaitReady().
  ##
  ## **returns** Current unsigned quotient result.

proc hwDividerS32QuotientWait*(): uint32 {.importc: "hw_divider_s32_quotient_wait".}
  ## Return result of last asynchronous HW divide, signed quotient only
  ##
  ## This function waits for the result to be ready by calling hwDividerWaitReady().
  ##
  ## **returns** Current signed quotient result.

proc hwDividerU32RemainderWait*(): uint32 {.importc: "hw_divider_u32_remainder_wait".}
  ## Return result of last asynchronous HW divide, unsigned remainder only
  ##
  ## This function waits for the result to be ready by calling hwDividerWaitReady().
  ##
  ## **returns** Current unsigned remainder result.

proc hwDividerS32RemainderWait*(): uint32 {.importc: "hw_divider_s32_remainder_wait".}
  ## Return result of last asynchronous HW divide, signed remainder only
  ##
  ## This function waits for the result to be ready by calling hwDividerWaitReady().
  ##
  ## **returns** Current remainder results.

proc hwDividerDivmodS32*(a, b: int32): HwDivmodResult {.importc: "hw_divider_divmod_s32".}
  ## Do a signed HW divide and wait for result
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return result as a fixed point 32p32 value.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Results of divide as a 32p32 fixed point value.

proc hwDividerDivmodU32*(a, b: uint32): HwDivmodResult {.importc: "hw_divider_divmod_u32".}
  ## Do an unsigned HW divide and wait for result
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return result as a fixed point 32p32 value.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Results of divide as a 32p32 fixed point value.

proc toQuotientU32*(r: HwDivmodResult): uint32 {.importc: "to_quotient_u32".}
  ## Efficient extraction of unsigned quotient from 32p32 fixed point
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **r**    32p32 fixed point value.
  ## ======  ======
  ##
  ## **returns** Unsigned quotient

proc toQuotientS32*(r: HwDivmodResult): int32 {.importc: "to_quotient_s32".}
  ## Efficient extraction of signed quotient from 32p32 fixed point
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **r**    32p32 fixed point value.
  ## ======  ======
  ##
  ## **returns** Signed quotient

proc toRemainderU32*(r: HwDivmodResult): uint32 {.importc: "to_remainder_u32".}
  ## Efficient extraction of unsigned remainder from 32p32 fixed point
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **r**    32p32 fixed point value.
  ## ======  ======
  ##
  ## **returns** Unsigned remainder
  ##
  ## **note** On Arm this is just a 32 bit register move or a nop

proc toRemainderS32*(r: HwDivmodResult): int32 {.importc: "to_remainder_s32".}
  ## Efficient extraction of signed remainder from 32p32 fixed point
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **r**    32p32 fixed point value.
  ## ======  ======
  ##
  ## **returns** Signed remainder
  ##
  ## **note** On Arm this is just a 32 bit register move or a nop

proc hwDividerU32Quotient*(a, b: uint32): uint32 {.importc: "hw_divider_u32_quotient".}
  ## Do an unsigned HW divide, wait for result, return quotient
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Quotient results of the divide

proc hwDividerU32Remainder*(a, b: uint32): uint32 {.importc: "hw_divider_u32_remainder".}
  ## Do an unsigned HW divide, wait for result, return remainder
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return remainder.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Remainder results of the divide

proc hwDividerS32Quotient*(a, b: int32): int32 {.importc: "hw_divider_s32_quotient".}
  ## Do a signed HW divide, wait for result, return quotient
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Quotient results of the divide

proc hwDividerS32Remainder*(a, b: int32): int32 {.importc: "hw_divider_s32_remainder".}
  ## Do a signed HW divide, wait for result, return remainder
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return remainder.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Remainder results of the divide

proc hwDividerPause*() {.importc: "hw_divider_pause".}
  ## Pause for exact amount of time needed for a asynchronous divide to complete

proc hwDividerU32QuotientInlined*(a, b: uint32): uint32 {.importc: "hw_divider_u32_quotient_inlined".}
  ## Do a hardware unsigned HW divide, wait for result, return quotient
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Quotient results of the divide

proc hwDividerU32RemainderInlined*(a, b: uint32): uint32 {.importc: "hw_divider_u32_remainder_inlined".}
  ## Do a hardware unsigned HW divide, wait for result, return remainder
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Remainder result of the divide

proc hwDividerS32QuotientInlined*(a, b: int32): int32 {.importc: "hw_divider_s32_quotient_inlined".}
  ## Do a hardware signed HW divide, wait for result, return quotient
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Quotient results of the divide

proc hwDividerS32RemainderInlined*(a, b: int32): int32 {.importc: "hw_divider_s32_remainder_inlined".}
  ## Do a hardware signed HW divide, wait for result, return remainder
  ##
  ## Divide `a` by `b`, wait for calculation to complete, return quotient.
  ##
  ## **Parameters:**
  ##
  ## ======  ======
  ## **a**    The dividend
  ## **b**    The divisor
  ## ======  ======
  ##
  ## **returns** Remainder result of the divide

proc hwDividerSaveState*(dest: ptr HwDividerState) {.importc: "hw_divider_save_state".}
  ## Save the calling cores hardware divider state
  ##
  ## Copy the current core's hardware divider state into the provided structure. This method
  ## waits for the divider results to be stable, then copies them to memory.
  ## They can be restored via hwDividerRestoreState()
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **dest**    the location to store the divider state
  ## =========  ======

proc hwDividerRestoreState*(src: ptr HwDividerState) {.importc: "hw_divider_restore_state".}
  ## Load a saved hardware divider state into the current core's hardware divider
  ##
  ## Copy the passed hardware divider state into the hardware divider.
  ##
  ## **Parameters:**
  ##
  ## ========  ======
  ## **src**    the location to load the divider state from
  ## ========  ======

{.pop.}
