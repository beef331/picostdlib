## *
##  @file
##  lwIP Error codes
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

## *
##  @defgroup infrastructure_errors Error codes
##  @ingroup infrastructure
##  @{
##
## * Definitions for error constants.

type
  ErrEnumT* {.pure, size: sizeof(cint).} = enum
    ERR_ARG        = -16
      ## Illegal argument.
    ERR_CLSD       = -15
      ## Connection closed.
    ERR_RST        = -14
      ## Connection reset.
    ERR_ABRT       = -13
      ## Connection aborted.

    ERR_IF         = -12
      ## Low-level netif error
    ERR_CONN       = -11
      ## Not connected.
    ERR_ISCONN     = -10
      ## Conn already established.
    ERR_ALREADY    = -9
      ## Already connecting.
    ERR_USE        = -8
      ## Address in use.
    ERR_WOULDBLOCK = -7
      ## Operation would block.
    ERR_VAL        = -6
      ## Illegal value.
    ERR_INPROGRESS = -5
      ## Operation in progress
    ERR_RTE        = -4
      ## Routing problem.
    ERR_TIMEOUT    = -3
      ## Timeout.
    ERR_BUF        = -2
      ## Buffer error.
    ERR_MEM        = -1
      ## Out of memory error.
    ERR_OK         = 0,
      ## No error, everything OK.


## * Define LWIP_ERR_T in cc.h if you want to use
##   a different type for your platform (must be signed).

when defined(LWIP_ERR_T):
  type
    ErrT* = Lwip_Err_T
else:
  type
    ErrT* = int8
## *
##  @}
##

when defined(LWIP_DEBUG):
  proc lwipStrerr*(err: ErrT): cstring {.importc: "lwip_strerr", header: "lwip/err.h".}
else:
  template lwipStrerr*(x: untyped): untyped =
    ""

when not defined(noSys):
  proc errToErrno*(err: ErrT): cint {.importc: "err_to_errno", header: "lwip/err.h".}