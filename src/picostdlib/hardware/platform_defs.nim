import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/" & $picoPlatform & "/hardware_regs/include".}
{.push header: "hardware/platform_defs.h".}

const
  NUM_CORES* = 2'u
  NUM_DMA_CHANNELS* = 12'u
  NUM_DMA_TIMERS* = 4'u
  NUM_IRQS* = 32'u
  NUM_USER_IRQS* = 6'u
  NUM_PIOS* = 2'u
  NUM_PIO_STATE_MACHINES* = 4'u
  NUM_PWM_SLICES* = 8'u
  NUM_SPIN_LOCKS* = 32'u
  NUM_UARTS* = 2'u
  NUM_I2CS* = 2'u
  NUM_SPIS* = 2'u
  NUM_TIMERS* = 4'u
  NUM_ADC_CHANNELS* = 5'u

  NUM_BANK0_GPIOS* = 30'u
  NUM_QSPI_GPIOS* = 6'u

  PIO_INSTRUCTION_COUNT* = 32'u

let
  XOSC_HZ* {.importc: "XOSC_HZ".}: uint
  SYS_CLK_HZ* {.importc: "SYS_CLK_HZ".}: uint
  USB_CLK_HZ* {.importc: "USB_CLK_HZ".}: uint

const
  FIRST_USER_IRQ* = NUM_IRQS - NUM_USER_IRQS
  VTABLE_FIRST_IRQ* = 16

{.pop.}
