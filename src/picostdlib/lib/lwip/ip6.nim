## *
##  @file
##
##  IPv6 layer.
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
##
##  Please coordinate changes and requests with Ivan Delamer
##  <delamer@inicotech.com>
##

import ./opt

when defined(lwipIpv6):
  import
    lwip/ip6Addr, lwip/prot/ip6, lwip/def, lwip/pbuf, lwip/netif, lwip/err

  proc ip6Route*(src: ptr Ip6AddrT; dest: ptr Ip6AddrT): ptr Netif {.
      importc: "ip6_route", header: "ip6.h".}
  proc ip6SelectSourceAddress*(netif: ptr Netif; dest: ptr Ip6AddrT): ptr IpAddrT {.
      importc: "ip6_select_source_address", header: "ip6.h".}
  proc ip6Input*(p: ptr Pbuf; inp: ptr Netif): ErrT {.importc: "ip6_input",
      header: "ip6.h".}
  proc ip6Output*(p: ptr Pbuf; src: ptr Ip6AddrT; dest: ptr Ip6AddrT; hl: U8T; tc: U8T;
                 nexth: U8T): ErrT {.importc: "ip6_output", header: "ip6.h".}
  proc ip6OutputIf*(p: ptr Pbuf; src: ptr Ip6AddrT; dest: ptr Ip6AddrT; hl: U8T; tc: U8T;
                   nexth: U8T; netif: ptr Netif): ErrT {.importc: "ip6_output_if",
      header: "ip6.h".}
  proc ip6OutputIfSrc*(p: ptr Pbuf; src: ptr Ip6AddrT; dest: ptr Ip6AddrT; hl: U8T; tc: U8T;
                      nexth: U8T; netif: ptr Netif): ErrT {.
      importc: "ip6_output_if_src", header: "ip6.h".}
  when lwip_Netif_Use_Hints:
    proc ip6OutputHinted*(p: ptr Pbuf; src: ptr Ip6AddrT; dest: ptr Ip6AddrT; hl: U8T;
                         tc: U8T; nexth: U8T; netifHint: ptr NetifHint): ErrT {.
        importc: "ip6_output_hinted", header: "ip6.h".}
  when lwip_Ipv6Mld:
    proc ip6OptionsAddHbhRa*(p: ptr Pbuf; nexth: U8T; value: U8T): ErrT {.
        importc: "ip6_options_add_hbh_ra", header: "ip6.h".}
  template ip6NetifGetLocalIp*(netif, dest: untyped): untyped =
    (if ((netif) != nil): ip6SelectSourceAddress(netif, dest) else: nil)

  when ip6Debug:
    proc ip6DebugPrint*(p: ptr Pbuf) {.importc: "ip6_debug_print", header: "ip6.h".}
  else:
    discard