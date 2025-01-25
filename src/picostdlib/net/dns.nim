import ../lib/lwip
import ../pico/cyw43_arch
import ../asyncdispatch

when not defined(release) or defined(debugDns):
  template debugv(text: string) = echo text
else:
  template debugv(text: string) = discard

type
  DnsState = object
    ipaddr: IpAddrT
    running: bool
    err: bool

  DnsCallback* = proc(hostname: string; ipaddr: ptr IpAddrT)

var dnsCbSlots: array[DNS_MAX_REQUESTS, DnsCallback]

proc getSlot(): int =
  for i, slot in dnsCbSlots:
    if slot == nil:
      return i
  return -1

proc dnsGethostbynameCb(hostname: cstring; ipaddr: ptr IpAddrT; arg: pointer) {.cdecl.} =
  assert(arg != nil)
  let slotIndex = (cast[uint](arg) - cast[uint](dnsCbSlots[0].addr)).int div sizeof(dnsCbSlots[0])
  assert(slotIndex >= 0 and slotIndex < dnsCbSlots.len)
  let callback = dnsCbSlots[slotIndex]
  # cast[ref DnsCbState](arg)
  if callback == nil: return
  dnsCbSlots[slotIndex] = nil
  #GC_unref(state)
  callback($hostname, ipaddr)

proc getHostByName*(hostname: string; callback: DnsCallback): bool =
  var err: ErrEnumT
  var ipaddrIn: IpAddrT

  withLwipLock:
    var slotIndex = getSlot()
    if slotIndex < 0:
      debugv(":dns callback count limit reached")
      return false
    #var state = new(DnsCbState)
    #state.callback = callback
    dnsCbSlots[slotIndex] = callback

    err = dnsGethostbyname(hostname.cstring, ipaddrIn.addr, dnsGethostbynameCb, dnsCbSlots[slotIndex].addr).ErrEnumT

    if err == ErrInprogress:
      #GC_ref(state)
      return true
    elif err != ErrOk:
      debugv(":dns err=" & $err & " " & hostname)
      dnsCbSlots[slotIndex] = nil
      return false
    debugv(":dns found " & $ipaddrIn)
    dnsCbSlots[slotIndex] = nil
    callback(hostname, ipaddrIn.addr)
    return true

proc getHostByName*(hostname: string; ipaddr: var IpAddrT; timeoutMs: Natural = 5000): bool =
  var state = DnsState(running: true)
  let ok = getHostByName(hostname, proc (hostnameOut: string; ipaddrOut: ptr IpAddrT) =
    if ipaddrOut != nil:
      state.ipaddr = ipaddrOut[]
    state.err = ipaddrOut.isNil
    state.running = false
  )
  if not ok or state.err:
    return false
  if not state.running:
    ipaddr = state.ipaddr
    return true

  pollDelay(timeoutMs, state.running)

  if state.running:
    return false

  ipaddr = state.ipaddr
  return true

proc getHostByName*(hostname: string; timeoutMs: Natural = 5000): owned Future[IpAddrT] =
  var retFuture = newFuture[IpAddrT]("getHostByName")
  var state = DnsState(running: true)

  let ok = getHostByName(hostname, proc (hostnameOut: string; ipaddrOut: ptr IpAddrT) =
    state.running = false
    state.err = ipaddrOut.isNil
    if ipaddrOut != nil:
      state.ipaddr = ipaddrOut[]
      retFuture.complete(state.ipaddr)
    else:
      retFuture.fail(newException(CatchableError, "getHostByName: DNS not found for " & hostname))
  )
  if not ok or state.err:
    retFuture.fail(newException(CatchableError, "getHostByName: DNS error for " & hostname))

  return retFuture
