let tFlashBinaryStart {.importc: "__flash_binary_start".}: cchar
let tFlashBinaryEnd {.importc: "__flash_binary_end".}: cchar
template FlashBinaryStart*: untyped = cast[cuint](tFlashBinaryStart.unsafeAddr)
template FlashBinaryEnd*: untyped = cast[cuint](tFlashBinaryEnd.unsafeAddr)

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/hardware_flash/include".}
{.push header: "hardware/flash.h".}

let
  FlashPageSize* {.importc: "FLASH_PAGE_SIZE".}: cuint
  FlashSectorSize* {.importc: "FLASH_SECTOR_SIZE".}: cuint
  FlashBlockSize* {.importc: "FLASH_BLOCK_SIZE".}: cuint
  FlashUniqueIdSizeBytes* {.importc: "FLASH_UNIQUE_ID_SIZE_BYTES".}: cuint

proc flashRangeErase*(flashOffs: uint32; count: cuint) {.importc: "flash_range_erase".}
  ## Erase areas of flash
  ##
  ## \param flash_offs Offset into flash, in bytes, to start the erase. Must be aligned to a 4096-byte flash sector.
  ## \param count Number of bytes to be erased. Must be a multiple of 4096 bytes (one sector).

proc flashRangeProgram*(flashOffs: uint32; data: ptr uint8; count: cuint) {.importc: "flash_range_program".}
  ## Program flash
  ##
  ## \param flash_offs Flash address of the first byte to be programmed. Must be aligned to a 256-byte flash page.
  ## \param data Pointer to the data to program into flash
  ## \param count Number of bytes to program. Must be a multiple of 256 bytes (one page).

proc flashGetUniqueId*(idOut: ptr uint8) {.importc: "flash_get_unique_id".}
  ## Get flash unique 64 bit identifier
  ##
  ## Use a standard 4Bh RUID instruction to retrieve the 64 bit unique
  ## identifier from a flash device attached to the QSPI interface. Since there
  ## is a 1:1 association between the MCU and this flash, this also serves as a
  ## unique identifier for the board.
  ##
  ## \param id_out Pointer to an 8-byte buffer to which the ID will be written

proc flashDoCmd*(txbuf: ptr uint8; rxbuf: ptr uint8; count: cuint) {.importc: "flash_do_cmd".}
  ## Execute bidirectional flash command
  ##
  ## Low-level function to execute a serial command on a flash device attached
  ## to the QSPI interface. Bytes are simultaneously transmitted and received
  ## from txbuf and to rxbuf. Therefore, both buffers must be the same length,
  ## count, which is the length of the overall transaction. This is useful for
  ## reading metadata from the flash chip, such as device ID or SFDP
  ## parameters.
  ##
  ## The XIP cache is flushed following each command, in case flash state
  ## has been modified. Like other hardware_flash functions, the flash is not
  ## accessible for execute-in-place transfers whilst the command is in
  ## progress, so entering a flash-resident interrupt handler or executing flash
  ## code on the second core concurrently will be fatal. To avoid these pitfalls
  ## it is recommended that this function only be used to extract flash metadata
  ## during startup, before the main application begins to run: see the
  ## implementation of pico_get_unique_id() for an example of this.
  ##
  ## \param txbuf Pointer to a byte buffer which will be transmitted to the flash
  ## \param rxbuf Pointer to a byte buffer where data received from the flash will be written. txbuf and rxbuf may be the same buffer.
  ## \param count Length in bytes of txbuf and of rxbuf

{.pop.}
