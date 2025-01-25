
let tStackLimit* {.importc: "__StackLimit".}: cchar
let tStackBottom* {.importc: "__StackBottom".}: cchar
let tBssEnd* {.importc: "__bss_end__".}: cchar

template StackLimit*: untyped = cast[int](tStackLimit.unsafeAddr)
template StackBottom*: untyped = cast[int](tStackBottom.unsafeAddr)
template BssEnd*: untyped = cast[int](tBssEnd.unsafeAddr)

type
  MallInfo* {.importc: "struct mallinfo", header: "<malloc.h>".} = object
    arena*: csize_t    ## total space allocated from system
    ordblks*: csize_t  ## number of non-inuse chunks
    smblks*: csize_t   ## unused -- always zero
    hblks*: csize_t    ## number of mmapped regions
    hblkhd*: csize_t   ## total space in mmapped regions
    usmblks*: csize_t  ## unused -- always zero
    fsmblks*: csize_t  ## unused -- always zero
    uordblks*: csize_t ## total allocated space
    fordblks*: csize_t ## total non-inuse space
    keepcost*: csize_t ## top-most, releasable (via malloc_trim) space

proc mallinfo*(): MallInfo {.importc: "mallinfo", header: "<malloc.h>".}

proc getTotalHeap*(): int {.inline.} =
  return StackLimit - BssEnd

proc getUsedHeap*(): int {.inline.} =
  return mallinfo().uordblks.int

proc getFreeHeap*(): int {.inline.} =
  return getTotalHeap() - getUsedHeap()
