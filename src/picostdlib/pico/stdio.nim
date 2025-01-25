import ./error
export error

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_stdio/include".}
{.push header: "pico/stdio.h".}

type
  StdioDriver* {.bycopy, importc: "struct stdio_driver".} = object
    out_chars* {.importc: "out_chars".}: proc (buf: cstring; len: cint) {.cdecl.}
    out_flush* {.importc: "out_flush".}: proc () {.cdecl.}
    in_chars* {.importc: "in_chars".}: proc (buf: cstring; len: cint): cint {.cdecl.}
    next* {.importc: "next".}: ptr StdioDriver

let
  StdoutMutex* {.importc: "PICO_STDOUT_MUTEX".}: bool
  StdioEnableCrlfSupport* {.importc: "PICO_STDIO_ENABLE_CRLF_SUPPORT".}: bool
  StdioDefaultCrlf* {.importc: "PICO_STDIO_DEFAULT_CRLF".}: bool
  StdioStackBufferSize* {.importc: "PICO_STDIO_STACK_BUFFER_SIZE".}: cuint
  StdioDeadlockTimeoutMs* {.importc: "PICO_STDIO_DEADLOCK_TIMEOUT_MS".}: cuint
  LIB_PICO_STDIO_USB* {.importc: "LIB_PICO_STDIO_USB".}: bool


proc stdioInitAll*(): bool {.discardable, importc: "stdio_init_all".}
  ## Initialize all of the present standard stdio types that are linked into the binary.
  ##
  ## Call this method once you have set up your clocks to enable the stdio support for UART, USB
  ## and semihosting based on the presence of the respective libraries in the binary.
  ##
  ## When stdio_usb is configured, this method can be optionally made to block, waiting for a connection
  ## via the variables specified in \ref stdio_usb_init (i.e. \ref PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS)
  ##
  ## \return true if at least one output was successfully initialized, false otherwise.
  ## \see stdio_uart, stdio_usb, stdio_semihosting

proc stdioFlush*() {.importc: "stdio_flush".}
  ## Flushes any buffered output.

proc getcharTimeoutUs*(timeoutUs: uint32): cint {.importc: "getchar_timeout_us".}
  ## Return a character from stdin if there is one available within a timeout
  ##
  ## \param timeout_us the timeout in microseconds, or 0 to not wait for a character if none available.
  ## \return the character from 0-255 or PICO_ERROR_TIMEOUT if timeout occurs

proc setEnabled*(driver: ptr StdioDriver; enabled: bool) {.importc: "stdio_set_driver_enabled".}
  ## Adds or removes a driver from the list of active drivers used for input/output
  ##
  ## \note this method should always be called on an initialized driver and is not re-entrant
  ## \param driver the driver
  ## \param enabled true to add, false to remove

proc filter*(driver: ptr StdioDriver) {.importc: "stdio_filter_driver".}
  ## Control limiting of output to a single driver
  ##
  ## \note this method should always be called on an initialized driver
  ##
  ## \param driver if non-null then output only that driver will be used for input/output (assuming it is in the list of enabled drivers).
  ##               if NULL then all enabled drivers will be used

proc setTranslateCrlf*(driver: ptr StdioDriver; translate: bool) {.importc: "stdio_set_translate_crlf".}
  ## control conversion of line feeds to carriage return on transmissions
  ##
  ## \note this method should always be called on an initialized driver
  ##
  ## \param driver the driver
  ## \param translate If true, convert line feeds to carriage return on transmissions

proc putcharRaw*(c: cint): cint {.importc: "putchar_raw".}
  ## putchar variant that skips any CR/LF conversion if enabled

proc putsRaw*(s: cstring): cint {.importc: "puts_raw".}
  ## puts variant that skips any CR/LF conversion if enabled

proc stdioSetCharsAvailableCallback*(fn: proc (param: pointer) {.cdecl.}; param: pointer) {.importc: "stdio_set_chars_available_callback".}
  ## get notified when there are input characters available
  ##
  ## \param fn Callback function to be called when characters are available. Pass NULL to cancel any existing callback
  ## \param param Pointer to pass to the callback

{.pop.}


## MODULE STDIO SEMIHOSTING

{.push header: "pico/stdio_semihosting.h".}

var stdioSemihosting* {.importc: "stdio_semihosting".}: StdioDriver

proc stdioSemihostingInit*() {.importc: "stdio_semihosting_init".}
  ## Explicitly initialize stdout over semihosting and add it to the current set of stdout targets
  ##
  ## \note this method is automatically called by \ref stdio_init_all() if pico_stdio_semihosting is included in the build

{.pop.}


## MODULE STDIO UART

import ../hardware/uart
export uart

{.push header: "pico/stdio_uart.h".}

var stdioUart* {.importc: "stdio_uart".}: StdioDriver

proc stdioUartInit*() {.importc: "stdio_uart_init".}
  ## Explicitly initialize stdin/stdout over UART and add it to the current set of stdin/stdout drivers
  ##
  ## This method sets up PICO_DEFAULT_UART_TX_PIN for UART output (if defined), PICO_DEFAULT_UART_RX_PIN for input (if defined)
  ## and configures the baud rate as PICO_DEFAULT_UART_BAUD_RATE.
  ##
  ## \note this method is automatically called by \ref stdio_init_all() if pico_stdio_uart is included in the build

proc stdoutUartInit*() {.importc: "stdout_uart_init".}
  ## Explicitly initialize stdout only (no stdin) over UART and add it to the current set of stdout drivers
  ##
  ## This method sets up PICO_DEFAULT_UART_TX_PIN for UART output (if defined) , and configures the baud rate as PICO_DEFAULT_UART_BAUD_RATE

proc stdinUartInit*() {.importc: "stdin_uart_init".}
  ## Explicitly initialize stdin only (no stdout) over UART and add it to the current set of stdin drivers
  ##
  ## This method sets up PICO_DEFAULT_UART_RX_PIN for UART input (if defined) , and configures the baud rate as PICO_DEFAULT_UART_BAUD_RATE

proc stdioUartInitFull*(uart: ptr UartInst; baudrate: cuint; txPin: cint; rxPin: cint) {.importc: "stdio_uart_init_full".}
  ## Perform custom initialization initialize stdin/stdout over UART and add it to the current set of stdin/stdout drivers
  ##
  ## \param uart the uart instance to use, \ref uart0 or \ref uart1
  ## \param baud_rate the baud rate in Hz
  ## \param tx_pin the UART pin to use for stdout (or -1 for no stdout)
  ## \param rx_pin the UART pin to use for stdin (or -1 for no stdin)

{.pop.}


## MODULE STDIO USB

{.push header: "pico/stdio_usb.h".}

let PicoStdioUsbConnectWaitTimeoutMs* {.importc: "PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS".}: uint32

var stdioUsb* {.importc: "stdio_usb".}: StdioDriver

proc stdioUsbInit*(): bool {.importc: "stdio_usb_init".}
  ## Explicitly initialize USB stdio and add it to the current set of stdin drivers
  ##
  ## \ref PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS can be set to cause this method to wait for a CDC connection
  ## from the host before returning, which is useful if you don't want any initial stdout output to be discarded
  ## before the connection is established.
  ##
  ## \return true if the USB CDC was initialized, false if an error occurred

proc stdioUsbConnected*(): bool {.importc: "stdio_usb_connected".}
  ## Check if there is an active stdio CDC connection to a host
  ##
  ## \return true if stdio is connected over CDC

{.pop.}


## Nim helpers

import system/ansi_c

proc blockUntilUsbConnected*() =
  ## Blocks until the usb is connected, useful if reliant on USB interface.
  while not stdioUsbConnected(): discard

proc print*(s: cstring) {.inline.} = c_printf(s)
  ## write output directly to the console (or serial console)

proc print*(s: string) =
  print(cstring s)
  print(cstring "\n")

proc stdinReadLine*(echoInput: bool = true): string =
  while true:
    let res = getcharTimeoutUs(100_000)
    if res != PicoErrorTimeout.int:
      let character = res.char
      if character == '\r':
        echo ""
        break
      else:
        result.add(character)
        if echoInput:
          discard putcharRaw(character.cint)
          stdioFlush()
