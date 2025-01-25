import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_base/include".}
{.push header: "hardware/address_mapped.h".}

type
  IoRw32* {.importc: "io_rw_32".} = uint32
  IoRo32* {.importc: "io_ro_32".} = uint32
  IoWo32* {.importc: "io_wo_32".} = uint32
  IoRw16* {.importc: "io_rw_16".} = uint16
  IoRo16* {.importc: "io_ro_16".} = uint16
  IoWo16* {.importc: "io_wo_16".} = uint16
  IoRw8* {.importc: "io_rw_8".} = uint8
  IoRo8* {.importc: "io_ro_8".} = uint8
  IoWo8* {.importc: "io_wo_8".} = uint8

proc hwSetBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_set_bits".}
  ## Atomically set the specified bits to 1 in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to set
  ## =========  ======

proc hwClearBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_clear_bits".}
  ## Atomically clear the specified bits to 0 in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to clear
  ## =========  ======

proc hwXorBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_xor_bits".}
  ## Atomically flip the specified bits in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to invert
  ## =========  ======

proc hwWriteMasked*(`addr`: ptr IoRw32, values: uint32, writeMask: uint32) {.importc: "hw_write_masked".}
  ## Set new values for a sub-set of the bits in a HW register
  ##
  ## Sets destination bits to values specified in `values`, if and only if corresponding bit in `writeMask` is set
  ##
  ## Note: this method allows safe concurrent modification of *different* bits of
  ## a register, but multiple concurrent access to the same bits is still unsafe.
  ##
  ## **Parameters:**
  ##
  ## ==============  ======
  ## **addr**         Address of writable register
  ## **values**       Bits values
  ## **writeMask**    Mask of bits to change
  ## ==============  ======

{.pop.}
