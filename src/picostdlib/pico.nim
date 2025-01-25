import ./pico/version
import ./pico/platform
import ./hardware/gpio
export version, platform, gpio

when defined(picoCyw43Supported):
  import ./pico/cyw43_arch
  export cyw43_arch

import ./helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_base_headers/include".}
{.push header: "pico.h".}

# Led
when not defined(picoCyw43Supported):
  let DefaultLedPin* {.importc: "PICO_DEFAULT_LED_PIN".}: Gpio
else:
  let DefaultLedPin* {.importc: "CYW43_WL_GPIO_LED_PIN".}: Cyw43WlGpio

let
  # Uart
  DefaultUart* {.importc: "PICO_DEFAULT_UART".}: cuint
  DefaultUartTxPin* {.importc: "PICO_DEFAULT_UART_TX_PIN".}: Gpio
  DefaultUartRxPin* {.importc: "PICO_DEFAULT_UART_RX_PIN".}: Gpio

  # Neopixel
  DefaultWs2812Pin* {.importc: "PICO_DEFAULT_WS2812_PIN".}: Gpio

  # I2c
  DefaultI2c* {.importc: "PICO_DEFAULT_I2C".}: cuint
  DefaultI2cSdaPin* {.importc: "PICO_DEFAULT_I2C_SDA_PIN".}: Gpio
  DefaultI2cSclPin* {.importc: "PICO_DEFAULT_I2C_SCL_PIN".}: Gpio

  # Spi
  DefaultSpi* {.importc: "PICO_DEFAULT_SPI".}: cuint
  DefaultSpiSckPin* {.importc: "PICO_DEFAULT_SPI_SCK_PIN".}: Gpio
  DefaultSpiTxPin* {.importc: "PICO_DEFAULT_SPI_TX_PIN".}: Gpio
  DefaultSpiRxPin* {.importc: "PICO_DEFAULT_SPI_RX_PIN".}: Gpio
  DefaultSpiCsnPin* {.importc: "PICO_DEFAULT_SPI_CSN_PIN".}: Gpio

  # Flash
  BootStage2ChooseW25Q080* {.importc: "PICO_BOOT_STAGE2_CHOOSE_W25Q080".}: bool
  BootStage2ChooseGeneric03H* {.importc: "PICO_BOOT_STAGE2_CHOOSE_GENERIC_03H".}: bool
  FlashSpiClkdiv* {.importc: "PICO_FLASH_SPI_CLKDIV".}: cuint
  FlashSizeBytes* {.importc: "PICO_FLASH_SIZE_BYTES".}: cuint

  SmpsModePin* {.importc: "PICO_SMPS_MODE_PIN".}: Gpio
  Rp2040B0Supported* {.importc: "PICO_RP2040_B0_SUPPORTED".}: bool
  Rp2040B1Supported* {.importc: "PICO_RP2040_B1_SUPPORTED".}: bool

  VbusPin* {.importc: "PICO_VBUS_PIN".}: Gpio
  VsysPin* {.importc: "PICO_VSYS_PIN".}: Gpio

  # Cyw43
  Cyw43PinWlHostWake* {.importc: "CYW43_PIN_WL_HOST_WAKE".}: Gpio
  Cyw43PinWlRegOn* {.importc: "CYW43_PIN_WL_REG_ON".}: Gpio
  Cyw43WlGpioCount* {.importc: "CYW43_WL_GPIO_COUNT".}: cuint
  Cyw43WlGpioLedPin* {.importc: "CYW43_WL_GPIO_LED_PIN".}: Cyw43WlGpio
  Cyw43WlGpioVbusPin* {.importc: "CYW43_WL_GPIO_VBUS_PIN".}: Cyw43WlGpio
  Cyw43UsesVsysPin* {.importc: "CYW43_USES_VSYS_PIN".}: bool

{.pop.}
