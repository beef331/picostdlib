## *
##  @file
##  TCP API (to be used from TCPIP thread)<br>
##  See also @ref tcp_raw
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
# export opt

when defined(lwipTcp):
  import ./tcpbase, ./mem, ./pbuf, ./ip, ./icmp, ./err, ./ip6, ./ip6_addr, ./priv/tcp_priv
  export tcpbase, mem, pbuf, ip, icmp, err, ip6, ip6_addr, tcp_priv

  discard "forward decl of tcp_pcb"

  discard "forward decl of tcp_pcb_listen"

  const
    LWIP_TCP_PCB_NUM_EXT_ARG_ID_INVALID* = 0xFF

  const
    TCP_ALLFLAGS* = 0xffff

  const
    TF_ACK_DELAY* = 0x01
    TF_ACK_NOW* = 0x02
    TF_INFR* = 0x04
    TF_CLOSEPEND* = 0x08
    TF_RXCLOSED* = 0x10
    TF_FIN* = 0x20
    TF_NODELAY* = 0x40
    TF_NAGLEMEMERR* = 0x80
  when defined(lwipWndScale):
    const
      TF_WND_SCALE* = 0x0100
  when defined(tcpListenBacklog):
    const
      TF_BACKLOGPEND* = 0x0200
  when defined(lwipTcpTimestamps):
    const
      TF_TIMESTAMP* = 0x0400
  const
    TF_RTO* = 0x0800
  when defined(lwipTcpSackOut):
    const
      TF_SACK* = 0x1000
  ## * the TCP protocol control block
  const
    TCP_SNDQUEUELEN_OVERFLOW* = (0xffff - 3)

  type
    TcpAcceptFn* = proc (arg: pointer; newpcb: ptr TcpPcb; err: ErrT): ErrT {.cdecl.}
      ## Function prototype for tcp accept callback functions. Called when a new
      ##  connection can be accepted on a listening pcb.
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param newpcb The new connection pcb
      ##  @param err An error code if there has been an error accepting.
      ##             Only return ERR_ABRT if you have called tcp_abort from within the
      ##             callback function!
      ##

    TcpRecvFn* = proc (arg: pointer; tpcb: ptr TcpPcb; p: ptr Pbuf; err: ErrT): ErrT {.cdecl.}
      ## * Function prototype for tcp receive callback functions. Called when data has
      ##  been received.
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param tpcb The connection pcb which received data
      ##  @param p The received data (or NULL when the connection has been closed!)
      ##  @param err An error code if there has been an error receiving
      ##             Only return ERR_ABRT if you have called tcp_abort from within the
      ##             callback function!
      ##

    TcpSentFn* = proc (arg: pointer; tpcb: ptr TcpPcb; len: uint16): ErrT {.cdecl.}
      ## * Function prototype for tcp sent callback functions. Called when sent data has
      ##  been acknowledged by the remote side. Use it to free corresponding resources.
      ## This also means that the pcb has now space available to send new data.
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param tpcb The connection pcb for which data has been acknowledged
      ##  @param len The amount of bytes acknowledged
      ##  @return ERR_OK: try to send some data by calling tcp_output
      ##             Only return ERR_ABRT if you have called tcp_abort from within the
      ##             callback function!
      ##

    TcpPollFn* = proc (arg: pointer; tpcb: ptr TcpPcb): ErrT {.cdecl.}
      ## * Function prototype for tcp poll callback functions. Called periodically as
      ##  specified by @see tcp_poll.
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param tpcb tcp pcb
      ##  @return ERR_OK: try to send some data by calling tcp_output
      ##             Only return ERR_ABRT if you have called tcp_abort from within the
      ##             callback function!
      ##

    TcpErrFn* = proc (arg: pointer; err: ErrT) {.cdecl.}
      ## * Function prototype for tcp error callback functions. Called when the pcb
      ##  receives a RST or is unexpectedly closed for any other reason.
      ##
      ##  @note The corresponding pcb is already freed when this callback is called!
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param err Error code to indicate why the pcb has been closed
      ##             ERR_ABRT: aborted through tcp_abort or by a TCP timer
      ##             ERR_RST: the connection was reset by the remote host
      ##

    TcpConnectedFn* = proc (arg: pointer; tpcb: ptr TcpPcb; err: ErrT): ErrT {.cdecl.}
      ## * Function prototype for tcp connected callback functions. Called when a pcb
      ##  is connected to the remote side after initiating a connection attempt by
      ##  calling tcp_connect().
      ##
      ##  @param arg Additional argument to pass to the callback function (@see tcp_arg())
      ##  @param tpcb The connection pcb which is connected
      ##  @param err An unused error code, always ERR_OK currently ;-) @todo!
      ##             Only return ERR_ABRT if you have called tcp_abort from within the
      ##             callback function!
      ##
      ##  @note When a connection attempt fails, the error callback is currently called!
      ##

    #[
    when defined(lwipWndScale):
      template rcv_Wnd_Scale*(pcb, wnd: untyped): untyped = (((wnd) shr (pcb).rcvScale))

      template snd_Wnd_Scale*(pcb, wnd: untyped): untyped = (((wnd) shl (pcb).sndScale))

      template tcpwnd16*(x: untyped): untyped = (cast[uint16](lwip_Min((x), 0xFFFF)))

      template tcp_Wnd_Max*(pcb: untyped): untyped = ((tcpwndSizeT)(if ((pcb).flags and tf_Wnd_Scale): tcp_Wnd else: tcpwnd16(tcp_Wnd)))

    else:
      template rcv_Wnd_Scale*(pcb, wnd: untyped): untyped = (wnd)

      template snd_Wnd_Scale*(pcb, wnd: untyped): untyped = (wnd)

      template tcpwnd16*(x: untyped): untyped = (x)

      template tcp_Wnd_Max*(pcb: untyped): untyped = tcp_Wnd


    ## Increments a tcpwnd_size_t and holds at max value rather than rollover
    template tcp_Wnd_Inc*(wnd, inc: untyped): void =
      while true:
        if (tcpwndSizeT)(wnd + inc) >= wnd:
          wnd = (tcpwndSizeT)(wnd + inc)
        else:
          wnd = (tcpwndSizeT) - 1
        if not 0:
          break
    ]#

    ##when defined(lwipTcpSackOut):
    TcpSackRange* {.importc: "struct tcp_sack_range", header: "lwip/tcp.h", bycopy.} = object
      ## * SACK ranges to include in ACK packets.
      ## SACK entry is invalid if left==right.
      left* {.importc: "left".}: uint32
      ## * Left edge of the SACK: the first acknowledged sequence number.
      right* {.importc: "right".}: uint32
      ## * Right edge of the SACK: the last acknowledged sequence number +1 (so first NOT acknowledged).

    ## *
    ##  members common to struct tcp_pcb and struct tcp_listen_pcb
    ##

    TcpPcbListen* {.importc: "struct tcp_pcb_listen", header: "lwip/tcp.h", bycopy.} = object
      ## * the TCP protocol control block for listening pcbs

      # IP_PCB
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

      # TCP_PCB_COMMON
      next* {.importc: "next".}: ptr TcpPcbListen
        ##  for the linked list
      callbackArg* {.importc: "callback_arg".}: pointer
      when defined(LWIP_TCP_PCB_NUM_EXT_ARGS):
        extArgs* {.importc: "ext_args".}: TcpPcbExtArgs[LWIP_TCP_PCB_NUM_EXT_ARGS]
      state* {.importc: "state".}: TcpState
        ## TCP state
      prio* {.importc: "prio".}: uint8
      # ports are in host byte order
      localPort* {.importc: "local_port".}: uint16

      when defined(lwipCallbackApi):
        ## Function to call when a listener has been connected.
        accept* {.importc: "accept".}: TcpAcceptFn
      when defined(tcpListenBacklog):
        backlog* {.importc: "backlog".}: uint8
        acceptsPending* {.importc: "accepts_pending".}: uint8


    TcpExtargCallbackPcbDestroyedFn* = proc (id: uint8; data: pointer) {.cdecl.}
      ## * Function prototype for deallocation of arguments. Called *just before* the
      ##  pcb is freed, so don't expect to be able to do anything with this pcb!
      ##
      ##  @param id ext arg id (allocated via @ref tcp_ext_arg_alloc_id)
      ##  @param data pointer to the data (set via @ref tcp_ext_arg_set before)
      ##

    TcpExtargCallbackPassiveOpenFn* = proc (id: uint8; lpcb: ptr TcpPcbListen; cpcb: ptr TcpPcb): ErrT {.cdecl.}
      ## * Function prototype to transition arguments from a listening pcb to an accepted pcb
      ##
      ##  @param id ext arg id (allocated via @ref tcp_ext_arg_alloc_id)
      ##  @param lpcb the listening pcb accepting a connection
      ##  @param cpcb the newly allocated connection pcb
      ##  @return ERR_OK if OK, any error if connection should be dropped
      ##

    TcpExtArgCallbacks* {.importc: "struct tcp_ext_arg_callbacks", header: "lwip/tcp.h", bycopy.} = object
      ## * A table of callback functions that is invoked for ext arguments
      destroy* {.importc: "destroy".}: TcpExtargCallbackPcbDestroyedFn ## * @ref
                                                                   ## tcp_extarg_callback_pcb_destroyed_fn
      ## * @ref tcp_extarg_callback_passive_open_fn
      passiveOpen* {.importc: "passive_open".}: TcpExtargCallbackPassiveOpenFn


      ##when defined(lwipTcpPcbNumExtArgs):
      ## This is the structure for ext args in tcp pcbs (used as array)

    TcpPcbExtArgs* {.importc: "struct tcp_pcb_ext_args", header: "lwip/tcp.h", bycopy.} = object
      callbacks* {.importc: "callbacks".}: ptr TcpExtArgCallbacks
      data* {.importc: "data".}: pointer

    TcpflagsT* = uint16

    TcpPcb* {.importc: "struct tcp_pcb", header: "lwip/tcp.h", bycopy.} = object

      # IP_PCB
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

      # TCP_PCB_COMMON
      next* {.importc: "next".}: ptr TcpPcb
        ##  for the linked list
      callbackArg* {.importc: "callback_arg".}: pointer
      when defined(LWIP_TCP_PCB_NUM_EXT_ARGS):
        extArgs* {.importc: "ext_args".}: TcpPcbExtArgs[LWIP_TCP_PCB_NUM_EXT_ARGS]
      state* {.importc: "state".}: TcpState
        ## TCP state
      prio* {.importc: "prio".}: uint8
      # ports are in host byte order
      localPort* {.importc: "local_port".}: uint16

      # ports are in host byte order
      remotePort* {.importc: "remote_port".}: uint16

      flags* {.importc: "flags".}: TcpflagsT

      ##  the rest of the fields are in host byte order
      ##      as we have to do some math with them
      ## Timers
      polltmr* {.importc: "polltmr".}: uint8
      pollinterval* {.importc: "pollinterval".}: uint8
      lastTimer* {.importc: "last_timer".}: uint8
      tmr* {.importc: "tmr".}: uint32 ##  receiver variables
      rcvNxt* {.importc: "rcv_nxt".}: uint32 ##  next seqno expected
      rcvWnd* {.importc: "rcv_wnd".}: TcpwndSizeT ##  receiver window available
      rcvAnnWnd* {.importc: "rcv_ann_wnd".}: TcpwndSizeT ##  receiver window to announce
      rcvAnnRightEdge* {.importc: "rcv_ann_right_edge".}: uint32 ##  announced right edge of window
                                                           ## Retransmission timer.
      rtime* {.importc: "rtime".}: int16
      mss* {.importc: "mss".}: uint16 ##  maximum segment size
                                ## RTT (round trip time) estimation variables
      rttest* {.importc: "rttest".}: uint32 ##  RTT estimate in 500ms ticks
      rtseq* {.importc: "rtseq".}: uint32 ##  sequence number being timed
      sa* {.importc: "sa".}: int16
      sv* {.importc: "sv".}: int16 ##  @see "Congestion Avoidance and Control" by Van Jacobson and Karels
      rto* {.importc: "rto".}: int16 ##  retransmission time-out (in ticks of TCP_SLOW_INTERVAL)
      nrtx* {.importc: "nrtx".}: uint8 ##  number of retransmissions
                                 ##  fast retransmit/recovery
      dupacks* {.importc: "dupacks".}: uint8
      lastack* {.importc: "lastack".}: uint32 ##  Highest acknowledged seqno.
                                        ##  congestion avoidance/control variables
      cwnd* {.importc: "cwnd".}: TcpwndSizeT
      ssthresh* {.importc: "ssthresh".}: TcpwndSizeT ##  first byte following last rto byte
      rtoEnd* {.importc: "rto_end".}: uint32 ##  sender variables
      sndNxt* {.importc: "snd_nxt".}: uint32 ##  next new seqno to be sent
      sndWl1* {.importc: "snd_wl1".}: uint32
      sndWl2* {.importc: "snd_wl2".}: uint32 ##  Sequence and acknowledgement numbers of last
                                       ##                              window update.
      sndLbb* {.importc: "snd_lbb".}: uint32 ##  Sequence number of next byte to be buffered.
      sndWnd* {.importc: "snd_wnd".}: TcpwndSizeT ##  sender window
      sndWndMax* {.importc: "snd_wnd_max".}: TcpwndSizeT ##  the maximum sender window announced by the remote host
      sndBuf* {.importc: "snd_buf".}: TcpwndSizeT ##  Available buffer space for sending (in bytes).
      sndQueuelen* {.importc: "snd_queuelen".}: uint16 ##  Number of pbufs currently in the send buffer.
      when defined(tcpOversize):
        ## Extra bytes available at the end of the last pbuf in unsent.
        unsentOversize* {.importc: "unsent_oversize".}: uint16
      bytesAcked* {.importc: "bytes_acked".}: TcpwndSizeT ##  These are ordered by sequence number:
      unsent* {.importc: "unsent".}: ptr TcpSeg ##  Unsent (queued) segments.
      unacked* {.importc: "unacked".}: ptr TcpSeg ##  Sent but unacknowledged segments.
      when defined(tcpQueueOoseq):
        ooseq* {.importc: "ooseq".}: ptr TcpSeg
        ## Received out of sequence segments.
      refusedData* {.importc: "refused_data".}: ptr Pbuf ##  Data previously received but not yet taken by upper layer
      when defined(lwipCallbackApi) or defined(tcpListenBacklog):
        listener* {.importc: "listener".}: ptr TcpPcbListen
      when defined(lwipCallbackApi):
        ## Function to be called when more send buffer space is available.
        sent* {.importc: "sent".}: TcpSentFn
        ## Function to be called when (in-sequence) data has arrived.
        recv* {.importc: "recv".}: TcpRecvFn
        ## Function to be called when a connection has been set up.
        connected* {.importc: "connected".}: TcpConnectedFn
        ## Function which is called periodically.
        poll* {.importc: "poll".}: TcpPollFn
        ## Function to be called whenever a fatal error occurs.
        errf* {.importc: "errf".}: TcpErrFn
      when defined(lwipTcpTimestamps):
        tsLastacksent* {.importc: "ts_lastacksent".}: uint32
        tsRecent* {.importc: "ts_recent".}: uint32
      keepIdle* {.importc: "keep_idle".}: uint32
        ##  idle time before KEEPALIVE is sent
      when defined(lwipTcpKeepalive):
        keepIntvl* {.importc: "keep_intvl".}: uint32
        keepCnt* {.importc: "keep_cnt".}: uint32
      persistCnt* {.importc: "persist_cnt".}: uint8
      ## Persist timer counter
      persistBackoff* {.importc: "persist_backoff".}: uint8
      ## Persist timer back-off
      persistProbe* {.importc: "persist_probe".}: uint8
      ## Number of persist probes
      keepCntSent* {.importc: "keep_cnt_sent".}: uint8
      ## KEEPALIVE counter
      when defined(lwipWndScale):
        sndScale* {.importc: "snd_scale".}: uint8
        rcvScale* {.importc: "rcv_scale".}: uint8

  when defined(lwipEventApi):
    type
      LwipEvent* {.size: sizeof(cint).} = enum
        LWIP_EVENT_ACCEPT, LWIP_EVENT_SENT, LWIP_EVENT_RECV, LWIP_EVENT_CONNECTED,
        LWIP_EVENT_POLL, LWIP_EVENT_ERR
    proc lwipTcpEvent*(arg: pointer; pcb: ptr TcpPcb; a3: LwipEvent; p: ptr Pbuf;
                      size: uint16; err: ErrT): ErrT {.importc: "lwip_tcp_event",
        header: "lwip/tcp.h".}
  ## Application program's interface:
  proc tcpNew*(): ptr TcpPcb {.importc: "tcp_new", header: "lwip/tcp.h".}
  proc tcpNewIpType*(`type`: uint8): ptr TcpPcb {.importc: "tcp_new_ip_type", header: "lwip/tcp.h".}
  proc tcpArg*(pcb: ptr TcpPcb; arg: pointer) {.importc: "tcp_arg", header: "lwip/tcp.h".}
  when defined(lwipCallbackApi):
    proc tcpRecv*(pcb: ptr TcpPcb; recv: TcpRecvFn) {.importc: "tcp_recv", header: "lwip/tcp.h".}
    proc tcpSent*(pcb: ptr TcpPcb; sent: TcpSentFn) {.importc: "tcp_sent", header: "lwip/tcp.h".}
    proc tcpErr*(pcb: ptr TcpPcb; err: TcpErrFn) {.importc: "tcp_err", header: "lwip/tcp.h".}
    proc tcpAccept*(pcb: ptr TcpPcb; accept: TcpAcceptFn) {.importc: "tcp_accept", header: "lwip/tcp.h".}
  proc tcpPoll*(pcb: ptr TcpPcb; poll: TcpPollFn; interval: uint8) {.importc: "tcp_poll", header: "lwip/tcp.h".}
  template tcpSetFlags*(pcb, setFlags: untyped): void =
    while true:
      (pcb).flags = (tcpflagsT)((pcb).flags or (setFlags))
      if not 0:
        break

  template tcpClearFlags*(pcb, clrFlags: untyped): void =
    while true:
      (pcb).flags = (tcpflagsT)((pcb).flags and
          (tcpflagsT)(not (clrFlags) and tcp_Allflags))
      if not 0:
        break

  template tcpIsFlagSet*(pcb, flag: untyped): untyped =
    (((pcb).flags and (flag)) != 0)

  when defined(lwipTcpTimestamps):
    template tcpMss*(pcb: untyped): untyped =
      (if ((pcb).flags and tf_Timestamp): ((pcb).mss - 12) else: (pcb).mss)

  else:
    ## * @ingroup tcp_raw
    template tcpMss*(pcb: untyped): untyped =
      ((pcb).mss)

  ## * @ingroup tcp_raw
  template tcpSndbuf*(pcb: untyped): untyped =
    (tcpwnd16((pcb).sndBuf))

  ## * @ingroup tcp_raw
  template tcpSndqueuelen*(pcb: untyped): untyped =
    ((pcb).sndQueuelen)

  ## * @ingroup tcp_raw
  template tcpNagleDisable*(pcb: untyped): untyped =
    tcpSetFlags(pcb, tf_Nodelay)

  ## * @ingroup tcp_raw
  template tcpNagleEnable*(pcb: untyped): untyped =
    tcpClearFlags(pcb, tf_Nodelay)

  ## * @ingroup tcp_raw
  template tcpNagleDisabled*(pcb: untyped): untyped =
    tcpIsFlagSet(pcb, tf_Nodelay)

  when defined(tcpListenBacklog):
    template tcpBacklogSet*(pcb, newBacklog: untyped): void =
      while true:
        lwip_Assert("pcb->state == LISTEN (called for wrong pcb?)",
                    (pcb).state == listen)
        (cast[ptr TcpPcbListen]((pcb))).backlog = (
            if (newBacklog): (newBacklog) else: 1)
        if not 0:
          break

    proc tcpBacklogDelayed*(pcb: ptr TcpPcb) {.importc: "tcp_backlog_delayed",
        header: "lwip/tcp.h".}
    proc tcpBacklogAccepted*(pcb: ptr TcpPcb) {.importc: "tcp_backlog_accepted",
        header: "lwip/tcp.h".}
  else:
    discard

  template tcpAccepted*(pcb: untyped): void =
    while true:                ##  compatibility define, not needed any more
      lwip_Unused_Arg(pcb)
      if not 0:
        break

  proc tcpRecved*(pcb: ptr TcpPcb; len: uint16) {.importc: "tcp_recved", header: "lwip/tcp.h".}
  proc tcpBind*(pcb: ptr TcpPcb; ipaddr: ptr IpAddrT; port: uint16): ErrT {.
      importc: "tcp_bind", header: "lwip/tcp.h".}
  proc tcpBindNetif*(pcb: ptr TcpPcb; netif: ptr Netif) {.importc: "tcp_bind_netif", header: "lwip/tcp.h".}
  proc tcpConnect*(pcb: ptr TcpPcb; ipaddr: ptr IpAddrT; port: uint16;
                  connected: TcpConnectedFn): ErrT {.importc: "tcp_connect",
      header: "lwip/tcp.h".}
  proc tcpListenWithBacklogAndErr*(pcb: ptr TcpPcb; backlog: uint8; err: ptr ErrT): ptr TcpPcb {.
      importc: "tcp_listen_with_backlog_and_err", header: "lwip/tcp.h".}
  proc tcpListenWithBacklog*(pcb: ptr TcpPcb; backlog: uint8): ptr TcpPcb {.
      importc: "tcp_listen_with_backlog", header: "lwip/tcp.h".}
  ## * @ingroup tcp_raw
  template tcpListen*(pcb: untyped): untyped =
    tcpListenWithBacklog(pcb, tcp_Default_Listen_Backlog)

  proc tcpAbort*(pcb: ptr TcpPcb) {.importc: "tcp_abort", header: "lwip/tcp.h".}
  proc tcpClose*(pcb: ptr TcpPcb): ErrT {.importc: "tcp_close", header: "lwip/tcp.h".}
  proc tcpShutdown*(pcb: ptr TcpPcb; shutRx: cint; shutTx: cint): ErrT {.
      importc: "tcp_shutdown", header: "lwip/tcp.h".}
  proc tcpWrite*(pcb: ptr TcpPcb; dataptr: pointer; len: uint16; apiflags: uint8): ErrT {.
      importc: "tcp_write", header: "lwip/tcp.h".}
  proc tcpSetprio*(pcb: ptr TcpPcb; prio: uint8) {.importc: "tcp_setprio", header: "lwip/tcp.h".}
  proc tcpOutput*(pcb: ptr TcpPcb): ErrT {.importc: "tcp_output", header: "lwip/tcp.h".}
  proc tcpGetTcpAddrinfo*(pcb: ptr TcpPcb; local: cint; `addr`: ptr IpAddrT;
                            port: ptr uint16): ErrT {.
      importc: "tcp_tcp_get_tcp_addrinfo", header: "lwip/tcp.h".}
  template tcpDbgGetTcpState*(pcb: untyped): untyped =
    ((pcb).state)

  ##  for compatibility with older implementation
  template tcpNewIp6*(): untyped =
    tcpNewIpType(IPADDR_TYPE_V6)

  when defined(lwipTcpPcbNumExtArgs):
    proc tcpExtArgAllocId*(): uint8 {.importc: "tcp_ext_arg_alloc_id", header: "lwip/tcp.h".}
    proc tcpExtArgSetCallbacks*(pcb: ptr TcpPcb; id: uint8;
                               callbacks: ptr TcpExtArgCallbacks) {.
        importc: "tcp_ext_arg_set_callbacks", header: "lwip/tcp.h".}
    proc tcpExtArgSet*(pcb: ptr TcpPcb; id: uint8; arg: pointer) {.
        importc: "tcp_ext_arg_set", header: "lwip/tcp.h".}
    proc tcpExtArgGet*(pcb: ptr TcpPcb; id: uint8): pointer {.importc: "tcp_ext_arg_get",
        header: "lwip/tcp.h".}