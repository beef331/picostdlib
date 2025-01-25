## *
##  @file
##  IPv4 address API
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

import ./opt, ./def

when defined(lwipIpv4):
  ## * This is the aligned version of ip4_addr_t,
  ##    used as local variable, on the stack, etc.
  type
    Ip4Addr* {.importc: "struct ip4_addr", header: "lwip/ip4_addr.h", bycopy.} = object
      `addr`* {.importc: "addr".}: uint32

  ## * ip4_addr_t uses a struct for convenience only, so that the same defines can
  ##  operate both on ip4_addr_t as well as on ip4_addr_p_t.
  type
    Ip4AddrT* = Ip4Addr
  ## Forward declaration to not include netif.h
  discard "forward decl of netif"
  const
    IPADDR_NONE* = (cast[uint32](0xffffffff))
  ## * 127.0.0.1
  const
    IPADDR_LOOPBACK* = (cast[uint32](0x7f000001))
  ## * 0.0.0.0
  const
    IPADDR_ANY* = (cast[uint32](0x00000000))
  ## * 255.255.255.255
  const
    IPADDR_BROADCAST* = (cast[uint32](0xffffffff))
  ## Definitions of the bits in an Internet address integer.
  ##
  ##    On subnets, host and network parts are found according to
  ##    the subnet mask, not these masks.
  template ip_Classa*(a: untyped): untyped =
    ((((uint32)(a)) and 0x80000000) == 0)

  const
    IP_CLASSA_NET* = 0xff000000
    IP_CLASSA_NSHIFT* = 24
    IP_CLASSA_HOST* = (0xffffffff and not IP_CLASSA_NET)
    IP_CLASSA_MAX* = 128
  template ip_Classb*(a: untyped): untyped =
    ((((uint32)(a)) and 0xc0000000) == 0x80000000)

  const
    IP_CLASSB_NET* = 0xffff0000
    IP_CLASSB_NSHIFT* = 16
    IP_CLASSB_HOST* = (0xffffffff and not IP_CLASSB_NET)
    IP_CLASSB_MAX* = 65536
  template ip_Classc*(a: untyped): untyped =
    ((((uint32)(a)) and 0xe0000000) == 0xc0000000)

  const
    IP_CLASSC_NET* = 0xffffff00
    IP_CLASSC_NSHIFT* = 8
    IP_CLASSC_HOST* = (0xffffffff and not IP_CLASSC_NET)
  template ip_Classd*(a: untyped): untyped =
    (((uint32)(a) and 0xf0000000) == 0xe0000000)

  const
    IP_CLASSD_NET* = 0xf0000000
    IP_CLASSD_NSHIFT* = 28
    IP_CLASSD_HOST* = 0x0fffffff
  template ip_Multicast*(a: untyped): untyped =
    ip_Classd(a)

  template ip_Experimental*(a: untyped): untyped =
    (((uint32)(a) and 0xf0000000) == 0xf0000000)

  template ip_Badclass*(a: untyped): untyped =
    (((uint32)(a) and 0xf0000000) == 0xf0000000)

  const
    IP_LOOPBACKNET* = 127
  ## * Set an IP address given by the four byte-parts
  template ip4Addr*(ipaddr, a, b, c, d: untyped): untyped =
    (ipaddr).`addr` = pp_Htonl(lwip_Makeu32(a, b, c, d))

  ## * Copy IP address - faster than ip4_addr_set: no NULL check
  template ip4AddrCopy*(dest, src: untyped): untyped =
    ((dest).`addr` = (src).`addr`)

  ## * Safely copy one IP address to another (src may be NULL)
  template ip4AddrSet*(dest, src: untyped): untyped =
    ((dest).`addr` = (if (src) == nil: 0 else: (src).`addr`))

  ## * Set complete address to zero
  template ip4AddrSetZero*(ipaddr: untyped): untyped =
    ((ipaddr).`addr` = 0)

  ## * Set address to IPADDR_ANY (no need for lwip_htonl())
  template ip4AddrSetAny*(ipaddr: untyped): untyped =
    ((ipaddr).`addr` = ipaddr_Any)

  ## * Set address to loopback address
  template ip4AddrSetLoopback*(ipaddr: untyped): untyped =
    ((ipaddr).`addr` = pp_Htonl(ipaddr_Loopback))

  ## * Check if an address is in the loopback region
  template ip4AddrIsloopback*(ipaddr: untyped): untyped =
    (((ipaddr).`addr` and pp_Htonl(ip_Classa_Net)) ==
        pp_Htonl((cast[uint32](ip_Loopbacknet)) shl 24))

  ## * Safely copy one IP address to another and change byte order
  ##  from host- to network-order.
  template ip4AddrSetHton*(dest, src: untyped): untyped =
    ((dest).`addr` = (if (src) == nil: 0 else: lwipHtonl((src).`addr`)))

  ## * IPv4 only: set the IP address given as an u32_t
  template ip4AddrSetU32*(destIpaddr, srcU32: untyped): untyped =
    ((destIpaddr).`addr` = (srcU32))

  ## * IPv4 only: get the IP address as an u32_t
  template ip4AddrGetU32*(srcIpaddr: untyped): untyped =
    ((srcIpaddr).`addr`)

  ## * Get the network address by combining host address with netmask
  template ip4AddrGetNetwork*(target, host, netmask: untyped): void =
    while true:
      ((target).`addr` = ((host).`addr`) and ((netmask).`addr`))
      if not 0:
        break

  ## *
  ## Determine if two address are on the same network.
  ##  @deprecated Renamed to @ref ip4_addr_net_eq
  ##
  template ip4AddrNetcmp*(addr1, addr2, mask: untyped): untyped =
    ip4AddrNetEq(addr1, addr2, mask)

  ## *
  ## Determine if two address are on the same network.
  ##
  ##  @arg addr1 IP address 1
  ##  @arg addr2 IP address 2
  ##  @arg mask network identifier mask
  ##  @return !0 if the network identifiers of both address match
  ##
  template ip4AddrNetEq*(addr1, addr2, mask: untyped): untyped =
    (((addr1).`addr` and (mask).`addr`) == ((addr2).`addr` and (mask).`addr`))

  ## *
  ##  @deprecated Renamed to ip4_addr_eq
  ##
  template ip4AddrCmp*(addr1, addr2: untyped): untyped =
    ip4AddrEq(addr1, addr2)

  template ip4AddrEq*(addr1, addr2: untyped): untyped =
    ((addr1).`addr` == (addr2).`addr`)

  template ip4AddrIsanyVal*(addr1: untyped): untyped =
    ((addr1).`addr` == ipaddr_Any)

  template ip4AddrIsany*(addr1: untyped): untyped =
    ((addr1) == nil or ip4AddrIsanyVal((addr1)[]))

  template ip4AddrIsbroadcast*(addr1, netif: untyped): untyped =
    ip4AddrIsbroadcastU32((addr1).`addr`, netif)

  # proc ip4AddrIsbroadcastU32*(`addr`: uint32; netif: ptr Netif): uint8 {.
  #     importc: "ip4_addr_isbroadcast_u32", header: "lwip/ip4_addr.h".}
  template ipAddrNetmaskValid*(netmask: untyped): untyped =
    ip4AddrNetmaskValid((netmask).`addr`)

  proc ip4AddrNetmaskValid*(netmask: uint32): uint8 {.importc: "ip4_addr_netmask_valid",
      header: "lwip/ip4_addr.h".}
  template ip4AddrIsmulticast*(addr1: untyped): untyped =
    (((addr1).`addr` and pp_Htonl(0xf0000000)) == pp_Htonl(0xe0000000))

  template ip4AddrIslinklocal*(addr1: untyped): untyped =
    (((addr1).`addr` and pp_Htonl(0xffff0000)) == pp_Htonl(0xa9fe0000))

  ##
  ## #define ip4_addr_debug_print_parts(debug, a, b, c, d) \
  ##   LWIP_DEBUGF(debug, ("%" U16_F ".%" U16_F ".%" U16_F ".%" U16_F, a, b, c, d))
  ## #define ip4_addr_debug_print(debug, ipaddr) \
  ##   ip4_addr_debug_print_parts(debug, \
  ##                       (u16_t)((ipaddr) != NULL ? ip4_addr1_16(ipaddr) : 0),       \
  ##                       (u16_t)((ipaddr) != NULL ? ip4_addr2_16(ipaddr) : 0),       \
  ##                       (u16_t)((ipaddr) != NULL ? ip4_addr3_16(ipaddr) : 0),       \
  ##                       (u16_t)((ipaddr) != NULL ? ip4_addr4_16(ipaddr) : 0))
  ## #define ip4_addr_debug_print_val(debug, ipaddr) \
  ##   ip4_addr_debug_print_parts(debug, \
  ##                       ip4_addr1_16_val(ipaddr),       \
  ##                       ip4_addr2_16_val(ipaddr),       \
  ##                       ip4_addr3_16_val(ipaddr),       \
  ##                       ip4_addr4_16_val(ipaddr))
  ##
  ## Get one byte from the 4-byte address
  template ip4AddrGetByte*(ipaddr, idx: untyped): untyped =
    ((cast[ptr uint8]((addr((ipaddr).`addr`))))[idx])

  template ip4Addr1*(ipaddr: untyped): untyped =
    ip4AddrGetByte(ipaddr, 0)

  template ip4Addr2*(ipaddr: untyped): untyped =
    ip4AddrGetByte(ipaddr, 1)

  template ip4Addr3*(ipaddr: untyped): untyped =
    ip4AddrGetByte(ipaddr, 2)

  template ip4Addr4*(ipaddr: untyped): untyped =
    ip4AddrGetByte(ipaddr, 3)

  ## Get one byte from the 4-byte address, but argument is 'ip4_addr_t',
  ##  not a pointer
  template ip4AddrGetByteVal*(ipaddr, idx: untyped): untyped =
    ((uint8)(((ipaddr).`addr` shr (idx * 8)) and 0xff))

  template ip4Addr1Val*(ipaddr: untyped): untyped =
    ip4AddrGetByteVal(ipaddr, 0)

  template ip4Addr2Val*(ipaddr: untyped): untyped =
    ip4AddrGetByteVal(ipaddr, 1)

  template ip4Addr3Val*(ipaddr: untyped): untyped =
    ip4AddrGetByteVal(ipaddr, 2)

  template ip4Addr4Val*(ipaddr: untyped): untyped =
    ip4AddrGetByteVal(ipaddr, 3)

  ## These are cast to u16_t, with the intent that they are often arguments
  ##  to printf using the U16_F format from cc.h.
  template ip4Addr116*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr1(ipaddr)))

  template ip4Addr216*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr2(ipaddr)))

  template ip4Addr316*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr3(ipaddr)))

  template ip4Addr416*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr4(ipaddr)))

  template ip4Addr116Val*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr1Val(ipaddr)))

  template ip4Addr216Val*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr2Val(ipaddr)))

  template ip4Addr316Val*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr3Val(ipaddr)))

  template ip4Addr416Val*(ipaddr: untyped): untyped =
    (cast[uint16](ip4Addr4Val(ipaddr)))

  const
    IP4ADDR_STRLEN_MAX* = 16
  ## * For backwards compatibility
  template ipNtoa*(ipaddr: untyped): untyped =
    ipaddrNtoa(ipaddr)

  proc ipaddrAddr*(cp: cstring): uint32 {.importc: "ipaddr_addr", header: "lwip/ip4_addr.h".}
  proc ip4addrAton*(cp: cstring; `addr`: ptr Ip4AddrT): cint {.importc: "ip4addr_aton",
      header: "lwip/ip4_addr.h".}
  ## * returns ptr to static buffer; not reentrant!
  proc ip4addrNtoa*(`addr`: ptr Ip4AddrT): cstring {.importc: "ip4addr_ntoa", header: "lwip/ip4_addr.h".}
  proc ip4addrNtoaR*(`addr`: ptr Ip4AddrT; buf: cstring; buflen: cint): cstring {.importc: "ip4addr_ntoa_r", header: "lwip/ip4_addr.h".}
