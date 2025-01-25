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
{.hint[XDeclaredButNotUsed]: off.}
{.hint[User]: off.}

import std/os
import ../helpers

import ./cyw43_driver/cyw43_country
export cyw43_country

const (cyw43ArchDefine, cyw43ArchLib, importLwip) = when cyw43ArchBackend == "threadsafe_background":
  ("PICO_CYW43_ARCH_THREADSAFE_BACKGROUND", "pico_cyw43_arch_lwip_threadsafe_background", true)
elif cyw43ArchBackend == "poll":
  ("PICO_CYW43_ARCH_POLL", "pico_cyw43_arch_lwip_poll", true)
elif cyw43ArchBackend == "freertos":
  ("PICO_CYW43_ARCH_FREERTOS", "pico_cyw43_arch_lwip_sys_freertos", true)
elif cyw43ArchBackend == "none":
  ("PICO_CYW43_ARCH_NONE", "pico_cyw43_arch_none", false)
else:
  {.error: "cyw43ArchBackend was set to an invalid value: " & cyw43ArchBackend.}
  ("PICO_CYW43_ARCH_NONE", "pico_cyw43_arch_none", false)

static:
  # echo (cyw43ArchDefine, cyw43ArchLib, importLwip)
  createDir(nimcacheDir)
  writeFile(nimcacheDir / "cyw43_arch_config.h", "#define " & cyw43ArchDefine & " (1)\n#define PICO_RP2040 (" & (when picoRp2040: "1" else: "0") & ")")

when cyw43ArchBackend == "freertos":
  import ./freertos
  export freertos

when importLwip:
  import ./lwip
  export lwip

when defined(nimcheck):
  include ../futharkgen/futhark_cyw43_driver
else:
  import std/macros
  import std/strutils
  import futhark

  const outputPath = when defined(futharkgen): futharkGenDir / "futhark_cyw43_driver.nim" else: ""

  proc futharkRenameCallbackCyw43(name: string; kind: string; partof: string): string =
    var name = name.replace("CYW43_PERFORMANCE_PM", "CYW43_PERFORMANCE_PM_ignore")
    return futharkRenameCallback(name, kind, partof)

  importc:
    outputPath outputPath
    compilerArg "--target=arm-none-eabi"
    compilerArg "-mthumb"
    compilerArg "-mcpu=cortex-m0plus"
    compilerArg "-fsigned-char"
    compilerArg "-fshort-enums" # needed to get the right enum size

    sysPath futhark.getClangIncludePath()
    sysPath armSysrootInclude
    sysPath armInstallInclude
    sysPath cmakeBinaryDir / "generated/pico_base"
    sysPath picoSdkPath / "src/common/pico_base_headers/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "hardware_regs/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "hardware_structs/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_base/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_irq/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_gpio/include"
    sysPath picoSdkPath / "src/rp2_common/hardware_timer/include"
    sysPath picoSdkPath / "src/rp2_common/pico_rand/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "pico_platform/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_compiler/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_sections/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_panic/include"
    sysPath picoSdkPath / "src/common/pico_time/include"
    sysPath picoSdkPath / "src/rp2_common/pico_cyw43_driver/include"
    sysPath picoSdkPath / "src/rp2_common/pico_lwip/include"
    sysPath picoSdkPath / "src/rp2_common/pico_cyw43_arch/include"
    sysPath picoSdkPath / "lib/lwip/src/include"
    # sysPath picoSdkPath / "src/rp2350/hardware_structs/include" # TODO set PICO_RP2040 after picoPlatform
    # sysPath picoSdkPath / "src/rp2350/hardware_regs/include" # TODO set PICO_RP2040 after picoPlatform
    path picoSdkPath / "lib/cyw43-driver/src"
    sysPath piconimCsourceDir
    path nimcacheDir
    sysPath getProjectPath()

    define "MBEDTLS_USER_CONFIG_FILE \"mbedtls_config.h\""

    renameCallback futharkRenameCallbackCyw43

    "cyw43_arch_config.h" # defines what type (background, poll, freertos, none)
    "cyw43.h"

{.emit: ["// picostdlib import: ", cyw43ArchLib].}

type
  Cyw43PowersaveMode* = uint32

  Cyw43TraceFlag* {.pure.} = enum
    ## Trace flags
    TraceAsyncEv = Cyw43TraceAsyncEv
    TraceEthTx = Cyw43TraceEthTx
    TraceEthRx = Cyw43TraceEthRx
    TraceEthFull = Cyw43TraceEthFull
    TraceMac = Cyw43TraceMac

  Cyw43LinkStatus* {.pure.} = enum
    LinkBadauth = Cyw43LinkBadauth ## Authenticatation failure
    LinkNonet = Cyw43LinkNonet     ## No matching SSID found (could be out of range, or down)
    LinkFail = Cyw43LinkFail       ## Connection failed
    LinkDown = Cyw43LinkDown       ## link is down
    LinkJoin = Cyw43LinkJoin       ## Connected to wifi
    LinkNoip = Cyw43LinkNoip       ## Connected to wifi, but no IP address
    LinkUp = Cyw43LinkUp           ## Connect to wifi with an IP address

  Cyw43Ioctl* {.pure.} = enum
    ## IOCTL commands
    GetSsid = Cyw43IoctlGetSsid
    GetChannel = Cyw43IoctlGetChannel
    SetDisassoc = Cyw43IoctlSetDisassoc
    GetAntdiv = Cyw43IoctlGetAntdiv
    SetAntdiv = Cyw43IoctlSetAntdiv
    SetMonitor = Cyw43IoctlSetMonitor
    GetVar = Cyw43IoctlGetVar
    SetVar = Cyw43IoctlSetVar

  Cyw43EventType* {.pure.} = enum
    ## Async events, event_type field
    EvSetSsid = Cyw43evsetssid
    EvJoin = Cyw43evjoin
    EvAuth = Cyw43evauth
    EvDeauth = Cyw43EvDeauth
    EvDeauthInd = Cyw43EvDeauthInd
    EvAssoc = Cyw43EvAssoc
    EvDisassoc = Cyw43EvDisassoc
    EvDisassocInd = Cyw43EvDisassocInd
    EvLink = Cyw43EvLink
    EvPrune = Cyw43EvPrune
    EvPskSup = Cyw43EvPskSup
    EvEscanResult = Cyw43EvEscanResult
    EvCsaCompleteInd = Cyw43EvCsaCompleteInd
    EvAssocReqIe = Cyw43EvAssocReqIe
    EvAssocRespIe = Cyw43EvAssocRespIe

  Cyw43EventStatus* {.pure.} = enum
    ## Event status values
    StatusSuccess = Cyw43StatusSuccess
    StatusFail = Cyw43StatusFail
    StatusTimeout = Cyw43StatusTimeout
    StatusNoNetworks = Cyw43StatusNoNetworks
    StatusAbort = Cyw43StatusAbort
    StatusNoAck = Cyw43StatusNoAck
    StatusUnsolicited = Cyw43StatusUnsolicited
    StatusAttempt = Cyw43StatusAttempt
    StatusPartial = Cyw43StatusPartial
    StatusNewscan = Cyw43StatusNewscan
    StatusNewassoc = Cyw43StatusNewassoc

  Cyw43AuthReason* {.pure.} = enum
    ## Values for AP auth setting
    AuthReasonInitialAssoc = Cyw43ReasonInitialAssoc     ##  initial assoc
    AuthReasonLowRssi = Cyw43ReasonLowRssi               ##  roamed due to low RSSI
    AuthReasonDeauth = Cyw43ReasonDeauth                 ##  roamed due to DEAUTH indication
    AuthReasonDisassoc = Cyw43ReasonDisassoc             ##  roamed due to DISASSOC indication
    AuthReasonBcnsLost = Cyw43ReasonBcnsLost             ##  roamed due to lost beacons
    AuthReasonFastRoamFailed = Cyw43ReasonFastRoamFailed ##  roamed due to fast roam failure
    AuthReasonDirectedRoam = Cyw43ReasonDirectedRoam     ##  roamed due to request by AP
    AuthReasonTspecRejected = Cyw43ReasonTspecRejected   ##  roamed due to TSPEC rejection
    AuthReasonBetterAp = Cyw43ReasonBetterAp             ##  roamed due to finding better AP

  Cyw43PruneReason* {.pure.} = enum
    ##  prune reason codes
    PruneReasonEncrMismatch = Cyw43ReasonPruneEncrMismatch   ##  encryption mismatch
    PruneReasonBcastBssid = Cyw43ReasonPruneBcastBssid       ##  AP uses a broadcast BSSID
    PruneReasonMacDeny = Cyw43ReasonPruneMacDeny             ##  STA's MAC addr is in AP's MAC deny list
    PruneReasonMacNa = Cyw43ReasonPruneMacNa                 ##  STA's MAC addr is not in AP's MAC allow list
    PruneReasonRegPassv = Cyw43ReasonPruneRegPassv           ##  AP not allowed due to regulatory restriction
    PruneReasonSpctMgmt = Cyw43ReasonPruneSpctMgmt           ##  AP does not support STA locale spectrum mgmt
    PruneReasonRadar = Cyw43ReasonPruneRadar                 ##  AP is on a radar channel of STA locale
    PruneReasonRsnMismatch = Cyw43ReasonRsnMismatch          ##  STA does not support AP's RSN
    PruneReasonNoCommonRates = Cyw43ReasonPruneNoCommonRates ##  No rates in common with AP
    PruneReasonBasicRates = Cyw43ReasonPruneBasicRates       ##  STA does not support all basic rates of BSS
    PruneReasonCcxfastPrevap = Cyw43ReasonPruneCcxfastPrevap ##  CCX FAST ROAM: prune previous AP
    PruneReasonCipherNa = Cyw43ReasonPruneCipherNa           ##  BSS's cipher not supported
    PruneReasonKnownSta = Cyw43ReasonPruneKnownSta           ##  AP is already known to us as a STA
    PruneReasonCcxfastDroam = Cyw43ReasonPruneCcxfastDroam   ##  CCX FAST ROAM: prune unqualified AP
    PruneReasonWdsPeer = Cyw43ReasonPruneWdsPeer             ##  AP is already known to us as a WDS peer
    PruneReasonQbssLoad = Cyw43ReasonPruneQbssLoad           ##  QBSS LOAD - AAC is too low
    PruneReasonHomeAp = Cyw43ReasonPruneHomeAp               ##  prune home AP
    PruneReasonApBlocked = Cyw43ReasonPruneApBlocked         ##  prune blocked AP
    PruneReasonNoDiagSupport = Cyw43ReasonPruneNoDiagSupport ##  prune due to diagnostic mode not supported

  Cyw43ReasonSup* {.pure.} = enum
    ## WPA failure reason codes carried in the WLC_E_PSK_SUP event
    ReasonSupOther = Cyw43ReasonSupOther                   ##  Other reason
    ReasonSupDecryptKeyData = Cyw43ReasonSupDecryptKeyData ##  Decryption of key data failed
    ReasonSupBadUcastWep128 = Cyw43ReasonSupBadUcastWep128 ##  Illegal use of ucast WEP128
    ReasonSupBadUcastWep40 = Cyw43ReasonSupBadUcastWep40   ##  Illegal use of ucast WEP40
    ReasonSupUnsupKeyLen = Cyw43ReasonSupUnsupKeyLen       ##  Unsupported key length
    ReasonSupPwKeyCipher = Cyw43ReasonSupPwKeyCipher       ##  Unicast cipher mismatch in pairwise key
    ReasonSupMsg3TooManyIe = Cyw43ReasonSupMsg3TooManyIe   ##  WPA IE contains > 1 RSN IE in key msg 3
    ReasonSupMsg3IeMismatch = Cyw43ReasonSupMsg3IeMismatch ##  WPA IE mismatch in key message 3
    ReasonSupNoInstallFlag = Cyw43ReasonSupNoInstallFlag   ##  INSTALL flag unset in 4-way msg
    ReasonSupMsg3NoGtk = Cyw43ReasonSupMsg3NoGtk           ##  encapsulated GTK missing from msg 3
    ReasonSupGrpKeyCipher = Cyw43ReasonSupGrpKeyCipher     ##  Multicast cipher mismatch in group key
    ReasonSupGrpMsg1NoGtk = Cyw43ReasonSupGrpMsg1NoGtk     ##  encapsulated GTK missing from group msg 1
    ReasonSupGtkDecryptFail = Cyw43ReasonSupGtkDecryptFail ##  GTK decrypt failure
    ReasonSupSendFail = Cyw43ReasonSupSendFail             ##  message send failure
    ReasonSupDeauth = Cyw43ReasonSupDeauth                 ##  received FC_DEAUTH
    ReasonSupWpaPskTmo = Cyw43ReasonSupWpaPskTmo           ##  WPA PSK 4-way handshake timeout

  # Cyw43Auth* {.pure.} = enum
  #   ## Values used for STA and AP auth settings
  #   WpaAuthPsk = Cyw43WpaAuthPsk
  #   Wpa2AuthPsk = Cyw43Wpa2AuthPsk

  Cyw43AuthType* {.pure, size: sizeof(uint32).} = enum
    ## Authorization types
    ## Used when setting up an access point, or connecting to an access point
    AuthOpen = Cyw43AuthOpen ## No authorisation required (open)
    AuthWpaTkipPsk = Cyw43AuthWpaTkipPsk ## WPA authorisation
    AuthWpa2AesPsk = Cyw43AuthWpa2AesPsk ## WPA2 authorisation (preferred)
    AuthWpa2MixedPsk = Cyw43AuthWpa2MixedPsk ## WPA2/WPA mixed authorisation

  Cyw43Itf* {.pure, size: sizeof(cuint).} = enum
    ## Network interface types
    ItfSta = Cyw43itfsta ## Client interface STA mode
    ItfAp = Cyw43itfap   ## Access point (AP) interface mode

# {.push header: "cyw43.h".}

template cyw43WifiPm*(self: ptr Cyw43T; pm: Cyw43PowersaveMode): cint = cyw43WifiPm(self, pm.uint32)

proc cyw43WifiScanActive*(self: ptr Cyw43T): bool {.inline.} =
  ## Determine if a wifi scan is in progress
  ##
  ## This method tells you if the scan is still in progress
  ##
  ## \param self the driver state object. This should always be  \c &cyw43_state
  ## \return true if a wifi scan is in progress
  self.wifi_scan_state == 1

proc cyw43WifiApGetSsid*(self: ptr Cyw43T; len: ptr csize_t; buf: ptr ptr uint8) {.inline.} =
  ## Get the ssid for the access point
  ##
  ## For access point (AP) mode, this method can be used to get the SSID name of the wifi access point.
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \param len Returns the length of the AP SSID name
  ## \param buf Returns a pointer to an internal buffer containing the AP SSID name
  len[] = self.ap_ssid_len
  buf[] = self.ap_ssid[0].addr

proc cyw43WifiApGetAuth*(self: ptr Cyw43T): Cyw43AuthType {.inline.} =
  ## Get the security authorisation used in AP mode
  ##
  ## For access point (AP) mode, this method can be used to get the security authorisation mode.
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \return the current security authorisation mode for the access point
  return cast[Cyw43AuthType](self.ap_auth.uint32)

proc cyw43WifiApSetChannel*(self: ptr Cyw43T; channel: uint32) {.inline.} =
  ## Set the the channel for the access point
  ##
  ## For access point (AP) mode, this method can be used to set the channel used for the wifi access point.
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \param channel Wifi channel to use for the wifi access point
  self.ap_channel = channel.uint8

proc cyw43WifiApSetSsid*(self: ptr Cyw43T; len: csize_t; buf: ptr uint8) {.inline.} =
  ## Set the ssid for the access point
  ##
  ## For access point (AP) mode, this method can be used to set the SSID name of the wifi access point.
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \param len The length of the AP SSID name
  ## \param buf A buffer containing the AP SSID name
  self.ap_ssid_len = min(len, sizeof(self.ap_ssid).csize_t).uint8
  copyMem(self.ap_ssid[0].addr, buf, self.ap_ssid_len)

proc cyw43WifiApSetPassword*(self: ptr Cyw43T; len: csize_t; buf: ptr uint8) {.inline.} =
  ## Set the password for the wifi access point
  ##
  ## For access point (AP) mode, this method can be used to set the password for the wifi access point.
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \param len The length of the AP password
  ## \param buf A buffer containing the AP password
  self.ap_key_len = min(len, sizeof(self.ap_key).csize_t).uint8
  copyMem(self.ap_key[0].addr, buf, self.ap_key_len)

# TODO: When pico-sdk updates, remove the uint8 here
# Current stable pico-sdk uses a version of cyw43_driver that has it set to uint8
# For now, make it compile with both
proc cyw43WifiApSetAuth*(self: ptr Cyw43T; auth: Cyw43AuthType|uint32|uint8) {.inline.} =
  ## Set the security authorisation used in AP mode
  ##
  ## For access point (AP) mode, this method can be used to set how access to the access point is authorised.
  ##
  ## Auth mode                 | Meaning
  ## --------------------------|--------
  ## CYW43_AUTH_OPEN           | Use an open access point with no authorisation required
  ## CYW43_AUTH_WPA_TKIP_PSK   | Use WPA authorisation
  ## CYW43_AUTH_WPA2_AES_PSK   | Use WPA2 (preferred)
  ## CYW43_AUTH_WPA2_MIXED_PSK | Use WPA2/WPA mixed (currently treated the same as \ref CYW43_AUTH_WPA2_AES_PSK)
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \param auth Auth mode for the access point
  self.ap_auth = typeof(self.ap_auth)(auth)

proc cyw43IsInitialized*(self: ptr Cyw43T): bool {.inline.} =
  ## Determines if the cyw43 driver been initialised
  ##
  ## Returns true if the cyw43 driver has been initialised with a call to \ref cyw43_init
  ##
  ## \param self the driver state object. This should always be \c &cyw43_state
  ## \return True if the cyw43 driver has been initialised
  return self.initted

func cyw43PmValue*(pmMode: Cyw43PowersaveMode; pm2SleepRetMs: uint16; liBeaconPeriod: uint8; liDtimPeriod: uint8; liAssoc: uint8): Cyw43PowersaveMode {.inline.} =
  ## Return a power management value to pass to cyw43_wifi_pm
  ##
  ## Generate the power management (PM) value to pass to cyw43_wifi_pm
  ##
  ## pm_mode                  | Meaning
  ## -------------------------|--------
  ## CYW43_NO_POWERSAVE_MODE  | No power saving
  ## CYW43_PM1_POWERSAVE_MODE | Aggressive power saving which reduces wifi throughput
  ## CYW43_PM2_POWERSAVE_MODE | Power saving with High throughput (preferred). Saves power when there is no wifi activity for some time.
  ##
  ## \see \ref CYW43_DEFAULT_PM
  ## \see \ref CYW43_AGGRESSIVE_PM
  ## \see \ref CYW43_PERFORMANCE_PM
  ##
  ## \param pm_mode Power management mode
  ## \param pm2_sleep_ret_ms The maximum time to wait before going back to sleep for CYW43_PM2_POWERSAVE_MODE mode.
  ## Value measured in milliseconds and must be between 10 and 2000ms and divisible by 10
  ## \param li_beacon_period Wake period is measured in beacon periods
  ## \param li_dtim_period Wake interval measured in DTIMs. If this is set to 0, the wake interval is measured in beacon periods
  ## \param li_assoc Wake interval sent to the access point
  return Cyw43PowersaveMode(
    liAssoc shl 20 or # listen interval sent to ap
    liDtimPeriod shl 16 or
    liBeaconPeriod shl 12 or
    (pm2SleepRetMs div 10) shl 4 or # cyw43_ll_wifi_pm multiplies this by 10
    pmMode.uint8 # CYW43_PM2_POWERSAVE_MODE etc
  )

const
  Cyw43NonePm* = cyw43PmValue(CYW43_NO_POWERSAVE_MODE, 10, 0, 0, 0)
    ## No power management

  Cyw43AggressivePm* = cyw43PmValue(CYW43_PM1_POWERSAVE_MODE, 10, 0, 0, 0)
    ## Aggressive power management mode for optimial power usage at the cost of performance

  Cyw43PerformancePm* = cyw43PmValue(CYW43_PM2_POWERSAVE_MODE, 200, 1, 1, 10)
    ## Performance power management mode where more power is used to increase performance

  Cyw43DefaultPm* = Cyw43PerformancePm
    ## Default power management mode

# {.pop.}
