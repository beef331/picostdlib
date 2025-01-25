## *
##  @file
##  DNS API
##
## *
##  lwip DNS resolver header file.
##
##  Author: Jim Pettinato
##    April 2007
##
##  ported from uIP resolv.c Copyright (c) 2002-2003, Adam Dunkels.
##
##  Redistribution and use in source and binary forms, with or without
##  modification, are permitted provided that the following conditions
##  are met:
##  1. Redistributions of source code must retain the above copyright
##     notice, this list of conditions and the following disclaimer.
##  2. Redistributions in binary form must reproduce the above copyright
##     notice, this list of conditions and the following disclaimer in the
##     documentation and/or other materials provided with the distribution.
##  3. The name of the author may not be used to endorse or promote
##     products derived from this software without specific prior
##     written permission.
##
##  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
##  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
##  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
##  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
##  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
##  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
##  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
##  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
##  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
##  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
##  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##

# import ./opt

when defined(lwipDns):
  import ./ip_addr, ./err
  export ip_addr, err

  ## * DNS timer period
  const
    DNS_TMR_INTERVAL* = 1000
  ## DNS resolve types:
  const
    LWIP_DNS_ADDRTYPE_IPV4* = 0
    LWIP_DNS_ADDRTYPE_IPV6* = 1
    LWIP_DNS_ADDRTYPE_IPV4_IPV6* = 2
    LWIP_DNS_ADDRTYPE_IPV6_IPV4* = 3
  when defined(lwipIpv4) and defined(lwipIpv6):
    when not defined(LWIP_DNS_ADDRTYPE_DEFAULT):
      const
        LWIP_DNS_ADDRTYPE_DEFAULT* = LWIP_DNS_ADDRTYPE_IPV4_IPV6
  elif defined(lwipIpv4):
    const
      LWIP_DNS_ADDRTYPE_DEFAULT* = LWIP_DNS_ADDRTYPE_IPV4
  else:
    const
      LWIP_DNS_ADDRTYPE_DEFAULT* = LWIP_DNS_ADDRTYPE_IPV6
  when defined(dns_Local_Hostlist):
    ## * struct used for local host-list
    type
      LocalHostlistEntry* {.importc: "local_hostlist_entry", header: "lwip/dns.h", bycopy.} = object
        name* {.importc: "name".}: cstring ## * static hostname
        ## * static host address in network byteorder
        `addr`* {.importc: "addr".}: IpAddrT
        next* {.importc: "next".}: ptr LocalHostlistEntry

    ## #define DNS_LOCAL_HOSTLIST_ELEM(name, addr_init) {name, addr_init, NULL}
    when defined(dns_Local_Hostlist_Is_Dynamic):
      when not defined(DNS_LOCAL_HOSTLIST_MAX_NAMELEN):
        const
          DNS_LOCAL_HOSTLIST_MAX_NAMELEN* = dns_Max_Name_Length
      const
        LOCALHOSTLIST_ELEM_SIZE* = ((sizeof(cast[LocalHostlistEntry](+dns_Local_Hostlist_Max_Namelen)) + 1))
  when defined(lwipIpv4):
    var dnsMqueryV4group* {.importc: "dns_mquery_v4group", header: "lwip/dns.h".}: IpAddrT
  when defined(lwipIpv6):
    var dnsMqueryV6group* {.importc: "dns_mquery_v6group", header: "lwip/dns.h".}: IpAddrT
  ## * Callback which is invoked when a hostname is found.
  ## A function of this type must be implemented by the application using the DNS resolver.
  ##  @param name pointer to the name that was looked up.
  ##  @param ipaddr pointer to an ip_addr_t containing the IP address of the hostname,
  ##         or NULL if the name could not be found (or on any other error).
  ##  @param callback_arg a user-specified callback argument passed to dns_gethostbyname
  ##
  type
    DnsFoundCallback* = proc (name: cstring; ipaddr: ptr IpAddrT; callbackArg: pointer) {.cdecl.}
  proc dnsInit*() {.importc: "dns_init", header: "lwip/dns.h".}
  proc dnsTmr*() {.importc: "dns_tmr", header: "lwip/dns.h".}
  proc dnsSetserver*(numdns: uint8; dnsserver: ptr IpAddrT) {.importc: "dns_setserver", header: "lwip/dns.h".}
  proc dnsGetserver*(numdns: uint8): ptr IpAddrT {.importc: "dns_getserver", header: "lwip/dns.h".}
  proc dnsGethostbyname*(hostname: cstring; `addr`: ptr IpAddrT; found: DnsFoundCallback; callbackArg: pointer): ErrT {.importc: "dns_gethostbyname", header: "lwip/dns.h".}
  proc dnsGethostbynameAddrtype*(hostname: cstring; `addr`: ptr IpAddrT; found: DnsFoundCallback; callbackArg: pointer; dnsAddrtype: uint8): ErrT {.importc: "dns_gethostbyname_addrtype", header: "lwip/dns.h".}

  when defined(dns_Local_Hostlist):
    proc dnsLocalIterate*(iteratorFn: DnsFoundCallback; iteratorArg: pointer): csize_t {.
        importc: "dns_local_iterate", header: "lwip/dns.h".}
    proc dnsLocalLookup*(hostname: cstring; `addr`: ptr IpAddrT; dnsAddrtype: uint8): ErrT {.
        importc: "dns_local_lookup", header: "lwip/dns.h".}
    when defined(dns_Local_Hostlist_Is_Dynamic):
      proc dnsLocalRemovehost*(hostname: cstring; `addr`: ptr IpAddrT): cint {.
          importc: "dns_local_removehost", header: "lwip/dns.h".}
      proc dnsLocalAddhost*(hostname: cstring; `addr`: ptr IpAddrT): ErrT {.
          importc: "dns_local_addhost", header: "lwip/dns.h".}