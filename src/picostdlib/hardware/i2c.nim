import ./gpio, ../pico/types, ../pico
export gpio, types
export DefaultI2c, DefaultI2cSdaPin, DefaultI2cSclPin

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_i2c/include".}

{.push header: "hardware/i2c.h".}

type
  I2cHw* {.importc: "i2c_hw_t".} = object

  I2cInst* {.importc: "struct i2c_inst".} = object
    hw* {.importc: "hw".}: ptr I2cHw
    restartOnNext* {.importc: "restart_on_next".}: bool

  I2cAddress* = distinct range[0'u8 .. 127'u8]

proc `==`*(a, b: I2cAddress): bool {.borrow.}
proc `$`*(a: I2cAddress): string {.borrow.}

let
  i2c0Hw* {.importc: "i2c0_hw".}: ptr I2cHw
  i2c1Hw* {.importc: "i2c1_hw".}: ptr I2cHw

  i2c0Inst* {.importc: "i2c0_inst".}: I2cInst
  i2c1Inst* {.importc: "i2c1_inst".}: I2cInst
  i2c0* {.importc: "i2c0".}: ptr I2cInst
  i2c1* {.importc: "i2c1".}: ptr I2cInst
  i2cDefault* {.importc: "i2c_default".}: ptr I2cInst



proc init*(i2c: ptr I2cInst, baudrate: cuint): cuint {.importc: "i2c_init".}
  ## Initialise the I2C HW block
  ##
  ## Put the I2C hardware into a known state, and enable it. Must be called
  ## before other functions. By default, the I2C is configured to operate as a
  ## master.
  ##
  ## The I2C bus frequency is set as close as possible to requested, and
  ## the actual rate set is returned
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param baudrate Baudrate in Hz (e.g. 100kHz is 100000)
  ## \return Actual set baudrate

proc deinit*(i2c: ptr I2cInst) {.importc: "i2c_deinit".}
  ## Disable the I2C HW block
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ##
  ## Disable the I2C again if it is no longer used. Must be reinitialised before
  ## being used again.

proc setBaudrate*(i2c: ptr I2cInst, baudrate: cuint): cuint {.importc: "i2c_set_baudrate".}
  ## Set I2C baudrate
  ##
  ## Set I2C bus frequency as close as possible to requested, and return actual
  ## rate set.
  ## Baudrate may not be as exactly requested due to clocking limitations.
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param baudrate Baudrate in Hz (e.g. 100kHz is 100000)
  ## \return Actual set baudrate

proc setSlaveMode*(i2c: ptr I2cInst, slave: bool, address: I2cAddress) {.importc: "i2c_set_slave_mode".}
  ## Set I2C port to slave mode
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param slave true to use slave mode, false to use master mode
  ## \param addr If \p slave is true, set the slave address to this value

proc hwIndex*(i2c: ptr I2cInst): cuint {.importc: "i2c_hw_index".}
  ## Convert I2C instance to hardware instance number
  ##
  ## \param i2c I2C instance
  ## \return Number of I2C, 0 or 1.

proc getHw*(i2c: ptr I2cInst): ptr I2cHw {.importc: "i2c_get_hw".}

proc i2cGetInstance*(instance: cuint): ptr I2cInst {.importc: "i2c_get_instance".}

proc writeBlockingUntil*(i2c: ptr I2cInst; address: I2cAddress; src: ptr uint8; len: csize_t; noStop: bool; until: AbsoluteTime): cint {.importc: "i2c_write_blocking_until".}
  ## Attempt to write specified number of bytes to address, blocking until the specified absolute time is reached.
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to write to
  ## \param src Pointer to data to send
  ## \param len Length of data in bytes to send
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \param until The absolute time that the block will wait until the entire transaction is complete. Note, an individual timeout of
  ##           this value divided by the length of data is applied for each byte transfer, so if the first or subsequent
  ##           bytes fails to transfer within that sub timeout, the function will return with an error.
  ##
  ## \return Number of bytes written, or PICO_ERROR_GENERIC if address not acknowledged, no device present, or PICO_ERROR_TIMEOUT if a timeout occurred.

proc readBlockingUntil*(i2c: ptr I2cInst; address: I2cAddress; dst: ptr uint8; len: csize_t; noStop: bool; until: AbsoluteTime): cint {.importc: "i2c_read_blocking_until".}
  ## Attempt to read specified number of bytes from address, blocking until the specified absolute time is reached.
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to read from
  ## \param dst Pointer to buffer to receive data
  ## \param len Length of data in bytes to receive
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \param until The absolute time that the block will wait until the entire transaction is complete.
  ## \return Number of bytes read, or PICO_ERROR_GENERIC if address not acknowledged, no device present, or PICO_ERROR_TIMEOUT if a timeout occurred.

proc writeTimeoutUs*(i2c: ptr I2cInst; address: I2cAddress; src: ptr uint8; len: csize_t; noStop: bool; timeoutUs: cuint): cint {.importc: "i2c_write_timeout_us".}
  ## Attempt to write specified number of bytes to address, with timeout
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to write to
  ## \param src Pointer to data to send
  ## \param len Length of data in bytes to send
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \param timeout_us The time that the function will wait for the entire transaction to complete. Note, an individual timeout of
  ##           this value divided by the length of data is applied for each byte transfer, so if the first or subsequent
  ##           bytes fails to transfer within that sub timeout, the function will return with an error.
  ##
  ## \return Number of bytes written, or PICO_ERROR_GENERIC if address not acknowledged, no device present, or PICO_ERROR_TIMEOUT if a timeout occurred.

proc readTimeoutUs*(i2c: ptr I2cInst; address: I2cAddress; dst: ptr uint8; len: csize_t; noStop: bool; timeoutUs: cuint): cint {.importc: "i2c_read_timeout_us".}
  ## Attempt to read specified number of bytes from address, with timeout
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to read from
  ## \param dst Pointer to buffer to receive data
  ## \param len Length of data in bytes to receive
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \param timeout_us The time that the function will wait for the entire transaction to complete
  ## \return Number of bytes read, or PICO_ERROR_GENERIC if address not acknowledged, no device present, or PICO_ERROR_TIMEOUT if a timeout occurred.

proc writeBlocking*(i2c: ptr I2cInst, address: I2cAddress, data: ptr uint8, len: csize_t, noStop: bool): cint {.importc: "i2c_write_blocking".}
  ## Attempt to write specified number of bytes to address, blocking
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to write to
  ## \param src Pointer to data to send
  ## \param len Length of data in bytes to send
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \return Number of bytes written, or PICO_ERROR_GENERIC if address not acknowledged, no device present.

proc readBlocking*(i2c: ptr I2cInst, address: I2cAddress, dest: ptr uint8, size: csize_t, noStop: bool): cint {.importc: "i2c_read_blocking".}
  ## Attempt to read specified number of bytes from address, blocking
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param addr 7-bit address of device to read from
  ## \param dst Pointer to buffer to receive data
  ## \param len Length of data in bytes to receive
  ## \param nostop  If true, master retains control of the bus at the end of the transfer (no Stop is issued),
  ##           and the next transfer will begin with a Restart rather than a Start.
  ## \return Number of bytes read, or PICO_ERROR_GENERIC if address not acknowledged or no device present.

proc getWriteAvailable*(i2c: ptr I2cInst): cuint {.importc: "i2c_get_write_available".}
  ## Determine non-blocking write space available
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \return 0 if no space is available in the I2C to write more data. If return is nonzero, at
  ## least that many bytes can be written without blocking.

proc getReadAvailable*(i2c: ptr I2cInst): cuint {.importc: "i2c_get_read_available".}
  ## Determine number of bytes received
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \return 0 if no data available, if return is nonzero at
  ## least that many bytes can be read without blocking.

proc writeRawBlocking*(i2c: ptr I2cInst; src: ptr uint8; len: csize_t) {.importc: "i2c_write_raw_blocking".}
  ## Write direct to TX FIFO
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param src Data to send
  ## \param len Number of bytes to send
  ##
  ## Writes directly to the I2C TX FIFO which is mainly useful for
  ## slave-mode operation.

proc readRawBlocking*(i2c: ptr I2cInst; dst: ptr uint8; len: csize_t) {.importc: "i2c_read_raw_blocking".}
  ## Read direct from RX FIFO
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param dst Buffer to accept data
  ## \param len Number of bytes to read
  ##
  ## Reads directly from the I2C RX FIFO which is mainly useful for
  ## slave-mode operation.

proc readByteRaw*(i2c: ptr I2cInst): uint8 {.importc: "i2c_read_byte_raw".}
  ## Pop a byte from I2C Rx FIFO.
  ##
  ## This function is non-blocking and assumes the Rx FIFO isn't empty.
  ##
  ## \param i2c I2C instance.
  ## \return uint8_t Byte value.

proc writeByteRaw*(i2c: ptr I2cInst; value: uint8) {.importc: "i2c_write_byte_raw".}
  ## Push a byte into I2C Tx FIFO.
  ##
  ## This function is non-blocking and assumes the Tx FIFO isn't full.
  ##
  ## \param i2c I2C instance.
  ## \param value Byte value.

proc getDreq*(i2c: ptr I2cInst; isTx: bool): cuint {.importc: "i2c_get_dreq".}
  ## Return the DREQ to use for pacing transfers to/from a particular I2C instance
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1
  ## \param is_tx true for sending data to the I2C instance, false for receiving data from the I2C instance

{.pop.}


## Nim helpers

template i2cSetupNim*(blokk: ptr I2cInst, pSda, pScl: Gpio, freq: uint, pull = true) =
  #sugar setup for i2c:
  #blokk= block i2c0 / i2c1 (see pinout)
  #pSda/pScl = the pins you want use (ex: 2.Gpio, 3.Gpio) I do not recommend the use of 0.Gpio, 1.Gpio
  #freq = is the working frequency of the i2c device (see device manual; ex: 100000)
  #pull = use or not to use pullup (default = true)
  var i2cx = blokk
  discard i2cx.init(freq)
  pSda.setFunction(GpioFunction.I2c)
  pScl.setFunction(GpioFunction.I2c)
  if pull:
    pSda.pullUp()
    pScl.pullUp()
  else:
    pSda.pullDown()
    pScl.pullDown()

proc i2cWriteBlockingNim*(
    i2c: ptr I2cInst,
    address: I2cAddress,
    data: var openArray[uint8],
    noStop: bool = false
  ): int =
  ## Write bytes to I2C bus.
  ## If `noStop` is `true`, master retains control of the bus at the end of
  ## the transfer.
  result = i2c.writeBlocking(address, data[0].addr, data.len.uint, noStop)

proc i2cReadBlockingNim*(
    i2c: ptr I2cInst,
    address: I2cAddress,
    numBytes: uint,
    noStop: bool = false
  ): seq[uint8] =
  ## Read `numBytes` bytes from I2C bus and return a seq containing the bytes
  ## that were read. In case of error return a 0-length seq. If `noStop` is
  ## `true`, master retains control of the bus at the end of the transfer.

  result.setLen(numBytes)
  let n = i2c.readBlocking(address, result[0].addr, numBytes.uint, noStop)
  result.setLen(max(0, n))

proc i2cReadBlockingNim*[N: Natural](
    i2c: ptr I2cInst,
    address: I2cAddress,
    dest: var array[N, uint8],
    noStop: bool = false
  ): int =
  ## Fill the array `dest` with bytes read from I2C bus. Return the number of
  ## bytes that were read successfully. Negative values are error codes (refer
  ## to Pico SDK documentation). In case of error return a 0-length seq. If
  ## `noStop` is `true`, master retains control of the bus at the end of the
  ## transfer.
  result = i2c.readBlocking(address, dest[0].addr, N.uint, noStop)

when defined(runtests):
  i2cSetupNim(DefaultI2c.i2cGetInstance(), DefaultI2cSdaPin, DefaultI2cSclPin, 1000)
