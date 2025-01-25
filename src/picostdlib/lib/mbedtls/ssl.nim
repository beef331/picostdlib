
{.push header: "mbedtls/ssl.h".}

type
  MbedtlsSslContext* {.importc: "struct mbedtls_ssl_context", bycopy.} = object

proc mbedtlsSslSetHostname*(ssl: ptr MbedtlsSslContext; hostname: cstring): cint {.importc: "mbedtls_ssl_set_hostname".}

{.pop.}
