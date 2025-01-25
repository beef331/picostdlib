import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_bit_ops/include".}
{.push header: "pico/bit_ops.h".}

proc rev*(bits: uint32): uint32 {.importc: "__rev".}
  ## Reverse the bits in a 32 bit word
  ##
  ## \param bits 32 bit input
  ## \return the 32 input bits reversed

proc revll*(bits: uint64): uint64 {.importc: "__revll".}
  ## Reverse the bits in a 64 bit double word
  ##
  ## \param bits 64 bit input
  ## \return the 64 input bits reversed

{.pop.}
