import ./base

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_interp/include".}
{.push header: "hardware/interp.h".}

type
  InterpHw* {.bycopy, importc: "interp_hw_t".} = object
    accum* {.importc.}: array[2, IoRw32]
    base* {.importc.}: array[3, IoRw32]
    pop* {.importc.}: array[3, IoRo32]
    peek* {.importc.}: array[3, IoRo32]
    ctrl* {.importc.}: array[2, IoRw32]
    addRaw* {.importc: "add_raw".}: array[2, IoRw32]
    base01* {.importc.}: IoWo32

  InterpConfig* {.bycopy, importc: "interp_config".} = object
    ctrl* {.importc.}: uint32

  InterpHwSave* {.bycopy, importc: "interp_hw_save_t".} = object
    accum* {.importc.}: array[2, IoRw32]
    base* {.importc.}: array[3, IoRw32]
    ctrl* {.importc.}: array[2, IoRw32]

  Lane* = distinct range[0.cuint .. 1.cuint]

proc `==`*(a, b: Lane): bool {.borrow.}
proc `$`*(p: Lane): string {.borrow.}


proc claimLane*(interp: ptr InterpHw; lane: Lane) {.importc: "interp_claim_lane".}
  ## Claim the interpolator lane specified
  ##
  ## Use this function to claim exclusive access to the specified interpolator lane.
  ##
  ## This function will panic if the lane is already claimed.
  ##
  ## \param interp Interpolator on which to claim a lane. interp0 or interp1
  ## \param lane The lane number, 0 or 1.

proc claimLaneMask*(interp: ptr InterpHw; laneMask: set[Lane]) {.importc: "interp_claim_lane_mask".}
  ## Claim the interpolator lanes specified in the mask
  ##
  ## \param interp Interpolator on which to claim lanes. interp0 or interp1
  ## \param lane_mask Bit pattern of lanes to claim (only bits 0 and 1 are valid)

proc unclaimLane*(interp: ptr InterpHw; lane: Lane) {.importc: "interp_unclaim_lane".}
  ## Release a previously claimed interpolator lane
  ##
  ## \param interp Interpolator on which to release a lane. interp0 or interp1
  ## \param lane The lane number, 0 or 1

proc laneIsClaimed*(interp: ptr InterpHw; lane: Lane): bool {.importc: "interp_lane_is_claimed".}
  ## Determine if an interpolator lane is claimed
  ##
  ## \param interp Interpolator whose lane to check
  ## \param lane The lane number, 0 or 1
  ## \return true if claimed, false otherwise
  ## \see interp_claim_lane
  ## \see interp_claim_lane_mask

proc unclaimLaneMask*(interp: ptr InterpHw; laneMask: set[Lane]) {.importc: "interp_unclaim_lane_mask".}
  ## Release previously claimed interpolator lanes \see interp_claim_lane_mask
  ##
  ## \param interp Interpolator on which to release lanes. interp0 or interp1
  ## \param lane_mask Bit pattern of lanes to unclaim (only bits 0 and 1 are valid)

proc setShift*(c: ptr InterpConfig; shift: cuint) {.importc: "interp_config_set_shift".}
  ## Set the interpolator shift value
  ##
  ## Sets the number of bits the accumulator is shifted before masking, on each iteration.
  ##
  ## \param c Pointer to an interpolator config
  ## \param shift Number of bits

proc setMask*(c: ptr InterpConfig; maskLsb: cuint; maskMsb: cuint) {.importc: "interp_config_set_mask".}
  ## Set the interpolator mask range
  ##
  ## Sets the range of bits (least to most) that are allowed to pass through the interpolator
  ##
  ## \param c Pointer to interpolation config
  ## \param mask_lsb The least significant bit allowed to pass
  ## \param mask_msb The most significant bit allowed to pass

proc setCrossInput*(c: ptr InterpConfig; crossInput: bool) {.importc: "interp_config_set_cross_input".}
  ## Enable cross input
  ##
  ##  Allows feeding of the accumulator content from the other lane back in to this lanes shift+mask hardware.
  ##  This will take effect even if the interp_config_set_add_raw option is set as the cross input mux is before the
  ##  shift+mask bypass
  ##
  ## \param c Pointer to interpolation config
  ## \param cross_input If true, enable the cross input.

proc setCrossResult*(c: ptr InterpConfig; crossResult: bool) {.importc: "interp_config_set_cross_result".}
  ## Enable cross results
  ##
  ##  Allows feeding of the other lane’s result into this lane’s accumulator on a POP operation.
  ##
  ## \param c Pointer to interpolation config
  ## \param cross_result If true, enables the cross result

proc setSigned*(c: ptr InterpConfig; signed: bool) {.importc: "interp_config_set_signed".}
  ## Set sign extension
  ##
  ## Enables signed mode, where the shifted and masked accumulator value is sign-extended to 32 bits
  ## before adding to BASE1, and LANE1 PEEK/POP results appear extended to 32 bits when read by processor.
  ##
  ## \param c Pointer to interpolation config
  ## \param  _signed If true, enables sign extension

proc setAddRaw*(c: ptr InterpConfig; addRaw: bool) {.importc: "interp_config_set_add_raw".}
  ## Set raw add option
  ##
  ## When enabled, mask + shift is bypassed for LANE0 result. This does not affect the FULL result.
  ##
  ## \param c Pointer to interpolation config
  ## \param add_raw If true, enable raw add option.

proc setBlend*(c: ptr InterpConfig; blend: bool) {.importc: "interp_config_set_blend".}
  ## Set blend mode
  ##
  ## If enabled, LANE1 result is a linear interpolation between BASE0 and BASE1, controlled
  ## by the 8 LSBs of lane 1 shift and mask value (a fractional number between 0 and 255/256ths)
  ##
  ## LANE0 result does not have BASE0 added (yields only the 8 LSBs of lane 1 shift+mask value)
  ##
  ## FULL result does not have lane 1 shift+mask value added (BASE2 + lane 0 shift+mask)
  ##
  ## LANE1 SIGNED flag controls whether the interpolation is signed or unsig
  ##
  ## \param c Pointer to interpolation config
  ## \param blend Set true to enable blend mode.

proc setClamp*(c: ptr InterpConfig; clamp: bool) {.importc: "interp_config_set_clamp".}
  ## Set interpolator clamp mode (Interpolator 1 only)
  ##
  ## Only present on INTERP1 on each core. If CLAMP mode is enabled:
  ## - LANE0 result is a shifted and masked ACCUM0, clamped by a lower bound of BASE0 and an upper bound of BASE1.
  ## - Signedness of these comparisons is determined by LANE0_CTRL_SIGNED
  ##
  ## \param c Pointer to interpolation config
  ## \param clamp Set true to enable clamp mode

proc setForceBits*(c: ptr InterpConfig; bits: cuint) {.importc: "interp_config_set_force_bits".}
  ## Set interpolator Force bits
  ##
  ## ORed into bits 29:28 of the lane result presented to the processor on the bus.
  ##
  ## No effect on the internal 32-bit datapath. Handy for using a lane to generate sequence
  ## of pointers into flash or SRAM
  ##
  ## \param c Pointer to interpolation config
  ## \param bits Sets the force bits to that specified. Range 0-3 (two bits)

proc interpDefaultConfig*(): InterpConfig {.importc: "interp_default_config".}
  ## Get a default configuration
  ##
  ## \return A default interpolation configuration

proc setConfig*(interp: ptr InterpHw; lane: Lane; config: ptr InterpConfig) {.importc: "interp_set_config".}
  ## Send configuration to a lane
  ##
  ## If an invalid configuration is specified (ie a lane specific item is set on wrong lane),
  ## depending on setup this function can panic.
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane to set
  ## \param config Pointer to interpolation config

proc setForceBits*(interp: ptr InterpHw; lane: Lane; bits: cuint) {.importc: "interp_set_force_bits".}
  ## Directly set the force bits on a specified lane
  ##
  ## These bits are ORed into bits 29:28 of the lane result presented to the processor on the bus.
  ## There is no effect on the internal 32-bit datapath.
  ##
  ## Useful for using a lane to generate sequence of pointers into flash or SRAM, saving a subsequent
  ## OR or add operation.
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane to set
  ## \param bits The bits to set (bits 0 and 1, value range 0-3)

proc save*(interp: ptr InterpHw; saver: ptr InterpHwSave) {.importc: "interp_save".}
  ## Save the specified interpolator state
  ##
  ## Can be used to save state if you need an interpolator for another purpose, state
  ## can then be recovered afterwards and continue from that point
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param saver Pointer to the save structure to fill in

proc restore*(interp: ptr InterpHw; saver: ptr InterpHwSave) {.importc: "interp_restore".}
  ## Restore an interpolator state
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param saver Pointer to save structure to reapply to the specified interpolator

proc setBase*(interp: ptr InterpHw; lane: Lane; val: uint32) {.importc: "interp_set_base".}
  ## Sets the interpolator base register by lane
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1 or 2
  ## \param val The value to apply to the register

proc getBase*(interp: ptr InterpHw; lane: Lane): uint32 {.importc: "interp_get_base".}
  ## Gets the content of interpolator base register by lane
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1 or 2
  ## \return  The current content of the lane base register

proc setBaseBoth*(interp: ptr InterpHw; val: uint32) {.importc: "interp_set_base_both".}
  ## Sets the interpolator base registers simultaneously
  ##
  ##  The lower 16 bits go to BASE0, upper bits to BASE1 simultaneously.
  ##  Each half is sign-extended to 32 bits if that lane’s SIGNED flag is set.
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param val The value to apply to the register

proc setAccumulator*(interp: ptr InterpHw; lane: Lane; val: uint32) {.importc: "interp_set_accumulator".}
  ## Sets the interpolator accumulator register by lane
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \param val The value to apply to the register

proc getAccumulator*(interp: ptr InterpHw; lane: Lane): uint32 {.importc: "interp_get_accumulator".}
  ## Gets the content of the interpolator accumulator register by lane
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \return The current content of the register

proc popLaneResult*(interp: ptr InterpHw; lane: Lane): uint32 {.importc: "interp_pop_lane_result".}
  ## Read lane result, and write lane results to both accumulators to update the interpolator
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \return The content of the lane result register

proc peekLaneResult*(interp: ptr InterpHw; lane: Lane): uint32 {.importc: "interp_peek_lane_result".}
  ## Read lane result
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \return The content of the lane result register

proc popFullResult*(interp: ptr InterpHw): uint32 {.importc: "interp_pop_full_result".}
  ## Read lane result, and write lane results to both accumulators to update the interpolator
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \return The content of the FULL register

proc peekFullResult*(interp: ptr InterpHw): uint32 {.importc: "interp_peek_full_result".}
  ## Read lane result
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \return The content of the FULL register

proc addAccumulator*(interp: ptr InterpHw; lane: Lane; val: uint32) {.importc: "interp_add_accumulater".}
  ## Add to accumulator
  ##
  ## Atomically add the specified value to the accumulator on the specified lane
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \param val Value to add

proc getRaw*(interp: ptr InterpHw; lane: Lane): uint32 {.importc: "interp_get_raw".}
  ## Get raw lane value
  ##
  ## Returns the raw shift and mask value from the specified lane, BASE0 is NOT added
  ##
  ## \param interp Interpolator instance, interp0 or interp1.
  ## \param lane The lane number, 0 or 1
  ## \return The raw shift/mask value

{.pop.}
