import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_claim/include".}
{.push header: "hardware/claim.h".}

type
  HwClaimToken* = distinct uint32

proc `==`*(a, b: HwClaimToken): bool {.borrow.}
proc `$`*(a: HwClaimToken): string {.borrow.}

proc hwClaimOrAssert*(bits: UncheckedArray[uint8], bitIndex: cuint, message: cstring) {.importc: "hw_claim_or_assert".}
  ## Atomically claim a resource, panicking if it is already in use
  ##
  ## The resource ownership is indicated by the bitIndex bit in an array of bits.
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **bits**        pointer to an array of bits (8 bits per byte)
  ## **bitIndex**    resource to claim (bit index into array of bits)
  ## **message**     string to display if the bit cannot be claimed; note this may have a single printf format "%d" for the bit
  ## =============  ======

proc hwClaimUnusedFromRange*(bits: UncheckedArray[uint8], required: bool, bitLsb: cuint, bitMsb: cuint, message: cstring): cint {.importc: "hw_claim_unused_from_range".}
  ## Atomically claim one resource out of a range of resources, optionally asserting if none are free
  ##
  ## The resource ownership is indicated by the bit_index bit in an array of bits.
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **bits**        pointer to an array of bits (8 bits per byte)
  ## **required**    true if this method should panic if the resource is not free
  ## **bitLsb**      the lower bound (inclusive) of the resource range to claim from
  ## **bitMsb**      the upper bound (inclusive) of the resource range to claim from
  ## **message**     string to display if the bit cannot be claimed
  ## =============  ======
  ##
  ## **returns** the bit index representing the claimed or -1 if none are available in the range, and required = false

proc hwIsClaimed*(bits: UncheckedArray[uint8], bitIndex: cuint): bool {.importc: "hw_is_claimed".}
  ## Determine if a resource is claimed at the time of the call
  ##
  ## The resource ownership is indicated by the bitIndex bit in an array of bits.
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **bits**        pointer to an array of bits (8 bits per byte)
  ## **bitIndex**    resource to check (bit index into array of bits)
  ## =============  ======
  ##
  ## **returns** true if the resource is claimed

proc hwClaimClear*(bits: UncheckedArray[uint8], bitIndex: cuint) {.importc: "hw_claim_clear".}
  ## Atomically unclaim a resource
  ##
  ## The resource ownership is indicated by the bitIndex bit in an array of bits.
  ##
  ## **Parameters:**
  ##
  ## =============  ======
  ## **bits**        pointer to an array of bits (8 bits per byte)
  ## **bitIndex**    resource to unclaim (bit index into array of bits)
  ## =============  ======

proc hwClaimLock*(): HwClaimToken {.importc: "hw_claim_lock".}
  ## Acquire the runtime mutual exclusion lock provided by the `hardware_claim` library
  ##
  ## This method is called automatically by the other `hw_claim_` methods, however it is provided as a convenience
  ## to code that might want to protect other hardware initialization code from concurrent use.
  ##
  ## hwClaimLock() uses a spin lock internally, so disables interrupts on the calling core, and will deadlock
  ## if the calling core already owns the lock.
  ##
  ## **returns** a token to pass to hw_claim_unlock()

proc hwClaimUnlock*(token: HwClaimToken) {.importc: "hw_claim_lock".}
  ## Release the runtime mutual exclusion lock provided by the `hardware_claim` library
  ##
  ## This method MUST be called from the same core that call hwClaimLock()
  ##
  ## **Parameters:**
  ##
  ## ==============  ======
  ## **token**        the token returned by the corresponding call to hwClaimLock()
  ## ==============  ======

{.pop.}
