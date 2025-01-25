import ../base
export base

import ../../helpers

{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_structs/include".}
{.push header: "hardware/structs/scb.h".}

when picoRp2040:
  type
    Armv6mScbHw* {.importc: "armv6m_scb_hw_t".} = object
      cpuid*: IoRo32
      icsr*: IoRw32
      vtor*: IoRw32
      aircr*: IoRw32
      scr*: IoRw32

  let scbHw* {.importc: "scb_hw".}: ptr Armv6mScbHw

else:
  type
    Armv8mScbHw* {.importc: "armv8m_scb_hw_t".} = object
      cpuid*: IoRo32
      icsr*: IoRw32
      vtor*: IoRw32
      aircr*: IoRw32
      scr*: IoRw32

  let scbHw* {.importc: "scb_hw".}: ptr Armv8mScbHw
  let scbNsHw* {.importc: "scb_ns_hw".}: ptr Armv8mScbHw

{.pop.}
