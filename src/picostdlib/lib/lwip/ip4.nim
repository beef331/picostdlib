## *
##  @file
##  IPv4 API
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
  ./opt

when defined(lwipIpv4):
  import
    ./def, ./pbuf, ./ip4_addr, ./err, ./netif, ./prot/ip4
  export pbuf, ip4_addr, err, netif, ip4

  when defined(LWIP_HOOK_IP4_ROUTE_SRC):
    const
      LWIP_IPV4_SRC_ROUTING* = 1
  else:
    const
      LWIP_IPV4_SRC_ROUTING* = 0
  ## * Currently, the function ip_output_if_opt() is only used with IGMP
  const
    IP_OPTIONS_SEND* = (defined(lwipIpv4) and defined(lwipIgmp))
  ## #define ip_init() /* Compatibility define, no init needed. */
  proc ip4Route*(dest: ptr Ip4AddrT): ptr Netif {.importc: "ip4_route", header: "lwip/ip4.h".}
  when defined(lwipIpv4SrcRouting):
    proc ip4RouteSrc*(src: ptr Ip4AddrT; dest: ptr Ip4AddrT): ptr Netif {.
        importc: "ip4_route_src", header: "lwip/ip4.h".}
  else:
    template ip4RouteSrc*(src, dest: untyped): untyped =
      ip4Route(dest)

  proc ip4Input*(p: ptr Pbuf; inp: ptr Netif): ErrT {.importc: "ip4_input",
      header: "lwip/ip4.h".}
  proc ip4Output*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8; tos: uint8;
                 proto: uint8): ErrT {.importc: "ip4_output", header: "lwip/ip4.h".}
  proc ip4OutputIf*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8; tos: uint8;
                   proto: uint8; netif: ptr Netif): ErrT {.importc: "ip4_output_if",
      header: "lwip/ip4.h".}
  proc ip4OutputIfSrc*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8;
                      tos: uint8; proto: uint8; netif: ptr Netif): ErrT {.
      importc: "ip4_output_if_src", header: "lwip/ip4.h".}
  when defined(lwip_Netif_Use_Hints):
    proc ip4OutputHinted*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8;
                         tos: uint8; proto: uint8; netifHint: ptr NetifHint): ErrT {.
        importc: "ip4_output_hinted", header: "lwip/ip4.h".}
  when defined(ip_Options_Send):
    proc ip4OutputIfOpt*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8;
                        tos: uint8; proto: uint8; netif: ptr Netif; ipOptions: pointer;
                        optlen: U16T): ErrT {.importc: "ip4_output_if_opt",
        header: "lwip/ip4.h".}
    proc ip4OutputIfOptSrc*(p: ptr Pbuf; src: ptr Ip4AddrT; dest: ptr Ip4AddrT; ttl: uint8;
                           tos: uint8; proto: uint8; netif: ptr Netif; ipOptions: pointer;
                           optlen: U16T): ErrT {.importc: "ip4_output_if_opt_src",
        header: "lwip/ip4.h".}
  when defined(lwip_Multicast_Tx_Options):
    proc ip4SetDefaultMulticastNetif*(defaultMulticastNetif: ptr Netif) {.
        importc: "ip4_set_default_multicast_netif", header: "lwip/ip4.h".}
  template ip4NetifGetLocalIp*(netif: untyped): untyped =
    (if ((netif) != nil): netifIpAddr4(netif) else: nil)

  when defined(ip_Debug):
    proc ip4DebugPrint*(p: ptr Pbuf) {.importc: "ip4_debug_print", header: "lwip/ip4.h".}
  else:
    discard