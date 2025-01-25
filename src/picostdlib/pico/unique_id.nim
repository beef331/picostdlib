import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_unique_id/include".}
{.push header: "pico/unique_id.h".}

const
  UniqueBoardIdSizeBytes* = 8

type
  UniqueBoardId* {.bycopy, importc: "pico_unique_board_id_t".} = object
    ## Unique board identifier
    ##
    ## This struct is suitable for holding the unique identifier of a NOR flash
    ## device on an RP2040-based board. It contains an array of
    ## PICO_UNIQUE_BOARD_ID_SIZE_BYTES identifier bytes.
    id*: array[UniqueBoardIdSizeBytes, uint8]

proc get*(idOut: ptr UniqueBoardId) {.importc: "pico_get_unique_board_id".}
  ## Get unique ID
  ##
  ## Get the unique 64-bit device identifier which was retrieved from the
  ## external NOR flash device at boot.
  ##
  ## On PICO_NO_FLASH builds the unique identifier is set to all 0xEE.
  ##
  ## \param id_out a pointer to a pico_unique_board_id_t struct, to which the identifier will be written

proc picoGetUniqueBoardIdString*(idOut: ptr char; len: cuint) {.importc: "pico_get_unique_board_id_string".}
  ## Get unique ID in string format
  ##
  ## Get the unique 64-bit device identifier which was retrieved from the
  ## external NOR flash device at boot, formatted as an ASCII hex string.
  ## Will always 0-terminate.
  ##
  ## On PICO_NO_FLASH builds the unique identifier is set to all 0xEE.
  ##
  ## \param id_out a pointer to a char buffer of size len, to which the identifier will be written
  ## \param len the size of id_out. For full serial, len >= 2 PICO_UNIQUE_BOARD_ID_SIZE_BYTES + 1

{.pop.}

## Nim helpers

proc picoGetUniqueBoardIdString*(): string =
  ## Returns the entire board id as a Nim string
  result = newString(16)
  picoGetUniqueBoardIdString(result[0].addr, (result.len + 1).cuint)
