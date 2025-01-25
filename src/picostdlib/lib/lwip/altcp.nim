## *
##  @file
##  Application layered TCP connection API (to be used from TCPIP thread)
##
##  This file contains the generic API.
##  For more details see @ref altcp_api.
##
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
##  This file is part of the lwIP TCP/IP stack.
##
##  Author: Simon Goldschmidt <goldsimon@gmx.de>
##
##

import ./opt
export opt

when defined(lwipAltcp):
  import ./tcpbase, ./err, ./pbuf, ./ip_addr, ./priv/altcp_priv
  export tcpbase, err, pbuf, ip_addr, altcp_priv

  discard "forward decl of altcp_pcb"
  discard "forward decl of altcp_functions"
  type
    AltcpAcceptFn* = proc (arg: pointer; newConn: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.}
    AltcpConnectedFn* = proc (arg: pointer; conn: ptr AltcpPcb; err: ErrT): ErrT {.cdecl.}
    AltcpRecvFn* = proc (arg: pointer; conn: ptr AltcpPcb; p: ptr Pbuf; err: ErrT): ErrT {.cdecl.}
    AltcpSentFn* = proc (arg: pointer; conn: ptr AltcpPcb; len: uint16): ErrT {.cdecl.}
    AltcpPollFn* = proc (arg: pointer; conn: ptr AltcpPcb): ErrT {.cdecl.}
    AltcpErrFn* = proc (arg: pointer; err: ErrT) {.cdecl.}
    AltcpNewFn* = proc (arg: pointer; ipType: uint8): ptr AltcpPcb {.cdecl.}

    AltcpPcb* {.importc: "struct altcp_pcb", header: "lwip/altcp.h", bycopy.} = object
      fns* {.importc: "fns".}: ptr AltcpFunctions
      innerConn* {.importc: "inner_conn".}: ptr AltcpPcb
      arg* {.importc: "arg".}: pointer
      state* {.importc: "state".}: pointer ##  application callbacks
      accept* {.importc: "accept".}: AltcpAcceptFn
      connected* {.importc: "connected".}: AltcpConnectedFn
      recv* {.importc: "recv".}: AltcpRecvFn
      sent* {.importc: "sent".}: AltcpSentFn
      poll* {.importc: "poll".}: AltcpPollFn
      err* {.importc: "err".}: AltcpErrFn
      pollinterval* {.importc: "pollinterval".}: uint8

    ## * @ingroup altcp

    AltcpAllocatorT* {.importc: "altcp_allocator_t", header: "lwip/altcp.h", bycopy.} = object
      ##   Struct containing an allocator and its state.
      alloc* {.importc: "alloc".}: AltcpNewFn
        ## * Allocator function
      arg* {.importc: "arg".}: pointer
        ## * Argument to allocator function

  proc altcpNew*(allocator: ptr AltcpAllocatorT): ptr AltcpPcb {.importc: "altcp_new",header: "lwip/altcp.h".}
  proc altcpNewIp6*(allocator: ptr AltcpAllocatorT): ptr AltcpPcb {.importc: "altcp_new_ip6", header: "lwip/altcp.h".}
  proc altcpNewIpType*(allocator: ptr AltcpAllocatorT; ipType: uint8): ptr AltcpPcb {.importc: "altcp_new_ip_type", header: "lwip/altcp.h".}
  proc altcpArg*(conn: ptr AltcpPcb; arg: pointer) {.importc: "altcp_arg", header: "lwip/altcp.h".}
  proc altcpAccept*(conn: ptr AltcpPcb; accept: AltcpAcceptFn) {.importc: "altcp_accept", header: "lwip/altcp.h".}
  proc altcpRecv*(conn: ptr AltcpPcb; recv: AltcpRecvFn) {.importc: "altcp_recv",header: "lwip/altcp.h".}
  proc altcpSent*(conn: ptr AltcpPcb; sent: AltcpSentFn) {.importc: "altcp_sent",header: "lwip/altcp.h".}
  proc altcpPoll*(conn: ptr AltcpPcb; poll: AltcpPollFn; interval: uint8) {.importc: "altcp_poll", header: "lwip/altcp.h".}
  proc altcpErr*(conn: ptr AltcpPcb; err: AltcpErrFn) {.importc: "altcp_err",header: "lwip/altcp.h".}
  proc altcpRecved*(conn: ptr AltcpPcb; len: uint16) {.importc: "altcp_recved",header: "lwip/altcp.h".}
  proc altcpBind*(conn: ptr AltcpPcb; ipaddr: ptr IpAddrT; port: uint16): ErrT {.importc: "altcp_bind", header: "lwip/altcp.h".}
  proc altcpConnect*(conn: ptr AltcpPcb; ipaddr: ptr IpAddrT; port: uint16; connected: AltcpConnectedFn): ErrT {.importc: "altcp_connect", header: "lwip/altcp.h".}
  ##  return conn for source code compatibility to tcp callback API only
  proc altcpListenWithBacklogAndErr*(conn: ptr AltcpPcb; backlog: uint8; err: ptr ErrT): ptr AltcpPcb {.importc: "altcp_listen_with_backlog_and_err", header: "lwip/altcp.h".}
  template altcpListenWithBacklog*(conn, backlog: untyped): untyped =
    altcpListenWithBacklogAndErr(conn, backlog, nil)

  ## * @ingroup altcp
  template altcpListen*(conn: untyped): untyped =
    altcpListenWithBacklogAndErr(conn, tcp_Default_Listen_Backlog, nil)

  proc altcpAbort*(conn: ptr AltcpPcb) {.importc: "altcp_abort", header: "lwip/altcp.h".}
  proc altcpClose*(conn: ptr AltcpPcb): ErrT {.importc: "altcp_close", header: "lwip/altcp.h".}
  proc altcpShutdown*(conn: ptr AltcpPcb; shutRx: cint; shutTx: cint): ErrT {.importc: "altcp_shutdown", header: "lwip/altcp.h".}
  proc altcpWrite*(conn: ptr AltcpPcb; dataptr: pointer; len: uint16; apiflags: uint8): ErrT {.importc: "altcp_write", header: "lwip/altcp.h".}
  proc altcpOutput*(conn: ptr AltcpPcb): ErrT {.importc: "altcp_output", header: "lwip/altcp.h".}
  proc altcpMss*(conn: ptr AltcpPcb): uint16 {.importc: "altcp_mss", header: "lwip/altcp.h".}
  proc altcpSndbuf*(conn: ptr AltcpPcb): uint16 {.importc: "altcp_sndbuf", header: "lwip/altcp.h".}
  proc altcpSndqueuelen*(conn: ptr AltcpPcb): uint16 {.importc: "altcp_sndqueuelen", header: "lwip/altcp.h".}
  proc altcpNagleDisable*(conn: ptr AltcpPcb) {.importc: "altcp_nagle_disable", header: "lwip/altcp.h".}
  proc altcpNagleEnable*(conn: ptr AltcpPcb) {.importc: "altcp_nagle_enable", header: "lwip/altcp.h".}
  proc altcpNagleDisabled*(conn: ptr AltcpPcb): cint {.importc: "altcp_nagle_disabled", header: "lwip/altcp.h".}
  proc altcpSetprio*(conn: ptr AltcpPcb; prio: uint8) {.importc: "altcp_setprio", header: "lwip/altcp.h".}
  proc altcpGetTcpAddrinfo*(conn: ptr AltcpPcb; local: cint; `addr`: ptr IpAddrT; port: ptr uint16): ErrT {.importc: "altcp_get_tcp_addrinfo", header: "lwip/altcp.h".}
  proc altcpGetIp*(conn: ptr AltcpPcb; local: cint): ptr IpAddrT {.importc: "altcp_get_ip", header: "lwip/altcp.h".}
  proc altcpGetPort*(conn: ptr AltcpPcb; local: cint): uint16 {.importc: "altcp_get_port", header: "lwip/altcp.h".}
  when defined(lwipTcpKeepalive):
    proc altcpKeepaliveDisable*(conn: ptr AltcpPcb) {.importc: "altcp_keepalive_disable", header: "lwip/altcp.h".}
    proc altcpKeepaliveEnable*(conn: ptr AltcpPcb; idle: uint32; intvl: uint32; count: uint32) {.importc: "altcp_keepalive_enable", header: "lwip/altcp.h".}
  when defined(LWIP_DEBUG):
    proc altcpDbgGetTcpState*(conn: ptr AltcpPcb): TcpState {.importc: "altcp_dbg_get_tcp_state", header: "lwip/altcp.h".}

else:
  ## ALTCP disabled, define everything to link against tcp callback API (e.g. to get a small non-ssl httpd)
  import ./tcp

  type
    AltcpAcceptFn* = TcpAcceptFn
    AltcpConnectedFn* = TcpConnectedFn
    AltcpRecvFn* = TcpRecvFn
    AltcpSentFn* = TcpSentFn
    AltcpPollFn* = TcpPollFn
    AltcpErrFn* = TcpErrFn
    AltcpPcb* = TcpPcb

  let
    altcpTcpNewIpType* = tcpNewIpType
    altcpTcpNew* = tcpNew
  template altcpTcpNewIp6*(): untyped = tcpNewIp6()
  template altcpNew*(allocator: untyped): untyped =
    tcpNew()

  template altcpNewIp6*(allocator: untyped): untyped =
    tcpNewIp6()

  template altcpNewIpType*(allocator, ipType: untyped): untyped =
    tcpNewIpType(ipType)

  const
    altcpArg* = tcpArg
    altcpAccept* = tcpAccept
    altcpRecv* = tcpRecv
    altcpSent* = tcpSent
    altcpPoll* = tcpPoll
    altcpErr* = tcpErr
    altcpRecved* = tcpRecved
    altcpBind* = tcpBind
    altcpConnect* = tcpConnect
    altcpListenWithBacklogAndErr* = tcpListenWithBacklogAndErr
    altcpListenWithBacklog* = tcpListenWithBacklog
  template altcpListen*(pcb: untyped): untyped = tcpListen(pcb)
  const
    altcpAbort* = tcpAbort
    altcpClose* = tcpClose
    altcpShutdown* = tcpShutdown
    altcpWrite* = tcpWrite
    altcpOutput* = tcpOutput
  template altcpMss*(pcb: untyped): untyped = tcpMss(pcb)
  template altcpSndbuf*(pcb: untyped): untyped = tcpSndbuf(pcb)
  template altcpSndqueuelen*(pcb: untyped): untyped = tcpSndqueuelen(pcb)
  template altcpNagleDisable*(pcb: untyped): untyped = tcpNagleDisable(pcb)
  template altcpNagleEnable*(pcb: untyped): untyped = tcpNagleEnable(pcb)
  template altcpNagleDisabled*(pcb: untyped): untyped = tcpNagleDisabled(pcb)
  const
    altcpSetprio* = tcpSetprio
    altcpGetTcpAddrinfo* = tcpGetTcpAddrinfo
  template altcpGetIp*(pcb, local: untyped): untyped =
    (if (local): (addr((pcb).localIp)) else: (addr((pcb).remoteIp)))

  when defined(LWIP_DEBUG):
    const
      altcpDbgGetTcpState* = tcpDbgGetTcpState
