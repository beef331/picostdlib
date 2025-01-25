import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_rand/include".}
{.push header: "pico/rand.h".}

type
  Rng128* {.importc: "rng_128_t".} = object
    ## We provide a maximum of 128 bits entropy in one go
    r* {.importc: "r".}: array[2, uint64]

proc getRand128*(rand128: var Rng128) {.importc: "get_rand_128".}
  ## Get 128-bit random number
  ##
  ## This method may be safely called from either core or from an IRQ, but be careful in the latter case as
  ## the call may block for a number of microseconds waiting on more entropy.
  ##
  ## \param rand128 Pointer to storage to accept a 128-bit random number

proc getRand64*(): uint64 {.importc: "get_rand_64".}
  ## Get 64-bit random number
  ##
  ## This method may be safely called from either core or from an IRQ, but be careful in the latter case as
  ## the call may block for a number of microseconds waiting on more entropy.
  ##
  ## \return 64-bit random number

proc getRand32*(): uint32 {.importc: "get_rand_32".}
  ## Get 32-bit random number
  ##
  ## This method may be safely called from either core or from an IRQ, but be careful in the latter case as
  ## the call may block for a number of microseconds waiting on more entropy.
  ##
  ## \return 32-bit random number

{.pop.}
