type
  Port* = distinct uint16

proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}
