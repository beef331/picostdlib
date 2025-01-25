## *
##  @file
##  Timer implementations
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
##          Simon Goldschmidt
##
##

import ./opt, ./err

# when not defined(noSys):
#   import ./sys

# when not defined(LWIP_DEBUG_TIMERNAMES):
#   when defined(LWIP_DEBUG):
#     const
#       LWIP_DEBUG_TIMERNAMES* = SYS_DEBUG
#   else:
#     const
#       LWIP_DEBUG_TIMERNAMES* = 0
## * Returned by sys_timeouts_sleeptime() to indicate there is no timer, so we
##  can sleep forever.
##

const
  SYS_TIMEOUTS_SLEEPTIME_INFINITE* = 0xFFFFFFFF

## * Function prototype for a stack-internal timer function that has to be
##  called at a defined interval

type
  LwipCyclicTimerHandler* = proc () {.cdecl.}

## * This struct contains information about a stack-internal timer function
##  that has to be called at a defined interval

type
  LwipCyclicTimer* {.importc: "lwip_cyclic_timer", header: "lwip/timeouts.h", bycopy.} = object
    intervalMs* {.importc: "interval_ms".}: uint32
    handler* {.importc: "handler".}: LwipCyclicTimerHandler
    when defined(lwipDebugTimernames):
      handlerName* {.importc: "handler_name".}: cstring


## * This array contains all stack-internal cyclic timers. To get the number of
##  timers, use lwip_num_cyclic_timers

let lwipCyclicTimers* {.importc: "lwip_cyclic_timers", header: "lwip/timeouts.h".}: ptr UncheckedArray[LwipCyclicTimer]

## * Array size of lwip_cyclic_timers[]

let lwipNumCyclicTimers* {.importc: "lwip_num_cyclic_timers", header: "lwip/timeouts.h".}: cint

when defined(lwipTimers):
  ## * Function prototype for a timeout callback function. Register such a function
  ##  using sys_timeout().
  ##
  ##  @param arg Additional argument to pass to the function - set up by sys_timeout()
  ##
  type
    SysTimeoutHandler* = proc (arg: pointer)
  type
    SysTimeo* {.importc: "struct sys_timeo", header: "lwip/timeouts.h", bycopy.} = object
      next* {.importc: "next".}: ptr SysTimeo
      time* {.importc: "time".}: uint32
      h* {.importc: "h".}: SysTimeoutHandler
      arg* {.importc: "arg".}: pointer
      when defined(lwipDebugTimernames):
        handlerName* {.importc: "handler_name".}: cstring

  proc sysTimeoutsInit*() {.importc: "sys_timeouts_init", header: "lwip/timeouts.h".}
  proc sysTimeout*(msecs: uint32; handler: SysTimeoutHandler; arg: pointer) {.importc: "sys_timeout", header: "lwip/timeouts.h".}
  proc sysUntimeout*(handler: SysTimeoutHandler; arg: pointer) {.importc: "sys_untimeout", header: "lwip/timeouts.h".}
  proc sysRestartTimeouts*() {.importc: "sys_restart_timeouts", header: "lwip/timeouts.h".}
  proc sysCheckTimeouts*() {.importc: "sys_check_timeouts", header: "lwip/timeouts.h".}
  proc sysTimeoutsSleeptime*(): uint32 {.importc: "sys_timeouts_sleeptime", header: "lwip/timeouts.h".}

  when defined(lwipTestmode):
    proc sysTimeoutsGetNextTimeout*(): ptr ptr SysTimeo {.importc: "sys_timeouts_get_next_timeout", header: "lwip/timeouts.h".}
    proc lwipCyclicTimer*(arg: pointer) {.importc: "lwip_cyclic_timer", header: "lwip/timeouts.h".}
