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

##  External interface
## *
##  \addtogroup cyw43_ll
##
## !\{
## *
##   \file cyw43_ll.h
## Low Level CYW43 driver interface
##
type
  Cyw43Ioctl* {.pure.} = enum
    ## IOCTL commands
    GetSsid = (0x32)
    GetChannel = (0x3a)
    SetDisassoc = (0x69)
    GetAntdiv = (0x7e)
    SetAntdiv = (0x81)
    SetMonitor = (0xd9)
    GetVar = (0x20c)
    SetVar = (0x20f)

  Cyw43EventType* {.pure.} = enum
    ## Async events, event_type field
    TypeSetSsid = (0)
    TypeJoin = (1)
    TypeAuth = (3)
    TypeDeauth = (5)
    TypeDeauthInd = (6)
    TypeAssoc = (7)
    TypeDisassoc = (11)
    TypeDisassocInd = (12)
    TypeLink = (16)
    TypePrune = (23)
    TypePskSup = (46)
    TypeEscanResult = (69)
    TypeCsaCompleteInd = (80)
    TypeAssocReqIe = (87)
    TypeAssonRespIe = (88)

  Cyw43EventStatus* {.pure.} = enum
    ## Event status values
    StatusSuccess = (0)
    StatusFail = (1)
    StatusTimeout = (2)
    StatusNoNetworks = (3)
    StatusAbort = (4)
    StatusNoAck = (5)
    StatusUnsolicited = (6)
    StatusAttempt = (7)
    StatusPartial = (8)
    StatusNewscan = (9)
    StatusNewassoc = (10)

  Cyw43AuthReason* {.pure.} = enum
    ## Values for AP auth setting
    AuthReasonInitialAssoc = (0)   ##  initial assoc
    AuthReasonLowRssi = (1)        ##  roamed due to low RSSI
    AuthReasonDeauth = (2)         ##  roamed due to DEAUTH indication
    AuthReasonDisassoc = (3)       ##  roamed due to DISASSOC indication
    AuthReasonBcnsLost = (4)       ##  roamed due to lost beacons
    AuthReasonFastRoamFailed = (5) ##  roamed due to fast roam failure
    AuthReasonDirectedRoam = (6)   ##  roamed due to request by AP
    AuthReasonTspecRejected = (7)  ##  roamed due to TSPEC rejection
    AuthReasonBetterAp = (8)       ##  roamed due to finding better AP

  Cyw43PruneReason* {.pure.} = enum
    ##  prune reason codes
    PruneReasonEncrMismatch = (1)   ##  encryption mismatch
    PruneReasonBcastBssid = (2)     ##  AP uses a broadcast BSSID
    PruneReasonMacDeny = (3)        ##  STA's MAC addr is in AP's MAC deny list
    PruneReasonMacNa = (4)          ##  STA's MAC addr is not in AP's MAC allow list
    PruneReasonRegPassv = (5)       ##  AP not allowed due to regulatory restriction
    PruneReasonSpctMgmt = (6)       ##  AP does not support STA locale spectrum mgmt
    PruneReasonRadar = (7)          ##  AP is on a radar channel of STA locale
    PruneReasonRsnMismatch = (8)    ##  STA does not support AP's RSN
    PruneReasonNoCommonRates = (9)  ##  No rates in common with AP
    PruneReasonBasicRates = (10)    ##  STA does not support all basic rates of BSS
    PruneReasonCcxfastPrevap = (11) ##  CCX FAST ROAM: prune previous AP
    PruneReasonCipherNa = (12)      ##  BSS's cipher not supported
    PruneReasonKnownSta = (13)      ##  AP is already known to us as a STA
    PruneReasonCcxfastDroam = (14)  ##  CCX FAST ROAM: prune unqualified AP
    PruneReasonWdsPeer = (15)       ##  AP is already known to us as a WDS peer
    PruneReasonQbssLoad = (16)      ##  QBSS LOAD - AAC is too low
    PruneReasonHomeAp = (17)        ##  prune home AP
    PruneReasonApBlocked = (18)     ##  prune blocked AP
    PruneReasonNoDiagSupport = (19) ##  prune due to diagnostic mode not supported

  Cyw43ReasonSup* {.pure.} = enum
    ## WPA failure reason codes carried in the WLC_E_PSK_SUP event
    ReasonSupOther = (0)           ##  Other reason
    ReasonSupDecryptKeyData = (1)  ##  Decryption of key data failed
    ReasonSupBadUcastWep128 = (2)  ##  Illegal use of ucast WEP128
    ReasonSupBadUcastWep40 = (3)   ##  Illegal use of ucast WEP40
    ReasonSupUnsupKeyLen = (4)     ##  Unsupported key length
    ReasonSupPwKeyCipher = (5)     ##  Unicast cipher mismatch in pairwise key
    ReasonSupMsg3TooManyIe = (6)   ##  WPA IE contains > 1 RSN IE in key msg 3
    ReasonSupMsg3IeMismatch = (7)  ##  WPA IE mismatch in key message 3
    ReasonSupNoInstallFlag = (8)   ##  INSTALL flag unset in 4-way msg
    ReasonSupMsg3NoGtk = (9)       ##  encapsulated GTK missing from msg 3
    ReasonSupGrpKeyCipher = (10)   ##  Multicast cipher mismatch in group key
    ReasonSupGrpMsg1NoGtk = (11)   ##  encapsulated GTK missing from group msg 1
    ReasonSupGtkDecryptFail = (12) ##  GTK decrypt failure
    ReasonSupSendFail = (13)       ##  message send failure
    ReasonSupDeauth = (14)         ##  received FC_DEAUTH
    ReasonSupWpaPskTmo = (15)      ##  WPA PSK 4-way handshake timeout

  Cyw43Auth* {.pure.} = enum
    ## Values used for STA and AP auth settings
    WpaAuthPsk = (0x0004)
    Wpa2AuthPsk = (0x0080)

  Cyw43AuthType* {.pure, size: sizeof(uint32).} = enum
    ## Authorization types
    ## Used when setting up an access point, or connecting to an access point
    AuthOpen = (0) ## No authorisation required (open)
    AuthWpaTkipPsk = (0x00200002) ## WPA authorisation
    AuthWpa2AesPsk = (0x00400004) ## WPA2 authorisation (preferred)
    AuthWpa2MixedPsk = (0x00400006) ## WPA2/WPA mixed authorisation

  Cyw43Itf* {.pure.} = enum
    ## Network interface types
    ItfSta = 0 ## Client interface STA mode
    ItfAp = 1  ## Access point (AP) interface mode

  Cyw43PowersaveMode* = distinct uint32
    ## Power save mode paramter passed to cyw43_ll_wifi_pm

const
  Cyw43NoPowersaveMode* = (0).Cyw43PowersaveMode  ##  No Powersave mode
  Cyw43Pm1PowersaveMode* = (1).Cyw43PowersaveMode ##  Powersave mode on specified interface without regard for throughput reduction
  Cyw43Pm2PowersaveMode* = (2).Cyw43PowersaveMode ##  Powersave mode on specified interface with High throughput

const
  ## Values used for STA and AP auth settings
  Cyw43SupDisconnected* = (0)      ##  Disconnected
  Cyw43SupConnecting* = (1)        ## Connecting
  Cyw43SupIdRequired* = (2)        ## ID Required
  Cyw43SupAuthenticating* = (3)    ##  Authenticating
  Cyw43SupAuthenticated* = (4)     ##  Authenticated
  Cyw43SupKeyxchange* = (5)        ## Key Exchange
  Cyw43SupKeyed* = (6)             ## Key Exchanged
  Cyw43SupTimeout* = (7)           ## Timeout
  Cyw43SupLastBasicState* = (8)    ##  Last Basic State
  Cyw43SupKeyxchangeWaitM1* = Cyw43SupAuthenticated
  Cyw43SupKeyxchangePrepM2* = Cyw43SupKeyxchange
  Cyw43SupKeyxchangeWaitM3* = Cyw43SupLastBasicState
  Cyw43SupKeyxchangePrepM4* = (9)  ##  Preparing to send handshake msg M4
  Cyw43SupKeyxchangeWaitG1* = (10) ##  Waiting to receive handshake msg G1
  Cyw43SupKeyxchangePrepG2* = (11) ##  Preparing to send handshake msg G2


{.push header: "cyw43_ll.h".}

## !\}
## !
## Structure to return wifi scan results
##
## !\{

type
  Cyw43EvScanResultT* {.importc: "cyw43_ev_scan_result_t", bycopy.} = object
    `0`* {.importc: "_0".}: array[5, uint32]
    bssid* {.importc: "bssid".}: array[6, uint8] ## /< access point mac address
    `1`* {.importc: "_1".}: array[2, uint16]
    ssidLen* {.importc: "ssid_len".}: uint8      ## /< length of wlan access point name
    ssid* {.importc: "ssid".}: array[32, uint8]  ## /< wlan access point name
    `2`* {.importc: "_2".}: array[5, uint32]
    channel* {.importc: "channel".}: uint16      ## /< wifi channel
    `3`* {.importc: "_3".}: uint16
    authMode* {.importc: "auth_mode".}: uint8    ## /< wifi auth mode \ref CYW43_AUTH_
    rssi* {.importc: "rssi".}: int16             ## /< signal strength


## !\}

type
  INNER_C_UNION_cyw43_ll_222* {.importc: "cyw43_async_event_t::no_name", bycopy, union.} = object
    scanResult* {.importc: "scan_result".}: Cyw43EvScanResultT

  Cyw43AsyncEventT* {.importc: "cyw43_async_event_t", bycopy.} = object
    `0`* {.importc: "_0".}: uint16
    flags* {.importc: "flags".}: uint16
    eventType* {.importc: "event_type".}: uint32
    status* {.importc: "status".}: uint32
    reason* {.importc: "reason".}: uint32
    `1`* {.importc: "_1".}: array[30, uint8]
    `interface`* {.importc: "interface".}: uint8
    `2`* {.importc: "_2".}: uint8
    u* {.importc: "u".}: INNER_C_UNION_cyw43_ll_222


## !
## wifi scan options passed to cyw43_wifi_scan
##
## !\{

type
  Cyw43WifiScanOptionsT* {.importc: "cyw43_wifi_scan_options_t", bycopy.} = object
    version* {.importc: "version".}: uint32                    ## /< version (not used)
    action* {.importc: "action".}: uint16                      ## /< action (not used)
    _* {.importc: "_".}: uint16                                ## /< not used
    ssidLen* {.importc: "ssid_len".}: uint32                   ## /< ssid length, 0=all
    ssid* {.importc: "ssid".}: array[32, uint8]                ## /< ssid name
    bssid* {.importc: "bssid".}: array[6, uint8]               ## /< bssid (not used)
    bssType* {.importc: "bss_type".}: int8                     ## /< bssid type (not used)
    scanType* {.importc: "scan_type".}: int8                   ## /< scan type 0=active, 1=passive
    nprobes* {.importc: "nprobes".}: int32                     ## /< number of probes (not used)
    activeTime* {.importc: "active_time".}: int32              ## /< active time (not used)
    passiveTime* {.importc: "passive_time".}: int32            ## /< passive time (not used)
    homeTime* {.importc: "home_time".}: int32                  ## /< home time (not used)
    channelNum* {.importc: "channel_num".}: int32              ## /< number of channels (not used)
    channelList* {.importc: "channel_list".}: array[1, uint16] ## /< channel list (not used)


## !\}

type
  Cyw43LlT* {.importc: "cyw43_ll_t", bycopy.} = object
    opaque* {.importc: "opaque".}: array[526 + 7, uint32] ##  note: array of words


proc cyw43LlInit*(self: ptr Cyw43LlT; cbData: pointer) {.importc: "cyw43_ll_init".}
proc cyw43LlDeinit*(self: ptr Cyw43LlT) {.importc: "cyw43_ll_deinit".}
proc cyw43LlBusInit*(self: ptr Cyw43LlT; mac: ptr uint8): cint {.importc: "cyw43_ll_bus_init".}
proc cyw43LlBusSleep*(self: ptr Cyw43LlT; canSleep: bool) {.importc: "cyw43_ll_bus_sleep".}
proc cyw43LlProcessPackets*(self: ptr Cyw43LlT) {.importc: "cyw43_ll_process_packets".}
proc cyw43LlIoctl*(self: ptr Cyw43LlT; cmd: uint32; len: csize_t; buf: ptr uint8;
                  iface: uint32): cint {.importc: "cyw43_ll_ioctl".}
proc cyw43LlSendEthernet*(self: ptr Cyw43LlT; itf: cint; len: csize_t; buf: pointer;
                         isPbuf: bool): cint {.importc: "cyw43_ll_send_ethernet".}
proc cyw43LlWifiOn*(self: ptr Cyw43LlT; country: uint32): cint {.importc: "cyw43_ll_wifi_on".}
proc cyw43LlWifiPm*(self: ptr Cyw43LlT; pm: uint32; pmSleepRet: uint32;
                   liBcn: uint32; liDtim: uint32; liAssoc: uint32): cint {.importc: "cyw43_ll_wifi_pm".}
proc cyw43LlWifiScan*(self: ptr Cyw43LlT; opts: ptr Cyw43WifiScanOptionsT): cint {.importc: "cyw43_ll_wifi_scan".}
proc cyw43LlWifiJoin*(self: ptr Cyw43LlT; ssidLen: csize_t; ssid: ptr uint8;
                     keyLen: csize_t; key: ptr uint8; authType: uint32;
                     bssid: ptr uint8; channel: uint32): cint {.importc: "cyw43_ll_wifi_join".}
proc cyw43LlWifiSetWpaAuth*(self: ptr Cyw43LlT) {.importc: "cyw43_ll_wifi_set_wpa_auth".}
proc cyw43LlWifiRejoin*(self: ptr Cyw43LlT) {.importc: "cyw43_ll_wifi_rejoin".}
proc cyw43LlWifiApInit*(self: ptr Cyw43LlT; ssidLen: csize_t; ssid: ptr uint8;
                       auth: uint32; keyLen: csize_t; key: ptr uint8;
                       channel: uint32): cint {.importc: "cyw43_ll_wifi_ap_init".}
proc cyw43LlWifiApSetUp*(self: ptr Cyw43LlT; up: bool): cint {.importc: "cyw43_ll_wifi_ap_set_up".}
proc cyw43LlWifiApGetStas*(self: ptr Cyw43LlT; numStas: ptr cint; macs: ptr uint8): cint {.importc: "cyw43_ll_wifi_ap_get_stas".}

when defined(cyw43Gpio):
  proc cyw43LlGpioSet*(self: ptr Cyw43LlT; gpioN: cint; gpioEn: bool): cint {.importc: "cyw43_ll_gpio_set".}
  proc cyw43LlGpioGet*(selfIn: ptr Cyw43LlT; gpioN: cint; gpioEn: ptr bool): cint {.importc: "cyw43_ll_gpio_get".}

##  Get mac address
proc cyw43LlWifiGetMac*(selfIn: ptr Cyw43LlT; `addr`: ptr uint8): cint {.importc: "cyw43_ll_wifi_get_mac".}

##  Returns true while there's work to do
proc cyw43LlHasWork*(self: ptr Cyw43LlT): bool {.importc: "cyw43_ll_has_work".}

##  Callbacks to be provided by mid-level interface
proc cyw43CbReadHostInterruptPin*(cbData: pointer): cint {.importc: "cyw43_cb_read_host_interrupt_pin".}
proc cyw43CbEnsureAwake*(cbData: pointer) {.importc: "cyw43_cb_ensure_awake".}
proc cyw43CbProcessAsyncEvent*(cbData: pointer; ev: ptr Cyw43AsyncEventT) {.importc: "cyw43_cb_process_async_event".}
proc cyw43CbProcessEthernet*(cbData: pointer; itf: cint; len: csize_t; buf: ptr uint8) {.importc: "cyw43_cb_process_ethernet".}


{.pop.}
