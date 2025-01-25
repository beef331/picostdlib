import ./async_context
export async_context

import ../helpers
{.localPassC: "-I" & picoSdkPath & "/src/rp2_common/pico_cyw43_driver/include".}
{.push header: "pico/cyw43_driver.h".}

proc cyw43DriverInit*(context: ptr AsyncContext): bool {.importc: "cyw43_driver_init".}
  ## Initializes the lower level cyw43_driver and integrates it with the provided async_context
  ##
  ## If the initialization succeeds, \ref lwip_nosys_deinit() can be called to shutdown lwIP support
  ##
  ## \param context the async_context instance that provides the abstraction for handling asynchronous work.
  ## \return true if the initialization succeeded

proc cyw43DriverDeinit*(context: ptr AsyncContext) {.importc: "cyw43_driver_deinit".}
  ## De-initialize the lowever level cyw43_driver and unhooks it from the async_context
  ##
  ## \param context the async_context the cyw43_driver support was added to via \ref cyw43_driver_init

{.pop.}
