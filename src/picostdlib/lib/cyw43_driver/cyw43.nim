##
##  This file is part of the cyw43-driver
##
##  Copyright (C) 2019-2022 George Robotics Pty Ltd
##
##  Redistribution and use in source and binary forms, with or without
##  modification, are permitted provided that the following conditions are met:
##
##  1. Redistributions of source code must retain the above copyright notice,
##     this list of conditions and the following disclaimer.
##  2. Redistributions in binary form must reproduce the above copyright notice,
##     this list of conditions and the following disclaimer in the documentation
##     and/or other materials provided with the distribution.
##  3. Any redistribution, use, or modification in source or binary form is done
##     solely for personal benefit and not for any commercial purpose or for
##     monetary gain.
##
##  THIS SOFTWARE IS PROVIDED BY THE LICENSOR AND COPYRIGHT OWNER "AS IS" AND ANY
##  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
##  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
##  DISCLAIMED. IN NO EVENT SHALL THE LICENSOR OR COPYRIGHT OWNER BE LIABLE FOR
##  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
##  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
##  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
##  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
##  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
##  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##
##  This software is also available for use with certain devices under different
##  terms, as set out in the top level LICENSE file.  For commercial licensing
##  options please email contact@georgerobotics.com.au.
##

when defined(cyw43Lwip):
  import ../lwip/[netif, dhcp]
  export netif, dhcp

when defined(cyw43Netutils):
  import ../netutils/dhcpserver

import cyw43_ll
export cyw43_ll

## * \addtogroup cyw43_driver
##
## !\{
## *
##  \file cyw43.h
## CYW43 driver interface
##
## !
##  \name Trace flags
##  \anchor CYW43_TRACE_
##
## !\{

type
  Cyw43TraceFlag* {.pure.} = enum
    ## Trace flags
    TraceAsyncEv = (0x0001)
    TraceEthTx = (0x0002)
    TraceEthRx = (0x0004)
    TraceEthFull = (0x0008)
    TraceMac = (0x0010)

## !\}
## !
##  \name Link status
##  \anchor CYW43_LINK_
##  \see status_name() to get a user readable name of the status for debug
##  \see cyw43_wifi_link_status() to get the wifi status
##  \see cyw43_tcpip_link_status() to get the overall link status
##
## !\{

type
  Cyw43LinkStatus* {.pure, size: sizeof(cint).} = enum
    LinkBadauth = -3 ## Authenticatation failure
    LinkNonet = -2   ## No matching SSID found (could be out of range, or down)
    LinkFail = -1    ## Connection failed
    LinkDown = 0     ## link is down
    LinkJoin = 1     ## Connected to wifi
    LinkNoip = 2     ## Connected to wifi, but no IP address
    LinkUp = 3       ## Connect to wifi with an IP address

{.push header: "cyw43.h".}

type
  Cyw43T* {.importc: "cyw43_t", bycopy.} = object
    cyw43Ll* {.importc: "cyw43_ll".}: Cyw43LlT
    itfState* {.importc: "itf_state".}: uint8
    traceFlags* {.importc: "trace_flags".}: uint32

    #  State for async events
    wifiScanState* {.importc: "wifi_scan_state".}: uint32
    wifiJoinState* {.importc: "wifi_join_state".}: uint32
    wifiScanEnv* {.importc: "wifi_scan_env".}: pointer
    wifiScanCb* {.importc: "wifi_scan_cb".}: Cyw43WifiScanResultCb
    initted* {.importc: "initted".}: bool

    #  Pending things to do
    pendDisassoc* {.importc: "pend_disassoc".}: bool
    pendRejoin* {.importc: "pend_rejoin".}: bool
    pendRejoinWpa* {.importc: "pend_rejoin_wpa".}: bool

    #  AP settings
    apAuth* {.importc: "ap_auth".}: uint32
    apChannel* {.importc: "ap_channel".}: uint8
    apSsidLen* {.importc: "ap_ssid_len".}: uint8
    apKeyLen* {.importc: "ap_key_len".}: uint8
    apSsid* {.importc: "ap_ssid".}: array[32, uint8]
    apKey* {.importc: "ap_key".}: array[64, uint8]
    when defined(cyw43Lwip):
      #  lwIP data
      netif* {.importc: "netif".}: array[2, Netif]
      when defined(lwipDhcp):
        dhcpClient* {.importc: "dhcp_client".}: Dhcp
    when defined(cyw43Netutils):
      dhcpServer* {.importc: "dhcp_server".}: DhcpServerT

    # mac from otp (or from cyw43_hal_generate_laa_mac if not set)
    mac* {.importc: "mac".}: array[6, uint8]

  Cyw43WifiScanResultCb* = proc (env: pointer; res: ptr Cyw43EvScanResultT): cint {.cdecl.}

var cyw43State* {.importc: "cyw43_state".}: Cyw43T

var cyw43Poll*: proc ()

var cyw43Sleep* {.importc: "cyw43_sleep".}: uint32

## !
## Initialize the driver
##
##  This method must be called before using the driver
##
##  \param self the driver state object. This should always be \c &cyw43_state
##

proc cyw43Init*(self: ptr Cyw43T) {.importc: "cyw43_init".}
## !
## Shut the driver down
##
##  This method will close the network interfaces, and free up resources
##
##  \param self the driver state object. This should always be \c &cyw43_state
##

proc cyw43Deinit*(self: ptr Cyw43T) {.importc: "cyw43_deinit".}
## !
## Send an ioctl command to cyw43
##
##  This method sends a command to cyw43.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param cmd the command to send
##  \param len the amount of data to send with the commannd
##  \param buf a buffer containing the data to send
##  \param itf the interface to use, either CYW43_ITF_STA or CYW43_ITF_AP
##  \return 0 on success
##

proc cyw43Ioctl*(self: ptr Cyw43T; cmd: uint32; len: csize_t; buf: ptr uint8;
                iface: uint32): cint {.importc: "cyw43_ioctl".}
## !
## Send a raw ethernet packet
##
##  This method sends a raw ethernet packet.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf interface to use, either CYW43_ITF_STA or CYW43_ITF_AP
##  \param len the amount of data to send
##  \param buf the data to send
##  \param is_pbuf true if buf points to an lwip struct pbuf
##  \return 0 on success
##

proc cyw43SendEthernet*(self: ptr Cyw43T; itf: cint; len: csize_t; buf: pointer;
                       isPbuf: bool): cint {.importc: "cyw43_send_ethernet".}
## !
## Set the wifi power management mode
##
##  This method sets the power management mode used by cyw43.
##  This should be called after cyw43_wifi_set_up
##
##  \see cyw43_pm_value
##  \see CYW43_DEFAULT_PM
##  \see CYW43_AGGRESSIVE_PM
##  \see CYW43_PERFORMANCE_PM
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param pm Power management value
##  \return 0 on success
##

proc cyw43WifiPm*(self: ptr Cyw43T; pm: uint32): cint {.importc: "cyw43_wifi_pm".}
## !
## Get the wifi link status
##
##  Returns the status of the wifi link.
##
##  link status        | Meaning
##  -------------------|--------
##  CYW43_LINK_DOWN    | Wifi down
##  CYW43_LINK_JOIN    | Connected to wifi
##  CYW43_LINK_FAIL    | Connection failed
##  CYW43_LINK_NONET   | No matching SSID found (could be out of range, or down)
##  CYW43_LINK_BADAUTH | Authenticatation failure
##
##  \note If the link status is negative it indicates an error
##  The wifi link status for the interface CYW43_ITF_AP is always CYW43_LINK_DOWN
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface to use, should be CYW43_ITF_STA or CYW43_ITF_AP
##  \return A integer value representing the link status
##

proc cyw43WifiLinkStatus*(self: ptr Cyw43T; itf: cint): cint {.importc: "cyw43_wifi_link_status".}
## !
## Set up and initialise wifi
##
##  This method turns on wifi and sets the country for regulation purposes.
##  The power management mode is initialised to \ref CYW43_DEFAULT_PM
##  For CYW43_ITF_AP, the access point is enabled.
##  For CYW43_ITF_STA, the TCP/IP stack is reinitialised
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface to use either CYW43_ITF_STA or CYW43_ITF_AP
##  \param up true to enable the link. Set to false to disable AP mode.
##  Setting the \em up parameter to false for CYW43_ITF_STA is ignored.
##  \param country the country code, see \ref CYW43_COUNTRY_
##
##

proc cyw43WifiSetUp*(self: ptr Cyw43T; itf: cint; up: bool; country: uint32) {.importc: "cyw43_wifi_set_up".}
## !
## Get the mac address of the device
##
##  This method returns the mac address of the interface.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface to use, either CYW43_ITF_STA or CYW43_ITF_AP
##  \param mac a buffer to receive the mac address
##  \return 0 on success
##

proc cyw43WifiGetMac*(self: ptr Cyw43T; itf: cint; mac: array[6, uint8]): cint {.importc: "cyw43_wifi_get_mac".}
## !
## Perform a wifi scan for wifi networks
##
##  Start a scan for wifi networks. Results are returned via the callback.
##
##  \note The scan is complete when \ref cyw43_wifi_scan_active return false
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param opts An instance of \ref cyw43_wifi_scan_options_t. Values in here are currently ignored.
##  \param env Pointer passed back in the callback
##  \param result_cb Callback for wifi scan results, see \ref cyw43_ev_scan_result_t
##  \return 0 on success
##

proc cyw43WifiScan*(self: ptr Cyw43T; opts: ptr Cyw43WifiScanOptionsT; env: pointer; resultCb: Cyw43WifiScanResultCb): cint {.importc: "cyw43_wifi_scan".}
## !
## Determine if a wifi scan is in progress
##
##  This method tells you if the scan is still in progress
##
##  \param self the driver state object. This should always be  \c &cyw43_state
##  \return true if a wifi scan is in progress
##

proc cyw43WifiScanActive*(self: ptr Cyw43T): bool {.inline, importc: "cyw43_wifi_scan_active".}

## !
## Connect or \em join a wifi network
##
##  Connect to a wifi network in STA (client) mode
##  After success is returned, periodically call \ref cyw43_wifi_link_status or \ref cyw43_tcpip_link_status,
##  to query the status of the link. It can take a many seconds to connect to fully join a network.
##
##  \note Call \ref cyw43_wifi_leave to dissassociate from a wifi network.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param ssid_len the length of the wifi network name
##  \param ssid A buffer containing the wifi network name
##  \param key_len The length of the wifi \em password
##  \param key A buffer containing the wifi \em password
##  \param auth_type Auth type, \see CYW43_AUTH_
##  \param bssid the mac address of the access point to connect to. This can be NULL.
##  \param channel Used to set the band of the connection. This is only used if bssid is non NULL.
##  \return 0 on success
##

proc cyw43WifiJoin*(self: ptr Cyw43T; ssidLen: csize_t; ssid: ptr uint8;
                   keyLen: csize_t; key: ptr uint8; authType: uint32;
                   bssid: ptr uint8; channel: uint32): cint {.importc: "cyw43_wifi_join".}
## !
## Dissassociate from a wifi network
##
##  This method dissassociates from a wifi network.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf The interface to disconnect, either CYW43_ITF_STA or CYW43_ITF_AP
##  \return 0 on success
##

proc cyw43WifiLeave*(self: ptr Cyw43T; itf: cint): cint {.importc: "cyw43_wifi_leave".}
## !
## Get the ssid for the access point
##
##  For access point (AP) mode, this method can be used to get the SSID name of the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param len Returns the length of the AP SSID name
##  \param buf Returns a pointer to an internal buffer containing the AP SSID name
##

proc cyw43WifiApGetSsid*(self: ptr Cyw43T; len: ptr csize_t; buf: ptr ptr uint8) {.inline, importc: "cyw43_wifi_ap_get_ssid".}

## !
## Set the the channel for the access point
##
##  For access point (AP) mode, this method can be used to set the channel used for the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param channel Wifi channel to use for the wifi access point
##

proc cyw43WifiApSetChannel*(self: ptr Cyw43T; channel: uint32) {.inline, importc: "cyw43_wifi_ap_set_channel".}

## !
## Set the ssid for the access point
##
##  For access point (AP) mode, this method can be used to set the SSID name of the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param len The length of the AP SSID name
##  \param buf A buffer containing the AP SSID name
##

proc cyw43WifiApSetSsid*(self: ptr Cyw43T; len: csize_t; buf: ptr uint8) {.inline, importc: "cyw43_wifi_ap_set_ssid".}

## !
## Set the password for the wifi access point
##
##  For access point (AP) mode, this method can be used to set the password for the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param len The length of the AP password
##  \param buf A buffer containing the AP password
##

proc cyw43WifiApSetPassword*(self: ptr Cyw43T; len: csize_t; buf: ptr uint8) {.inline, importc: "cyw43_wifi_ap_set_password".}

## !
## Set the security authorisation used in AP mode
##
##  For access point (AP) mode, this method can be used to set how access to the access point is authorised.
##
##  Auth mode                 | Meaning
##  --------------------------|--------
##  CYW43_AUTH_OPEN           | Use an open access point with no authorisation required
##  CYW43_AUTH_WPA_TKIP_PSK   | Use WPA authorisation
##  CYW43_AUTH_WPA2_AES_PSK   | Use WPA2 (preferred)
##  CYW43_AUTH_WPA2_MIXED_PSK | Use WPA2/WPA mixed (currently treated the same as \ref CYW43_AUTH_WPA2_AES_PSK)
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param auth Auth mode for the access point
##

proc cyw43WifiApSetAuth*(self: ptr Cyw43T; auth: uint32) {.inline, importc: "cyw43_wifi_ap_set_auth".}

## !
## Get the maximum number of devices (STAs) that can be associated with the wifi access point
##
##  For access point (AP) mode, this method can be used to get the maximum number of devices that can be
##  connected to the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param max_stas Returns the maximum number of devices (STAs) that can be connected to the access point
##

proc cyw43WifiApGetMaxStas*(self: ptr Cyw43T; maxStas: ptr cint) {.importc: "cyw43_wifi_ap_get_max_stas".}
## !
## Get the number of devices (STAs) associated with the wifi access point
##
##  For access point (AP) mode, this method can be used to get the number of devices and mac addresses of devices
##  connected to the wifi access point.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param num_stas Returns the number of devices (STA) connected to the access point
##  \param macs Returns the mac addresses of devies (STA) connected to the access point.
##  The supplied buffer should have enough room for 6 bytes per mac address.
##  Call \ref cyw43_wifi_ap_get_max_stas to determine how many mac addresses can be returned.
##

proc cyw43WifiApGetStas*(self: ptr Cyw43T; numStas: ptr cint; macs: ptr uint8) {.importc: "cyw43_wifi_ap_get_stas".}
## !
## Determines if the cyw43 driver been initialised
##
##  Returns true if the cyw43 driver has been initialised with a call to \ref cyw43_init
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \return True if the cyw43 driver has been initialised
##

proc cyw43IsInitialized*(self: ptr Cyw43T): bool {.inline, importc: "cyw43_is_initialized".}

## !
## Initialise the IP stack
##
##  This method must be provided by the network stack interface
##  It is called to initialise the IP stack.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface used, either CYW43_ITF_STA or CYW43_ITF_AP
##

proc cyw43CbTcpipInit*(self: ptr Cyw43T; itf: cint) {.importc: "cyw43_cb_tcpip_init".}
## !
## Deinitialise the IP stack
##
##  This method must be provided by the network stack interface
##  It is called to close the IP stack and free resources.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface used, either CYW43_ITF_STA or CYW43_ITF_AP
##

proc cyw43CbTcpipDeinit*(self: ptr Cyw43T; itf: cint) {.importc: "cyw43_cb_tcpip_deinit".}
## !
## Notify the IP stack that the link is up
##
##  This method must be provided by the network stack interface
##  It is called to notify the IP stack that the link is up.
##  This can, for example be used to request an IP address via DHCP.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface used, either CYW43_ITF_STA or CYW43_ITF_AP
##

proc cyw43CbTcpipSetLinkUp*(self: ptr Cyw43T; itf: cint) {.importc: "cyw43_cb_tcpip_set_link_up".}
## !
## Notify the IP stack that the link is down
##
##  This method must be provided by the network stack interface
##  It is called to notify the IP stack that the link is down.
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface used, either CYW43_ITF_STA or CYW43_ITF_AP
##

proc cyw43CbTcpipSetLinkDown*(self: ptr Cyw43T; itf: cint) {.importc: "cyw43_cb_tcpip_set_link_down".}
## !
## Get the link status
##
##  Returns the status of the link which is a superset of the wifi link status returned by \ref cyw43_wifi_link_status
##  \note If the link status is negative it indicates an error
##
##  link status        | Meaning
##  -------------------|--------
##  CYW43_LINK_DOWN    | Wifi down
##  CYW43_LINK_JOIN    | Connected to wifi
##  CYW43_LINK_NOIP    | Connected to wifi, but no IP address
##  CYW43_LINK_UP      | Connect to wifi with an IP address
##  CYW43_LINK_FAIL    | Connection failed
##  CYW43_LINK_NONET   | No matching SSID found (could be out of range, or down)
##  CYW43_LINK_BADAUTH | Authenticatation failure
##
##  \param self the driver state object. This should always be \c &cyw43_state
##  \param itf the interface for which to return the link status, should be CYW43_ITF_STA or CYW43_ITF_AP
##  \return A value representing the link status
##

proc cyw43TcpipLinkStatus*(self: ptr Cyw43T; itf: cint): cint {.importc: "cyw43_tcpip_link_status".}

when defined(cyw43Gpio):
  ## !
  ## Set the value of the cyw43 gpio
  ##
  ## Set the value of a cyw43 gpio.
  ##  \note Check the datasheet for the number and purpose of the cyw43 gpios.
  ##
  ##  \param self the driver state object. This should always be \c &cyw43_state
  ##  \param gpio number of the gpio to set
  ##  \param val value for the gpio
  ##  \return 0 on success
  ##
  proc cyw43GpioSet*(self: ptr Cyw43T; gpio: cint; val: bool): cint {.importc: "cyw43_gpio_set".}

  ## !
  ## Get the value of the cyw43 gpio
  ##
  ## Get the value of a cyw43 gpio.
  ##  \note Check the datasheet for the number and purpose of the cyw43 gpios.
  ##
  ##  \param self the driver state object. This should always be \c &cyw43_state
  ##  \param gpio number of the gpio to get
  ##  \param val Returns the value of the gpio
  ##  \return 0 on success
  ##
  proc cyw43GpioGet*(self: ptr Cyw43T; gpio: cint; val: ptr bool): cint {.importc: "cyw43_gpio_get".}

## !
## Return a power management value to pass to cyw43_wifi_pm
##
##  Generate the power management (PM) value to pass to cyw43_wifi_pm
##
##  pm_mode                  | Meaning
##  -------------------------|--------
##  CYW43_NO_POWERSAVE_MODE  | No power saving
##  CYW43_PM1_POWERSAVE_MODE | Aggressive power saving which reduces wifi throughput
##  CYW43_PM2_POWERSAVE_MODE | Power saving with High throughput (preferred). Saves power when there is no wifi activity for some time.
##
##  \see \ref CYW43_DEFAULT_PM
##  \see \ref CYW43_AGGRESSIVE_PM
##  \see \ref CYW43_PERFORMANCE_PM
##
##  \param pm_mode Power management mode
##  \param pm2_sleep_ret_ms The maximum time to wait before going back to sleep for CYW43_PM2_POWERSAVE_MODE mode.
##  Value measured in milliseconds and must be between 10 and 2000ms and divisible by 10
##  \param li_beacon_period Wake period is measured in beacon periods
##  \param li_dtim_period Wake interval measured in DTIMs. If this is set to 0, the wake interval is measured in beacon periods
##  \param li_assoc Wake interval sent to the access point
##

proc cyw43PmValue*(pmMode: uint8; pm2SleepRetMs: uint16; liBeaconPeriod: uint8; liDtimPeriod: uint8; liAssoc: uint8): uint32 {.inline, importc: "cyw43_pm_value".}

## !
## Default power management mode
##

let CYW43_DEFAULT_PM* {.importc: "CYW43_DEFAULT_PM".}: uint32

## !
## Aggressive power management mode for optimial power usage at the cost of performance
##

let CYW43_AGGRESSIVE_PM* {.importc: "CYW43_AGGRESSIVE_PM".}: uint32

## !
## Performance power management mode where more power is used to increase performance
##

let CYW43_PERFORMANCE_PM* {.importc: "CYW43_PERFORMANCE_PM".}: uint32

## !\} // cyw43_driver doxygen group

{.pop.}
