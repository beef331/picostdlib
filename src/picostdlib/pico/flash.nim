import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_flash/include".}
{.push header: "pico/flash.h".}

type
  FlashSafetyHelper* {.importc: "flash_safety_helper_t".} = object
    coreInitDeinit* {.importc: "core_init_deinit".}: proc (init: bool): bool
    enterSafeZoneTimeoutMs* {.importc: "enter_safe_zone_timeout_ms".}: proc (timeoutMs: uint32): cint
    exitSafeZoneTimeoutMs* {.importc: "exit_safe_zone_timeout_ms".}: proc (timeoutMs: uint32): cint

proc flashSafeExecuteCoreInit*(): bool {.importc: "flash_safe_execute_core_init".}
  ## Initialize a core such that the other core can lock it out during \ref flash_safe_execute.
  ##
  ## \note This is not necessary for FreeRTOS SMP, but should be used when launching via \ref multicore_launch_core1
  ## \return true on success; there is no need to call \ref flash_safe_execute_core_deinit() on failure.

proc flashSafeExecuteCoreDeinit*(): bool {.importc: "flash_safe_execute_core_deinit".}
  ## De-initialize work done by \ref flash_safe_execute_core_init
  ##
  ## \return true on success

proc flashSafeExecute*(`func`: proc (param: pointer); param: pointer; enterExitTimeoutMs: uint32): cint {.importc: "flash_safe_execute".}
  ## Execute a function with IRQs disabled and with the other core also not executing/reading flash
  ##
  ## \param func the function to call
  ## \param param the parameter to pass to the function
  ## \param enter_exit_timeout_ms the timeout for each of the enter/exit phases when coordinating with the other core
  ##
  ## \return PICO_OK on success (the function will have been called).
  ##         PICO_TIMEOUT on timeout (the function may have been called).
  ##         PICO_ERROR_NOT_PERMITTED if safe execution is not possible (the function will not have been called).
  ##         PICO_ERROR_INSUFFICIENT_RESOURCES if the method fails due to dynamic resource exhaustion (the function will not have been called)
  ## \note if \ref PICO_FLASH_ASSERT_ON_UNSAFE is 1, this function will assert in debug mode vs returning
  ##       PICO_ERROR_NOT_PERMITTED

proc getFlashSafetyHelper*(): ptr FlashSafetyHelper {.importc: "get_flash_safety_helper".}
  ## Internal method to return the flash safety helper implementation.
  ##
  ## Advanced users can provide their own implementation of this function to perform
  ## different inter-core coordination before disabling XIP mode.
  ##
  ## @return the \ref flash_safety_helper_t

{.pop.}
