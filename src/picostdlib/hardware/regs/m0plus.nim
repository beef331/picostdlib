import ../../helpers
{.passC: "-I" & picoSdkPath & "/src/rp2040/hardware_regs/include".}
{.push header: "hardware/regs/m0plus.h".}

let
  M0PLUS_SCR_SLEEPDEEP_BITS* {.importc: "M0PLUS_SCR_SLEEPDEEP_BITS".}: uint32

{.pop.}
