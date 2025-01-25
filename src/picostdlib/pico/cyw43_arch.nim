import ../pico
import ./error
import ./types
import ./async_context
import ../lib/cyw43_driver
from ../asyncdispatch import currentAsyncContext

export pico, error, types, async_context, cyw43_driver, currentAsyncContext

proc cyw43ThreadEnter*() {.importc: "cyw43_thread_enter".}
proc cyw43ThreadExit*() {.importc: "cyw43_thread_exit".}

# {.push header: "pico/cyw43_arch.h".}

proc cyw43ArchInit*(): PicoErrorCode {.importc: "cyw43_arch_init".}
  ## Initialize the CYW43 architecture
  ##
  ## This method initializes the `cyw43_driver` code and initializes the lwIP stack (if it
  ## was enabled at build time). This method must be called prior to using any other \c pico_cyw43_arch,
  ## \c cyw43_driver or lwIP functions.
  ##
  ## \note this method initializes wireless with a country code of \c PICO_CYW43_ARCH_DEFAULT_COUNTRY_CODE
  ## which defaults to \c CYW43_COUNTRY_WORLDWIDE. Worldwide settings may not give the best performance; consider
  ## setting PICO_CYW43_ARCH_DEFAULT_COUNTRY_CODE to a different value or calling \ref cyw43_arch_init_with_country
  ##
  ## By default this method initializes the cyw43_arch code's own async_context by calling
  ## \ref cyw43_arch_init_default_async_context, however the user can specify use of their own async_context
  ## by calling \ref cyw43_arch_set_async_context() before calling this method
  ##
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchInitWithCountry*(country: Cyw43Country): PicoErrorCode {.importc: "cyw43_arch_init_with_country".}
  ## Initialize the CYW43 architecture for use in a specific country
  ##
  ## This method initializes the `cyw43_driver` code and initializes the lwIP stack (if it
  ## was enabled at build time). This method must be called prior to using any other \c pico_cyw43_arch,
  ## \c cyw43_driver or lwIP functions.
  ##
  ## By default this method initializes the cyw43_arch code's own async_context by calling
  ## \ref cyw43_arch_init_default_async_context, however the user can specify use of their own async_context
  ## by calling \ref cyw43_arch_set_async_context() before calling this method
  ##
  ## \param country the country code to use (see \ref CYW43_COUNTRY_)
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchDeinit*() {.importc: "cyw43_arch_deinit".}
  ## De-initialize the CYW43 architecture
  ##
  ## This method de-initializes the `cyw43_driver` code and de-initializes the lwIP stack (if it
  ## was enabled at build time). Note this method should always be called from the same core (or RTOS
  ## task, depending on the environment) as \ref cyw43_arch_init.
  ##
  ## Additionally if the cyw43_arch is using its own async_context instance, then that instance is de-initialized.

proc cyw43ArchAsyncContext*(): ptr AsyncContext {.importc: "cyw43_arch_async_context".}
  ## Return the current async_context currently in use by the cyw43_arch code
  ##
  ## \return the async_context.

proc cyw43ArchSetAsyncContext*(context: ptr AsyncContext) {.importc: "cyw43_arch_set_async_context".}
  ## Set the async_context to be used by the cyw43_arch_init
  ##
  ## \note This method must be called before calling cyw43_arch_init or cyw43_arch_init_with_country
  ## if you wish to use a custom async_context instance.
  ##
  ## \param context the async_context to be used

proc cyw43ArchInitDefaultAsyncContext*(): ptr AsyncContext {.importc: "cyw43_arch_init_default_async_context".}
  ## Initialize the default async_context for the current cyw43_arch type
  ##
  ## This method initializes and returns a pointer to the static async_context associated
  ## with cyw43_arch. This method is called by \ref cyw43_arch_init automatically
  ## if a different async_context has not been set by \ref cyw43_arch_set_async_context
  ##
  ## \return the context or NULL if initialization failed.

proc cyw43ArchPoll*() {.importc: "cyw43_arch_poll".}
  ## Perform any processing required by the \c cyw43_driver or the TCP/IP stack
  ##
  ## This method must be called periodically from the main loop when using a
  ## \em polling style \c pico_cyw43_arch (e.g. \c pico_cyw43_arch_lwip_poll ). It
  ## may be called in other styles, but it is unnecessary to do so.

proc cyw43ArchWaitForWorkUntil*(until: AbsoluteTime) {.importc: "cyw43_arch_wait_for_work_until".}
  ## Sleep until there is cyw43_driver work to be done
  ##
  ## This method may be called by code that is waiting for an event to
  ## come from the cyw43_driver, and has no work to do, but would like
  ## to sleep without blocking any background work associated with the cyw43_driver.
  ##
  ## \param until the time to wait until if there is no work to do.

proc cyw43ArchLwipBegin*() {.inline.} = cyw43ThreadEnter()
  ## \fn cyw43_arch_lwip_begin
  ## Acquire any locks required to call into lwIP
  ##
  ## The lwIP API is not thread safe. You should surround calls into the lwIP API
  ## with calls to this method and \ref cyw43_arch_lwip_end. Note these calls are not
  ## necessary (but harmless) when you are calling back into the lwIP API from an lwIP callback.
  ## If you are using single-core polling only (pico_cyw43_arch_poll) then these calls are no-ops
  ## anyway it is good practice to call them anyway where they are necessary.
  ##
  ## \note as of SDK release 1.5.0, this is now equivalent to calling \ref pico_async_context_acquire_lock_blocking
  ## on the async_context associated with cyw43_arch and lwIP.
  ##
  ## \sa cyw43_arch_lwip_end
  ## \sa cyw43_arch_lwip_protect
  ## \sa async_context_acquire_lock_blocking
  ## \sa cyw43_arch_async_context

proc cyw43ArchLwipEnd*() {.inline.} = cyw43ThreadExit()
  ## \fn void cyw43_arch_lwip_end(void)
  ## Release any locks required for calling into lwIP
  ##
  ## The lwIP API is not thread safe. You should surround calls into the lwIP API
  ## with calls to \ref cyw43_arch_lwip_begin and this method. Note these calls are not
  ## necessary (but harmless) when you are calling back into the lwIP API from an lwIP callback.
  ## If you are using single-core polling only (pico_cyw43_arch_poll) then these calls are no-ops
  ## anyway it is good practice to call them anyway where they are necessary.
  ##
  ## \note as of SDK release 1.5.0, this is now equivalent to calling \ref async_context_release_lock
  ## on the async_context associated with cyw43_arch and lwIP.
  ##
  ## \sa cyw43_arch_lwip_begin
  ## \sa cyw43_arch_lwip_protect
  ## \sa async_context_release_lock
  ## \sa cyw43_arch_async_context

proc cyw43ArchLwipProtect*(`func`: proc (param: pointer): cint {.cdecl.}, param: pointer): cint {.inline.} =
  ## \fn int cyw43_arch_lwip_protect(int (*func)(void *param), void *param)
  ## sad Release any locks required for calling into lwIP
  ##
  ## The lwIP API is not thread safe. You can use this method to wrap a function
  ## with any locking required to call into the lwIP API. If you are using
  ## single-core polling only (pico_cyw43_arch_poll) then there are no
  ## locks to required, but it is still good practice to use this function.
  ##
  ## \param func the function ta call with any required locks held
  ## \param param parameter to pass to \c func
  ## \return the return value from \c func
  ## \sa cyw43_arch_lwip_begin
  ## \sa cyw43_arch_lwip_end
  cyw43ArchLwipBegin()
  let rc = `func`(param)
  cyw43ArchLwipEnd()
  return rc

proc cyw43ArchGetCountryCode*(): Cyw43Country {.importc: "cyw43_arch_get_country_code".}
  ## Return the country code used to initialize cyw43_arch
  ##
  ## \return the country code (see \ref CYW43_COUNTRY_)

proc cyw43ArchEnableStaMode*() {.importc: "cyw43_arch_enable_sta_mode".}
  ## Enables Wi-Fi STA (Station) mode.
  ##
  ## This enables the Wi-Fi in \em Station mode such that connections can be made to other Wi-Fi Access Points

proc cyw43ArchDisableStaMode* {.importc: "cyw43_arch_disable_sta_mode".}
  ## Disables Wi-Fi STA (Station) mode.
  ##
  ## This disables the Wi-Fi in \em Station mode, disconnecting any active connection.
  ## You should subsequently check the status by calling \ref cyw43_wifi_link_status.

proc cyw43ArchEnableApMode*(ssid: cstring; password: cstring; auth: Cyw43AuthType) {.importc: "cyw43_arch_enable_ap_mode".}
  ## Enables Wi-Fi AP (Access point) mode.
  ##
  ## This enables the Wi-Fi in \em Access \em Point mode such that connections can be made to the device by other Wi-Fi clients
  ## \param ssid the name for the access point
  ## \param password the password to use or NULL for no password.
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)

proc cyw43ArchDisableApMode*() {.importc: "cyw43_arch_disable_ap_mode".}
  ## Disables Wi-Fi AP (Access point) mode.
  ##
  ## This Disbles the Wi-Fi in \em Access \em Point mode.

proc cyw43ArchWifiConnectBlocking*(ssid: cstring; pw: cstring; auth: Cyw43AuthType): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_blocking".}
  ## Attempt to connect to a wireless access point, blocking until the network is joined or a failure is detected.
  ##
  ## \param ssid the network name to connect to
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ##
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchWifiConnectBssidBlocking*(ssid: cstring; bssid: ptr uint8; pw: cstring; auth: Cyw43AuthType): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_bssid_blocking".}
  ## Attempt to connect to a wireless access point specified by SSID and BSSID, blocking until the network is joined or a failure is detected.
  ##
  ## \param ssid the network name to connect to
  ## \param bssid the network BSSID to connect to or NULL if ignored
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ##
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchWifiConnectTimeoutMs*(ssid: cstring; pw: cstring; auth: Cyw43AuthType; timeout: uint32): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_timeout_ms".}
  ## Attempt to connect to a wireless access point, blocking until the network is joined, a failure is detected or a timeout occurs
  ##
  ## \param ssid the network name to connect to
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ## \param timeout how long to wait in milliseconds for a connection to succeed before giving up
  ##
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchWifiConnectBssidTimeoutMms*(ssid: cstring; bssid: ptr uint8; pw: cstring; auth: Cyw43AuthType; timeoutMs: uint32): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_bssid_timeout_ms".}
  ## Attempt to connect to a wireless access point specified by SSID and BSSID, blocking until the network is joined, a failure is detected or a timeout occurs
  ##
  ## \param ssid the network name to connect to
  ## \param bssid the network BSSID to connect to or NULL if ignored
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ##
  ## \return 0 if the initialization is successful, an error code otherwise \see pico_error_codes

proc cyw43ArchWifiConnectAsync*(ssid: cstring; pw: cstring; auth: Cyw43AuthType): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_async".}
  ## Start attempting to connect to a wireless access point
  ##
  ## This method tells the CYW43 driver to start connecting to an access point. You should subsequently check the
  ## status by calling \ref cyw43_wifi_link_status.
  ##
  ## \param ssid the network name to connect to
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ##
  ## \return 0 if the scan was started successfully, an error code otherwise \see pico_error_codes

proc cyw43ArchWifiConnectBssidAsync*(ssid: cstring; bssid: ptr uint8; pw: cstring; auth: Cyw43AuthType): PicoErrorCode {.importc: "cyw43_arch_wifi_connect_bssid_async".}
  ## Start attempting to connect to a wireless access point specified by SSID and BSSID
  ##
  ## This method tells the CYW43 driver to start connecting to an access point. You should subsequently check the
  ## status by calling \ref cyw43_wifi_link_status.
  ##
  ## \param ssid the network name to connect to
  ## \param bssid the network BSSID to connect to or NULL if ignored
  ## \param pw the network password or NULL if there is no password required
  ## \param auth the authorization type to use when the password is enabled. Values are \ref CYW43_AUTH_WPA_TKIP_PSK,
  ##             \ref CYW43_AUTH_WPA2_AES_PSK, or \ref CYW43_AUTH_WPA2_MIXED_PSK (see \ref CYW43_AUTH_)
  ##
  ## \return 0 if the scan was started successfully, an error code otherwise \see pico_error_codes

proc put*(wlGpio: Cyw43WlGpio; value: Value) {.importc: "cyw43_arch_gpio_put".}
  ## Set a GPIO pin on the wireless chip to a given value
  ## \note this method does not check for errors setting the GPIO. You can use the lower level \ref cyw43_gpio_set instead if you wish
  ## to check for errors.
  ##
  ## \param wl_gpio the GPIO number on the wireless chip
  ## \param value true to set the GPIO, false to clear it.

proc get*(wlGpio: Cyw43WlGpio): Value {.importc: "cyw43_arch_gpio_get".}
  ## Read the value of a GPIO pin on the wireless chip
  ## \note this method does not check for errors setting the GPIO. You can use the lower level \ref cyw43_gpio_get instead if you wish
  ## to check for errors.
  ##
  ## \param wl_gpio the GPIO number on the wireless chip
  ## \return true if the GPIO is high, false otherwise

# {.pop.}

## Nim helpers

import ../pico/time

var lwipLock* {.compileTime.}: int
var lwipLocked* = false
template withLwipLock*(body: untyped) =
  cyw43ArchLwipBegin()
  {.locks: [lwipLock].}:
    lwipLocked = true
    defer:
      lwipLocked = false
      cyw43ArchLwipEnd()
    body

proc cyw43Wait*(timeoutMs: Natural) {.inline.} = cyw43ArchWaitForWorkUntil(makeTimeoutTimeMs(timeoutMs.uint32))

template cyw43WaitCondition*(timeoutMs: Natural; condition: untyped): bool =
  var timedOut = true
  let endTime = makeTimeoutTimeMs(timeoutMs.uint32)
  if lwipLocked:
    cyw43ArchLwipEnd()
  while diffUs(getAbsoluteTime(), endTime) > 0:
    cyw43ArchWaitForWorkUntil(endTime)
    cyw43ArchLwipBegin()
    defer: cyw43ArchLwipEnd()
    if (condition):
      timedOut = false
      break
    # cyw43ArchPoll()
  # echo "poll delay: ", timeoutMs - (diffUs(getAbsoluteTime(), endTime) div 1000)
  if lwipLocked:
    cyw43ArchLwipBegin()
  timedOut

proc pollDelay*(timeoutMs: Natural; blocked: var bool) =
  discard cyw43WaitCondition(timeoutMs, (blocked == false))

# helper functions to support code using DefaultLedPin
proc init*(wlGpio: Cyw43WlGpio) = assert cyw43ArchInit() == PicoOk
proc setDir*(wlGpio: Cyw43WlGpio; direction: Direction) = discard
proc deinit*(wlGpio: Cyw43WlGpio) = cyw43ArchDeinit()
