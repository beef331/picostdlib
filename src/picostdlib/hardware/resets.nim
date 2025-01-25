import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_resets/include".}
{.push header: "hardware/resets.h".}

let
  RESETS_RESET_USBCTRL_BITS* {.importc: "RESETS_RESET_USBCTRL_BITS".}: cuint
  RESETS_RESET_UART1_BITS* {.importc: "RESETS_RESET_UART1_BITS".}: cuint
  RESETS_RESET_UART0_BITS* {.importc: "RESETS_RESET_UART0_BITS".}: cuint
  RESETS_RESET_TIMER_BITS* {.importc: "RESETS_RESET_TIMER_BITS".}: cuint
  RESETS_RESET_TBMAN_BITS* {.importc: "RESETS_RESET_TBMAN_BITS".}: cuint
  RESETS_RESET_SYSINFO_BITS* {.importc: "RESETS_RESET_SYSINFO_BITS".}: cuint
  RESETS_RESET_SYSCFG_BITS* {.importc: "RESETS_RESET_SYSCFG_BITS".}: cuint
  RESETS_RESET_SPI1_BITS* {.importc: "RESETS_RESET_SPI1_BITS".}: cuint
  RESETS_RESET_SPI0_BITS* {.importc: "RESETS_RESET_SPI0_BITS".}: cuint
  RESETS_RESET_RTC_BITS* {.importc: "RESETS_RESET_RTC_BITS".}: cuint
  RESETS_RESET_PWM_BITS* {.importc: "RESETS_RESET_PWM_BITS".}: cuint
  RESETS_RESET_PLL_USB_BITS* {.importc: "RESETS_RESET_PLL_USB_BITS".}: cuint
  RESETS_RESET_PLL_SYS_BITS* {.importc: "RESETS_RESET_PLL_SYS_BITS".}: cuint
  RESETS_RESET_PIO1_BITS* {.importc: "RESETS_RESET_PIO1_BITS".}: cuint
  RESETS_RESET_PIO0_BITS* {.importc: "RESETS_RESET_PIO0_BITS".}: cuint
  RESETS_RESET_PADS_QSPI_BITS* {.importc: "RESETS_RESET_PADS_QSPI_BITS".}: cuint
  RESETS_RESET_PADS_BANK0_BITS* {.importc: "RESETS_RESET_PADS_BANK0_BITS".}: cuint
  RESETS_RESET_JTAG_BITS* {.importc: "RESETS_RESET_JTAG_BITS".}: cuint
  RESETS_RESET_IO_QSPI_BITS* {.importc: "RESETS_RESET_IO_QSPI_BITS".}: cuint
  RESETS_RESET_IO_BANK0_BITS* {.importc: "RESETS_RESET_IO_BANK0_BITS".}: cuint
  RESETS_RESET_I2C1_BITS* {.importc: "RESETS_RESET_I2C1_BITS".}: cuint
  RESETS_RESET_I2C0_BITS* {.importc: "RESETS_RESET_I2C0_BITS".}: cuint
  RESETS_RESET_DMA_BITS* {.importc: "RESETS_RESET_DMA_BITS".}: cuint
  RESETS_RESET_BUSCTRL_BITS* {.importc: "RESETS_RESET_BUSCTRL_BITS".}: cuint
  RESETS_RESET_ADC_BITS* {.importc: "RESETS_RESET_ADC_BITS".}: cuint

let
  RESET_ADC* {.importc: "RESET_ADC".}: cuint  # Select ADC to be reset
  RESET_BUSCTRL* {.importc: "RESET_BUSCTRL".}: cuint  # Select BUSCTRL to be reset
  RESET_DMA* {.importc: "RESET_DMA".}: cuint  # Select DMA to be reset
  RESET_I2C0* {.importc: "RESET_I2C0".}: cuint  # Select I2C0 to be reset
  RESET_I2C1* {.importc: "RESET_I2C1".}: cuint  # Select I2C1 to be reset
  RESET_IO_BANK0* {.importc: "RESET_IO_BANK0".}: cuint  # Select IO_BANK0 to be reset
  RESET_IO_QSPI* {.importc: "RESET_IO_QSPI".}: cuint  # Select IO_QSPI to be reset
  RESET_JTAG* {.importc: "RESET_JTAG".}: cuint  # Select JTAG to be reset
  RESET_PADS_BANK0* {.importc: "RESET_PADS_BANK0".}: cuint # Select PADS_BANK0 to be reset
  RESET_PADS_QSPI* {.importc: "RESET_PADS_QSPI".}: cuint  # Select PADS_QSPI to be reset
  RESET_PIO0* {.importc: "RESET_PIO0".}: cuint  # Select PIO0 to be reset
  RESET_PIO1* {.importc: "RESET_PIO1".}: cuint  # Select PIO1 to be reset
  RESET_PLL_SYS* {.importc: "RESET_PLL_SYS".}: cuint  # Select PLL_SYS to be reset
  RESET_PLL_USB* {.importc: "RESET_PLL_USB".}: cuint  # Select PLL_USB to be reset
  RESET_PWM* {.importc: "RESET_PWM".}: cuint  # Select PWM to be reset
  RESET_RTC* {.importc: "RESET_RTC".}: cuint  # Select RTC to be reset
  RESET_SPI0* {.importc: "RESET_SPI0".}: cuint  # Select SPI0 to be reset
  RESET_SPI1* {.importc: "RESET_SPI1".}: cuint  # Select SPI1 to be reset
  RESET_SYSCFG* {.importc: "RESET_SYSCFG".}: cuint  # Select SYSCFG to be reset
  RESET_SYSINFO* {.importc: "RESET_SYSINFO".}: cuint  # Select SYSINFO to be reset
  RESET_TBMAN* {.importc: "RESET_TBMAN".}: cuint  # Select TBMAN to be reset
  RESET_TIMER* {.importc: "RESET_TIMER".}: cuint  # Select TIMER to be reset
  RESET_UART0* {.importc: "RESET_UART0".}: cuint  # Select UART0 to be reset
  RESET_UART1* {.importc: "RESET_UART1".}: cuint  # Select UART1 to be reset
  RESET_USBCTRL* {.importc: "RESET_USBCTRL".}: cuint  # Select USBCTRL to be reset

  # rp2350 specific
  RESET_HSTX* {.importc: "RESET_HSTX".}: cuint  # Select HSTX to be reset
  RESET_PIO2* {.importc: "RESET_PIO2".}: cuint  # Select PIO2 to be reset
  RESET_SHA256* {.importc: "RESET_SHA256".}: cuint  # Select SHA256 to be reset
  RESET_TIMER0* {.importc: "RESET_TIMER0".}: cuint  # Select TIMER0 to be reset
  RESET_TIMER1* {.importc: "RESET_TIMER1".}: cuint  # Select TIMER1 to be reset
  RESET_TRNG* {.importc: "RESET_TRNG".}: cuint  # Select TRNG to be reset

proc resetBlockMask*(bits: uint32) {.importc: "reset_block_mask".}
  ## Reset the specified HW blocks
  ##
  ## \param bits Bit pattern indicating blocks to reset. See \ref reset_bitmask

proc unresetBlockMask*(bits: uint32) {.importc: "unreset_block_mask".}
  ## Bring specified HW blocks out of reset
  ##
  ## \param bits Bit pattern indicating blocks to unreset. See \ref reset_bitmask

proc unresetBlockMaskWaitBlocking*(bits: uint32) {.importc: "unreset_block_mask_wait_blocking".}
  ## Bring specified HW blocks out of reset and wait for completion
  ##
  ## \param bits Bit pattern indicating blocks to unreset. See \ref reset_bitmask

proc resetBlockNum*(blockNum: uint32) {.importc: "reset_block_num".}
  ## Reset the specified HW block
  ##
  ## \param block_num the block number

proc unresetBlockNum*(blockNum: cuint) {.importc: "unreset_block_num".}
  ## bring specified HW block out of reset
  ##
  ## \param block_num the block number

proc unresetBlockNumWaitBlocking*(blockNum: cuint) {.importc: "unreset_block_num_wait_blocking".}
  ## Bring specified HW block out of reset and wait for completion
  ##
  ## \param block_num the block number

proc resetUnresetBlockNumWaitBlocking*(blockNum: cuint) {.importc: "reset_unreset_block_num_wait_blocking".}
  ## Reset the specified HW block, and then bring at back out of reset and wait for completion
  ##
  ## \param block_num the block number

{.pop.}
