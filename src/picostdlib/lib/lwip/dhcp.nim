## *
##  @file
##  DHCP client API
##
##
##  Copyright (c) 2001-2004 Leon Woestenberg <leon.woestenberg@gmx.net>
##  Copyright (c) 2001-2004 Axon Digital Design B.V., The Netherlands.
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
##  Author: Leon Woestenberg <leon.woestenberg@gmx.net>
##
##

import
  ./opt

when defined(lwipDhcp):
  import
    ./netif, ./udp

  when defined(lwipDhcpDoesAcdCheck):
    import
      ./acd

  ## * period (in seconds) of the application calling dhcp_coarse_tmr()
  const
    DHCP_COARSE_TIMER_SECS* = 60
  ## * period (in milliseconds) of the application calling dhcp_coarse_tmr()
  const
    DHCP_COARSE_TIMER_MSECS* = (dhcp_Coarse_Timer_Secs * 1000'ul)
  ## * period (in milliseconds) of the application calling dhcp_fine_tmr()
  const
    DHCP_FINE_TIMER_MSECS* = 500
    DHCP_BOOT_FILE_LEN* = 128'u
    DHCP_FLAG_SUBNET_MASK_GIVEN* = 0x01
    DHCP_FLAG_EXTERNAL_MEM* = 0x02
  ## AutoIP cooperation flags (struct dhcp.autoip_coop_state)
  type
    DhcpAutoipCoopStateEnumT* {.size: sizeof(cint).} = enum
      DHCP_AUTOIP_COOP_STATE_OFF = 0, DHCP_AUTOIP_COOP_STATE_ON = 1
  type
    Dhcp* {.importc: "dhcp", header: "lwip/dhcp.h", bycopy.} = object
      xid* {.importc: "xid".}: U32T ## * transaction identifier of last sent request
      ## * track PCB allocation state
      pcbAllocated* {.importc: "pcb_allocated".}: U8T ## * current DHCP state machine state
      state* {.importc: "state".}: U8T ## * retries of current request
      tries* {.importc: "tries".}: U8T ## * see DHCP_FLAG_*
      flags* {.importc: "flags".}: U8T
      requestTimeout* {.importc: "request_timeout".}: U16T ##  #ticks with period DHCP_FINE_TIMER_SECS for request timeout
      t1Timeout* {.importc: "t1_timeout".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS for renewal time
      t2Timeout* {.importc: "t2_timeout".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS for rebind time
      t1RenewTime* {.importc: "t1_renew_time".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS until next renew try
      t2RebindTime* {.importc: "t2_rebind_time".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS until next rebind try
      leaseUsed* {.importc: "lease_used".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS since last received DHCP ack
      t0Timeout* {.importc: "t0_timeout".}: U16T ##  #ticks with period DHCP_COARSE_TIMER_SECS for lease time
      serverIpAddr* {.importc: "server_ip_addr".}: IpAddrT ##  dhcp server address that offered this lease (ip_addr_t because passed to UDP)
      offeredIpAddr* {.importc: "offered_ip_addr".}: Ip4AddrT
      offeredSnMask* {.importc: "offered_sn_mask".}: Ip4AddrT
      offeredGwAddr* {.importc: "offered_gw_addr".}: Ip4AddrT
      offeredT0Lease* {.importc: "offered_t0_lease".}: U32T ##  lease period (in seconds)
      offeredT1Renew* {.importc: "offered_t1_renew".}: U32T ##  recommended renew time (usually 50% of lease period)
      offeredT2Rebind* {.importc: "offered_t2_rebind".}: U32T ##  recommended rebind time (usually 87.5 of lease period)
      when lwip_Dhcp_Bootp_File:
        offeredSiAddr* {.importc: "offered_si_addr".}: Ip4AddrT
        bootFileName* {.importc: "boot_file_name".}: array[
            dhcp_Boot_File_Len, char]
      when lwip_Dhcp_Does_Acd_Check:
        ## * acd struct
        acd* {.importc: "acd".}: Acd

  proc dhcpSetStruct*(netif: ptr Netif; dhcp: ptr Dhcp) {.importc: "dhcp_set_struct",
      header: "lwip/dhcp.h".}
  ## * Remove a struct dhcp previously set to the netif using dhcp_set_struct()
  template dhcpRemoveStruct*(netif: untyped): untyped =
    netifSetClientData(netif, lwip_Netif_Client_Data_Index_Dhcp, nil)

  proc dhcpCleanup*(netif: ptr Netif) {.importc: "dhcp_cleanup", header: "lwip/dhcp.h".}
  proc dhcpStart*(netif: ptr Netif): ErrT {.importc: "dhcp_start", header: "lwip/dhcp.h".}
  proc dhcpRenew*(netif: ptr Netif): ErrT {.importc: "dhcp_renew", header: "lwip/dhcp.h".}
  proc dhcpRelease*(netif: ptr Netif): ErrT {.importc: "dhcp_release", header: "lwip/dhcp.h".}
  proc dhcpStop*(netif: ptr Netif) {.importc: "dhcp_stop", header: "lwip/dhcp.h".}
  proc dhcpReleaseAndStop*(netif: ptr Netif) {.importc: "dhcp_release_and_stop",
      header: "lwip/dhcp.h".}
  proc dhcpInform*(netif: ptr Netif) {.importc: "dhcp_inform", header: "lwip/dhcp.h".}
  proc dhcpNetworkChangedLinkUp*(netif: ptr Netif) {.
      importc: "dhcp_network_changed_link_up", header: "lwip/dhcp.h".}
  proc dhcpSuppliedAddress*(netif: ptr Netif): U8T {.
      importc: "dhcp_supplied_address", header: "lwip/dhcp.h".}
  ##  to be called every minute
  proc dhcpCoarseTmr*() {.importc: "dhcp_coarse_tmr", header: "lwip/dhcp.h".}
  ##  to be called every half second
  proc dhcpFineTmr*() {.importc: "dhcp_fine_tmr", header: "lwip/dhcp.h".}
  when lwip_Dhcp_Get_Ntp_Srv:
    ## * This function must exist, in other to add offered NTP servers to
    ##  the NTP (or SNTP) engine.
    ## See LWIP_DHCP_MAX_NTP_SERVERS
    proc dhcpSetNtpServers*(numNtpServers: U8T; ntpServerAddrs: ptr Ip4AddrT) {.
        importc: "dhcp_set_ntp_servers", header: "lwip/dhcp.h".}
  template netifDhcpData*(netif: untyped): untyped =
    (cast[ptr Dhcp](netifGetClientData(netif, lwip_Netif_Client_Data_Index_Dhcp)))
