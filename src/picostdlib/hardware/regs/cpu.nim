import ../../helpers
{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_regs/include".}

when picoPlatform == PlatformRp2040:
  const header = "hardware/regs/m0plus.h"
  const prefix = "M0PLUS_"

elif picoPlatform == PlatformRp2350_ArmS:
  const header = "hardware/regs/m33.h"
  const prefix = "M33_"
else:
  {.error: "unknown cpu platform " & $picoPlatform.}

{.push header: header.}

let
  SCR_SLEEPDEEP_BITS* {.importc: $prefix & "SCR_SLEEPDEEP_BITS".}: uint32

{.pop.}
