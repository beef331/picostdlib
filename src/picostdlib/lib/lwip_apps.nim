##
##  Copyright (c) 2017 Simon Goldschmidt
##  All rights reserved.
##
##  Redistribution and use in source and binary forms, with or without modification,
##  are permitted provided that the following conditions are met:
##
##  1. Redistributions of source code must retain the above copyright notice,
##     this list of conditions and the following disclaimer.
##  2. Redistributions in binary form must reproduce the above copyright notice,
##     this list of conditions and the following disclaimer in the documentation
##     and/or other materials provided with the distribution.
##  3. The name of the author may not be used to endorse or promote products
##     derived from this software without specific prior written permission.
##
##  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
##  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
##  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
##  SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
##  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
##  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
##  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
##  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
##  IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
##  OF SUCH DAMAGE.
##
{.hint[XDeclaredButNotUsed]: off.}
{.hint[User]: off.}

import ./lwip
export lwip

when defined(nimcheck):
  include ../futharkgen/futhark_lwip_apps
else:
  import std/os, std/macros
  import ../helpers
  import futhark

  const outputPath = when defined(futharkgen): futharkGenDir / "futhark_lwip_apps.nim" else: ""

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
    sysPath picoSdkPath / "src" / $picoPlatform / "hardware_regs/include"
    sysPath picoSdkPath / "src/common/pico_base_headers/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "pico_platform/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_compiler/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_sections/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_panic/include"
    sysPath picoSdkPath / "src/rp2_common/pico_rand/include"
    sysPath cmakeBinaryDir / "generated/pico_base"
    path picoSdkPath / "src/rp2_common/pico_lwip/include"
    path picoLwipPath / "src/include"
    path picoLwipPath / "src/include/lwip/apps"
    path picoLwipPath / "contrib/apps"
    sysPath piconimCsourceDir
    path nimcacheDir
    sysPath getProjectPath()

    define "MBEDTLS_USER_CONFIG_FILE \"mbedtls_config.h\""
    define "PICO_RP2040 (1)"

    renameCallback futharkRenameCallback

    "altcp_proxyconnect.h"
    "http_client.h"
    "httpd.h"
    "lwiperf.h"
    "mdns.h"
    "mqtt.h"
    "netbiosns.h"
    "smtp.h"
    "snmp.h"
    "snmpv3.h"
    "sntp.h"
    "tftp_client.h"
    "tftp_server.h"
    "ping/ping.h"


# Nim helpers

type
  SntpOpmode* = enum
    OpmodePoll
    OpmodeListenonly

template sntpSetoperatingmode*(operatingMode: SntpOpmode) =
  sntpSetoperatingmode(operatingMode.uint8)

template mqttSubscribe*(client: ptr MqttClientT; topic: cstring; qos: uint8; cb: MqttRequestCbT, arg: pointer): ErrT =
  mqttSubUnsub(client, topic, qos, cb, arg, 1)

template mqttUnsubscribe*(client: ptr MqttClientT; topic: cstring; cb: MqttRequestCbT, arg: pointer): ErrT =
  mqttSubUnsub(client, topic, 0, cb, arg, 0)
