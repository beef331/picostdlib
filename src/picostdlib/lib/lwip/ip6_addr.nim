## *
##  @file
##
##  IPv6 addresses.
##
##
##  Copyright (c) 2010 Inico Technologies Ltd.
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
##  Author: Ivan Delamer <delamer@inicotech.com>
##
##  Structs and macros for handling IPv6 addresses.
##
##  Please coordinate changes and requests with Ivan Delamer
##  <delamer@inicotech.com>
##

import ./opt, ./def

## * This is the aligned version of ip6_addr_t,
##     used as local variable, on the stack, etc.
type
  Ip6Addr* {.importc: "ip6_addr", header: "lwip/ip6_addr.h", bycopy.} = object
    `addr`* {.importc: "addr".}: array[4, uint32]
    when defined(lwipIpv6Scopes):
      zone* {.importc: "zone".}: uint8

  ## * IPv6 address
  Ip6AddrT* = Ip6Addr

when defined(lwipIpv6):
  import
    ./ip6_zone


  ## * Set an IPv6 partial address given by byte-parts
  template ip6Addr_Part*(ip6addr, index, a, b, c, d: untyped): untyped =
    (ip6addr).`addr`[index] = pp_Htonl(lwip_Makeu32(a, b, c, d))

  ## * Set a full IPv6 address by passing the 4 u32_t indices in network byte order
  ##     (use PP_HTONL() for constants)
  template ip6Addr*(ip6addr, idx0, idx1, idx2, idx3: untyped): void =
    while true:
      (ip6addr).`addr`[0] = idx0
      (ip6addr).`addr`[1] = idx1
      (ip6addr).`addr`[2] = idx2
      (ip6addr).`addr`[3] = idx3
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  ## * Access address in 16-bit block
  template ip6Addr_Block1*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[0]) shr 16) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block2*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[0])) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block3*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[1]) shr 16) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block4*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[1])) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block5*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[2]) shr 16) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block6*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[2])) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block7*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[3]) shr 16) and 0xffff))

  ## * Access address in 16-bit block
  template ip6Addr_Block8*(ip6addr: untyped): untyped =
    ((u16T)((lwipHtonl((ip6addr).`addr`[3])) and 0xffff))

  ## * Copy IPv6 address - faster than ip6_addr_set: no NULL check
  template ip6AddrCopy*(dest, src: untyped): void =
    while true:
      (dest).`addr`[0] = (src).`addr`[0]
      (dest).`addr`[1] = (src).`addr`[1]
      (dest).`addr`[2] = (src).`addr`[2]
      (dest).`addr`[3] = (src).`addr`[3]
      ip6AddrCopyZone((dest), (src))
      if not 0:
        break

  ## * Safely copy one IPv6 address to another (src may be NULL)
  template ip6AddrSet*(dest, src: untyped): void =
    while true:
      (dest).`addr`[0] = if (src) == nil: 0 else: (src).`addr`[0]
      (dest).`addr`[1] = if (src) == nil: 0 else: (src).`addr`[1]
      (dest).`addr`[2] = if (src) == nil: 0 else: (src).`addr`[2]
      (dest).`addr`[3] = if (src) == nil: 0 else: (src).`addr`[3]
      ip6AddrSetZone((dest), if (src) == nil: ip6No_Zone else: ip6AddrZone(src))
      if not 0:
        break

  ## * Copy packed IPv6 address to unpacked IPv6 address; zone is not set
  template ip6AddrCopyFromPacked*(dest, src: untyped): void =
    while true:
      (dest).`addr`[0] = (src).`addr`[0]
      (dest).`addr`[1] = (src).`addr`[1]
      (dest).`addr`[2] = (src).`addr`[2]
      (dest).`addr`[3] = (src).`addr`[3]
      ip6AddrClearZone(addr(dest))
      if not 0:
        break

  ## * Copy unpacked IPv6 address to packed IPv6 address; zone is lost
  template ip6AddrCopyToPacked*(dest, src: untyped): void =
    while true:
      (dest).`addr`[0] = (src).`addr`[0]
      (dest).`addr`[1] = (src).`addr`[1]
      (dest).`addr`[2] = (src).`addr`[2]
      (dest).`addr`[3] = (src).`addr`[3]
      if not 0:
        break

  ## * Set complete address to zero
  template ip6AddrSetZero*(ip6addr: untyped): void =
    while true:
      (ip6addr).`addr`[0] = 0
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[2] = 0
      (ip6addr).`addr`[3] = 0
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  ## * Set address to ipv6 'any' (no need for lwip_htonl())
  template ip6AddrSetAny*(ip6addr: untyped): untyped =
    ip6AddrSetZero(ip6addr)

  ## * Set address to ipv6 loopback address
  template ip6AddrSetLoopback*(ip6addr: untyped): void =
    while true:
      (ip6addr).`addr`[0] = 0
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[2] = 0
      (ip6addr).`addr`[3] = pp_Htonl(0x00000001)
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  ## * Safely copy one IPv6 address to another and change byte order
  ##  from host- to network-order.
  template ip6AddrSetHton*(dest, src: untyped): void =
    while true:
      (dest).`addr`[0] = if (src) == nil: 0 else: lwipHtonl((src).`addr`[0])
      (dest).`addr`[1] = if (src) == nil: 0 else: lwipHtonl((src).`addr`[1])
      (dest).`addr`[2] = if (src) == nil: 0 else: lwipHtonl((src).`addr`[2])
      (dest).`addr`[3] = if (src) == nil: 0 else: lwipHtonl((src).`addr`[3])
      ip6AddrSetZone((dest), if (src) == nil: ip6No_Zone else: ip6AddrZone(src))
      if not 0:
        break

  ## * @deprecated Renamed to @ref ip6_addr_net_zoneless_eq
  template ip6AddrNetcmpZoneless*(addr1, addr2: untyped): untyped =
    ip6AddrNetZonelessEq(addr1, addr2)

  ## * Compare IPv6 networks, ignoring zone information. To be used sparingly!
  template ip6AddrNetZonelessEq*(addr1, addr2: untyped): untyped =
    (((addr1).`addr`[0] == (addr2).`addr`[0]) and
        ((addr1).`addr`[1] == (addr2).`addr`[1]))

  ## *
  ## Determine if two IPv6 address are on the same network.
  ##  @deprecated Renamed to @ref ip6_addr_net_eq
  ##
  template ip6AddrNetcmp*(addr1, addr2: untyped): untyped =
    ip6AddrNetEq(addr1, addr2)

  ## *
  ## Determine if two IPv6 address are on the same network.
  ##
  ##  @param addr1 IPv6 address 1
  ##  @param addr2 IPv6 address 2
  ##  @return 1 if the network identifiers of both address match, 0 if not
  ##
  template ip6AddrNetEq*(addr1, addr2: untyped): untyped =
    (ip6AddrNetZonelessEq((addr1), (addr2)) and ip6AddrZoneEq((addr1), (addr2)))

  template ip6AddrNethostcmp*(addr1, addr2: untyped): untyped =
    ip6AddrNethostEq(addr1, addr2)

  ## Exact-host comparison *after* ip6_addr_net_eq() succeeded, for efficiency.
  template ip6AddrNethostEq*(addr1, addr2: untyped): untyped =
    (((addr1).`addr`[2] == (addr2).`addr`[2]) and
        ((addr1).`addr`[3] == (addr2).`addr`[3]))

  ## * @deprecated Renamed to @ref ip6_addr_zoneless_eq
  template ip6AddrCmpZoneless*(addr1, addr2: untyped): untyped =
    ip6AddrZonelessEq(addr1, addr2)

  ## * Compare IPv6 addresses, ignoring zone information. To be used sparingly!
  template ip6AddrZonelessEq*(addr1, addr2: untyped): untyped =
    (((addr1).`addr`[0] == (addr2).`addr`[0]) and
        ((addr1).`addr`[1] == (addr2).`addr`[1]) and
        ((addr1).`addr`[2] == (addr2).`addr`[2]) and
        ((addr1).`addr`[3] == (addr2).`addr`[3]))

  ## * @deprecated Renamed to @ref ip6_addr_eq
  template ip6AddrCmp*(addr1, addr2: untyped): untyped =
    ip6AddrEq(addr1, addr2)

  ## *
  ## Determine if two IPv6 addresses are the same. In particular, the address
  ##  part of both must be the same, and the zone must be compatible.
  ##
  ##  @param addr1 IPv6 address 1
  ##  @param addr2 IPv6 address 2
  ##  @return 1 if the addresses are considered equal, 0 if not
  ##
  template ip6AddrEq*(addr1, addr2: untyped): untyped =
    (ip6AddrZonelessEq((addr1), (addr2)) and ip6AddrZoneEq((addr1), (addr2)))

  ## * @deprecated Renamed to @ref ip6_addr_packed_eq
  template ip6AddrCmpPacked*(ip6addr, paddr, zoneIdx: untyped): untyped =
    ip6AddrPackedEq(ip6addr, paddr, zoneIdx)

  ## * Compare IPv6 address to packed address and zone
  template ip6AddrPackedEq*(ip6addr, paddr, zoneIdx: untyped): untyped =
    (((ip6addr).`addr`[0] == (paddr).`addr`[0]) and
        ((ip6addr).`addr`[1] == (paddr).`addr`[1]) and
        ((ip6addr).`addr`[2] == (paddr).`addr`[2]) and
        ((ip6addr).`addr`[3] == (paddr).`addr`[3]) and
        ip6AddrEqualsZone((ip6addr), (zoneIdx)))

  template ip6GetSubnetId*(ip6addr: untyped): untyped =
    (lwipHtonl((ip6addr).`addr`[2]) and 0x0000ffff)

  template ip6AddrIsanyVal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == 0) and ((ip6addr).`addr`[1] == 0) and
        ((ip6addr).`addr`[2] == 0) and ((ip6addr).`addr`[3] == 0))

  template ip6AddrIsany*(ip6addr: untyped): untyped =
    (((ip6addr) == nil) or ip6AddrIsanyVal((ip6addr)[]))

  template ip6AddrIsloopback*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == 0'ul) and ((ip6addr).`addr`[1] == 0'ul) and
        ((ip6addr).`addr`[2] == 0'ul) and
        ((ip6addr).`addr`[3] == pp_Htonl(0x00000001)))

  template ip6AddrIsglobal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xe0000000)) == pp_Htonl(0x20000000))

  template ip6AddrIslinklocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xffc00000)) == pp_Htonl(0xfe800000))

  template ip6AddrIssitelocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xffc00000)) == pp_Htonl(0xfec00000))

  template ip6AddrIsuniquelocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xfe000000)) == pp_Htonl(0xfc000000))

  template ip6AddrIsipv4mappedipv6*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == 0) and ((ip6addr).`addr`[1] == 0) and
        (((ip6addr).`addr`[2]) == pp_Htonl(0x0000FFFF)))

  template ip6AddrIsipv4compat*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == 0'ul) and ((ip6addr).`addr`[1] == 0'ul) and
        ((ip6addr).`addr`[2] == 0'ul) and (htonl((ip6addr).`addr`[3]) > 1))

  template ip6AddrIsmulticast*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff000000)) == pp_Htonl(0xff000000))

  template ip6AddrMulticastTransientFlag*(ip6addr: untyped): untyped =
    ((ip6addr).`addr`[0] and pp_Htonl(0x00100000))

  template ip6AddrMulticastPrefixFlag*(ip6addr: untyped): untyped =
    ((ip6addr).`addr`[0] and pp_Htonl(0x00200000))

  template ip6AddrMulticastRendezvousFlag*(ip6addr: untyped): untyped =
    ((ip6addr).`addr`[0] and pp_Htonl(0x00400000))

  template ip6AddrMulticastScope*(ip6addr: untyped): untyped =
    ((lwipHtonl((ip6addr).`addr`[0]) shr 16) and 0xf)

  const
    IP6_MULTICAST_SCOPE_RESERVED* = 0x0
    IP6_MULTICAST_SCOPE_RESERVED0* = 0x0
    IP6_MULTICAST_SCOPE_INTERFACE_LOCAL* = 0x1
    IP6_MULTICAST_SCOPE_LINK_LOCAL* = 0x2
    IP6_MULTICAST_SCOPE_RESERVED3* = 0x3
    IP6_MULTICAST_SCOPE_ADMIN_LOCAL* = 0x4
    IP6_MULTICAST_SCOPE_SITE_LOCAL* = 0x5
    IP6_MULTICAST_SCOPE_ORGANIZATION_LOCAL* = 0x8
    IP6_MULTICAST_SCOPE_GLOBAL* = 0xe
    IP6_MULTICAST_SCOPE_RESERVEDF* = 0xf
  template ip6AddrIsmulticastIflocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff010000))

  template ip6AddrIsmulticastLinklocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff020000))

  template ip6AddrIsmulticastAdminlocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff040000))

  template ip6AddrIsmulticastSitelocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff050000))

  template ip6AddrIsmulticastOrglocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff080000))

  template ip6AddrIsmulticastGlobal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] and pp_Htonl(0xff8f0000)) == pp_Htonl(0xff0e0000))

  ## Scoping note: while interface-local and link-local multicast addresses do
  ##  have a scope (i.e., they are meaningful only in the context of a particular
  ##  interface), the following functions are not assigning or comparing zone
  ##  indices. The reason for this is backward compatibility. Any call site that
  ##  produces a non-global multicast address must assign a multicast address as
  ##  appropriate itself.
  template ip6AddrIsallnodesIflocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == pp_Htonl(0xff010000)) and
        ((ip6addr).`addr`[1] == 0'ul) and ((ip6addr).`addr`[2] == 0'ul) and
        ((ip6addr).`addr`[3] == pp_Htonl(0x00000001)))

  template ip6AddrIsallnodesLinklocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == pp_Htonl(0xff020000)) and
        ((ip6addr).`addr`[1] == 0'ul) and ((ip6addr).`addr`[2] == 0'ul) and
        ((ip6addr).`addr`[3] == pp_Htonl(0x00000001)))

  template ip6AddrSetAllnodesLinklocal*(ip6addr: untyped): void =
    while true:
      (ip6addr).`addr`[0] = pp_Htonl(0xff020000)
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[2] = 0
      (ip6addr).`addr`[3] = pp_Htonl(0x00000001)
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  template ip6AddrIsallroutersLinklocal*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == pp_Htonl(0xff020000)) and
        ((ip6addr).`addr`[1] == 0'ul) and ((ip6addr).`addr`[2] == 0'ul) and
        ((ip6addr).`addr`[3] == pp_Htonl(0x00000002)))

  template ip6AddrSetAllroutersLinklocal*(ip6addr: untyped): void =
    while true:
      (ip6addr).`addr`[0] = pp_Htonl(0xff020000)
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[2] = 0
      (ip6addr).`addr`[3] = pp_Htonl(0x00000002)
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  template ip6AddrIssolicitednode*(ip6addr: untyped): untyped =
    (((ip6addr).`addr`[0] == pp_Htonl(0xff020000)) and
        ((ip6addr).`addr`[2] == pp_Htonl(0x00000001)) and
        (((ip6addr).`addr`[3] and pp_Htonl(0xff000000)) == pp_Htonl(0xff000000)))

  template ip6AddrSetSolicitednode*(ip6addr, ifId: untyped): void =
    while true:
      (ip6addr).`addr`[0] = pp_Htonl(0xff020000)
      (ip6addr).`addr`[1] = 0
      (ip6addr).`addr`[2] = pp_Htonl(0x00000001)
      (ip6addr).`addr`[3] = (pp_Htonl(0xff000000) or (ifId))
      ip6AddrClearZone(ip6addr)
      if not 0:
        break

  template ip6AddrCmpSolicitednode*(ip6addr, snAddr: untyped): untyped =
    ip6AddrSolicitednodeEq(ip6addr, snAddr)

  template ip6AddrSolicitednodeEq*(ip6addr, snAddr: untyped): untyped =
    (((ip6addr).`addr`[0] == pp_Htonl(0xff020000)) and
        ((ip6addr).`addr`[1] == 0) and
        ((ip6addr).`addr`[2] == pp_Htonl(0x00000001)) and
        ((ip6addr).`addr`[3] == (pp_Htonl(0xff000000) or (snAddr).`addr`[3])))

  ## IPv6 address states.
  const
    IP6_ADDR_INVALID* = 0x00
    IP6_ADDR_TENTATIVE* = 0x08
    IP6_ADDR_TENTATIVE_1* = 0x09
    IP6_ADDR_TENTATIVE_2* = 0x0a
    IP6_ADDR_TENTATIVE_3* = 0x0b
    IP6_ADDR_TENTATIVE_4* = 0x0c
    IP6_ADDR_TENTATIVE_5* = 0x0d
    IP6_ADDR_TENTATIVE_6* = 0x0e
    IP6_ADDR_TENTATIVE_7* = 0x0f
    IP6_ADDR_VALID* = 0x10
    IP6_ADDR_PREFERRED* = 0x30
    IP6_ADDR_DEPRECATED* = 0x10
    IP6_ADDR_DUPLICATED* = 0x40
    IP6_ADDR_TENTATIVE_COUNT_MASK* = 0x07
  template ip6AddrIsinvalid*(addrState: untyped): untyped =
    (addrState == ip6Addr_Invalid)

  template ip6AddrIstentative*(addrState: untyped): untyped =
    (addrState and ip6Addr_Tentative)

  template ip6AddrIsvalid*(addrState: untyped): untyped =
    (addrState and ip6Addr_Valid) ##  Include valid, preferred, and deprecated.

  template ip6AddrIspreferred*(addrState: untyped): untyped =
    (addrState == ip6Addr_Preferred)

  template ip6AddrIsdeprecated*(addrState: untyped): untyped =
    (addrState == ip6Addr_Deprecated)

  template ip6AddrIsduplicated*(addrState: untyped): untyped =
    (addrState == ip6Addr_Duplicated)

  when defined(lwipIpv6AddressLifetimes):
    const
      IP6_ADDR_LIFE_STATIC* = (0)
      IP6_ADDR_LIFE_INFINITE* = (0xffffffff)
    template ip6AddrLifeIsstatic*(addrLife: untyped): untyped =
      ((addrLife) == ip6Addr_Life_Static)

    template ip6AddrLifeIsinfinite*(addrLife: untyped): untyped =
      ((addrLife) == ip6Addr_Life_Infinite)

  ##
  ## #define ip6_addr_debug_print_parts(debug, a, b, c, d, e, f, g, h) \
  ##   LWIP_DEBUGF(debug, ("%" X16_F ":%" X16_F ":%" X16_F ":%" X16_F ":%" X16_F ":%" X16_F ":%" X16_F ":%" X16_F, \
  ##                       a, b, c, d, e, f, g, h))
  ## #define ip6_addr_debug_print(debug, ipaddr) \
  ##   ip6_addr_debug_print_parts(debug, \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK1(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK2(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK3(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK4(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK5(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK6(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK7(ipaddr) : 0),    \
  ##                       (u16_t)((ipaddr) != NULL ? IP6_ADDR_BLOCK8(ipaddr) : 0))
  ## #define ip6_addr_debug_print_val(debug, ipaddr) \
  ##   ip6_addr_debug_print_parts(debug, \
  ##                       IP6_ADDR_BLOCK1(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK2(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK3(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK4(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK5(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK6(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK7(&(ipaddr)),    \
  ##                       IP6_ADDR_BLOCK8(&(ipaddr)))
  ##
  const
    IP6ADDR_STRLEN_MAX* = 46
  proc ip6addrAton*(cp: cstring; `addr`: ptr Ip6AddrT): cint {.importc: "ip6addr_aton",
      header: "lwip/ip6_addr.h".}
  ## * returns ptr to static buffer; not reentrant!
  proc ip6addrNtoa*(`addr`: ptr Ip6AddrT): cstring {.importc: "ip6addr_ntoa",
      header: "lwip/ip6_addr.h".}
  proc ip6addrNtoaR*(`addr`: ptr Ip6AddrT; buf: cstring; buflen: cint): cstring {.
      importc: "ip6addr_ntoa_r", header: "lwip/ip6_addr.h".}