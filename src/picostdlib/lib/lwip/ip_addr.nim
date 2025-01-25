## *
##  @file
##  IP address API (common IPv4 and IPv6)
##
##
##  Copyright (c) 2001-2004 Swedish Institute of Computer Science.
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
##  This file is part of the lwIP TCP/IP stack.
##
##  Author: Adam Dunkels <adam@sics.se>
##
##

import
  ./opt, ./def, ./ip4_addr, ./ip6_addr

export ip4_addr, ip6_addr

## * @ingroup ipaddr
##  IP address types for use in ip_addr_t.type member.
##  @see tcp_new_ip_type(), udp_new_ip_type(), raw_new_ip_type().
##

type
  LwipIpAddrType* {.size: sizeof(cint).} = enum ## * IPv4
    IPADDR_TYPE_V4 = 0'u,    ## * IPv6
    IPADDR_TYPE_V6 = 6'u,    ## * IPv4+IPv6 ("dual-stack")
    IPADDR_TYPE_ANY = 46'u


when defined(lwipIpv4) and defined(lwipIpv6):
  ## *
  ##  @ingroup ipaddr
  ## A union struct for both IP version's addresses.
  ## ATTENTION: watch out for its size when adding IPv6 address scope!
  ##
  type
    INNER_C_UNION_ip_addr_76* {.importc: "ip_addr_t::no_name", header: "lwip/ip_addr.h",
                               bycopy, union.} = object
      ip6* {.importc: "ip6".}: Ip6AddrT
      ip4* {.importc: "ip4".}: Ip4AddrT

  type
    IpAddrT* {.importc: "ip_addr_t", header: "lwip/ip_addr.h", bycopy.} = object
      uAddr* {.importc: "u_addr".}: INNER_C_UNION_ip_addr_76 ## * @ref lwip_ip_addr_type
      `type`* {.importc: "type".}: uint8

  var ipAddrAnyType* {.importc: "ip_addr_any_type", header: "lwip/ip_addr.h".}: IpAddrT
  ## * @ingroup ip4addr
  ## #define IPADDR4_INIT(u32val)          { { { { u32val, 0ul, 0ul, 0ul } IPADDR6_ZONE_INIT } }, IPADDR_TYPE_V4 }
  ## * @ingroup ip4addr
  template ipaddr4Init_Bytes*(a, b, c, d: untyped): untyped =
    ipaddr4Init(pp_Htonl(lwip_Makeu32(a, b, c, d)))

  ## * @ingroup ip6addr
  ## #define IPADDR6_INIT(a, b, c, d)      { { { { a, b, c, d } IPADDR6_ZONE_INIT } }, IPADDR_TYPE_V6 }
  ## * @ingroup ip6addr
  ## #define IPADDR6_INIT_HOST(a, b, c, d) { { { { PP_HTONL(a), PP_HTONL(b), PP_HTONL(c), PP_HTONL(d) } IPADDR6_ZONE_INIT } }, IPADDR_TYPE_V6 }
  ## * @ingroup ipaddr
  template ip_Is_Any_Type_Val*(ipaddr: untyped): untyped =
    (ip_Get_Type(addr(ipaddr)) == ipaddr_Type_Any)

  ## * @ingroup ipaddr
  ## #define IPADDR_ANY_TYPE_INIT          { { { { 0ul, 0ul, 0ul, 0ul } IPADDR6_ZONE_INIT } }, IPADDR_TYPE_ANY }
  ## * @ingroup ip4addr
  template ip_Is_V4Val*(ipaddr: untyped): untyped =
    (ip_Get_Type(addr(ipaddr)) == ipaddr_Type_V4)

  ## * @ingroup ip6addr
  template ip_Is_V6Val*(ipaddr: untyped): untyped =
    (ip_Get_Type(addr(ipaddr)) == ipaddr_Type_V6)

  ## * @ingroup ip4addr
  template ip_Is_V4*(ipaddr: untyped): untyped =
    (((ipaddr) == nil) or ip_Is_V4Val((ipaddr)[]))

  ## * @ingroup ip6addr
  template ip_Is_V6*(ipaddr: untyped): untyped =
    (((ipaddr) != nil) and ip_Is_V6Val((ipaddr)[]))

  template ip_Set_Type_Val*(ipaddr, iptype: untyped): void =
    while true:
      (ipaddr).`type` = (iptype)
      if not 0:
        break

  template ip_Set_Type*(ipaddr, iptype: untyped): void =
    while true:
      if (ipaddr) != nil:
        ip_Set_Type_Val((ipaddr)[], iptype)
      if not 0:
        break

  template ip_Get_Type*(ipaddr: untyped): untyped =
    ((ipaddr).`type`)

  template ip_Addr_Raw_Size*(ipaddr: untyped): untyped =
    (if ip_Get_Type(addr(ipaddr)) == ipaddr_Type_V4: sizeof((ip4AddrT)) else: sizeof(
        (ip6AddrT)))

  template ip_Addr_Pcb_Version_Match_Exact*(pcb, ipaddr: untyped): untyped =
    (ip_Get_Type(addr(pcb.localIp)) == ip_Get_Type(ipaddr))

  template ip_Addr_Pcb_Version_Match*(pcb, ipaddr: untyped): untyped =
    (ip_Is_Any_Type_Val(pcb.localIp) or
        ip_Addr_Pcb_Version_Match_Exact(pcb, ipaddr))

  ## * @ingroup ip6addr
  ## Convert generic ip address to specific protocol version
  ##
  template ip2Ip6*(ipaddr: untyped): untyped =
    (addr(((ipaddr).uAddr.ip6)))

  ## * @ingroup ip4addr
  ## Convert generic ip address to specific protocol version
  ##
  template ip2Ip4*(ipaddr: untyped): untyped =
    (addr(((ipaddr).uAddr.ip4)))

  ## * @ingroup ip4addr
  template ip_Addr4*(ipaddr, a, b, c, d: untyped): void =
    while true:
      ip4Addr(ip2Ip4(ipaddr), a, b, c, d)
      ip_Set_Type_Val((ipaddr)[], ipaddr_Type_V4)
      if not 0:
        break

  ## * @ingroup ip6addr
  template ip_Addr6*(ipaddr, i0, i1, i2, i3: untyped): void =
    while true:
      ip6Addr(ip2Ip6(ipaddr), i0, i1, i2, i3)
      ip_Set_Type_Val((ipaddr)[], ipaddr_Type_V6)
      if not 0:
        break

  ## * @ingroup ip6addr
  template ip_Addr6Host*(ipaddr, i0, i1, i2, i3: untyped): untyped =
    ip_Addr6(ipaddr, pp_Htonl(i0), pp_Htonl(i1), pp_Htonl(i2), pp_Htonl(i3))

  template ipClearNo4*(ipaddr: untyped): void =
    while true:
      ip2Ip6(ipaddr).`addr`[1] = 0
      ip2Ip6(ipaddr).`addr`[2] = 0
      ip2Ip6(ipaddr).`addr`[3] = 0
      ip6AddrClearZone(ip2Ip6(ipaddr))
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrCopy*(dest, src: untyped): void =
    while true:
      ip_Set_Type_Val(dest, ip_Get_Type(addr(src)))
      if ip_Is_V6Val(src):
        ip6AddrCopy(ip2Ip6(addr((dest)))[], ip2Ip6(addr((src)))[])
      else:
        ip4AddrCopy(ip2Ip4(addr((dest)))[], ip2Ip4(addr((src)))[])
        ipClearNo4(addr(dest))
      if not 0:
        break

  ## * @ingroup ip6addr
  template ipAddrCopyFromIp6*(dest, src: untyped): void =
    while true:
      ip6AddrCopy(ip2Ip6(addr((dest)))[], src)
      ip_Set_Type_Val(dest, ipaddr_Type_V6)
      if not 0:
        break

  ## * @ingroup ip6addr
  template ipAddrCopyFromIp6Packed*(dest, src: untyped): void =
    while true:
      ip6AddrCopyFromPacked(ip2Ip6(addr((dest)))[], src)
      ip_Set_Type_Val(dest, ipaddr_Type_V6)
      if not 0:
        break

  ## * @ingroup ip4addr
  template ipAddrCopyFromIp4*(dest, src: untyped): void =
    while true:
      ip4AddrCopy(ip2Ip4(addr((dest)))[], src)
      ip_Set_Type_Val(dest, ipaddr_Type_V4)
      ipClearNo4(addr(dest))
      if not 0:
        break

  ## * @ingroup ip4addr
  template ipAddrSetIp4U32*(ipaddr, val: untyped): void =
    while true:
      if ipaddr:
        ip4AddrSetU32(ip2Ip4(ipaddr), val)
        ip_Set_Type(ipaddr, ipaddr_Type_V4)
        ipClearNo4(ipaddr)
      if not 0:
        break

  ## * @ingroup ip4addr
  template ipAddrSetIp4U32Val*(ipaddr, val: untyped): void =
    while true:
      ip4AddrSetU32(ip2Ip4(addr((ipaddr))), val)
      ip_Set_Type_Val(ipaddr, ipaddr_Type_V4)
      ipClearNo4(addr(ipaddr))
      if not 0:
        break

  ## * @ingroup ip4addr
  template ipAddrGetIp4U32*(ipaddr: untyped): untyped =
    (if ((ipaddr) and ip_Is_V4(ipaddr)): ip4AddrGetU32(ip2Ip4(ipaddr)) else: 0)

  ## * @ingroup ipaddr
  template ipAddrSet*(dest, src: untyped): void =
    while true:
      ip_Set_Type(dest, ip_Get_Type(src))
      if ip_Is_V6(src):
        ip6AddrSet(ip2Ip6(dest), ip2Ip6(src))
      else:
        ip4AddrSet(ip2Ip4(dest), ip2Ip4(src))
        ipClearNo4(dest)
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetIpaddr*(dest, src: untyped): untyped =
    ipAddrSet(dest, src)

  ## * @ingroup ipaddr
  template ipAddrSetZero*(ipaddr: untyped): void =
    while true:
      ip6AddrSetZero(ip2Ip6(ipaddr))
      ip_Set_Type(ipaddr, 0)
      if not 0:
        break

  ## * @ingroup ip5addr
  template ipAddrSetZeroIp4*(ipaddr: untyped): void =
    while true:
      ip6AddrSetZero(ip2Ip6(ipaddr))
      ip_Set_Type(ipaddr, ipaddr_Type_V4)
      if not 0:
        break

  ## * @ingroup ip6addr
  template ipAddrSetZeroIp6*(ipaddr: untyped): void =
    while true:
      ip6AddrSetZero(ip2Ip6(ipaddr))
      ip_Set_Type(ipaddr, ipaddr_Type_V6)
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetAny*(isIpv6, ipaddr: untyped): void =
    while true:
      if isIpv6:
        ip6AddrSetAny(ip2Ip6(ipaddr))
        ip_Set_Type(ipaddr, ipaddr_Type_V6)
      else:
        ip4AddrSetAny(ip2Ip4(ipaddr))
        ip_Set_Type(ipaddr, ipaddr_Type_V4)
        ipClearNo4(ipaddr)
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetAnyVal*(isIpv6, ipaddr: untyped): void =
    while true:
      if isIpv6:
        ip6AddrSetAny(ip2Ip6(addr((ipaddr))))
        ip_Set_Type_Val(ipaddr, ipaddr_Type_V6)
      else:
        ip4AddrSetAny(ip2Ip4(addr((ipaddr))))
        ip_Set_Type_Val(ipaddr, ipaddr_Type_V4)
        ipClearNo4(addr(ipaddr))
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetLoopback*(isIpv6, ipaddr: untyped): void =
    while true:
      if isIpv6:
        ip6AddrSetLoopback(ip2Ip6(ipaddr))
        ip_Set_Type(ipaddr, ipaddr_Type_V6)
      else:
        ip4AddrSetLoopback(ip2Ip4(ipaddr))
        ip_Set_Type(ipaddr, ipaddr_Type_V4)
        ipClearNo4(ipaddr)
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetLoopbackVal*(isIpv6, ipaddr: untyped): void =
    while true:
      if isIpv6:
        ip6AddrSetLoopback(ip2Ip6(addr((ipaddr))))
        ip_Set_Type_Val(ipaddr, ipaddr_Type_V6)
      else:
        ip4AddrSetLoopback(ip2Ip4(addr((ipaddr))))
        ip_Set_Type_Val(ipaddr, ipaddr_Type_V4)
        ipClearNo4(addr(ipaddr))
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrSetHton*(dest, src: untyped): void =
    while true:
      if ip_Is_V6(src):
        ip6AddrSetHton(ip2Ip6(dest), ip2Ip6(src))
        ip_Set_Type(dest, ipaddr_Type_V6)
      else:
        ip4AddrSetHton(ip2Ip4(dest), ip2Ip4(src))
        ip_Set_Type(dest, ipaddr_Type_V4)
        ipClearNo4(ipaddr)
      if not 0:
        break

  ## * @ingroup ipaddr
  template ipAddrGetNetwork*(target, host, netmask: untyped): void =
    while true:
      if ip_Is_V6(host):
        ip4AddrSetZero(ip2Ip4(target))
        ip_Set_Type(target, ipaddr_Type_V6)
      else:
        ip4AddrGetNetwork(ip2Ip4(target), ip2Ip4(host), ip2Ip4(netmask))
        ip_Set_Type(target, ipaddr_Type_V4)
      if not 0:
        break

  ## *
  ##  @ingroup ipaddr
  ##  @deprecated Renamed to @ref ip_addr_net_eq
  ##
  template ipAddrNetcmp*(addr1, addr2, mask: untyped): untyped =
    ipAddrNetEq((addr1), (addr2), (mask))

  ## * @ingroup ipaddr
  ##   Check if two ip addresses are share the same network, for a specific netmask.
  template ipAddrNetEq*(addr1, addr2, mask: untyped): untyped =
    (if (ip_Is_V6(addr1) and ip_Is_V6(addr2)): 0 else: ip4AddrNetEq(ip2Ip4(addr1),
        ip2Ip4(addr2), mask))

  ## *
  ##  @ingroup ipaddr
  ##  @deprecated Renamed to @ref ip_addr_eq
  ##
  template ipAddrCmp*(addr1, addr2: untyped): untyped =
    ipAddrEq((addr1), (addr2))

  ## * @ingroup ipaddr
  ##   Check if two ip addresses are equal.
  template ipAddrEq*(addr1, addr2: untyped): untyped =
    (if (ip_Get_Type(addr1) != ip_Get_Type(addr2)): 0 else: (if ip_Is_V6Val((addr1)[]): ip6AddrEq(
        ip2Ip6(addr1), ip2Ip6(addr2)) else: ip4AddrEq(ip2Ip4(addr1), ip2Ip4(addr2))))

  ## *
  ##  @ingroup ipaddr
  ##  @deprecated Renamed to @ref ip_addr_zoneless_eq
  ##
  template ipAddrCmpZoneless*(addr1, addr2: untyped): untyped =
    ipAddrZonelessEq((addr1), (addr2))

  ## * @ingroup ipaddr
  ##   Check if two ip addresses are equal, ignoring the zone.
  template ipAddrZonelessEq*(addr1, addr2: untyped): untyped =
    (if (ip_Get_Type(addr1) != ip_Get_Type(addr2)): 0 else: (if ip_Is_V6Val((addr1)[]): ip6AddrZonelessEq(
        ip2Ip6(addr1), ip2Ip6(addr2)) else: ip4AddrEq(ip2Ip4(addr1), ip2Ip4(addr2))))

  ## * @ingroup ipaddr
  ##   Check if an ip address is the 'any' address.
  template ipAddrIsany*(ipaddr: untyped): untyped =
    (if ((ipaddr) == nil): 1 else: (if (ip_Is_V6(ipaddr)): ip6AddrIsany(ip2Ip6(ipaddr)) else: ip4AddrIsany(
        ip2Ip4(ipaddr))))

  ## * @ingroup ipaddr
  ##   Check if an ip address is the 'any' address, by value.
  template ipAddrIsanyVal*(ipaddr: untyped): untyped =
    (if (ip_Is_V6Val(ipaddr)): ip6AddrIsanyVal(ip2Ip6(addr((ipaddr)))[]) else: ip4AddrIsanyVal(
        ip2Ip4(addr((ipaddr)))[]))

  ## * @ingroup ipaddr
  ##   Check if an ip address is a broadcast address.
  template ipAddrIsbroadcast*(ipaddr, netif: untyped): untyped =
    (if (ip_Is_V6(ipaddr)): 0 else: ip4AddrIsbroadcast(ip2Ip4(ipaddr), netif))

  ## * @ingroup ipaddr
  ##   Check inf an ip address is a multicast address.
  template ipAddrIsmulticast*(ipaddr: untyped): untyped =
    (if (ip_Is_V6(ipaddr)): ip6AddrIsmulticast(ip2Ip6(ipaddr)) else: ip4AddrIsmulticast(
        ip2Ip4(ipaddr)))

  ## * @ingroup ipaddr
  ##   Check inf an ip address is a loopback address.
  template ipAddrIsloopback*(ipaddr: untyped): untyped =
    (if (ip_Is_V6(ipaddr)): ip6AddrIsloopback(ip2Ip6(ipaddr)) else: ip4AddrIsloopback(
        ip2Ip4(ipaddr)))

  ## * @ingroup ipaddr
  ##   Check inf an ip address is a link-local address.
  template ipAddrIslinklocal*(ipaddr: untyped): untyped =
    (if (ip_Is_V6(ipaddr)): ip6AddrIslinklocal(ip2Ip6(ipaddr)) else: ip4AddrIslinklocal(
        ip2Ip4(ipaddr)))

  template ipAddrDebugPrint*(debug, ipaddr: untyped): void =
    while true:
      if ip_Is_V6(ipaddr):
        ip6AddrDebugPrint(debug, ip2Ip6(ipaddr))
      else:
        ip4AddrDebugPrint(debug, ip2Ip4(ipaddr))
      if not 0:
        break

  template ipAddrDebugPrintVal*(debug, ipaddr: untyped): void =
    while true:
      if ip_Is_V6Val(ipaddr):
        ip6AddrDebugPrintVal(debug, ip2Ip6(addr((ipaddr)))[])
      else:
        ip4AddrDebugPrintVal(debug, ip2Ip4(addr((ipaddr)))[])
      if not 0:
        break

  proc ipaddrNtoa*(`addr`: ptr IpAddrT): cstring {.importc: "ipaddr_ntoa", header: "lwip/ip_addr.h".}
  proc ipaddrNtoaR*(`addr`: ptr IpAddrT; buf: cstring; buflen: cint): cstring {.importc: "ipaddr_ntoa_r", header: "lwip/ip_addr.h".}
  proc ipaddrAton*(cp: cstring; `addr`: ptr IpAddrT): cint {.importc: "ipaddr_aton", header: "lwip/ip_addr.h".}
  ## * @ingroup ipaddr
  const
    IPADDR_STRLEN_MAX* = Ip6addr_Strlen_Max
  ## * @ingroup ipaddr
  template ip42Ipv4MappedIpv6*(ip6addr, ip4addr: untyped): void =
    while true:
      (ip6addr).`addr`[3] = (ip4addr).`addr`
      (ip6addr).`addr`[2] = pp_Htonl(0x0000FFFF)
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[0] = 0
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  ## * @ingroup ipaddr
  ## #define unmap_ipv4_mapped_ipv6(ip4addr, ip6addr) \
  ##   (ip4addr)->addr = (ip6addr)->addr[3];
  template ip46Addr_Any*(`type`: untyped): untyped =
    (if ((`type`) == ipaddr_Type_V6): ip6Addr_Any else: ip4Addr_Any)

else:
  template ip_Addr_Pcb_Version_Match*(`addr`, pcb: untyped): untyped =
    1

  template ip_Addr_Pcb_Version_Match_Exact*(pcb, ipaddr: untyped): untyped =
    1

  template ipAddrSetAnyVal*(isIpv6, ipaddr: untyped): untyped =
    ipAddrSetAny(isIpv6, addr((ipaddr)))

  template ipAddrSetLoopbackVal*(isIpv6, ipaddr: untyped): untyped =
    ipAddrSetLoopback(isIpv6, addr((ipaddr)))

  when defined(lwipIpv4):
    type
      IpAddrT* = Ip4AddrT
    ## #define IPADDR4_INIT(u32val)                    { u32val }
    template ipaddr4Init_Bytes*(a, b, c, d: untyped): untyped =
      ipaddr4Init(pp_Htonl(lwip_Makeu32(a, b, c, d)))

    template ip_Is_V4Val*(ipaddr: untyped): untyped =
      1

    template ip_Is_V6Val*(ipaddr: untyped): untyped =
      0

    template ip_Is_V4*(ipaddr: untyped): untyped =
      1

    template ip_Is_V6*(ipaddr: untyped): untyped =
      0

    template ip_Is_Any_Type_Val*(ipaddr: untyped): untyped =
      0

    template ip_Get_Type*(ipaddr: untyped): untyped =
      ipaddr_Type_V4

    template ip_Addr_Raw_Size*(ipaddr: untyped): untyped =
      sizeof((ip4AddrT))

    template ip2Ip4*(ipaddr: untyped): untyped =
      (ipaddr)

    template ip_Addr4*(ipaddr, a, b, c, d: untyped): untyped =
      ip4Addr(ipaddr, a, b, c, d)

    template ipAddrCopy*(dest, src: untyped): untyped =
      ip4AddrCopy(dest, src)

    template ipAddrCopyFromIp4*(dest, src: untyped): untyped =
      ip4AddrCopy(dest, src)

    template ipAddrSetIp4U32*(ipaddr, val: untyped): untyped =
      ip4AddrSetU32(ip2Ip4(ipaddr), val)

    template ipAddrSetIp4U32Val*(ipaddr, val: untyped): untyped =
      ipAddrSetIp4U32(addr((ipaddr)), val)

    template ipAddrGetIp4U32*(ipaddr: untyped): untyped =
      ip4AddrGetU32(ip2Ip4(ipaddr))

    template ipAddrSet*(dest, src: untyped): untyped =
      ip4AddrSet(dest, src)

    template ipAddrSetIpaddr*(dest, src: untyped): untyped =
      ip4AddrSet(dest, src)

    template ipAddrSetZero*(ipaddr: untyped): untyped =
      ip4AddrSetZero(ipaddr)

    template ipAddrSetZeroIp4*(ipaddr: untyped): untyped =
      ip4AddrSetZero(ipaddr)

    template ipAddrSetAny*(isIpv6, ipaddr: untyped): untyped =
      ip4AddrSetAny(ipaddr)

    template ipAddrSetLoopback*(isIpv6, ipaddr: untyped): untyped =
      ip4AddrSetLoopback(ipaddr)

    template ipAddrSetHton*(dest, src: untyped): untyped =
      ip4AddrSetHton(dest, src)

    template ipAddrGetNetwork*(target, host, mask: untyped): untyped =
      ip4AddrGetNetwork(target, host, mask)

    template ipAddrNetcmp*(addr1, addr2, mask: untyped): untyped =
      ip4AddrNetEq(addr1, addr2, mask)

    template ipAddrNetEq*(addr1, addr2, mask: untyped): untyped =
      ip4AddrNetEq(addr1, addr2, mask)

    template ipAddrCmp*(addr1, addr2: untyped): untyped =
      ip4AddrEq(addr1, addr2)

    template ipAddrEq*(addr1, addr2: untyped): untyped =
      ip4AddrEq(addr1, addr2)

    template ipAddrIsany*(ipaddr: untyped): untyped =
      ip4AddrIsany(ipaddr)

    template ipAddrIsanyVal*(ipaddr: untyped): untyped =
      ip4AddrIsanyVal(ipaddr)

    template ipAddrIsloopback*(ipaddr: untyped): untyped =
      ip4AddrIsloopback(ipaddr)

    template ipAddrIslinklocal*(ipaddr: untyped): untyped =
      ip4AddrIslinklocal(ipaddr)

    template ipAddrIsbroadcast*(`addr`, netif: untyped): untyped =
      ip4AddrIsbroadcast(`addr`, netif)

    template ipAddrIsmulticast*(ipaddr: untyped): untyped =
      ip4AddrIsmulticast(ipaddr)

    template ipAddrDebugPrint*(debug, ipaddr: untyped): untyped =
      ip4AddrDebugPrint(debug, ipaddr)

    template ipAddrDebugPrintVal*(debug, ipaddr: untyped): untyped =
      ip4AddrDebugPrintVal(debug, ipaddr)

    template ipaddrNtoa*(ipaddr: untyped): untyped =
      ip4addrNtoa(ipaddr)

    template ipaddrNtoaR*(ipaddr, buf, buflen: untyped): untyped =
      ip4addrNtoaR(ipaddr, buf, buflen)

    template ipaddrAton*(cp, `addr`: untyped): untyped =
      ip4addrAton(cp, `addr`)

    const
      IPADDR_STRLEN_MAX* = IP4ADDR_STRLEN_MAX
    template ip46Addr_Any*(`type`: untyped): untyped =
      (ip4Addr_Any)

  else:
    type
      IpAddrT* = Ip6AddrT
    ## #define IPADDR6_INIT(a, b, c, d)                { { a, b, c, d } IPADDR6_ZONE_INIT }
    ## #define IPADDR6_INIT_HOST(a, b, c, d)           { { PP_HTONL(a), PP_HTONL(b), PP_HTONL(c), PP_HTONL(d) } IPADDR6_ZONE_INIT }
    template ip_Is_V4Val*(ipaddr: untyped): untyped =
      0

    template ip_Is_V6Val*(ipaddr: untyped): untyped =
      1

    template ip_Is_V4*(ipaddr: untyped): untyped =
      0

    template ip_Is_V6*(ipaddr: untyped): untyped =
      1

    template ip_Is_Any_Type_Val*(ipaddr: untyped): untyped =
      0

    ## #define IP_SET_TYPE_VAL(ipaddr, iptype)
    ## #define IP_SET_TYPE(ipaddr, iptype)
    template ip_Get_Type*(ipaddr: untyped): untyped =
      ipaddr_Type_V6

    template ip_Addr_Raw_Size*(ipaddr: untyped): untyped =
      sizeof((ip6AddrT))

    template ip2Ip6*(ipaddr: untyped): untyped =
      (ipaddr)

    template ip_Addr6*(ipaddr, i0, i1, i2, i3: untyped): untyped =
      ip6Addr(ipaddr, i0, i1, i2, i3)

    template ip_Addr6Host*(ipaddr, i0, i1, i2, i3: untyped): untyped =
      ip_Addr6(ipaddr, pp_Htonl(i0), pp_Htonl(i1), pp_Htonl(i2), pp_Htonl(i3))

    template ipAddrCopy*(dest, src: untyped): untyped =
      ip6AddrCopy(dest, src)

    template ipAddrCopyFromIp6*(dest, src: untyped): untyped =
      ip6AddrCopy(dest, src)

    template ipAddrCopyFromIp6Packed*(dest, src: untyped): untyped =
      ip6AddrCopyFromPacked(dest, src)

    template ipAddrSet*(dest, src: untyped): untyped =
      ip6AddrSet(dest, src)

    template ipAddrSetIpaddr*(dest, src: untyped): untyped =
      ip6AddrSet(dest, src)

    template ipAddrSetZero*(ipaddr: untyped): untyped =
      ip6AddrSetZero(ipaddr)

    template ipAddrSetZeroIp6*(ipaddr: untyped): untyped =
      ip6AddrSetZero(ipaddr)

    template ipAddrSetAny*(isIpv6, ipaddr: untyped): untyped =
      ip6AddrSetAny(ipaddr)

    template ipAddrSetLoopback*(isIpv6, ipaddr: untyped): untyped =
      ip6AddrSetLoopback(ipaddr)

    template ipAddrSetHton*(dest, src: untyped): untyped =
      ip6AddrSetHton(dest, src)

    template ipAddrGetNetwork*(target, host, mask: untyped): untyped =
      ip6AddrSetZero(target)

    template ipAddrNetcmp*(addr1, addr2, mask: untyped): untyped =
      0

    template ipAddrNetEq*(addr1, addr2, mask: untyped): untyped =
      0

    template ipAddrCmp*(addr1, addr2: untyped): untyped =
      ip6AddrEq(addr1, addr2)

    template ipAddrEq*(addr1, addr2: untyped): untyped =
      ip6AddrEq(addr1, addr2)

    template ipAddrCmpZoneless*(addr1, addr2: untyped): untyped =
      ip6AddrZonelessEq(addr1, addr2)

    template ipAddrZonelessEq*(addr1, addr2: untyped): untyped =
      ip6AddrZonelessEq(addr1, addr2)

    template ipAddrIsany*(ipaddr: untyped): untyped =
      ip6AddrIsany(ipaddr)

    template ipAddrIsanyVal*(ipaddr: untyped): untyped =
      ip6AddrIsanyVal(ipaddr)

    template ipAddrIsloopback*(ipaddr: untyped): untyped =
      ip6AddrIsloopback(ipaddr)

    template ipAddrIslinklocal*(ipaddr: untyped): untyped =
      ip6AddrIslinklocal(ipaddr)

    template ipAddrIsbroadcast*(`addr`, netif: untyped): untyped =
      0

    template ipAddrIsmulticast*(ipaddr: untyped): untyped =
      ip6AddrIsmulticast(ipaddr)

    template ipAddrDebugPrint*(debug, ipaddr: untyped): untyped =
      ip6AddrDebugPrint(debug, ipaddr)

    template ipAddrDebugPrintVal*(debug, ipaddr: untyped): untyped =
      ip6AddrDebugPrintVal(debug, ipaddr)

    template ipaddrNtoa*(ipaddr: untyped): untyped =
      ip6addrNtoa(ipaddr)

    template ipaddrNtoaR*(ipaddr, buf, buflen: untyped): untyped =
      ip6addrNtoaR(ipaddr, buf, buflen)

    template ipaddrAton*(cp, `addr`: untyped): untyped =
      ip6addrAton(cp, `addr`)

    const
      IPADDR_STRLEN_MAX* = Ip6addr_Strlen_Max
    template ip46Addr_Any*(`type`: untyped): untyped =
      (ip6Addr_Any)

when defined(lwipIpv4):
  var ipAddrAny* {.importc: "ip_addr_any", header: "lwip/ip_addr.h".}: IpAddrT
  var ipAddrBroadcast* {.importc: "ip_addr_broadcast", header: "lwip/ip_addr.h".}: IpAddrT
  ## *
  ##  @ingroup ip4addr
  ## Can be used as a fixed/const ip_addr_t
  ##  for the IP wildcard.
  ## Defined to @ref IP4_ADDR_ANY when IPv4 is enabled.
  ## Defined to @ref IP6_ADDR_ANY in IPv6 only systems.
  ## Use this if you can handle IPv4 _AND_ IPv6 addresses.
  ## Use @ref IP4_ADDR_ANY or @ref IP6_ADDR_ANY when the IP
  ##  type matters.
  ##

  ## *
  ##  @ingroup ip4addr
  ## Can be used as a fixed/const ip_addr_t
  ##  for the IPv4 wildcard and the broadcast address
  ##
  let
    IP4_ADDR_ANY* = (addr(ipAddrAny))
    IP_ADDR_ANY* = IP4_ADDR_ANY
  ## *
  ##  @ingroup ip4addr
  ## Can be used as a fixed/const ip4_addr_t
  ##  for the wildcard and the broadcast address
  ##
  let
    IP4_ADDR_ANY4* = (ip2Ip4(addr(ipAddrAny)))
  ## * @ingroup ip4addr
  let
    IP_ADDR_BROADCAST* = (addr(ipAddrBroadcast))
  ## * @ingroup ip4addr
  let
    IP4_ADDR_BROADCAST* = (ip2Ip4(addr(ipAddrBroadcast)))
when defined(lwipIpv6):
  var ip6AddrAny* {.importc: "ip6_addr_any", header: "lwip/ip_addr.h".}: IpAddrT
  ## *
  ##  @ingroup ip6addr
  ## IP6_ADDR_ANY can be used as a fixed ip_addr_t
  ##  for the IPv6 wildcard address
  ##
  let
    IP6_ADDR_ANY* = (addr(ip6AddrAny))
  ## *
  ##  @ingroup ip6addr
  ## IP6_ADDR_ANY6 can be used as a fixed ip6_addr_t
  ##  for the IPv6 wildcard address
  ##
  let
    IP6_ADDR_ANY6* = (ip2Ip6(addr(ip6AddrAny)))
  when not defined(lwipIpv4):
    ## * IPv6-only configurations
    let
      IP_ADDR_ANY* = ip6AddrAny
## * @ingroup ipaddr
##   Macro representing the 'any' address.

let IP_ANY_TYPE* {.importc: "IP_ANY_TYPE", header: "lwip/ip_addr.h".}: ptr IpAddrT


## Nim helpers

proc `$`*(ip: ptr IpAddrT): string = $(ipaddrNtoa(ip))

proc `$`*(ip: var IpAddrT): string = $(ipaddrNtoa(addr(ip)))
