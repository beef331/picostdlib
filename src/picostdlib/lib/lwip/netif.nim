## *
##  @file
##  netif API (to be used from TCPIP thread)
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

import ./opt
export opt

const
  ENABLE_LOOPBACK* = (defined(lwipNetifLoopback) or defined(lwipHaveLoopif))

import ./err, ./ip_addr, ./def, ./pbuf, ./stats
export err, ip_addr, def, pbuf, stats

##  Throughout this file, IP addresses are expected to be in
##  the same byte order as in IP_PCB.
## * Must be the maximum of all used hardware address lengths
##     across all types of interfaces in use.
##     This does not have to be changed, normally.

when not defined(NETIF_MAX_HWADDR_LEN):
  const
    NETIF_MAX_HWADDR_LEN* = 6'u
## * The size of a fully constructed netif name which the
##  netif can be identified by in APIs. Composed of
##  2 chars, 3 (max) digits, and 1 \0
##

const
  NETIF_NAMESIZE* = 6

## *
##  @defgroup netif_flags Flags
##  @ingroup netif
##  @{
##
## * Whether the network interface is 'up'. This is
##  a software flag used to control whether this network
##  interface is enabled and processes traffic.
##  It must be set by the startup code before this netif can be used
##  (also for dhcp/autoip).
##

const
  NETIF_FLAG_UP* = 0x01

## * If set, the netif has broadcast capability.
##  Set by the netif driver in its init function.

const
  NETIF_FLAG_BROADCAST* = 0x02

## * If set, the interface has an active link
##   (set by the network interface driver).
##  Either set by the netif driver in its init function (if the link
##  is up at that time) or at a later point once the link comes up
##  (if link detection is supported by the hardware).

const
  NETIF_FLAG_LINK_UP* = 0x04

## * If set, the netif is an ethernet device using ARP.
##  Set by the netif driver in its init function.
##  Used to check input packet types and use of DHCP.

const
  NETIF_FLAG_ETHARP* = 0x08

## * If set, the netif is an ethernet device. It might not use
##  ARP or TCP/IP if it is used for PPPoE only.
##

const
  NETIF_FLAG_ETHERNET* = 0x10

## * If set, the netif has IGMP capability.
##  Set by the netif driver in its init function.

const
  NETIF_FLAG_IGMP* = 0x20

## * If set, the netif has MLD6 capability.
##  Set by the netif driver in its init function.

const
  NETIF_FLAG_MLD6* = 0x40

## *
##  @}
##


when defined(lwipChecksumCtrlPerNetif):
  const
    NETIF_CHECKSUM_GEN_IP* = 0x0001
    NETIF_CHECKSUM_GEN_UDP* = 0x0002
    NETIF_CHECKSUM_GEN_TCP* = 0x0004
    NETIF_CHECKSUM_GEN_ICMP* = 0x0008
    NETIF_CHECKSUM_GEN_ICMP6* = 0x0010
    NETIF_CHECKSUM_CHECK_IP* = 0x0100
    NETIF_CHECKSUM_CHECK_UDP* = 0x0200
    NETIF_CHECKSUM_CHECK_TCP* = 0x0400
    NETIF_CHECKSUM_CHECK_ICMP* = 0x0800
    NETIF_CHECKSUM_CHECK_ICMP6* = 0x1000
    NETIF_CHECKSUM_ENABLE_ALL* = 0xFFFF
    NETIF_CHECKSUM_DISABLE_ALL* = 0x0000
discard "forward decl of netif"
type
  NetifMacFilterAction* {.size: sizeof(cint).} = enum ## * Delete a filter entry
    NETIF_DEL_MAC_FILTER = 0,   ## * Add a filter entry
    NETIF_ADD_MAC_FILTER = 1

when defined(lwip_Dhcp) or defined(lwip_Autoip) or defined(lwipIgmp) or defined(lwipIpv6Mld) or defined(lwip_Ipv6Dhcp6) or
    ((lwip_Num_Netif_Client_Data) > 0):
  when lwip_Num_Netif_Client_Data > 0:
    proc netifAllocClientDataId*(): uint8 {.importc: "netif_alloc_client_data_id",
                                       header: "lwip/netif.h".}
  ## * @ingroup netif_cd
  ## Set client data. Obtain ID from netif_alloc_client_data_id().
  ##
  template netifSetClientData*(netif, id, data: untyped): untyped =
    netifGetClientData(netif, id) = (data)

  ## * @ingroup netif_cd
  ## Get client data. Obtain ID from netif_alloc_client_data_id().
  ##
  template netifGetClientData*(netif, id: untyped): untyped =
    (netif).clientData[(id)]

when (defined(lwipIpv4) and defined(lwip_Arp) and (arp_Table_Size > 0x7f)) or
    (defined(lwipIpv6) and (lwip_Nd6Num_Destinations > 0x7f)):
  type
    NetifAddrIdxT* = uint16
  const
    NETIF_ADDR_IDX_MAX* = 0x7FFF
else:
  type
    NetifAddrIdxT* = uint8
  const
    NETIF_ADDR_IDX_MAX* = 0x7F
when defined(lwipNetifHwaddrhint) or defined(lwipVlanPcp):
  const
    LWIP_NETIF_USE_HINTS* = true
  type
    NetifHint* {.importc: "struct netif_hint", header: "lwip/netif.h", bycopy.} = object
      when defined(lwipNetifHwaddrhint):
        addrHint* {.importc: "addr_hint".}: uint8
      when defined(lwipVlanPcp):
        ## * VLAN hader is set if this is >= 0 (but must be <= 0xFFFF)
        tci* {.importc: "tci".}: int32

else:
  const
    LWIP_NETIF_USE_HINTS* = false
## * Generic data structure used for all lwIP network interfaces.
##   The following fields should be filled in by the initialization
##   function for the device driver: hwaddr_len, hwaddr[], mtu, flags

type

  ## * Function prototype for netif init functions. Set up flags and output/linkoutput
  ##  callback functions in this function.
  ##
  ##  @param netif The netif to initialize
  ##
  NetifInitFn* = proc (netif: ptr Netif): ErrT {.cdecl.}

  ## * Function prototype for netif->output functions. Called by lwIP when a packet
  ##  shall be sent. For ethernet netif, set this to 'etharp_output' and set
  ##  'linkoutput'.
  ##
  ##  @param netif The netif which shall send a packet
  ##  @param p The packet to send (p->payload points to IP header)
  ##  @param ipaddr The IP address to which the packet shall be sent
  ##
  NetifOutputFn* = proc (netif: ptr Netif; p: ptr Pbuf; ipaddr: ptr Ip4AddrT): ErrT {.cdecl.}

  ## * Function prototype for netif->input functions. This function is saved as 'input'
  ##  callback function in the netif struct. Call it when a packet has been received.
  ##
  ##  @param p The received packet, copied into a pbuf
  ##  @param inp The netif which received the packet
  ##  @return ERR_OK if the packet was handled
  ##          != ERR_OK is the packet was NOT handled, in this case, the caller has
  ##                    to free the pbuf
  ##

  NetifInputFn* = proc (p: ptr Pbuf; inp: ptr Netif): ErrT {.cdecl.}

  ## * Function prototype for netif->output_ip6 functions. Called by lwIP when a packet
  ##  shall be sent. For ethernet netif, set this to 'ethip6_output' and set
  ##  'linkoutput'.
  ##
  ##  @param netif The netif which shall send a packet
  ##  @param p The packet to send (p->payload points to IP header)
  ##  @param ipaddr The IPv6 address to which the packet shall be sent
  ##
  NetifOutputIp6Fn* = proc (netif: ptr Netif; p: ptr Pbuf; ipaddr: ptr Ip6AddrT): ErrT {.cdecl.}

  ## * Function prototype for netif->linkoutput functions. Only used for ethernet
  ##  netifs. This function is called by ARP when a packet shall be sent.
  ##
  ##  @param netif The netif which shall send a packet
  ##  @param p The packet to send (raw ethernet packet)
  ##
  NetifLinkoutputFn* = proc (netif: ptr Netif; p: ptr Pbuf): ErrT {.cdecl.}

  Netif* {.importc: "struct netif", header: "lwip/netif.h", bycopy.} = object
    ## Generic data structure used for all lwIP network interfaces.
    ## The following fields should be filled in by the initialization
    ## function for the device driver: hwaddr_len, hwaddr[], mtu, flags

    when not defined(lwipSingleNetif):
      next* {.importc: "next".}: ptr Netif
        ## * pointer to next in linked list
    when defined(lwipIpv4):
      ## * IP address configuration in network byte order
      ipAddr* {.importc: "ip_addr".}: IpAddrT
      netmask* {.importc: "netmask".}: IpAddrT
      gw* {.importc: "gw".}: IpAddrT
    when defined(lwipIpv6):
      ip6Addr* {.importc: "ip6_addr".}: array[lwip_Ipv6Num_Addresses, IpAddrT]
        ## * Array of IPv6 addresses for this netif.
      ip6AddrState* {.importc: "ip6_addr_state".}: array[lwip_Ipv6Num_Addresses, uint8]
        ## * The state of each IPv6 address (Tentative, Preferred, etc).
        ##  @see ip6_addr.h
      when defined(lwipIpv6AddressLifetimes):
        ## * Remaining valid and preferred lifetime of each IPv6 address, in seconds.
        ## For valid lifetimes, the special value of IP6_ADDR_LIFE_STATIC (0)
        ## indicates the address is static and has no lifetimes.
        ip6AddrValidLife* {.importc: "ip6_addr_valid_life".}: array[lwip_Ipv6Num_Addresses, uint32]
        ip6AddrPrefLife* {.importc: "ip6_addr_pref_life".}: array[lwip_Ipv6Num_Addresses, uint32]

    input* {.importc: "input".}: NetifInputFn
      ## * This function is called by the network device driver
      ##   to pass a packet up the TCP/IP stack.

    when defined(lwipIpv4):
      output* {.importc: "output".}: NetifOutputFn
        ## * This function is called by the IP module when it wants
        ##   to send a packet on the interface. This function typically
        ##   first resolves the hardware address, then sends the packet.
        ##   For ethernet physical layer, this is usually etharp_output()

    linkoutput* {.importc: "linkoutput".}: NetifLinkoutputFn
      ## * This function is called by ethernet_output() when it wants
      ##   to send a packet on the interface. This function outputs
      ##   the pbuf as-is on the link medium.
    when defined(lwipIpv6):
      ## * This function is called by the IPv6 module when it wants
      ##   to send a packet on the interface. This function typically
      ##   first resolves the hardware address, then sends the packet.
      ##   For ethernet physical layer, this is usually ethip6_output()
      outputIp6* {.importc: "output_ip6".}: NetifOutputIp6Fn
    when defined(lwip_Netif_Status_Callback):
      ## * This function is called when the netif state is set to up or down
      statusCallback* {.importc: "status_callback".}: NetifStatusCallbackFn
    when defined(lwip_Netif_Link_Callback):
      ## * This function is called when the netif link is set to up or down
      linkCallback* {.importc: "link_callback".}: NetifStatusCallbackFn
    when defined(lwip_Netif_Remove_Callback):
      ## * This function is called when the netif has been removed
      removeCallback* {.importc: "remove_callback".}: NetifStatusCallbackFn

    state* {.importc: "state".}: pointer
      ## * This field can be set by the device driver and could point
      ##   to state information for the device.
    when defined(netif_get_client_data):
      clientData* {.importc: "client_data".}: array[
          lwip_Netif_Client_Data_Index_Max + lwip_Num_Netif_Client_Data, pointer]
    when defined(lwipNetifHostname):
      ##  the hostname for this netif, NULL is a valid value
      hostname* {.importc: "hostname".}: cstring
    when defined(lwip_Checksum_Ctrl_Per_Netif):
      chksumFlags* {.importc: "chksum_flags".}: uint16

    mtu* {.importc: "mtu".}: uint16
      ## * maximum transfer unit (in bytes)
    when defined(lwipIpv6) and defined(lwip_Nd6Allow_Ra_Updates):
      ## * maximum transfer unit (in bytes), updated by RA
      mtu6* {.importc: "mtu6".}: uint16
    hwaddr* {.importc: "hwaddr".}: array[NETIF_MAX_HWADDR_LEN, uint8]
      ## * link level hardware address of this interface
    hwaddrLen* {.importc: "hwaddr_len".}: uint8
      ## * number of bytes used in hwaddr
    flags* {.importc: "flags".}: uint8
      ## * flags (@see @ref netif_flags)
    name* {.importc: "name".}: array[2, char]
      ## * descriptive abbreviation
    num* {.importc: "num".}: uint8
      ## * number of this interface. Used for @ref if_api and @ref netifapi_netif,
      ##  as well as for IPv6 zones
    when defined(lwip_Ipv6Autoconfig):
      ip6AutoconfigEnabled* {.importc: "ip6_autoconfig_enabled".}: uint8
        ## * is this netif enabled for IPv6 autoconfiguration
    when defined(lwip_Ipv6Send_Router_Solicit):
      rsCount* {.importc: "rs_count".}: uint8
        ## * Number of Router Solicitation messages that remain to be sent.
    when defined(mib2Stats):
      linkType* {.importc: "link_type".}: uint8
        ## * link type (from "snmp_ifType" enum from snmp_mib2.h)
      linkSpeed* {.importc: "link_speed".}: uint32
        ## * (estimate) link speed
      ts* {.importc: "ts".}: uint32
        ## * timestamp at last change made (up/down)
      mib2Counters* {.importc: "mib2_counters".}: StatsMib2NetifCtrs
        ## * counters
    when defined(lwipIpv4) and defined(lwipIgmp):
      igmpMacFilter* {.importc: "igmp_mac_filter".}: NetifIgmpMacFilterFn
        ## * This function could be called to add or delete an entry in the multicast
        ##       filter table of the ethernet MAC.
    when defined(lwipIpv6) and defined(lwipIpv6Mld):
      mldMacFilter* {.importc: "mld_mac_filter".}: NetifMldMacFilterFn
        ## * This function could be called to add or delete an entry in the IPv6 multicast
        ##       filter table of the ethernet MAC.
    when defined(lwipAcd):
      acdList* {.importc: "acd_list".}: ptr Acd
    when defined(lwipNetifUseHints):
      hints* {.importc: "hints".}: ptr NetifHint
    when defined(enableLoopback):
      ## List of packets to be queued for ourselves.
      loopFirst* {.importc: "loop_first".}: ptr Pbuf
      loopLast* {.importc: "loop_last".}: ptr Pbuf
      when defined(lwip_Loopback_Max_Pbufs):
        loopCntCurrent* {.importc: "loop_cnt_current".}: uint16
      when defined(lwip_Netif_Loopback_Multithreading):
        ## Used if the original scheduling failed.
        reschedulePoll* {.importc: "reschedule_poll".}: uint8


  NetifStatusCallbackFn* = proc (netif: ptr Netif) {.cdecl.}
    ## * Function prototype for netif status- or link-callback functions.

  ##when defined(lwipIpv4) and defined(lwipIgmp):
  ## * Function prototype for netif igmp_mac_filter functions
  NetifIgmpMacFilterFn* = proc (netif: ptr Netif; group: ptr Ip4AddrT; action: NetifMacFilterAction): ErrT {.cdecl.}

  ##when defined(lwipIpv6) and defined(lwipIpv6Mld):
  ## * Function prototype for netif mld_mac_filter functions
  NetifMldMacFilterFn* = proc (netif: ptr Netif; group: ptr Ip6AddrT; action: NetifMacFilterAction): ErrT {.cdecl.}


when defined(lwip_Checksum_Ctrl_Per_Netif):
  template netif_Set_Checksum_Ctrl*(netif, chksumflags: untyped): void =
    while true:
      (netif).chksumFlags = chksumflags
      if not 0:
        break

  template netif_Checksum_Enabled*(netif, chksumflag: untyped): untyped =
    (((netif) == nil) or (((netif).chksumFlags and (chksumflag)) != 0))

else:
  template netif_Checksum_Enabled*(netif, chksumflag: untyped): untyped =
    0

when defined(lwip_Single_Netif):
  ## #define NETIF_SET_CHECKSUM_CTRL(netif, chksumflags)
  ## #define IF__NETIF_CHECKSUM_ENABLED(netif, chksumflag)
  discard
else:
  ## * The list of network interfaces.
  var netifList* {.importc: "netif_list", header: "lwip/netif.h".}: ptr Netif
  ## #define NETIF_FOREACH(netif) for ((netif) = netif_list; (netif) != NULL; (netif) = (netif)->next)

## * The default network interface.
let netifDefault* {.importc: "netif_default", header: "lwip/netif.h".}: ptr Netif

proc netifInit*() {.importc: "netif_init", header: "lwip/netif.h".}
proc netifAddNoaddr*(netif: ptr Netif; state: pointer; init: NetifInitFn; input: NetifInputFn): ptr Netif {.importc: "netif_add_noaddr", header: "lwip/netif.h".}
when defined(lwipIpv4):
  proc netifAdd*(netif: ptr Netif; ipaddr: ptr Ip4AddrT; netmask: ptr Ip4AddrT; gw: ptr Ip4AddrT; state: pointer; init: NetifInitFn; input: NetifInputFn): ptr Netif {.importc: "netif_add",
      header: "lwip/netif.h".}
  proc netifSetAddr*(netif: ptr Netif; ipaddr: ptr Ip4AddrT; netmask: ptr Ip4AddrT; gw: ptr Ip4AddrT) {.importc: "netif_set_addr", header: "lwip/netif.h".}
else:
  proc netifAdd*(netif: ptr Netif; state: pointer; init: NetifInitFn; input: NetifInputFn): ptr Netif {.importc: "netif_add", header: "lwip/netif.h".}
proc netifRemove*(netif: ptr Netif) {.importc: "netif_remove", header: "lwip/netif.h".}
##  Returns a network interface given its name. The name is of the form
##    "et0", where the first two letters are the "name" field in the
##    netif structure, and the digit is in the num field in the same
##    structure.

proc netifFind*(name: cstring): ptr Netif {.importc: "netif_find", header: "lwip/netif.h".}
proc netifSetDefault*(netif: ptr Netif) {.importc: "netif_set_default", header: "lwip/netif.h".}

when defined(lwipIpv4):
  proc netifSetIpaddr*(netif: ptr Netif; ipaddr: ptr Ip4AddrT) {.importc: "netif_set_ipaddr", header: "lwip/netif.h".}
  proc netifSetNetmask*(netif: ptr Netif; netmask: ptr Ip4AddrT) {.importc: "netif_set_netmask", header: "lwip/netif.h".}
  proc netifSetGw*(netif: ptr Netif; gw: ptr Ip4AddrT) {.importc: "netif_set_gw", header: "lwip/netif.h".}
  ## * @ingroup netif_ip4
  template netifIp4Addr*(netif: untyped): untyped =
    (cast[ptr Ip4AddrT](ip2Ip4(addr(((netif).ipAddr)))))

  ## * @ingroup netif_ip4
  template netifIp4Netmask*(netif: untyped): untyped =
    (cast[ptr Ip4AddrT](ip2Ip4(addr(((netif).netmask)))))

  ## * @ingroup netif_ip4
  template netifIp4Gw*(netif: untyped): untyped =
    (cast[ptr Ip4AddrT](ip2Ip4(addr(((netif).gw)))))

  ## * @ingroup netif_ip4
  template netifIpAddr4*(netif: untyped): untyped =
    (cast[ptr IpAddrT](addr(((netif).ipAddr))))

  ## * @ingroup netif_ip4
  template netifIpNetmask4*(netif: untyped): untyped =
    (cast[ptr IpAddrT](addr(((netif).netmask))))

  ## * @ingroup netif_ip4
  template netifIpGw4*(netif: untyped): untyped =
    (cast[ptr IpAddrT](addr(((netif).gw))))

template netifSetFlags*(netif, setFlags: untyped): void =
  while true:
    (netif).flags = (uint8)((netif).flags or (setFlags))
    if not 0:
      break

template netifClearFlags*(netif, clrFlags: untyped): void =
  while true:
    (netif).flags = (uint8)((netif).flags and (uint8)(not (clrFlags) and 0xff))
    if not 0:
      break

template netifIsFlagSet*(netif, flag: untyped): untyped =
  (((netif).flags and (flag)) != 0)

proc netifSetUp*(netif: ptr Netif) {.importc: "netif_set_up", header: "lwip/netif.h".}
proc netifSetDown*(netif: ptr Netif) {.importc: "netif_set_down", header: "lwip/netif.h".}

## * @ingroup netif

template netifIsUp*(netif: untyped): untyped =
  ## Ask if an interface is up
  (if ((netif).flags and netif_Flag_Up): cast[uint8](1) else: cast[uint8](0))

when defined(lwipNetifStatusCallback):
  proc netifSetStatusCallback*(netif: ptr Netif; statusCallback: NetifStatusCallbackFn) {.importc: "netif_set_status_callback", header: "lwip/netif.h".}
when defined(lwipNetifRemoveCallback):
  proc netifSetRemoveCallback*(netif: ptr Netif; removeCallback: NetifStatusCallbackFn) {.importc: "netif_set_remove_callback", header: "lwip/netif.h".}
proc netifSetLinkUp*(netif: ptr Netif) {.importc: "netif_set_link_up", header: "lwip/netif.h".}
proc netifSetLinkDown*(netif: ptr Netif) {.importc: "netif_set_link_down", header: "lwip/netif.h".}

template netifIsLinkUp*(netif: untyped): untyped =
  ## * Ask if a link is up
  (if ((netif).flags and netif_Flag_Link_Up): cast[uint8](1) else: cast[uint8](0))

when defined(lwipNetifLinkCallback):
  proc netifSetLinkCallback*(netif: ptr Netif; linkCallback: NetifStatusCallbackFn) {.importc: "netif_set_link_callback", header: "lwip/netif.h".}
when defined(lwipNetifHostname):
  ## * @ingroup netif
  template netifSetHostname*(netif: ptr Netif, name: cstring) =
    if not netif.isNil:
      (netif).hostname = name

  ## * @ingroup netif
  template netifGetHostname*(netif: untyped): untyped =
    (if ((netif) != nil): ((netif).hostname) else: nil)

when defined(lwipIgmp):
  ## * @ingroup netif
  ## Set igmp mac filter function for a netif.
  template netifSetIgmpMacFilter*(netif, function: untyped): void =
    while true:
      if (netif) != nil:
        (netif).igmpMacFilter = function
      if not 0:
        break

  ## * Get the igmp mac filter function for a netif.
  template netifGetIgmpMacFilter*(netif: untyped): untyped =
    (if ((netif) != nil): ((netif).igmpMacFilter) else: nil)

when defined(lwipIpv6) and defined(lwipIpv6Mld):
  ## * @ingroup netif
  ## Set mld mac filter function for a netif.
  template netifSetMldMacFilter*(netif, function: untyped): void =
    while true:
      if (netif) != nil:
        (netif).mldMacFilter = function
      if not 0:
        break

  ## * Get the mld mac filter function for a netif.
  template netifGetMldMacFilter*(netif: untyped): untyped =
    (if ((netif) != nil): ((netif).mldMacFilter) else: nil)

  template netifMldMacFilter*(netif, `addr`, action: untyped): void =
    while true:
      if (netif) and (netif).mldMacFilter:
        (netif).mldMacFilter((netif), (`addr`), (action))
      if not 0:
        break

when defined(enableLoopback):
  proc netifLoopOutput*(netif: ptr Netif; p: ptr Pbuf): ErrT {.importc: "netif_loop_output", header: "lwip/netif.h".}
  proc netifPoll*(netif: ptr Netif) {.importc: "netif_poll", header: "lwip/netif.h".}
  when not lwip_Netif_Loopback_Multithreading:
    proc netifPollAll*() {.importc: "netif_poll_all", header: "lwip/netif.h".}
proc netifInput*(p: ptr Pbuf; inp: ptr Netif): ErrT {.importc: "netif_input", header: "lwip/netif.h".}
when defined(lwipIpv6):
  ## * @ingroup netif_ip6
  template netifIpAddr6*(netif, i: untyped): untyped =
    (cast[ptr IpAddrT]((addr(((netif).ip6Addr[i])))))

  ## * @ingroup netif_ip6
  template netifIp6Addr*(netif, i: untyped): untyped =
    (cast[ptr Ip6AddrT](ip2Ip6(addr(((netif).ip6Addr[i])))))

  proc netifIp6AddrSet*(netif: ptr Netif; addrIdx: int8; addr6: ptr Ip6AddrT) {.importc: "netif_ip6_addr_set", header: "lwip/netif.h".}
  proc netifIp6AddrSetParts*(netif: ptr Netif; addrIdx: int8; i0: uint32; i1: uint32; i2: uint32; i3: uint32) {.importc: "netif_ip6_addr_set_parts", header: "lwip/netif.h".}
  template netifIp6AddrState*(netif, i: untyped): untyped =
    ((netif).ip6AddrState[i])

  proc netifIp6AddrSetState*(netif: ptr Netif; addrIdx: int8; state: uint8) {.importc: "netif_ip6_addr_set_state", header: "lwip/netif.h".}
  proc netifGetIp6AddrMatch*(netif: ptr Netif; ip6addr: ptr Ip6AddrT): int8 {.importc: "netif_get_ip6_addr_match", header: "lwip/netif.h".}
  proc netifCreateIp6LinklocalAddress*(netif: ptr Netif; fromMac48bit: uint8) {.importc: "netif_create_ip6_linklocal_address", header: "lwip/netif.h".}
  proc netifAddIp6Address*(netif: ptr Netif; ip6addr: ptr Ip6AddrT; chosenIdx: ptr int8): ErrT {.importc: "netif_add_ip6_address", header: "lwip/netif.h".}
  template netifSetIp6AutoconfigEnabled*(netif, action: untyped): void =
    while true:
      if netif:
        (netif).ip6AutoconfigEnabled = (action)
      if not 0:
        break

  when lwip_Ipv6Address_Lifetimes:
    template netifIp6AddrValidLife*(netif, i: untyped): untyped =
      (if ((netif) != nil): ((netif).ip6AddrValidLife[i]) else: ip6Addr_Life_Static)

    template netifIp6AddrSetValidLife*(netif, i, secs: untyped): void =
      while true:
        if netif != nil:
          (netif).ip6AddrValidLife[i] = (secs)
        if not 0:
          break

    template netifIp6AddrPrefLife*(netif, i: untyped): untyped =
      (if ((netif) != nil): ((netif).ip6AddrPrefLife[i]) else: ip6Addr_Life_Static)

    template netifIp6AddrSetPrefLife*(netif, i, secs: untyped): void =
      while true:
        if netif != nil:
          (netif).ip6AddrPrefLife[i] = (secs)
        if not 0:
          break

    template netifIp6AddrIsstatic*(netif, i: untyped): untyped =
      (netifIp6AddrValidLife((netif), (i)) == ip6Addr_Life_Static)

  else:
    template netifIp6AddrIsstatic*(netif, i: untyped): untyped =
      (1)                     ##  all addresses are static

  when lwip_Nd6Allow_Ra_Updates:
    template netifMtu6*(netif: untyped): untyped =
      ((netif).mtu6)

  else:
    template netifMtu6*(netif: untyped): untyped =
      ((netif).mtu)

when defined(lwipNetifUseHints):
  template netif_Set_Hints*(netif, netifhint: untyped): untyped =
    (netif).hints = (netifhint)

  template netif_Reset_Hints*(netif: untyped): untyped =
    (netif).hints = nil

else:
  template netif_Set_Hints*(netif, netifhint: untyped): untyped = discard

  template netif_Reset_Hints*(netif: untyped): untyped = discard

proc netifNameToIndex*(name: cstring): uint8 {.importc: "netif_name_to_index", header: "lwip/netif.h".}
proc netifIndexToName*(idx: uint8; name: cstring): cstring {.importc: "netif_index_to_name", header: "lwip/netif.h".}
proc netifGetByIndex*(idx: uint8): ptr Netif {.importc: "netif_get_by_index", header: "lwip/netif.h".}

##  Interface indexes always start at 1 per RFC 3493, section 4, num starts at 0 (internal index is 0..254)
template netifGetIndex*(netif: untyped): untyped =
  ((uint8)((netif).num + 1))

const
  NETIF_NO_INDEX* = (0)

## *
##  @ingroup netif
##  Extended netif status callback (NSC) reasons flags.
##  May be extended in the future!
##

type
  NetifNscReasonT* = uint16

##  used for initialization only

const
  LWIP_NSC_NONE* = 0x0000

## * netif was added. arg: NULL. Called AFTER netif was added.

const
  LWIP_NSC_NETIF_ADDED* = 0x0001

## * netif was removed. arg: NULL. Called BEFORE netif is removed.

const
  LWIP_NSC_NETIF_REMOVED* = 0x0002

## * link changed

const
  LWIP_NSC_LINK_CHANGED* = 0x0004

## * netif administrative status changed.<br>
##  up is called AFTER netif is set up.<br>
##  down is called BEFORE the netif is actually set down.

const
  LWIP_NSC_STATUS_CHANGED* = 0x0008

## * IPv4 address has changed

const
  LWIP_NSC_IPV4_ADDRESS_CHANGED* = 0x0010

## * IPv4 gateway has changed

const
  LWIP_NSC_IPV4_GATEWAY_CHANGED* = 0x0020

## * IPv4 netmask has changed

const
  LWIP_NSC_IPV4_NETMASK_CHANGED* = 0x0040

## * called AFTER IPv4 address/gateway/netmask changes have been applied

const
  LWIP_NSC_IPV4_SETTINGS_CHANGED* = 0x0080

## * IPv6 address was added

const
  LWIP_NSC_IPV6_SET* = 0x0100

## * IPv6 address state has changed

const
  LWIP_NSC_IPV6_ADDR_STATE_CHANGED* = 0x0200

## * IPv4 settings: valid address set, application may start to communicate

const
  LWIP_NSC_IPV4_ADDR_VALID* = 0x0400

## * @ingroup netif
##  Argument supplied to netif_ext_callback_fn.
##

type
  link_changed_s_netif_671* {.importc: "netif_ext_callback_args_t::no_name", header: "lwip/netif.h", bycopy.} = object
    state* {.importc: "state".}: uint8 ## * 1: up; 0: down

  status_changed_s_netif_671* {.importc: "netif_ext_callback_args_t::no_name", header: "lwip/netif.h", bycopy.} = object
    state* {.importc: "state".}: uint8 ## * 1: up; 0: down

  ipv4_changed_s_netif_671* {.importc: "netif_ext_callback_args_t::no_name", header: "lwip/netif.h", bycopy.} = object
    oldAddress* {.importc: "old_address".}: ptr IpAddrT ## * Old IPv4 address
    oldNetmask* {.importc: "old_netmask".}: ptr IpAddrT
    oldGw* {.importc: "old_gw".}: ptr IpAddrT

  ipv6_set_s_netif_671* {.importc: "netif_ext_callback_args_t::no_name", header: "lwip/netif.h", bycopy.} = object
    addrIndex* {.importc: "addr_index".}: int8 ## * Index of changed IPv6 address
    ## * Old IPv6 address
    oldAddress* {.importc: "old_address".}: ptr IpAddrT

  ipv6_addr_state_changed_s_netif_671* {.importc: "netif_ext_callback_args_t::no_name", header: "lwip/netif.h", bycopy.} = object
    addrIndex* {.importc: "addr_index".}: int8 ## * Index of affected IPv6 address
    ## * Old IPv6 address state
    oldState* {.importc: "old_state".}: uint8 ## * Affected IPv6 address
    address* {.importc: "address".}: ptr IpAddrT

  NetifExtCallbackArgsT* {.importc: "netif_ext_callback_args_t", header: "lwip/netif.h",
                          bycopy, union.} = object
    linkChanged* {.importc: "link_changed".}: link_changed_s_netif_671 ## * Args to
                                                                   ## LWIP_NSC_LINK_CHANGED callback
    ## * Args to LWIP_NSC_STATUS_CHANGED callback
    statusChanged* {.importc: "status_changed".}: status_changed_s_netif_671 ## * Args to
                                                                         ## LWIP_NSC_IPV4_ADDRESS_CHANGED|LWIP_NSC_IPV4_GATEWAY_CHANGED|LWIP_NSC_IPV4_NETMASK_CHANGED|LWIP_NSC_IPV4_SETTINGS_CHANGED
                                                                         ## callback
    ipv4Changed* {.importc: "ipv4_changed".}: ipv4_changed_s_netif_671 ## * Args to
                                                                   ## LWIP_NSC_IPV6_SET callback
    ipv6Set* {.importc: "ipv6_set".}: ipv6_set_s_netif_671 ## * Args to
                                                       ## LWIP_NSC_IPV6_ADDR_STATE_CHANGED callback
    ipv6AddrStateChanged* {.importc: "ipv6_addr_state_changed".}: ipv6_addr_state_changed_s_netif_671


## *
##  @ingroup netif
##  Function used for extended netif status callbacks
##  Note: When parsing reason argument, keep in mind that more reasons may be added in the future!
##  @param netif netif that is affected by change
##  @param reason change reason
##  @param args depends on reason, see reason description
##

type
  NetifExtCallbackFn* = proc (netif: ptr Netif; reason: NetifNscReasonT;
                           args: ptr NetifExtCallbackArgsT)

when defined(lwipNetifExtStatusCallback):
  discard "forward decl of netif_ext_callback"
  type
    NetifExtCallbackT* {.importc: "netif_ext_callback_t", header: "lwip/netif.h", bycopy.} = object
      callbackFn* {.importc: "callback_fn".}: NetifExtCallbackFn
      next* {.importc: "next".}: ptr NetifExtCallback

  template netif_Declare_Ext_Callback*(name: untyped): void =
    var name* {.importc: "name", header: "lwip/netif.h".}: NetifExtCallbackT

  proc netifAddExtCallback*(callback: ptr NetifExtCallbackT; fn: NetifExtCallbackFn) {.
      importc: "netif_add_ext_callback", header: "lwip/netif.h".}
  proc netifRemoveExtCallback*(callback: ptr NetifExtCallbackT) {.
      importc: "netif_remove_ext_callback", header: "lwip/netif.h".}
  proc netifInvokeExtCallback*(netif: ptr Netif; reason: NetifNscReasonT;
                              args: ptr NetifExtCallbackArgsT) {.
      importc: "netif_invoke_ext_callback", header: "lwip/netif.h".}
else:
  #[
  template netif_Declare_Ext_Callback*(name: untyped): void = discard

  proc netifAddExtCallback*(callback: ptr NetifExtCallbackT; fn: NetifExtCallbackFn) = discard
  proc netifRemoveExtCallback*(callback: ptr NetifExtCallbackT) = discard
  proc netifInvokeExtCallback*(netif: ptr Netif; reason: NetifNscReasonT;
                              args: ptr NetifExtCallbackArgsT) = discard
  ]#
  discard

when defined(lwipTestmode) and defined(lwipHaveLoopif):
  proc netifGetLoopif*(): ptr Netif {.importc: "netif_get_loopif", header: "lwip/netif.h".}