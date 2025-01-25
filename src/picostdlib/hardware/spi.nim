import ./base
import ./gpio
import ../pico

export gpio
export DefaultSpi, DefaultSpiSckPin, DefaultSpiTxPin, DefaultSpiRxPin, DefaultSpiCsnPin

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_spi/include".}

## spi_inst struct does not exist
## cpp backend needs this to be defined
{.emit: "struct spi_inst {};".}

{.push header: "hardware/spi.h".}

type
  SpiHw* {.importc: "spi_hw_t".} = object
    dr*: IoRw32
    sr*: IoRo32
    icr*: IoRw32

  SpiClockPhase* {.pure, importc: "spi_cpha_t".} = enum
    ## Enumeration of SPI CPHA (clock phase) values.
    Phase0, Phase1

  SpiClockPolarity* {.pure, importc: "spi_cpol_t".} = enum
    ## Enumeration of SPI CPOL (clock polarity) values.
    Pol0, Pol1

  SpiOrder* {.pure, importc: "spi_order_t".} = enum
    ## Enumeration of SPI bit-order values.
    LsbFirst, MsbFirst

  SpiInst* {.importc: "spi_inst_t", bycopy.} = object
    ## Opaque type representing an SPI instance.
let
  SPI_SSPSR_BSY_BITS* {.importc: "SPI_SSPSR_BSY_BITS".}: cuint
  SPI_SSPICR_RORIC_BITS* {.importc: "SPI_SSPICR_RORIC_BITS".}: cuint

  spi0Hw* {.importc: "spi0_hw".}: ptr SpiHw
  spi1Hw* {.importc: "spi1_hw".}: ptr SpiHw

  spi0* {.importc: "spi0".}: ptr SpiInst
  spi1* {.importc: "spi1".}: ptr SpiInst
  spiDefault* {.importc: "spi_default".}: ptr SpiInst


proc init*(spi: ptr SpiInst; baudrate: cuint): cuint {.importc: "spi_init".}
  ## Initialise SPI instances
  ## Puts the SPI into a known state, and enable it. Must be called before other
  ## functions.
  ##
  ## \note There is no guarantee that the baudrate requested can be achieved exactly; the nearest will be chosen
  ## and returned
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param baudrate Baudrate requested in Hz
  ## \return the actual baud rate set

proc deinit*(spi: ptr SpiInst) {.importc: "spi_deinit".}
  ## Deinitialise SPI instances
  ## Puts the SPI into a disabled state. Init will need to be called to reenable the device
  ## functions.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1

proc setBaudrate*(spi: ptr SpiInst; baudrate: cuint): cuint {.importc: "spi_set_baudrate".}
  ## Set SPI baudrate
  ##
  ## Set SPI frequency as close as possible to baudrate, and return the actual
  ## achieved rate.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param baudrate Baudrate required in Hz, should be capable of a bitrate of at least 2Mbps, or higher, depending on system clock settings.
  ## \return The actual baudrate set

proc getBaudrate*(spi: ptr SpiInst): cuint {.importc: "spi_get_baudrate".}
  ## Get SPI baudrate
  ##
  ## Get SPI baudrate which was set by \see spi_set_baudrate
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \return The actual baudrate set

proc getIndex*(spi: ptr SpiInst): cuint {.importc: "spi_get_index".}
  ## Convert SPI instance to hardware instance number
  ##
  ## \param spi SPI instance
  ## \return Number of SPI, 0 or 1.

proc getHw*(spi: ptr SpiInst): ptr SpiHw {.importc: "spi_get_hw".}

proc getConstHw*(spi: ptr SpiInst): ptr SpiHw {.importc: "spi_get_const_hw".}

proc setFormat*(spi: ptr SpiInst; dataBits: cuint(4) .. cuint(16); cpol: SpiClockPolarity; cpha: SpiClockPhase; order: SpiOrder) {.importc: "spi_set_format".}
  ## Configure SPI
  ##
  ## Configure how the SPI serialises and deserialises data on the wire
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param data_bits Number of data bits per transfer. Valid values 4..16.
  ## \param cpol SSPCLKOUT polarity, applicable to Motorola SPI frame format only.
  ## \param cpha SSPCLKOUT phase, applicable to Motorola SPI frame format only
  ## \param order Must be SPI_MSB_FIRST, no other values supported on the PL022

proc setSlave*(spi: ptr SpiInst; slave: bool) {.importc: "spi_set_slave".}
  ## Set SPI master/slave
  ##
  ## Configure the SPI for master- or slave-mode operation. By default,
  ## spi_init() sets master-mode.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param slave true to set SPI device as a slave device, false for master.

# Generic input/output

proc isWritable*(spi: ptr SpiInst): bool {.importc: "spi_is_writable".}
  ## Check whether a write can be done on SPI device
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \return false if no space is available to write. True if a write is possible

proc isReadable*(spi: ptr SpiInst): bool {.importc: "spi_is_readable".}
  ## Check whether a read can be done on SPI device
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \return true if a read is possible i.e. data is present

proc isBusy*(spi: ptr SpiInst): bool {.importc: "spi_is_busy".}
  ## Check whether SPI is busy
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \return true if SPI is busy

proc writeReadBlocking*(spi: ptr SpiInst; src, dst: ptr uint8; len: csize_t): cint {.importc: "spi_write_read_blocking".}
  ## Write/Read to/from an SPI device
  ##
  ## Write \p len bytes from \p src to SPI. Simultaneously read \p len bytes from SPI to \p dst.
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param src Buffer of data to write
  ## \param dst Buffer for read data
  ## \param len Length of BOTH buffers
  ## \return Number of bytes written/read

proc writeBlocking*(spi: ptr SpiInst; src: ptr uint8; len: csize_t): cint {.importc: "spi_write_blocking".}
  ## Write to an SPI device, blocking
  ##
  ## Write \p len bytes from \p src to SPI, and discard any data received back
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param src Buffer of data to write
  ## \param len Length of \p src
  ## \return Number of bytes written/read

proc readBlocking*(spi: ptr SpiInst; repeatedTxData: uint8; dst: ptr uint8; len: csize_t): cint {.importc: "spi_read_blocking".}
  ## Read from an SPI device
  ##
  ## Read \p len bytes from SPI to \p dst.
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ## \p repeated_tx_data is output repeatedly on TX as data is read in from RX.
  ## Generally this can be 0, but some devices require a specific value here,
  ## e.g. SD cards expect 0xff
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param repeated_tx_data Buffer of data to write
  ## \param dst Buffer for read data
  ## \param len Length of buffer \p dst
  ## \return Number of bytes written/read

proc write16Read16Blocking*(spi: ptr SpiInst; src: ptr uint16; dst: ptr uint16; len: csize_t): cint {.importc: "spi_write16_read16_blocking".}
  ## Write/Read half words to/from an SPI device
  ##
  ## Write \p len halfwords from \p src to SPI. Simultaneously read \p len halfwords from SPI to \p dst.
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ##
  ## \note SPI should be initialised with 16 data_bits using \ref spi_set_format first, otherwise this function will only read/write 8 data_bits.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param src Buffer of data to write
  ## \param dst Buffer for read data
  ## \param len Length of BOTH buffers in halfwords
  ## \return Number of halfwords written/read

proc write16Blocking*(spi: ptr SpiInst; src: ptr uint16; len: csize_t): cint {.importc: "spi_write16_blocking".}
  ## Write to an SPI device
  ##
  ## Write \p len halfwords from \p src to SPI. Discard any data received back.
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ##
  ## \note SPI should be initialised with 16 data_bits using \ref spi_set_format first, otherwise this function will only write 8 data_bits.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param src Buffer of data to write
  ## \param len Length of buffers
  ## \return Number of halfwords written/read

proc read16Blocking*(spi: ptr SpiInst; repeatedTxData: uint16; dst: ptr uint16; len: csize_t): cint {.importc: "spi_read16_blocking".}
  ## Read from an SPI device
  ##
  ## Read \p len halfwords from SPI to \p dst.
  ## Blocks until all data is transferred. No timeout, as SPI hardware always transfers at a known data rate.
  ## \p repeated_tx_data is output repeatedly on TX as data is read in from RX.
  ## Generally this can be 0, but some devices require a specific value here,
  ## e.g. SD cards expect 0xff
  ##
  ## \note SPI should be initialised with 16 data_bits using \ref spi_set_format first, otherwise this function will only read 8 data_bits.
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param repeated_tx_data Buffer of data to write
  ## \param dst Buffer for read data
  ## \param len Length of buffer \p dst in halfwords
  ## \return Number of halfwords written/read

proc getDreq*(spi: ptr SpiInst; isTx: bool): cuint {.importc: "spi_get_dreq".}
  ## Return the DREQ to use for pacing transfers to/from a particular SPI instance
  ##
  ## \param spi SPI instance specifier, either \ref spi0 or \ref spi1
  ## \param is_tx true for sending data to the SPI instance, false for receiving data from the SPI instance

{.pop.}


## Nim helpers

proc writeBlocking*(spi: ptr SpiInst; src: varargs[uint8]): cint =
  assert(src.len > 0)
  return spi.writeBlocking(src[0].unsafeAddr, src.len.csize_t)
