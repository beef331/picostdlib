## *
##  @file
##  various utility macros
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
## *
##  @defgroup perf Performance measurement
##  @ingroup sys_layer
##  All defines related to this section must not be placed in lwipopts.h,
##  but in arch/perf.h!
##  Measurement calls made throughout lwip, these can be defined to nothing.
##  - PERF_START: start measuring something.
##  - PERF_STOP(x): stop measuring something, and record the result.
##

##  arch.h might define NULL already

# import ./arch
import ./opt

when defined(lwipPerf):
  import
    arch/perf

else:
  ## #define PERF_START    /* null definition */
  ## #define PERF_STOP(x)  /* null definition */

template lwip_Max*(x, y: untyped): untyped =
  (if ((x) > (y)): (x) else: (y))

template lwip_Min*(x, y: untyped): untyped =
  (if ((x) < (y)): (x) else: (y))

##  Get the number of entries in an array ('x' must NOT be a pointer!)

template lwip_Arraysize*(x: untyped): untyped =
  (sizeof((x) div sizeof(((x)[0]))))

## * Create u32_t value from bytes

template lwip_Makeu32*(a, b, c, d: untyped): untyped =
  (((u32T)((a) and 0xff) shl 24) or ((u32T)((b) and 0xff) shl 16) or
      ((u32T)((c) and 0xff) shl 8) or (u32T)((d) and 0xff))

when not defined(NULL):
  discard
when cpuEndian == Endianness.bigEndian:
  template lwipHtons*(x: untyped): untyped =
    ((u16T)(x))

  template lwipNtohs*(x: untyped): untyped =
    ((u16T)(x))

  template lwipHtonl*(x: untyped): untyped =
    ((u32T)(x))

  template lwipNtohl*(x: untyped): untyped =
    ((u32T)(x))

  template pp_Htons*(x: untyped): untyped =
    ((u16T)(x))

  template pp_Ntohs*(x: untyped): untyped =
    ((u16T)(x))

  template pp_Htonl*(x: untyped): untyped =
    ((u32T)(x))

  template pp_Ntohl*(x: untyped): untyped =
    ((u32T)(x))

else:
  when not defined(lwip_htons):
    proc lwipHtons*(x: uint16): uint16 {.importc: "lwip_htons", header: "lwip/def.h".}
  template lwipNtohs*(x: untyped): untyped =
    lwipHtons(x)

  when not defined(lwip_htonl):
    proc lwipHtonl*(x: uint32): uint32 {.importc: "lwip_htonl", header: "lwip/def.h".}
  template lwipNtohl*(x: untyped): untyped =
    lwipHtonl(x)

  ## These macros should be calculated by the preprocessor and are used
  ##    with compile-time constants only (so that there is no little-endian
  ##    overhead at runtime).
  template pp_Htons*(x: untyped): untyped =
    ((u16T)((((x) and cast[uint16](0x00ff)) shl 8) or
        (((x) and cast[uint16](0xff00)) shr 8)))

  template pp_Ntohs*(x: untyped): untyped =
    pp_Htons(x)

  template pp_Htonl*(x: untyped): untyped =
    ((((x) and cast[uint32](0x000000ff)) shl 24) or
        (((x) and cast[uint32](0x0000ff00)) shl 8) or
        (((x) and cast[uint32](0x00ff0000)) shr 8) or
        (((x) and cast[uint32](0xff000000)) shr 24))

  template pp_Ntohl*(x: untyped): untyped =
    pp_Htonl(x)

##  Provide usual function names as macros for users, but this can be turned off

when not defined(LWIP_DONT_PROVIDE_BYTEORDER_FUNCTIONS):
  template htons*(x: untyped): untyped =
    lwipHtons(x)

  template ntohs*(x: untyped): untyped =
    lwipNtohs(x)

  template htonl*(x: untyped): untyped =
    lwipHtonl(x)

  template ntohl*(x: untyped): untyped =
    lwipNtohl(x)

##  Functions that are not available as standard implementations.
##  In cc.h, you can #define these to implementations available on
##  your platform to save some code bytes if you use these functions
##  in your application, too.
##

when not defined(lwip_itoa):
  ## This can be #defined to itoa() or snprintf(result, bufsize, "%d", number) depending on your platform
  proc lwipItoa*(result: cstring; bufsize: csize_t; number: cint) {.
      importc: "lwip_itoa", header: "lwip/def.h".}
when not defined(lwip_strnicmp):
  ## This can be #defined to strnicmp() or strncasecmp() depending on your platform
  proc lwipStrnicmp*(str1: cstring; str2: cstring; len: csize_t): cint {.
      importc: "lwip_strnicmp", header: "lwip/def.h".}
when not defined(lwip_stricmp):
  ## This can be #defined to stricmp() or strcasecmp() depending on your platform
  proc lwipStricmp*(str1: cstring; str2: cstring): cint {.importc: "lwip_stricmp",
      header: "lwip/def.h".}
when not defined(lwip_strnstr):
  ## This can be #defined to strnstr() depending on your platform
  proc lwipStrnstr*(buffer: cstring; token: cstring; n: csize_t): cstring {.
      importc: "lwip_strnstr", header: "lwip/def.h".}
when not defined(lwip_strnistr):
  ## This can be #defined to strnistr() depending on your platform
  proc lwipStrnistr*(buffer: cstring; token: cstring; n: csize_t): cstring {.
      importc: "lwip_strnistr", header: "lwip/def.h".}