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

import ../helpers

{.localPassC: "-I" & piconimCsourceDir.}

let
  TCP_SND_BUF* {.importc: "TCP_SND_BUF", header: "lwipopts.h".}: uint16

when defined(nimcheck):
  include ../futharkgen/futhark_lwip
else:
  import std/os, std/macros

  import futhark

  const outputPath = when defined(futharkgen): futharkGenDir / "futhark_lwip.nim" else: ""

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
    sysPath picoLwipPath / "contrib/ports/freertos/include"
    sysPath picoSdkPath / "src/common/pico_base_headers/include"
    sysPath picoSdkPath / "src" / $picoPlatform / "pico_platform/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_compiler/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_sections/include"
    sysPath picoSdkPath / "src/rp2_common/pico_platform_panic/include"
    sysPath picoSdkPath / "src/rp2_common/pico_rand/include"
    sysPath picoSdkPath / "src/rp2_common/pico_cyw43_driver/include"
    sysPath cmakeBinaryDir / "generated/pico_base"
    path picoMbedtlsPath / "include"
    path picoMbedtlsPath / "library"
    path picoSdkPath / "src/rp2_common/pico_lwip/include"
    path picoLwipPath / "src/include"
    path piconimCsourceDir
    path nimcacheDir
    path getProjectPath()

    define "MBEDTLS_USER_CONFIG_FILE \"mbedtls_config.h\""
    define "PICO_RP2040 (1)"

    renameCallback futharkRenameCallback

    "cyw43_arch_config.h" # defines what type (background, poll, freertos, none)
    "lwip/acd.h"
    "lwip/altcp.h"
    "lwip/altcp_tcp.h"
    "lwip/altcp_tls.h"
    "lwip/api.h"
    "lwip/arch.h"
    "lwip/autoip.h"
    "lwip/debug.h"
    "lwip/def.h"
    "lwip/dhcp.h"
    "lwip/dhcp6.h"
    "lwip/dns.h"
    "lwip/err.h"
    "lwip/errno.h"
    "lwip/etharp.h"
    "lwip/ethip6.h"
    "lwip/icmp.h"
    "lwip/icmp6.h"
    "lwip/if_api.h"
    "lwip/igmp.h"
    "lwip/inet.h"
    "lwip/inet_chksum.h"
    "lwip/init.h"
    "lwip/ip.h"
    "lwip/ip4.h"
    "lwip/ip4_addr.h"
    "lwip/ip4_frag.h"
    "lwip/ip6.h"
    "lwip/ip6_addr.h"
    "lwip/ip6_frag.h"
    "lwip/ip6_zone.h"
    "lwip/ip_addr.h"
    "lwip/mem.h"
    "lwip/memp.h"
    "lwip/mld6.h"
    "lwip/nd6.h"
    "lwip/netbuf.h"
    "lwip/netdb.h"
    "lwip/netif.h"
    "lwip/netifapi.h"
    "lwip/opt.h"
    "lwip/pbuf.h"
    "lwip/raw.h"
    "lwip/sio.h"
    "lwip/snmp.h"
    "lwip/sockets.h"
    "lwip/stats.h"
    "lwip/sys.h"
    "lwip/tcp.h"
    "lwip/tcpbase.h"
    "lwip/tcpip.h"
    "lwip/timeouts.h"
    "lwip/udp.h"

{.emit: "// picostdlib import: pico_lwip pico_lwip_mbedtls pico_mbedtls".}

##  Nim helpers/macros

const lwipIpv4* = when declared(LWIP_IPV4): LWIP_IPV4.bool else: false
const lwipIpv6* = when declared(LWIP_IPV6): LWIP_IPV6.bool else: false

const PBUF_NOT_FOUND* = uint16.high

proc pbufMemcmp*(p: ptr Pbuf; offset: Natural; s2: string): uint16 {.inline.} =
  assert(s2.len > 0)
  var cs2 = s2.cstring
  return p.pbufMemcmp(offset.uint16, cast[pointer](cs2[0].addr), cs2.len.uint16)

proc pbufMemfind*(p: ptr Pbuf; mem: string; startOffset: Natural): uint16 {.inline.} =
  assert(mem.len > 0)
  var cmem = mem.cstring
  return p.pbufMemfind(cast[pointer](cmem[0].addr), cmem.len.uint16, startOffset.uint16)

template altcpListenWithBacklog*(conn, backlog: untyped): untyped = altcpListenWithBacklogAndErr(conn, backlog, nil)
template altcpListen*(conn: untyped): untyped = altcpListenWithBacklogAndErr(conn, TcpDefaultListenBacklog, nil)
template altcpTcpNew*(): untyped = altcpTcpNewIpType(IpAddrTypeV4.uint8)
template altcpTcpNewIp6*(): untyped = altcpTcpNewIpType(IpAddrTypeV6.uint8)

proc getTcpState*(conn: ptr AltcpPcb): TcpState =
  result = CLOSED
  if conn != nil:
    let pcb = cast[ptr TcpPcb](conn.state)
    if pcb != nil:
      return pcb.state

when not declared(DNS_MAX_REQUESTS):
  const DNS_MAX_REQUESTS* = DNS_TABLE_SIZE

# IP helper macros

template ipGetOption*(pcb: untyped; opt: cuint): bool = (pcb.so_options and opt) != 0

# proc ipIsV4*(ipaddr: ptr IpAddrT): bool {.importc: "IP_IS_V4", header: "lwip/ip_addr.h"}
# proc ipIsV6*(ipaddr: ptr IpAddrT): bool {.importc: "IP_IS_V6", header: "lwip/ip_addr.h"}
# proc ipIsAnyTypeVal*(ipaddr: ptr IpAddrT): bool {.importc: "IP_IS_ANY_TYPE_VAL", header: "lwip/ip_addr.h".}
# proc ipGetType*(ipaddr: ptr IpAddrT): LwipIpAddrType {.importc: "IP_GET_TYPE", header: "lwip/ip_addr.h".}

# when lwipIpv4:
#   proc ip2Ip4*(ipaddr: ptr IpAddrT): ptr Ip4AddrT {.importc: "ip_2_ip4", header: "lwip/ip_addr.h".}

# when lwipIpv6:
#   proc ip2Ip6*(ipaddr: ptr IpAddrT): ptr Ip6AddrT {.importc: "ip_2_ip6", header: "lwip/ip_addr.h".}

#   proc ip6AddrHasScope*(ip6addr: ptr Ip6AddrT; scope: LwipIpv6ScopeType): bool {.importc: "ip6_addr_has_scope", header: "lwip/ip6_zone.h".}

#   proc ip6AddrLacksZone*(ip6addr: ptr Ip6AddrT; scope: LwipIpv6ScopeType): bool {.importc: "ip6_addr_lacks_zone", header: "lwip/ip6_zone.h".}

#   proc ip6AddrAssignZone*(ip6addr: ptr Ip6AddrT; scope: LwipIpv6ScopeType; netif: ptr Netif) {.importc: "ip6_addr_assign_zone", header: "lwip/ip6_zone.h"}

# warning: ipAddrNtoa is not reentrant!
when lwipIpv4 and lwipIpv6:
  discard
elif lwipIpv4:
  const ipAddrNtoa* = ip4AddrNtoa
  const ipAddrAton* = ip4AddrAton
elif lwipIpv6:
  const ipAddrNtoa* = ip6AddrNtoa
  const ipAddrAton* = ip6AddrAton

proc `$`*(ipaddr: ptr IpAddrT): string = $ipAddrNtoa(ipaddr)
proc `$`*(ipaddr: var IpAddrT): string = $ipAddrNtoa(addr(ipaddr))
proc `$`*(ipaddr: IpAddrT): string = $ipAddrNtoa(unsafeAddr(ipaddr))
