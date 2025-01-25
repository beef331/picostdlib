## *
##  @file
##  Base TCP API definitions shared by TCP and ALTCP<br>
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

# import ./opt
# export opt

when defined(lwipTcp):
  when defined(lwipWndScale):
    type
      TcpwndSizeT* = uint32
  else:
    type
      TcpwndSizeT* = uint16
  type
    TcpState* {.size: sizeof(cint).} = enum
      CLOSED = 0
      LISTEN = 1
      SYN_SENT = 2
      SYN_RCVD = 3
      ESTABLISHED = 4
      FIN_WAIT_1 = 5
      FIN_WAIT_2 = 6
      CLOSE_WAIT = 7
      CLOSING = 8
      LAST_ACK = 9
      TIME_WAIT = 10

  ## ATTENTION: this depends on state number ordering!
  template tcp_State_Is_Closing*(state: untyped): untyped = ((state) >= fin_Wait_1)

  ## Flags for "apiflags" parameter in tcp_write
  const
    TCP_WRITE_FLAG_COPY* = 0x01
    TCP_WRITE_FLAG_MORE* = 0x02
    TCP_PRIO_MIN* = 1
    TCP_PRIO_NORMAL* = 64
    TCP_PRIO_MAX* = 127

  proc tcpDebugStateStr*(s: TcpState): cstring {.importc: "tcp_debug_state_str", header: "lwip/tcpbase.h".}
