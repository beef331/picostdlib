## *
##  @file
##  IP API
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
  ./opt, ./def, ./pbuf, ./ip_addr, ./err, ./netif, ./ip4, ./ip6, ./prot/ip

export pbuf, ip_addr, err, netif, ip4, ip6, ip

##  This is passed as the destination address to ip_output_if (not
##    to ip_output), meaning that an IP header already is constructed
##    in the pbuf. This is used when TCP retransmits.

const
  LWIP_IP_HDRINCL* = nil

## * pbufs passed to IP must have a ref-count of 1 as their payload pointer
##     gets altered as the packet is passed down the stack

when not defined(LWIP_IP_CHECK_PBUF_REF_COUNT_FOR_TX):
  template lwip_Ip_Check_Pbuf_Ref_Count_For_Tx*(p: untyped): untyped =
    lwip_Assert("p->ref == 1", (p).`ref` == 1)

when defined(lwipNetifUseHints):
  ## #define IP_PCB_NETIFHINT ;struct netif_hint netif_hints
else:
  ##  #define IP_PCB_NETIFHINT
## * This is the common part of all PCB types. It needs to be at the
##    beginning of a PCB type definition. It is located here so that
##    changes to this common part are made in one location instead of
##    having to change all PCB structs.
## #define IP_PCB                             \
##  ip addresses in network byte order
## ip_addr_t local_ip;                      \
## ip_addr_t remote_ip;                     \
##  Bound netif index
## u8_t netif_idx;                          \
##  Socket options
## u8_t so_options;                         \
##  Type Of Service
## u8_t tos;                                \
##  Time To Live
## u8_t ttl                                 \
##  link layer address resolution hint
## IP_PCB_NETIFHINT

type
  IpPcb* {.importc: "ip_pcb", header: "lwip/ip.h", bycopy.} = object
    # ip addresses in network byte order
    localIp* {.importc: "local_ip".}: ptr IpAddrT
    remoteIp* {.importc: "remote_ip".}: ptr IpAddrT
    # Bound netif index
    netifIdx* {.importc: "netif_idx".}: uint8
    # Socket options
    soOptions* {.importc: "so_options".}: uint8
    # Type Of Service
    tos* {.importc: "tos".}: uint8
    # Time To Live
    ttl* {.importc: "ttl".}: uint8
    when LWIP_NETIF_USE_HINTS:
      netifHints* {.importc: "netif_hints".}: NetifHint


##
##  Option flags per-socket. These are the same like SO_XXX in sockets.h
##

const
  SOF_REUSEADDR* = 0x04
  SOF_KEEPALIVE* = 0x08
  SOF_BROADCAST* = 0x20

##  These flags are inherited (e.g. from a listen-pcb to a connection-pcb):

const
  SOF_INHERITED* = (Sof_Reuseaddr or Sof_Keepalive)

## * Global variables of this module, kept in a struct for efficient access using base+index.

type
  IpGlobals* {.importc: "ip_globals", header: "lwip/ip.h", bycopy.} = object
    currentNetif* {.importc: "current_netif".}: ptr Netif
    ## * The interface that accepted the packet for the current callback invocation.
    currentInputNetif* {.importc: "current_input_netif".}: ptr Netif
    ## * The interface that received the packet for the current callback invocation.
    when defined(lwipIpv4):
      currentIp4Header* {.importc: "current_ip4_header".}: ptr IpHdr
      ## * Header of the input packet currently being processed.
    when defined(lwipIpv6):
      currentIp6Header* {.importc: "current_ip6_header".}: ptr Ip6Hdr
      ## * Header of the input IPv6 packet currently being processed.

    currentIpHeaderTotLen* {.importc: "current_ip_header_tot_len".}: uint16
    ## * Total header length of current_ip4/6_header (i.e. after this, the UDP/TCP header starts)
    currentIphdrSrc* {.importc: "current_iphdr_src".}: IpAddrT
    ## * Source IP address of current_header
    currentIphdrDest* {.importc: "current_iphdr_dest".}: IpAddrT
    ## * Destination IP address of current_header


var ipData* {.importc: "ip_data", header: "lwip/ip.h".}: IpGlobals

## * Get the interface that accepted the current packet.
##  This may or may not be the receiving netif, depending on your netif/network setup.
##  This function must only be called from a receive callback (udp_recv,
##  raw_recv, tcp_accept). It will return NULL otherwise.

template ipCurrentNetif*(): untyped =
  (ipData.currentNetif)

## * Get the interface that received the current packet.
##  This function must only be called from a receive callback (udp_recv,
##  raw_recv, tcp_accept). It will return NULL otherwise.

template ipCurrentInputNetif*(): untyped =
  (ipData.currentInputNetif)

## * Total header length of ip(6)_current_header() (i.e. after this, the UDP/TCP header starts)

template ipCurrentHeaderTotLen*(): untyped =
  (ipData.currentIpHeaderTotLen)

## * Source IP address of current_header

template ipCurrentSrcAddr*(): untyped =
  (addr(ipData.currentIphdrSrc))

## * Destination IP address of current_header

template ipCurrentDestAddr*(): untyped =
  (addr(ipData.currentIphdrDest))

when defined(lwipIpv4) and defined(lwipIpv6):
  ## * Get the IPv4 header of the current packet.
  ## This function must only be called from a receive callback (udp_recv,
  ##  raw_recv, tcp_accept). It will return NULL otherwise.
  template ip4CurrentHeader*(): untyped =
    ipData.currentIp4Header

  ## * Get the IPv6 header of the current packet.
  ## This function must only be called from a receive callback (udp_recv,
  ##  raw_recv, tcp_accept). It will return NULL otherwise.
  template ip6CurrentHeader*(): untyped =
    (cast[ptr Ip6Hdr]((ipData.currentIp6Header)))

  ## * Returns TRUE if the current IP input packet is IPv6, FALSE if it is IPv4
  template ipCurrentIsV6*(): untyped =
    (ip6CurrentHeader() != nil)

  ## * Source IPv6 address of current_header
  template ip6CurrentSrcAddr*(): untyped =
    (ip2Ip6(addr(ipData.currentIphdrSrc)))

  ## * Destination IPv6 address of current_header
  template ip6CurrentDestAddr*(): untyped =
    (ip2Ip6(addr(ipData.currentIphdrDest)))

  ## * Get the transport layer protocol
  template ipCurrentHeaderProto*(): untyped =
    (if ipCurrentIsV6(): ip6h_Nexth(ip6CurrentHeader()) else: iph_Proto(
        ip4CurrentHeader()))

  ## * Get the transport layer header
  template ipNextHeaderPtr*(): untyped =
    (cast[pointer](((if ipCurrentIsV6(): cast[ptr U8T](ip6CurrentHeader()) else: cast[ptr U8T](ip4CurrentHeader())) +
        ipCurrentHeaderTotLen())))

  ## * Source IP4 address of current_header
  template ip4CurrentSrcAddr*(): untyped =
    (ip2Ip4(addr(ipData.currentIphdrSrc)))

  ## * Destination IP4 address of current_header
  template ip4CurrentDestAddr*(): untyped =
    (ip2Ip4(addr(ipData.currentIphdrDest)))

elif defined(lwipIpv4):
  ## * Get the IPv4 header of the current packet.
  ## This function must only be called from a receive callback (udp_recv,
  ##  raw_recv, tcp_accept). It will return NULL otherwise.
  template ip4CurrentHeader*(): untyped =
    ipData.currentIp4Header

  ## * Always returns FALSE when only supporting IPv4 only
  template ipCurrentIsV6*(): untyped =
    0

  ## * Get the transport layer protocol
  template ipCurrentHeaderProto*(): untyped =
    iph_Proto(ip4CurrentHeader())

  ## * Get the transport layer header
  template ipNextHeaderPtr*(): untyped =
    (cast[pointer]((cast[ptr U8T](ip4CurrentHeader()) + ipCurrentHeaderTotLen())))

  ## * Source IP4 address of current_header
  template ip4CurrentSrcAddr*(): untyped =
    (addr(ipData.currentIphdrSrc))

  ## * Destination IP4 address of current_header
  template ip4CurrentDestAddr*(): untyped =
    (addr(ipData.currentIphdrDest))

elif defined(lwipIpv6):
  ## * Get the IPv6 header of the current packet.
  ## This function must only be called from a receive callback (udp_recv,
  ##  raw_recv, tcp_accept). It will return NULL otherwise.
  template ip6CurrentHeader*(): untyped =
    (cast[ptr Ip6Hdr]((ipData.currentIp6Header)))

  ## * Always returns TRUE when only supporting IPv6 only
  template ipCurrentIsV6*(): untyped =
    1

  ## * Get the transport layer protocol
  template ipCurrentHeaderProto*(): untyped =
    ip6h_Nexth(ip6CurrentHeader())

  ## * Get the transport layer header
  template ipNextHeaderPtr*(): untyped =
    (cast[pointer](((cast[ptr U8T](ip6CurrentHeader())) + ipCurrentHeaderTotLen())))

  ## * Source IP6 address of current_header
  template ip6CurrentSrcAddr*(): untyped =
    (addr(ipData.currentIphdrSrc))

  ## * Destination IP6 address of current_header
  template ip6CurrentDestAddr*(): untyped =
    (addr(ipData.currentIphdrDest))

## * Union source address of current_header

template ipCurrentSrcAddr*(): untyped =
  (addr(ipData.currentIphdrSrc))

## * Union destination address of current_header

template ipCurrentDestAddr*(): untyped =
  (addr(ipData.currentIphdrDest))

## * Gets an IP pcb option (SOF_* flags)

template ipGetOption*(pcb, opt: untyped): untyped =
  ((pcb).soOptions and (opt))

## * Sets an IP pcb option (SOF_* flags)

template ipSetOption*(pcb, opt: untyped): untyped =
  ((pcb).soOptions = (u8T)((pcb).soOptions or (opt)))

## * Resets an IP pcb option (SOF_* flags)

template ipResetOption*(pcb, opt: untyped): untyped =
  ((pcb).soOptions = (u8T)((pcb).soOptions and not (opt)))

when defined(lwipIpv4) and defined(lwipIpv6):
  ## *
  ##  @ingroup ip
  ## Output IP packet, netif is selected by source address
  ##
  template ipOutput*(p, src, dest, ttl, tos, proto: untyped): untyped =
    (if ip_Is_V6(dest): ip6Output(p, ip2Ip6(src), ip2Ip6(dest), ttl, tos, proto) else: ip4Output(
        p, ip2Ip4(src), ip2Ip4(dest), ttl, tos, proto))

  ## *
  ##  @ingroup ip
  ## Output IP packet to specified interface
  ##
  template ipOutputIf*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    (if ip_Is_V6(dest): ip6OutputIf(p, ip2Ip6(src), ip2Ip6(dest), ttl, tos, proto, netif) else: ip4OutputIf(
        p, ip2Ip4(src), ip2Ip4(dest), ttl, tos, proto, netif))

  ## *
  ##  @ingroup ip
  ## Output IP packet to interface specifying source address
  ##
  template ipOutputIfSrc*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    (if ip_Is_V6(dest): ip6OutputIfSrc(p, ip2Ip6(src), ip2Ip6(dest), ttl, tos, proto,
                                     netif) else: ip4OutputIfSrc(p, ip2Ip4(src),
        ip2Ip4(dest), ttl, tos, proto, netif))

  ## * Output IP packet that already includes an IP header.
  template ipOutputIfHdrincl*(p, src, dest, netif: untyped): untyped =
    (if ip_Is_V6(dest): ip6OutputIf(p, ip2Ip6(src), lwip_Ip_Hdrincl, 0, 0, 0, netif) else: ip4OutputIf(
        p, ip2Ip4(src), lwip_Ip_Hdrincl, 0, 0, 0, netif))

  ## * Output IP packet with netif_hint
  template ipOutputHinted*(p, src, dest, ttl, tos, proto, netifHint: untyped): untyped =
    (if ip_Is_V6(dest): ip6OutputHinted(p, ip2Ip6(src), ip2Ip6(dest), ttl, tos, proto,
                                      netifHint) else: ip4OutputHinted(p,
        ip2Ip4(src), ip2Ip4(dest), ttl, tos, proto, netifHint))

  ## *
  ##  @ingroup ip
  ## Get netif for address combination. See \ref ip6_route and \ref ip4_route
  ##
  template ipRoute*(src, dest: untyped): untyped =
    (if ip_Is_V6(dest): ip6Route(ip2Ip6(src), ip2Ip6(dest)) else: ip4RouteSrc(
        ip2Ip4(src), ip2Ip4(dest)))

  ## *
  ##  @ingroup ip
  ## Get netif for IP.
  ##
  template ipNetifGetLocalIp*(netif, dest: untyped): untyped =
    (if ip_Is_V6(dest): ip6NetifGetLocalIp(netif, ip2Ip6(dest)) else: ip4NetifGetLocalIp(
        netif))

  template ipDebugPrint*(isIpv6, p: untyped): untyped =
    (if (isIpv6): ip6DebugPrint(p) else: ip4DebugPrint(p))

  proc ipInput*(p: ptr Pbuf; inp: ptr Netif): ErrT {.importc: "ip_input", header: "lwip/ip.h".}
elif defined(lwipIpv4):
  template ipOutput*(p, src, dest, ttl, tos, proto: untyped): untyped =
    ip4Output(p, src, dest, ttl, tos, proto)

  template ipOutputIf*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    ip4OutputIf(p, src, dest, ttl, tos, proto, netif)

  template ipOutputIfSrc*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    ip4OutputIfSrc(p, src, dest, ttl, tos, proto, netif)

  template ipOutputHinted*(p, src, dest, ttl, tos, proto, netifHint: untyped): untyped =
    ip4OutputHinted(p, src, dest, ttl, tos, proto, netifHint)

  template ipOutputIfHdrincl*(p, src, dest, netif: untyped): untyped =
    ip4OutputIf(p, src, lwip_Ip_Hdrincl, 0, 0, 0, netif)

  template ipRoute*(src, dest: untyped): untyped =
    ip4RouteSrc(src, dest)

  template ipNetifGetLocalIp*(netif, dest: untyped): untyped =
    ip4NetifGetLocalIp(netif)

  template ipDebugPrint*(isIpv6, p: untyped): untyped =
    ip4DebugPrint(p)

  const
    ipInput* = ip4Input
elif defined(lwipIpv6):
  template ipOutput*(p, src, dest, ttl, tos, proto: untyped): untyped =
    ip6Output(p, src, dest, ttl, tos, proto)

  template ipOutputIf*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    ip6OutputIf(p, src, dest, ttl, tos, proto, netif)

  template ipOutputIfSrc*(p, src, dest, ttl, tos, proto, netif: untyped): untyped =
    ip6OutputIfSrc(p, src, dest, ttl, tos, proto, netif)

  template ipOutputHinted*(p, src, dest, ttl, tos, proto, netifHint: untyped): untyped =
    ip6OutputHinted(p, src, dest, ttl, tos, proto, netifHint)

  template ipOutputIfHdrincl*(p, src, dest, netif: untyped): untyped =
    ip6OutputIf(p, src, lwip_Ip_Hdrincl, 0, 0, 0, netif)

  template ipRoute*(src, dest: untyped): untyped =
    ip6Route(src, dest)

  template ipNetifGetLocalIp*(netif, dest: untyped): untyped =
    ip6NetifGetLocalIp(netif, dest)

  template ipDebugPrint*(isIpv6, p: untyped): untyped =
    ip6DebugPrint(p)

  const
    ipInput* = ip6Input
template ipRouteGetLocalIp*(src, dest, netif, ipaddr: untyped): void =
  while true:
    (netif) = ipRoute(src, dest)
    (ipaddr) = ipNetifGetLocalIp(netif, dest)
    if not 0:
      break
