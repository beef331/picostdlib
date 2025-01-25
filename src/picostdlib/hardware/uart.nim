import ../pico
import ./base
import ./gpio

export gpio, base
export DefaultUart, DefaultUartTxPin, DefaultUartRxPin

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_uart/include".}

## uart_inst struct does not exist
## cpp backend needs this to be defined
{.emit: "struct uart_inst {};".}

{.push header: "hardware/uart.h".}

type
  UartHw* {.importc: "uart_hw_t".} = object

  UartParity* {.pure, importc: "uart_parity_t".} = enum
    ## UART Parity enumeration
    None, Even, Odd

  UartInst* {.importc: "uart_inst_t", bycopy.} = object
    ## Currently always a pointer to hw but it might not be in the future

let
  uart0Hw* {.importc: "uart0_hw".}: ptr UartHw
  uart1Hw* {.importc: "uart1_hw".}: ptr UartHw

  uart0* {.importc: "uart0".}: ptr UartInst
  uart1* {.importc: "uart1".}: ptr UartInst
  uartDefault* {.importc: "uart_default".}: ptr UartInst

  UartAssertionsEnabled* {.importc: "PARAM_ASSERTIONS_ENABLED_UART".}: bool
  UartEnableCrlfSupport* {.importc: "PICO_UART_ENABLE_CRLF_SUPPORT".}: bool
  UartDefaultCrlf* {.importc: "PICO_UART_DEFAULT_CRLF".}: bool
  DefaultUartBaudrate* {.importc: "PICO_DEFAULT_UART_BAUD_RATE".}: cuint


proc getIndex*(uart: ptr UartInst): cuint {.importc: "uart_get_index".}
  ## Convert UART instance to hardware instance number
  ##
  ## \param uart UART instance
  ## \return Number of UART, 0 or 1.

# Setup

proc init*(uart: ptr UartInst; baudrate: cuint): cuint {.importc: "uart_init".}
  ## Initialise a UART
  ##
  ## Put the UART into a known state, and enable it. Must be called before other
  ## functions.
  ##
  ## \note There is no guarantee that the baudrate requested will be possible, the nearest will be chosen,
  ## and this function will return the configured baud rate.
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param baudrate Baudrate of UART in Hz
  ## \return Actual set baudrate

proc deinit*(uart: ptr UartInst) {.importc: "uart_deinit".}
  ## DeInitialise a UART
  ##
  ## Disable the UART if it is no longer used. Must be reinitialised before
  ## being used again.
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1

proc setBaudrate*(uart: ptr UartInst; baudrate: cuint): cuint {.importc: "uart_set_baudrate".}
  ## Set UART baud rate
  ##
  ## Set baud rate as close as possible to requested, and return actual rate selected.
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param baudrate Baudrate in Hz
  ## \return Actual set baudrate

proc setHwFlow*(uart: ptr UartInst; cts: bool; rts: bool) {.importc: "uart_set_hw_flow".}
  ## Set UART flow control CTS/RTS
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param cts If true enable flow control of TX  by clear-to-send input
  ## \param rts If true enable assertion of request-to-send output by RX flow control

proc setFormat*(uart: ptr UartInst; dataBits: range[5.cuint .. 8.cuint]; stopBits: range[1.cuint .. 2.cuint]; parity: UartParity)
  {.importc: "uart_set_format".}
  ## Set UART data format
  ##
  ## Configure the data format (bits etc() for the UART
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param data_bits Number of bits of data. 5..8
  ## \param stop_bits Number of stop bits 1..2
  ## \param parity Parity option.

proc setIrqEnables*(uart: ptr UartInst; rxHasData: bool; txNeedsData: bool) {.importc: "uart_set_irq_enables".}
  ## Setup UART interrupts
  ##
  ## Enable the UART's interrupt output. An interrupt handler will need to be installed prior to calling
  ## this function.
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param rx_has_data If true an interrupt will be fired when the RX FIFO contains data.
  ## \param tx_needs_data If true an interrupt will be fired when the TX FIFO needs data.

proc isEnabled*(uart: ptr UartInst): bool {.importc: "uart_is_enabled".}
  ## Test if specific UART is enabled
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \return true if the UART is enabled

proc setFifoEnabled*(uart: ptr UartInst; enabled: bool) {.importc: "uart_set_fifo_enabled".}
  ## Enable/Disable the FIFOs on specified UART
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param enabled true to enable FIFO (default), false to disable

proc isWritable*(uart: ptr UartInst): bool {.importc: "uart_is_writable".}
  ## Determine if space is available in the TX FIFO
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \return false if no space available, true otherwise

proc txWaitBlocking*(uart: ptr UartInst) {.importc: "uart_tx_wait_blocking".}
  ## Wait for the UART TX fifo to be drained
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1

proc isReadable*(uart: ptr UartInst): bool {.importc: "uart_is_readable".}
  ## Determine whether data is waiting in the RX FIFO
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \return true if the RX FIFO is not empty, otherwise false.

proc writeBlocking*(uart: ptr UartInst; src: ptr uint8; len: cuint) {.importc: "uart_write_blocking".}
  ## Write to the UART for transmission.
  ##
  ## This function will block until all the data has been sent to the UART
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param src The bytes to send
  ## \param len The number of bytes to send

proc readBlocking*(uart: ptr UartInst; dst: ptr uint8; len: cuint) {.importc: "uart_read_blocking".}
  ## Read from the UART
  ##
  ## This function blocks until len characters have been read from the UART
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param dst Buffer to accept received bytes
  ## \param len The number of bytes to receive.

# UART-specific operations and aliases

proc putcRaw*(uart: ptr UartInst; c: cchar) {.importc: "uart_putc_raw".}
  ## Write single character to UART for transmission.
  ##
  ## This function will block until the entire character has been sent
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param c The character  to send

proc putc*(uart: ptr UartInst; c: cchar) {.importc: "uart_putc".}
  ## Write single character to UART for transmission, with optional CR/LF conversions
  ##
  ## This function will block until the character has been sent
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param c The character  to send

proc puts*(uart: ptr UartInst; s: cstring) {.importc: "uart_puts".}
  ## Write string to UART for transmission, doing any CR/LF conversions
  ##
  ## This function will block until the entire string has been sent
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param s The null terminated string to send

proc getc*(uart: ptr UartInst): cchar {.importc: "uart_getc".}
  ## Read a single character from the UART
  ##
  ## This function will block until a character has been read
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \return The character read.

proc setBreak*(uart: ptr UartInst; en: bool) {.importc: "uart_set_break".}
  ## Assert a break condition on the UART transmission.
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param en Assert break condition (TX held low) if true. Clear break condition if false.

proc setTranslateCrlf*(uart: ptr UartInst; translate: bool) {.importc: "uart_set_translate_crlf".}
  ## Set CR/LF conversion on UART
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param translate If true, convert line feeds to carriage return on transmissions

proc uartDefaultTxWaitBlocking*() {.importc: "uart_default_tx_wait_blocking".}
  ## Wait for the default UART's TX FIFO to be drained

proc isReadableWithinUs*(uart: ptr UartInst; us: uint32): bool {.importc: "uart_is_readable_within_us".}
  ## Wait for up to a certain number of microseconds for the RX FIFO to be non empty
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param us the number of microseconds to wait at most (may be 0 for an instantaneous check)
  ## \return true if the RX FIFO became non empty before the timeout, false otherwise

proc getDreq*(uart: ptr UartInst; isTx: bool): cuint {.importc: "uart_get_dreq".}
  ## Return the DREQ to use for pacing transfers to/from a particular UART instance
  ##
  ## \param uart UART instance. \ref uart0 or \ref uart1
  ## \param is_tx true for sending data to the UART instance, false for receiving data from the UART instance

{.pop.}
