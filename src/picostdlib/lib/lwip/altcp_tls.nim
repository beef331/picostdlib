## *
##  @file
##  Application layered TCP/TLS connection API (to be used from TCPIP thread)
##
##  @defgroup altcp_tls TLS layer
##  @ingroup altcp
##  This file contains function prototypes for a TLS layer.
##  A port to ARM mbedtls is provided in the apps/ tree
##  (LWIP_ALTCP_TLS_MBEDTLS option).
##
##
##  Copyright (c) 2017 Simon Goldschmidt
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
##  Author: Simon Goldschmidt <goldsimon@gmx.de>
##
##

import ./opt

when defined(lwipAltcp):
  when defined(lwipAltcpTls):
    import ./altcp
    export altcp

    ##  check if mbedtls port is enabled
    # import ./apps/altcpTlsMbedtlsOpts

    ##  allow session structure to be fully defined when using mbedtls port
    when defined(lwipAltcpTlsMbedtls):
      import ../mbedtls/ssl
      export ssl

    ## * @ingroup altcp_tls
    ## ALTCP_TLS configuration handle, content depends on port (e.g. mbedtls)
    ##
    discard "forward decl of altcp_tls_config"
    type
      AltcpTlsConfig* {.importc: "struct altcp_tls_config", header: "lwip/altcp_tls.h"} = object

    proc altcpTlsCreateConfigServer*(certCount: uint8): ptr AltcpTlsConfig {.importc: "altcp_tls_create_config_server", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Add a certificate to an ALTCP_TLS server configuration handle
    ##
    proc altcpTlsConfigServerAddPrivkeyCert*(config: ptr AltcpTlsConfig;
        privkey: ptr uint8; privkeyLen: csize_t; privkeyPass: ptr uint8;
        privkeyPassLen: csize_t; cert: ptr uint8; certLen: csize_t): ErrT {.importc: "altcp_tls_config_server_add_privkey_cert", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create an ALTCP_TLS server configuration handle with one certificate
    ##  (short version of calling @ref altcp_tls_create_config_server and
    ##  @ref altcp_tls_config_server_add_privkey_cert)
    ##
    proc altcpTlsCreateConfigServerPrivkeyCert*(privkey: ptr uint8;
        privkeyLen: csize_t; privkeyPass: ptr uint8; privkeyPassLen: csize_t;
        cert: ptr uint8; certLen: csize_t): ptr AltcpTlsConfig {.importc: "altcp_tls_create_config_server_privkey_cert", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create an ALTCP_TLS client configuration handle
    ##
    proc altcpTlsCreateConfigClient*(cert: ptr uint8; certLen: csize_t): ptr AltcpTlsConfig {.importc: "altcp_tls_create_config_client", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create an ALTCP_TLS client configuration handle with two-way server/client authentication
    ##
    proc altcpTlsCreateConfigClient2wayauth*(ca: ptr uint8; caLen: csize_t;
        privkey: ptr uint8; privkeyLen: csize_t; privkeyPass: ptr uint8;
        privkeyPassLen: csize_t; cert: ptr uint8; certLen: csize_t): ptr AltcpTlsConfig {.importc: "altcp_tls_create_config_client_2wayauth", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Configure ALPN TLS extension
    ## Example:<br>
    ##  static const char *g_alpn_protocols[] = { "x-amzn-mqtt-ca", NULL };<br>
    ##  tls_config = altcp_tls_create_config_client(ca, ca_len);<br>
    ##  altcp_tls_conf_alpn_protocols(tls_config, g_alpn_protocols);<br>
    ##
    proc altcpTlsConfigureAlpnProtocols*(conf: ptr AltcpTlsConfig; protos: cstringArray): cint {.importc: "altcp_tls_configure_alpn_protocols", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Free an ALTCP_TLS configuration handle
    ##
    proc altcpTlsFreeConfig*(conf: ptr AltcpTlsConfig) {.importc: "altcp_tls_free_config", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Free an ALTCP_TLS global entropy instance.
    ## All ALTCP_TLS configuration are linked to one altcp_tls_entropy_rng structure
    ##  that handle an unique system entropy & ctr_drbg instance.
    ## This function allow application to free this altcp_tls_entropy_rng structure
    ##  when all configuration referencing it were destroyed.
    ## This function does nothing if some ALTCP_TLS configuration handle are still
    ##  active.
    ##
    proc altcpTlsFreeEntropy*() {.importc: "altcp_tls_free_entropy", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create new ALTCP_TLS layer wrapping an existing pcb as inner connection (e.g. TLS over TCP)
    ##
    proc altcpTlsWrap*(config: ptr AltcpTlsConfig; innerPcb: ptr AltcpPcb): ptr AltcpPcb {.importc: "altcp_tls_wrap", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create new ALTCP_TLS pcb and its inner tcp pcb
    ##
    proc altcpTlsNew*(config: ptr AltcpTlsConfig; ipType: uint8): ptr AltcpPcb {.importc: "altcp_tls_new", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Create new ALTCP_TLS layer pcb and its inner tcp pcb.
    ## Same as @ref altcp_tls_new but this allocator function fits to
    ##  @ref altcp_allocator_t / @ref altcp_new.<br>
    ##  'arg' must contain a struct altcp_tls_config *.
    ##
    proc altcpTlsAlloc*(arg: pointer; ipType: uint8): ptr AltcpPcb {.importc: "altcp_tls_alloc", header: "lwip/altcp_tls.h", cdecl.}
    ## * @ingroup altcp_tls
    ## Return pointer to internal TLS context so application can tweak it.
    ## Real type depends on port (e.g. mbedtls)
    ##
    proc altcpTlsContext*(conn: ptr AltcpPcb): pointer {.importc: "altcp_tls_context", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## ALTCP_TLS session handle, content depends on port (e.g. mbedtls)
    ##
    type
      AltcpTlsSession* {.importc: "altcp_tls_session", header: "lwip/altcp_tls.h", bycopy.} = object
        # when defined(lwipAltcpTlsMbedtls):
        #   data* {.importc: "data".}: MbedtlsSslSession

    ## * @ingroup altcp_tls
    ## Initialise a TLS session buffer.
    ## Real type depends on port (e.g. mbedtls use mbedtls_ssl_session)
    ##
    proc altcpTlsInitSession*(dest: ptr AltcpTlsSession) {.importc: "altcp_tls_init_session", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Save current connected session to reuse it later. Should be called after altcp_connect() succeeded.
    ## Return error if saving session fail.
    ## Real type depends on port (e.g. mbedtls use mbedtls_ssl_session)
    ##
    proc altcpTlsGetSession*(conn: ptr AltcpPcb; dest: ptr AltcpTlsSession): ErrT {.importc: "altcp_tls_get_session", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Restore a previously saved session. Must be called before altcp_connect().
    ## Return error if cannot restore session.
    ## Real type depends on port (e.g. mbedtls use mbedtls_ssl_session)
    ##
    proc altcpTlsSetSession*(conn: ptr AltcpPcb; `from`: ptr AltcpTlsSession): ErrT {.importc: "altcp_tls_set_session", header: "lwip/altcp_tls.h".}
    ## * @ingroup altcp_tls
    ## Free allocated data inside a TLS session buffer.
    ## Real type depends on port (e.g. mbedtls use mbedtls_ssl_session)
    ##
    proc altcpTlsFreeSession*(dest: ptr AltcpTlsSession) {.importc: "altcp_tls_free_session", header: "lwip/altcp_tls.h".}
