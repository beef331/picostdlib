
type
  IpHdr* {.bycopy, importc: "struct ip_hdr", header: "lwip/prot/ip4.h".} = object
