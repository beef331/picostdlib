import ../hardware/i2c

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_i2c_slave/include".}
{.push header: "pico/i2c_slave.h".}

type
  I2cSlaveEvent* {.pure, importc: "i2c_slave_event_t".} = enum
    ## I2C slave event types.
    I2cSlaveReceive # Data from master is available for reading. Slave must read from Rx FIFO.
    I2cSlaveRequest # Master is requesting data. Slave must write into Tx FIFO.
    I2cSlaveFinish  # Master has sent a Stop or Restart signal. Slave may prepare for the next transfer.

  I2cSlaveHandler* {.importc: "i2c_slave_handler_t".} = proc (i2c: ptr I2cInst; event: I2cSlaveEvent) {.cdecl.}
    ## I2C slave event handler
    ##
    ## The event handler will run from the I2C ISR, so it should return quickly (under 25 us at 400 kb/s).
    ## Avoid blocking inside the handler and split large data transfers across multiple calls for best results.
    ## When sending data to master, up to \ref i2c_get_write_available()  bytes can be written without blocking.
    ## When receiving data from master, up to \ref i2c_get_read_available() bytes can be read without blocking.
    ##
    ## \param i2c Either \ref i2c0 or \ref i2c1
    ## \param event Event type.

proc slaveInit*(i2c: ptr I2cInst; address: I2cAddress; handler: I2cSlaveHandler) {.importc: "i2c_slave_init".}
  ## Configure an I2C instance for slave mode.
  ##
  ## \param i2c I2C instance.
  ## \param address 7-bit slave address.
  ## \param handler Callback for events from I2C master. It will run from the I2C ISR, on the CPU core
  ##                where the slave was initialised.

proc slaveDeinit*(i2c: ptr I2cInst) {.importc: "i2c_slave_deinit".}
  ## Restore I2C instance to master mode.
  ##
  ## \param i2c Either \ref i2c0 or \ref i2c1

{.pop.}
