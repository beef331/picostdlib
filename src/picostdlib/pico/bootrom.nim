import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_bootrom/include".}
{.push header: "pico/bootrom.h".}

type
  rom_popcount32_fn* {.importc.} = proc (a1: uint32): uint32 {.cdecl.}
  rom_reverse32_fn* {.importc.} = proc (a1: uint32): uint32 {.cdecl.}
  rom_clz32_fn* {.importc.} = proc (a1: uint32): uint32 {.cdecl.}
  rom_ctz32_fn* {.importc.} = proc (a1: uint32): uint32 {.cdecl.}
  rom_memset_fn* {.importc.} = proc (a1: ptr uint8; a2: uint8; a3: uint32): ptr uint8 {.cdecl.}
  rom_memset4_fn* {.importc.} = proc (a1: ptr uint32; a2: uint8; a3: uint32): ptr uint32 {.cdecl.}
  rom_memcpy_fn* {.importc.} = proc (a1: ptr uint8; a2: ptr uint8; a3: uint32): ptr uint32 {.cdecl.}
  rom_memcpy44_fn* {.importc.} = proc (a1: ptr uint32; a2: ptr uint32; a3: uint32): ptr uint32 {.cdecl.}
  rom_reset_usb_boot_fn* {.importc.} = proc (a1: uint32; a2: uint32) {.cdecl.}
  rom_connect_internal_flash_fn* {.importc.} = proc () {.cdecl.}
  rom_flash_exit_xip_fn* {.importc.} = proc () {.cdecl.}
  rom_flash_range_erase_fn* {.importc.} = proc (a1: uint32; a2: cuint; a3: uint32; a4: uint8) {.cdecl.}
  rom_flash_range_program_fn* {.importc.} = proc (a1: uint32; a2: ptr uint8; a3: uint) {.cdecl.}
  rom_flash_flush_cache_fn* {.importc.} = proc () {.cdecl.}
  rom_flash_enter_cmd_xip_fn* {.importc.} = proc () {.cdecl.}
  rom_table_lookup_fn* {.importc.} = proc (table: ptr uint16; code: uint32): pointer {.cdecl.}

  reset_usb_boot_fn* {.importc, deprecated: "use rom_reset_usb_boot_fn instead".} = rom_reset_usb_boot_fn
    ## kept for backwards compatibility

let
  RomFuncPopCount32* {.importc: "ROM_FUNC_POPCOUNT32".}: uint32
  RomFuncReverse32* {.importc: "ROM_FUNC_REVERSE32".}: uint32
  RomFuncClz32* {.importc: "ROM_FUNC_CLZ32".}: uint32
  RomFuncCtz32* {.importc: "ROM_FUNC_CTZ32".}: uint32
  RomFuncMemset* {.importc: "ROM_FUNC_MEMSET".}: uint32
  RomFuncMemset4* {.importc: "ROM_FUNC_MEMSET4".}: uint32
  RomFuncMemcpy* {.importc: "ROM_FUNC_MEMCPY".}: uint32
  RomFuncMemcpy44* {.importc: "ROM_FUNC_MEMCPY44".}: uint32
  RomFuncResetUsbBoot* {.importc: "ROM_FUNC_RESET_USB_BOOT".}: uint32
  RomFuncConnectInternalFlash* {.importc: "ROM_FUNC_CONNECT_INTERNAL_FLASH".}: uint32
  RomFuncFlashExitXip* {.importc: "ROM_FUNC_FLASH_EXIT_XIP".}: uint32
  RomFuncFlashRangeErase* {.importc: "ROM_FUNC_FLASH_RANGE_ERASE".}: uint32
  RomFuncFlashRangeProgram* {.importc: "ROM_FUNC_FLASH_RANGE_PROGRAM".}: uint32
  RomFuncFlashFlushCache* {.importc: "ROM_FUNC_FLASH_FLUSH_CACHE".}: uint32
  RomFuncFlashEnterCmdXip* {.importc: "ROM_FUNC_FLASH_ENTER_CMD_XIP".}: uint32

proc romTableCode*(c1: char; c2: char): uint32 {.importc: "rom_table_code".}
  ## Return a bootrom lookup code based on two ASCII characters
  ##
  ## These codes are uses to lookup data or function addresses in the bootrom
  ##
  ## \param c1 the first character
  ## \param c2 the second character
  ## \return the 'code' to use in rom_func_lookup() or rom_data_lookup()

proc romFuncLookup*(code: uint32): pointer {.importc: "rom_func_lookup".}
  ## Lookup a bootrom function by code
  ##
  ## \param code the code
  ## \return a pointer to the function, or NULL if the code does not match any bootrom function

proc romDataLookup*(code: uint32): pointer {.importc: "rom_data_lookup".}
  ## Lookup a bootrom address by code
  ##
  ## \param code the code
  ## \return a pointer to the data, or NULL if the code does not match any bootrom function

proc romFuncsLookup*(table: ptr uint32; count: cuint): bool {.importc: "rom_funcs_lookup".}
  ## Helper function to lookup the addresses of multiple bootrom functions
  ##
  ## This method looks up the 'codes' in the table, and convert each table entry to the looked up
  ## function pointer, if there is a function for that code in the bootrom.
  ##
  ## \param table an IN/OUT array, elements are codes on input, function pointers on success.
  ## \param count the number of elements in the table
  ## \return true if all the codes were found, and converted to function pointers, false otherwise

proc romHwordAsPtr*(romAddress: uint16): pointer {.importc: "rom_hword_as_ptr".}
  ## Convert a 16 bit pointer stored at the given rom address into a 32 bit pointer

proc romFuncLookupInline*(code: uint32): pointer {.importc: "rom_func_lookup_inline".}
  ## Lookup a bootrom function by code. This method is forceably inlined into the caller for FLASH/RAM sensitive code usage
  ##
  ## \param code the code
  ## \return a pointer to the function, or NULL if the code does not match any bootrom function

proc resetUsbBoot*(usbActivityGpioPinMask: uint32; disableInterfaceMask: uint32) {.importc: "reset_usb_boot".}
  ## Reboot the device into BOOTSEL mode
  ##
  ## This function reboots the device into the BOOTSEL mode ('usb boot").
  ##
  ## Facilities are provided to enable an "activity light" via GPIO attached LED for the USB Mass Storage Device,
  ## and to limit the USB interfaces exposed.
  ##
  ## \param usb_activity_gpio_pin_mask 0 No pins are used as per a cold boot. Otherwise a single bit set indicating which
  ##                               GPIO pin should be set to output and raised whenever there is mass storage activity
  ##                               from the host.
  ## \param disable_interface_mask value to control exposed interfaces
  ##  - 0 To enable both interfaces (as per a cold boot)
  ##  - 1 To disable the USB Mass Storage Interface
  ##  - 2 To disable the USB PICOBOOT Interface

{.pop.}
