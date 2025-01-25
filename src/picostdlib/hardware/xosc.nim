import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_xosc/include".}
{.push header: "hardware/xosc.h".}

proc xoscInit*() {.importc: "xosc_init".}
  ## Initialise the crystal oscillator system
  ##
  ## This function will block until the crystal oscillator has stabilised.

proc xoscDisable*() {.importc: "xosc_disable".}
  ## Disable the Crystal oscillator
  ##
  ## Turns off the crystal oscillator source, and waits for it to become unstable

proc xoscDormant*() {.importc: "xosc_dormant".}
  ## Set the crystal oscillator system to dormant
  ##
  ## Turns off the crystal oscillator until it is woken by an interrupt. This will block and hence
  ## the entire system will stop, until an interrupt wakes it up. This function will
  ## continue to block until the oscillator becomes stable after its wakeup.

{.pop.}
