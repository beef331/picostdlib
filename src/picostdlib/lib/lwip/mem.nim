## *
##  @file
##  Heap API
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

when defined(memLibcMalloc):
  # import./arch

  type
    MemSizeT* = csize_t
    # MEM_SIZE_F* = szt_F
elif defined(memUsePools):
  type
    MemSizeT* = uint16
    # MEM_SIZE_F* = uint16
else:
  ## MEM_SIZE would have to be aligned, but using 64000 here instead of
  ## 65535 leaves some room for alignment...
  ##
  when mem_Size > 64000.clong:
    type
      MemSizeT* = uint32
      # MEM_SIZE_F* = uint32
  else:
    type
      MemSizeT* = uint16
      # MEM_SIZE_F* = uint16

proc memInit*() {.importc: "mem_init", header: "lwip/mem.h".}
proc memTrim*(mem: pointer; size: MemSizeT): pointer {.importc: "mem_trim", header: "lwip/mem.h".}
proc memMalloc*(size: MemSizeT): pointer {.importc: "mem_malloc", header: "lwip/mem.h".}
proc memCalloc*(count: MemSizeT; size: MemSizeT): pointer {.importc: "mem_calloc", header: "lwip/mem.h".}
proc memFree*(mem: pointer) {.importc: "mem_free", header: "lwip/mem.h".}
