## *
##  @file
##  pbuf API
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

import ./opt, ./err

export opt, err

## * LWIP_SUPPORT_CUSTOM_PBUF==1: Custom pbufs behave much like their pbuf type
##  but they are allocated by external code (initialised by calling
##  pbuf_alloced_custom()) and when pbuf_free gives up their last reference, they
##  are freed by calling pbuf_custom->custom_free_function().
##  Currently, the pbuf_custom code is only needed for one specific configuration
##  of IP_FRAG, unless required by external driver/application code.

# when not defined(LWIP_SUPPORT_CUSTOM_PBUF):
#   const
#     LWIP_SUPPORT_CUSTOM_PBUF* = ((ip_Frag and not lwip_Netif_Tx_Single_Pbuf) or
#         (lwip_Ipv6 and lwip_Ipv6Frag))

## * @ingroup pbuf
##  PBUF_NEEDS_COPY(p): return a boolean value indicating whether the given
##  pbuf needs to be copied in order to be kept around beyond the current call
##  stack without risking being corrupted. The default setting provides safety:
##  it will make a copy iof any pbuf chain that does not consist entirely of
##  PBUF_ROM type pbufs. For setups with zero-copy support, it may be redefined
##  to evaluate to true in all cases, for example. However, doing so also has an
##  effect on the application side: any buffers that are *not* copied must also
##  *not* be reused by the application after passing them to lwIP. For example,
##  when setting PBUF_NEEDS_COPY to (0), after using udp_send() with a PBUF_RAM
##  pbuf, the application must free the pbuf immediately, rather than reusing it
##  for other purposes. For more background information on this, see tasks #6735
##  and #7896, and bugs #11400 and #49914.

when not defined(PBUF_NEEDS_COPY):
  template pbuf_Needs_Copy*(p: untyped): untyped =
    ((p).typeInternal and pbuf_Type_Flag_Data_Volatile)

##  @todo: We need a mechanism to prevent wasting memory in every pbuf
##    (TCP vs. UDP, IPv4 vs. IPv6: UDP/IPv4 packets may waste up to 28 bytes)

const
  PBUF_TRANSPORT_HLEN* = 20

when defined(lwipIpv6):
  const
    PBUF_IP_HLEN* = 40
else:
  const
    PBUF_IP_HLEN* = 20
## *
##  @ingroup pbuf
##  Enumeration of pbuf layers
##

type PbufLayer* = distinct cint

let
  PBUF_TRANSPORT* {.importc: "PBUF_TRANSPORT", header: "lwip/pbuf.h".}: PbufLayer
    ## Includes spare room for transport layer header, e.g. UDP header.
    ## Use this if you intend to pass the pbuf to functions like udp_send().
  PBUF_IP* {.importc: "PBUF_IP", header: "lwip/pbuf.h".}: PbufLayer
    ## Includes spare room for IP header.
    ## Use this if you intend to pass the pbuf to functions like raw_send().
  PBUF_LINK* {.importc: "PBUF_LINK", header: "lwip/pbuf.h".}: PbufLayer
    ## Includes spare room for link layer header (ethernet header).
    ## Use this if you intend to pass the pbuf to functions like ethernet_output().
    ##  @see PBUF_LINK_HLEN
  PBUF_RAW_TX* {.importc: "PBUF_RAW_TX", header: "lwip/pbuf.h".}: PbufLayer
    ## Includes spare room for additional encapsulation header before ethernet
    ##  headers (e.g. 802.11).
    ## Use this if you intend to pass the pbuf to functions like netif->linkoutput().
    ##  @see PBUF_LINK_ENCAPSULATION_HLEN
  PBUF_RAW* {.importc: "PBUF_RAW", header: "lwip/pbuf.h".}: PbufLayer
    ## Use this for input packets in a netif driver when calling netif->input()
    ##  in the most common case - ethernet-layer netif driver.


##  Base flags for pbuf_type definitions:
## * Indicates that the payload directly follows the struct pbuf.
##   This makes @ref pbuf_header work in both directions.

const
  PBUF_TYPE_FLAG_STRUCT_DATA_CONTIGUOUS* = 0x80

## * Indicates the data stored in this pbuf can change. If this pbuf needs
##   to be queued, it must be copied/duplicated.

const
  PBUF_TYPE_FLAG_DATA_VOLATILE* = 0x40

## * 4 bits are reserved for 16 allocation sources (e.g. heap, pool1, pool2, etc)
##   Internally, we use: 0=heap, 1=MEMP_PBUF, 2=MEMP_PBUF_POOL -> 13 types free

const
  PBUF_TYPE_ALLOC_SRC_MASK* = 0x0F

## * Indicates this pbuf is used for RX (if not set, indicates use for TX).
##   This information can be used to keep some spare RX buffers e.g. for
##   receiving TCP ACKs to unblock a connection)

const
  PBUF_ALLOC_FLAG_RX* = 0x0100

## * Indicates the application needs the pbuf payload to be in one piece

const
  PBUF_ALLOC_FLAG_DATA_CONTIGUOUS* = 0x0200
  PBUF_TYPE_ALLOC_SRC_MASK_STD_HEAP* = 0x00
  PBUF_TYPE_ALLOC_SRC_MASK_STD_MEMP_PBUF* = 0x01
  PBUF_TYPE_ALLOC_SRC_MASK_STD_MEMP_PBUF_POOL* = 0x02

## * First pbuf allocation type for applications

const
  PBUF_TYPE_ALLOC_SRC_MASK_APP_MIN* = 0x03

## * Last pbuf allocation type for applications

const
  PBUF_TYPE_ALLOC_SRC_MASK_APP_MAX* = PBUF_TYPE_ALLOC_SRC_MASK

## *
##  @ingroup pbuf
##  Enumeration of pbuf types
##

type PbufType* = distinct cint

let
  PBUF_RAM* {.importc: "PBUF_RAM", header: "lwip/pbuf.h".}: PbufType
    ##  pbuf data is stored in RAM, used for TX mostly, struct pbuf and its payload
    ##  are allocated in one piece of contiguous memory (so the first payload byte
    ##  can be calculated from struct pbuf).
    ##  pbuf_alloc() allocates PBUF_RAM pbufs as unchained pbufs (although that might
    ##  change in future versions).
    ## This should be used for all OUTGOING packets (TX).
  PBUF_ROM* {.importc: "PBUF_ROM", header: "lwip/pbuf.h".}: PbufType
    ##  pbuf data is stored in ROM, i.e. struct pbuf and its payload are located in
    ##  totally different memory areas. Since it points to ROM, payload does not
    ##  have to be copied when queued for transmission.
  PBUF_REF* {.importc: "PBUF_REF", header: "lwip/pbuf.h".}: PbufType
    ##  pbuf comes from the pbuf pool. Much like PBUF_ROM but payload might change
    ##  so it has to be duplicated when queued before transmitting, depending on
    ##  who has a 'ref' to it.
  PBUF_POOL* {.importc: "PBUF_POOL", header: "lwip/pbuf.h".}: PbufType
    ##  pbuf payload refers to RAM. This one comes from a pool and should be used
    ##  for RX. Payload can be chained (scatter-gather RX) but like PBUF_RAM, struct
    ##  pbuf and its payload are allocated in one piece of contiguous memory (so
    ##  the first payload byte can be calculated from struct pbuf).
    ## Don't use this for TX, if the pool becomes empty e.g. because of TCP queuing,
    ##  you are unable to receive TCP acks!


## * indicates this packet's data should be immediately passed to the application

const
  PBUF_FLAG_PUSH* = 0x01

## * indicates this is a custom pbuf: pbuf_free calls pbuf_custom->custom_free_function()
##   when the last reference is released (plus custom PBUF_RAM cannot be trimmed)

const
  PBUF_FLAG_IS_CUSTOM* = 0x02

## * indicates this pbuf is UDP multicast to be looped back

const
  PBUF_FLAG_MCASTLOOP* = 0x04

## * indicates this pbuf was received as link-level broadcast

const
  PBUF_FLAG_LLBCAST* = 0x08

## * indicates this pbuf was received as link-level multicast

const
  PBUF_FLAG_LLMCAST* = 0x10

## * indicates this pbuf includes a TCP FIN flag

const
  PBUF_FLAG_TCP_FIN* = 0x20

const PBUF_NOT_FOUND* = 0xFFFF.uint16

## * Main packet buffer struct

type
  Pbuf* {.importc: "struct pbuf", header: "lwip/pbuf.h", bycopy.} = object
    next* {.importc: "next".}: ptr Pbuf ## * next pbuf in singly linked pbuf chain
    payload* {.importc: "payload".}: pointer
      ## * pointer to the actual data in the buffer
    totLen* {.importc: "tot_len".}: uint16
      ##  total length of this buffer and all next buffers in chain
      ##  belonging to the same packet.
      ##
      ## For non-queue packet chains this is the invariant:
      ##  p->tot_len == p->len + (p->next? p->next->tot_len: 0)
      ##
    len* {.importc: "len".}: uint16
      ## * length of this buffer
    typeInternal* {.importc: "type_internal".}: uint8
      ## * a bit field indicating pbuf type and allocation sources
      ##       (see PBUF_TYPE_FLAG_*, PBUF_ALLOC_FLAG_* and PBUF_TYPE_ALLOC_SRC_MASK)
      ##
    flags* {.importc: "flags".}: uint8
      ## * misc flags
    `ref`* {.importc: "ref".}: LwipPbufRefT
      ## *
      ##  the reference count always equals the number of pointers
      ##  that refer to this pbuf. This can be pointers from an application,
      ##  the stack itself, or pbuf->next pointers from a chain.
      ##
    ifIdx* {.importc: "if_idx".}: uint8
      ## * For incoming packets, this contains the input netif's index

      ## LWIP_PBUF_CUSTOM_DATA
      ## * In case the user needs to store data custom data on a pbuf


## * Helper struct for const-correctness only.
##  The only meaning of this one is to provide a const payload pointer
##  for PBUF_ROM type.
##
type
  PbufRomStruct* {.importc: "struct pbuf_rom", header: "lwip/pbuf.h", bycopy.} = object
    next* {.importc: "next".}: ptr Pbuf
      ## * next pbuf in singly linked pbuf chain
    payload* {.importc: "payload".}: pointer
      ## * pointer to the actual data in the buffer


when defined(lwipSupportCustomPbuf):
  ## * Prototype for a function to free a custom pbuf
  type
    PbufFreeCustomFn* = proc (p: ptr Pbuf)
  ## * A custom pbuf: like a pbuf, but following a function pointer to free it.
  type
    PbufCustom* {.importc: "pbuf_custom", header: "lwip/pbuf.h", bycopy.} = object
      pbuf* {.importc: "pbuf".}: Pbuf ## * The actual pbuf
      ## * This function is called when pbuf_free deallocates this pbuf(_custom)
      customFreeFunction* {.importc: "custom_free_function".}: PbufFreeCustomFn

## * Define this to 0 to prevent freeing ooseq pbufs when the PBUF_POOL is empty

when not defined(PBUF_POOL_FREE_OOSEQ):
  const
    PBUF_POOL_FREE_OOSEQ* = 1
when defined(lwipTcp) and defined(tcpQueueOoseq) and defined(noSys) and defined(pbufPoolFreeOoseq):
  var pbufFreeOoseqPending* {.importc: "pbuf_free_ooseq_pending", header: "lwip/pbuf.h".}: uint8
  proc pbufFreeOoseq*() {.importc: "pbuf_free_ooseq", header: "lwip/pbuf.h".}
  ## * When not using sys_check_timeouts(), call PBUF_CHECK_FREE_OOSEQ()
  ##     at regular intervals from main level to check if ooseq pbufs need to be
  ##     freed!
  template pbuf_Check_Free_Ooseq*(): void =
    while true:
      if pbufFreeOoseqPending:
        ##  pbuf_alloc() reported PBUF_POOL to be empty -> try to free some \
        ##      ooseq queued pbufs now
        pbufFreeOoseq()
      if not 0:
        break

else:
  ## Otherwise declare an empty PBUF_CHECK_FREE_OOSEQ
##  Initializes the pbuf module. This call is empty for now, but may not be in future.

proc pbufAlloc*(l: PbufLayer; length: uint16; `type`: PbufType): ptr Pbuf {.importc: "pbuf_alloc", header: "lwip/pbuf.h".}
proc pbufAllocReference*(payload: pointer; length: uint16; `type`: PbufType): ptr Pbuf {.importc: "pbuf_alloc_reference", header: "lwip/pbuf.h".}
when defined(lwipSupportCustomPbuf):
  proc pbufAllocedCustom*(l: PbufLayer; length: uint16; `type`: PbufType; p: ptr PbufCustom; payloadMem: pointer; payloadMemLen: uint16): ptr Pbuf {.importc: "pbuf_alloced_custom", header: "lwip/pbuf.h".}
proc pbufRealloc*(p: ptr Pbuf; size: uint16) {.importc: "pbuf_realloc", header: "lwip/pbuf.h".}
template pbufGetAllocsrc*(p: untyped): untyped =
  ((p).typeInternal and pbuf_Type_Alloc_Src_Mask)

template pbufMatchAllocsrc*(p, `type`: untyped): untyped =
  (pbufGetAllocsrc(p) == ((`type`) and pbuf_Type_Alloc_Src_Mask))

template pbufMatchType*(p, `type`: untyped): untyped =
  pbufMatchAllocsrc(p, `type`)

proc pbufHeader*(p: ptr Pbuf; headerSize: int16): uint8 {.importc: "pbuf_header", header: "lwip/pbuf.h".}
proc pbufHeaderForce*(p: ptr Pbuf; headerSize: int16): uint8 {.importc: "pbuf_header_force", header: "lwip/pbuf.h".}
proc pbufAddHeader*(p: ptr Pbuf; headerSizeIncrement: csize_t): uint8 {.importc: "pbuf_add_header", header: "lwip/pbuf.h".}
proc pbufAddHeaderForce*(p: ptr Pbuf; headerSizeIncrement: csize_t): uint8 {.importc: "pbuf_add_header_force", header: "lwip/pbuf.h".}
proc pbufRemoveHeader*(p: ptr Pbuf; headerSize: csize_t): uint8 {.importc: "pbuf_remove_header", header: "lwip/pbuf.h".}
proc pbufFreeHeader*(q: ptr Pbuf; size: uint16): ptr Pbuf {.importc: "pbuf_free_header", header: "lwip/pbuf.h".}
proc pbufRef*(p: ptr Pbuf) {.importc: "pbuf_ref", header: "lwip/pbuf.h".}
proc pbufFree*(p: ptr Pbuf): uint8 {.importc: "pbuf_free", header: "lwip/pbuf.h".}
proc pbufClen*(p: ptr Pbuf): uint16 {.importc: "pbuf_clen", header: "lwip/pbuf.h".}
proc pbufCat*(head: ptr Pbuf; tail: ptr Pbuf) {.importc: "pbuf_cat", header: "lwip/pbuf.h".}
proc pbufChain*(head: ptr Pbuf; tail: ptr Pbuf) {.importc: "pbuf_chain", header: "lwip/pbuf.h".}
proc pbufDechain*(p: ptr Pbuf): ptr Pbuf {.importc: "pbuf_dechain", header: "lwip/pbuf.h".}
proc pbufCopy*(pTo: ptr Pbuf; pFrom: ptr Pbuf): ErrT {.importc: "pbuf_copy", header: "lwip/pbuf.h".}
proc pbufCopyPartialPbuf*(pTo: ptr Pbuf; pFrom: ptr Pbuf; copyLen: uint16; offset: uint16): ErrT {.importc: "pbuf_copy_partial_pbuf", header: "lwip/pbuf.h".}
proc pbufCopyPartial*(p: ptr Pbuf; dataptr: pointer; len: uint16; offset: uint16): uint16 {.importc: "pbuf_copy_partial", header: "lwip/pbuf.h".}
proc pbufGetContiguous*(p: ptr Pbuf; buffer: pointer; bufsize: csize_t; len: uint16; offset: uint16): pointer {.importc: "pbuf_get_contiguous", header: "lwip/pbuf.h".}
proc pbufTake*(buf: ptr Pbuf; dataptr: pointer; len: uint16): ErrT {.importc: "pbuf_take", header: "lwip/pbuf.h".}
proc pbufTakeAt*(buf: ptr Pbuf; dataptr: pointer; len: uint16; offset: uint16): ErrT {.importc: "pbuf_take_at", header: "lwip/pbuf.h".}
proc pbufSkip*(`in`: ptr Pbuf; inOffset: uint16; outOffset: ptr uint16): ptr Pbuf {.importc: "pbuf_skip", header: "lwip/pbuf.h".}
proc pbufCoalesce*(p: ptr Pbuf; layer: PbufLayer): ptr Pbuf {.importc: "pbuf_coalesce", header: "lwip/pbuf.h".}
proc pbufClone*(l: PbufLayer; `type`: PbufType; p: ptr Pbuf): ptr Pbuf {.importc: "pbuf_clone", header: "lwip/pbuf.h".}
when defined(lwipChecksumOnCopy):
  proc pbufFillChksum*(p: ptr Pbuf; startOffset: uint16; dataptr: pointer; len: uint16;
                      chksum: ptr uint16): ErrT {.importc: "pbuf_fill_chksum", header: "lwip/pbuf.h".}
when defined(lwipTcp) and defined(tcpQueueOoseq) and defined(lwipWndScale):
  proc pbufSplit64k*(p: ptr Pbuf; rest: ptr ptr Pbuf) {.importc: "pbuf_split_64k", header: "lwip/pbuf.h".}
proc pbufGetAt*(p: ptr Pbuf; offset: uint16): uint8 {.importc: "pbuf_get_at", header: "lwip/pbuf.h".}
proc pbufTryGetAt*(p: ptr Pbuf; offset: uint16): cint {.importc: "pbuf_try_get_at", header: "lwip/pbuf.h".}
proc pbufPutAt*(p: ptr Pbuf; offset: uint16; data: uint8) {.importc: "pbuf_put_at", header: "lwip/pbuf.h".}
proc pbufMemcmp*(p: ptr Pbuf; offset: uint16; s2: pointer; n: uint16): uint16 {.importc: "pbuf_memcmp", header: "lwip/pbuf.h".}
proc pbufMemfind*(p: ptr Pbuf; mem: pointer; memLen: uint16; startOffset: uint16): uint16 {.importc: "pbuf_memfind", header: "lwip/pbuf.h".}
proc pbufStrstr*(p: ptr Pbuf; substr: cstring): uint16 {.importc: "pbuf_strstr", header: "lwip/pbuf.h".}


##  Nim helpers

proc pbufMemcmp*(p: ptr Pbuf; offset: int|uint16; s2: string): uint16 {.inline.} =
  assert(s2.len > 0)
  var cs2 = s2.cstring
  return p.pbufMemcmp(offset.uint16, cast[pointer](cs2[0].addr), cs2.len.uint16)

proc pbufMemfind*(p: ptr Pbuf; mem: string; startOffset: int|uint16): uint16 {.inline.} =
  assert(mem.len > 0)
  var cmem = mem.cstring
  return p.pbufMemfind(cast[pointer](cmem[0].addr), cmem.len.uint16, startOffset.uint16)

