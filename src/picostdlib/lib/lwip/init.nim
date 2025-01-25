## *
##  @file
##  lwIP initialization API
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

{.push header: "lwip/init.h".}

## *
##  @defgroup lwip_version Version
##  @ingroup lwip
##  @{
##

let
  LWIP_VERSION_MAJOR* {.importc: "LWIP_VERSION_MAJOR".}: cint
    ## X.x.x: Major version of the stack

  LWIP_VERSION_MINOR* {.importc: "LWIP_VERSION_MINOR".}: cint
    ##  x.X.x: Minor version of the stack

  LWIP_VERSION_REVISION* {.importc: "LWIP_VERSION_REVISION".}: cint
    ##  x.x.X: Revision of the stack

  LWIP_VERSION_RC* {.importc: "LWIP_VERSION_RC".}: cint
    ## For release candidates, this is set to 1..254
    ## For official releases, this is set to 255 (LWIP_RC_RELEASE)
    ## For development versions (Git), this is set to 0 (LWIP_RC_DEVELOPMENT)

const
  LWIP_RC_RELEASE* = 255
    ## LWIP_VERSION_RC is set to LWIP_RC_RELEASE for official releases

  LWIP_RC_DEVELOPMENT* = 0
    ## LWIP_VERSION_RC is set to LWIP_RC_DEVELOPMENT for Git versions

let
  LWIP_VERSION_IS_RELEASE* {.importc: "LWIP_VERSION_IS_RELEASE".}: bool
  LWIP_VERSION_IS_DEVELOPMENT* {.importc: "LWIP_VERSION_IS_DEVELOPMENT".}: bool
  LWIP_VERSION_IS_RC* {.importc: "LWIP_VERSION_IS_RC".}: bool

##  Some helper defines to get a version string


let
  LWIP_VERSION* {.importc: "LWIP_VERSION".}: cint
    ## Provides the version of the stack

  LWIP_VERSION_STRING* {.importc: "LWIP_VERSION_STRING".}: cstring
    ## Provides the version of the stack as string


## *
##  @}
##


proc lwipInit*() {.importc: "lwip_init".}
  ## Modules initialization

{.pop.}
