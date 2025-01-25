#
# HTTPClient.h
#
# Modified 2022 by Earle F. Philhower, III
#
# Created on: 02.11.2015
#
# Copyright (c) 2015 Markus Sattler. All rights reserved.
# This file is part of the ESP8266HTTPClient for Arduino.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# Modified by Jeroen Döll, June 2018
#
# Adapted from https://github.com/earlephilhower/arduino-pico/blob/master/libraries/HTTPClient/src/HTTPClient.h
#

import std/strutils
import std/streams
import std/uri
import std/base64
import std/httpcore
import std/parseutils

import ../pico/time
import ./wifi/tcpcontext

export streams, uri, tcpcontext

proc pipe(s: Stream; c: Stream; chunkSize: static[int] = 1000; size = -1): int =
  var buffer = newString(chunkSize)
  let endMs = makeTimeoutTimeMs(5000)
  while not s.atEnd() and diffUs(getAbsoluteTime(), endMs) > 0:
    let readSize = if size < 0: buffer.len else: min(buffer.len, size - result)
    if readSize <= 0:
      break
    let x = s.readData(addr(buffer[0]), readSize)
    if x <= 0:
      break
    if x > 0:
      c.writeData(addr(buffer[0]), x)
      inc(result, x)

  return result


proc DEBUG_HTTPCLIENT(formatstr: cstring) {.importc: "printf", varargs, header: "<stdio.h>".}

# when defined(DEBUG_ESP_HTTP_CLIENT):
#   when defined(DEBUG_ESP_PORT):
#     ## #define DEBUG_HTTPCLIENT(fmt, ...) DEBUG_ESP_PORT.printf_P( (PGM_P)PSTR(fmt), ## __VA_ARGS__ )
# ## #define DEBUG_HTTPCLIENT(fmt, ...) Serial.printf(fmt, ## __VA_ARGS__ )

# when not defined(DEBUG_HTTPCLIENT):
#   ## #define DEBUG_HTTPCLIENT(...) do { (void)0; } while (0)

type
  ChunkedState = enum
    CHUNKED_IN_CHUNK_SIZE
    CHUNKED_IN_CHUNK_EXT
    CHUNKED_IN_CHUNK_DATA
    CHUNKED_IN_CHUNK_CRLF
    CHUNKED_IN_TRAILERS_LINE_HEAD
    CHUNKED_IN_TRAILERS_LINE_MIDDLE
  ChunkedDecoder* = object
    bytes_left_in_chunk*: uint # number of bytes left in current chunk
    consume_trailer*: bool # if trailing headers should be consumed
    hex_count: uint8
    state: ChunkedState
    total_read: uint64
    total_overhead: uint64

func decodeHex(ch: char): int =
  if ord('0') <= ord(ch) and ord(ch) <= ord('9'):
    return ord(ch) - ord('0')
  elif ord('A') <= ord(ch) and ord(ch) <= ord('F'):
    return ord(ch) - ord('A') + 0xa
  elif ord('a') <= ord(ch) and ord(ch) <= ord('f'):
    return ord(ch) - ord('a') + 0xa
  else:
    return -1

proc decodeChunked*(decoder: var ChunkedDecoder; buf: ptr UncheckedArray[char]; bufsz: var uint): int =
  var dst: uint = 0
  var src: uint = 0
  var ret: int = -2 # incomplete
  var complete = false

  decoder.total_read += bufsz

  block outer:
    while true:
      case decoder.state:
      of CHUNKED_IN_CHUNK_SIZE:
        while true:
          if src == bufsz:
            break outer
          let v = decodeHex(buf[src])
          if v == -1:
            if decoder.hex_count == 0:
              ret = -1
              break outer

            # the only characters that may appear after the chunk size are BWS, semicolon, or CRLF
            case buf[src]:
            of ' ', '\x09', ';', '\x0a', '\x0d':
              discard
            else:
              ret = -1;
              break outer
            break

          if decoder.hex_count == sizeof(csize_t) * 2:
            ret = -1
            break outer

          decoder.bytes_left_in_chunk = decoder.bytes_left_in_chunk * 16 + v.uint
          inc(decoder.hex_count)
          inc(src)

        decoder.hex_count = 0
        decoder.state = CHUNKED_IN_CHUNK_EXT

      of CHUNKED_IN_CHUNK_EXT:
        # RFC 7230 A.2 "Line folding in chunk extensions is disallowed"
        while true:
          if src == bufsz:
            break outer
          if buf[src] == '\x0a':
            break
          inc(src)

        inc(src)
        if decoder.bytes_left_in_chunk == 0:
          if decoder.consume_trailer:
            decoder.state = CHUNKED_IN_TRAILERS_LINE_HEAD
            break
          else:
            complete = true
            break outer

        decoder.state = CHUNKED_IN_CHUNK_DATA

      of CHUNKED_IN_CHUNK_DATA:
        let avail = bufsz - src
        if avail < decoder.bytes_left_in_chunk:
          if dst != src:
            moveMem(buf[dst].addr, buf[src].addr, avail)
          src += avail
          dst += avail
          decoder.bytes_left_in_chunk -= avail
          break outer;

        if dst != src:
          moveMem(buf[dst].addr, buf[src].addr, decoder.bytes_left_in_chunk)
        src += decoder.bytes_left_in_chunk
        dst += decoder.bytes_left_in_chunk
        decoder.bytes_left_in_chunk = 0
        decoder.state = CHUNKED_IN_CHUNK_CRLF

      of CHUNKED_IN_CHUNK_CRLF:
        while true:
          if src == bufsz:
            break outer
          if buf[src] != '\x0d':
            break
          inc(src)

        if buf[src] != '\x0a':
          ret = -1
          break outer

        inc(src)
        decoder.state = CHUNKED_IN_CHUNK_SIZE

      of CHUNKED_IN_TRAILERS_LINE_HEAD:
        while true:
          if src == bufsz:
            break outer
          if buf[src] != '\x0d':
            break
          inc(src)

        inc(src)
        if buf[src - 1] == '\x0a':
          complete = true
          break outer
        decoder.state = CHUNKED_IN_TRAILERS_LINE_MIDDLE

      of CHUNKED_IN_TRAILERS_LINE_MIDDLE:
        while true:
          if src == bufsz:
            break outer
          if buf[src] == '\x0a':
            break
          inc(src)

        inc(src)
        decoder.state = CHUNKED_IN_TRAILERS_LINE_HEAD

  if complete:
    ret = int bufsz - src

  if dst != src:
    moveMem(buf[dst].addr, buf[src].addr, bufsz - src)
  bufsz = dst
  # if incomplete but the overhead of the chunked encoding is >=100KB and >80%, signal an error
  if ret == -2:
    decoder.total_overhead += bufsz - dst
    if decoder.total_overhead >= 100 * 1024 and decoder.total_read - decoder.total_overhead < decoder.total_read div 4:
      ret = -1

  return ret

proc decodeChunkedIsInData*(decoder: ptr ChunkedDecoder): bool =
  return decoder.state == CHUNKED_IN_CHUNK_DATA


const
  HTTPCLIENT_DEFAULT_TCP_TIMEOUT* = 10_000
  defaultUserAgent*: string = "Pico"

## / HTTP client errors

type
  HttpClientError* = enum
    ErrReadTimeout = -11
    ErrStreamWrite = -10
    ErrEncoding = -9
    ErrTooLessRam = -8
    ErrNoHttpServer = -7
    ErrNoStream = -6
    ErrConnectionLost = -5
    ErrNotConnected = -4
    ErrSendPayloadFailed = -3
    ErrSendHeaderFailed = -2
    ErrConnectionFailed = -1

## constexpr int HTTPC_ERROR_CONNECTION_REFUSED __attribute__((deprecated)) = HTTPC_ERROR_CONNECTION_FAILED;
## / size for the stream handling

const
  HTTP_TCP_BUFFER_SIZE* = (1460)

## / HTTP codes see RFC7231

const
  HTTP_CODE_CONTINUE* = Http100
  HTTP_CODE_SWITCHING_PROTOCOLS* = Http101
  HTTP_CODE_PROCESSING* = Http102
  HTTP_CODE_OK* = Http200
  HTTP_CODE_CREATED* = Http201
  HTTP_CODE_ACCEPTED* = Http202
  HTTP_CODE_NON_AUTHORITATIVE_INFORMATION* = Http203
  HTTP_CODE_NO_CONTENT* = Http204
  HTTP_CODE_RESET_CONTENT* = Http205
  HTTP_CODE_PARTIAL_CONTENT* = Http206
  HTTP_CODE_MULTI_STATUS* = Http207
  HTTP_CODE_ALREADY_REPORTED* = Http208
  HTTP_CODE_IM_USED* = Http226
  HTTP_CODE_MULTIPLE_CHOICES* = Http300
  HTTP_CODE_MOVED_PERMANENTLY* = Http301
  HTTP_CODE_FOUND* = Http302
  HTTP_CODE_SEE_OTHER* = Http303
  HTTP_CODE_NOT_MODIFIED* = Http304
  HTTP_CODE_USE_PROXY* = Http305
  HTTP_CODE_TEMPORARY_REDIRECT* = Http307
  HTTP_CODE_PERMANENT_REDIRECT* = Http308
  HTTP_CODE_BAD_REQUEST* = Http400
  HTTP_CODE_UNAUTHORIZED* = Http401
  HTTP_CODE_PAYMENT_REQUIRED* = Http402
  HTTP_CODE_FORBIDDEN* = Http403
  HTTP_CODE_NOT_FOUND* = Http404
  HTTP_CODE_METHOD_NOT_ALLOWED* = Http405
  HTTP_CODE_NOT_ACCEPTABLE* = Http406
  HTTP_CODE_PROXY_AUTHENTICATION_REQUIRED* = Http407
  HTTP_CODE_REQUEST_TIMEOUT* = Http408
  HTTP_CODE_CONFLICT* = Http409
  HTTP_CODE_GONE* = Http410
  HTTP_CODE_LENGTH_REQUIRED* = Http411
  HTTP_CODE_PRECONDITION_FAILED* = Http412
  HTTP_CODE_PAYLOAD_TOO_LARGE* = Http413
  HTTP_CODE_URI_TOO_LONG* = Http414
  HTTP_CODE_UNSUPPORTED_MEDIA_TYPE* = Http415
  HTTP_CODE_RANGE_NOT_SATISFIABLE* = Http416
  HTTP_CODE_EXPECTATION_FAILED* = Http417
  HTTP_CODE_MISDIRECTED_REQUEST* = Http421
  HTTP_CODE_UNPROCESSABLE_ENTITY* = Http422
  HTTP_CODE_LOCKED* = Http423
  HTTP_CODE_FAILED_DEPENDENCY* = Http424
  HTTP_CODE_UPGRADE_REQUIRED* = Http426
  HTTP_CODE_PRECONDITION_REQUIRED* = Http428
  HTTP_CODE_TOO_MANY_REQUESTS* = Http429
  HTTP_CODE_REQUEST_HEADER_FIELDS_TOO_LARGE* = Http431
  HTTP_CODE_INTERNAL_SERVER_ERROR* = Http500
  HTTP_CODE_NOT_IMPLEMENTED* = Http501
  HTTP_CODE_BAD_GATEWAY* = Http502
  HTTP_CODE_SERVICE_UNAVAILABLE* = Http503
  HTTP_CODE_GATEWAY_TIMEOUT* = Http504
  HTTP_CODE_HTTP_VERSION_NOT_SUPPORTED* = Http505
  HTTP_CODE_VARIANT_ALSO_NEGOTIATES* = Http506
  HTTP_CODE_INSUFFICIENT_STORAGE* = Http507
  HTTP_CODE_LOOP_DETECTED* = Http508
  HTTP_CODE_NOT_EXTENDED* = Http510
  HTTP_CODE_NETWORK_AUTHENTICATION_REQUIRED* = Http511

type
  TransferEncodingT* {.pure.} = enum
    HTTPC_TE_IDENTITY
    HTTPC_TE_CHUNKED

  FollowRedirectsT* {.pure.} = enum
    ## *
    ##     redirection follow mode.
    ##     + `HTTPC_DISABLE_FOLLOW_REDIRECTS` - no redirection will be followed.
    ##     + `HTTPC_STRICT_FOLLOW_REDIRECTS` - strict RFC2616, only requests using
    ##         GET or HEAD methods will be redirected (using the same method),
    ##         since the RFC requires end-user confirmation in other cases.
    ##     + `HTTPC_FORCE_FOLLOW_REDIRECTS` - all redirections will be followed,
    ##         regardless of a used method. New request will use the same method,
    ##         and they will include the same body data and the same headers.
    ##         In the sense of the RFC, it's just like every redirection is confirmed.
    ##
    HTTPC_DISABLE_FOLLOW_REDIRECTS
    HTTPC_STRICT_FOLLOW_REDIRECTS
    HTTPC_FORCE_FOLLOW_REDIRECTS

  #TransportTraitsPtr* = owned TransportTraits

  HttpClient* = object
    client*: TcpContext
    clientTLS: bool                     # = false
    clientGiven: bool                   # = false
    host: string
    port: Port                          # = 0
    reuse: bool                         # = true
    tcpTimeout: uint                    # = Httpclient_Default_Tcp_Timeout
    useHttp1_0: bool                    # = false
    uri: Uri
    protocol: string
    headers: string
    base64Authorization: string
    userAgent: string                   # = defaultUserAgent ## / Response handling
    currentHeaders: owned HttpHeaders
    # headerKeysCount: int# = 0
    returnCode: int                     # = 0
    size: int                           # = -1
    canReuse: bool                      # = false
    followRedirects: FollowRedirectsT   # = Httpc_Disable_Follow_Redirects
    redirectLimit: Natural              # = 10
    location: string
    contentType: string
    transferEncoding: TransferEncodingT # = Httpc_Te_Identity
    payload: StringStream               # #[owned]#
    chunkedDecoder: ChunkedDecoder
    beforeBuffer*: string

  # HttpClientRequestArgument* = object
  #   key*: string
  #   value*: string



# template client(self: var HttpClient): untyped =
#   self.client

proc constructHTTPClient*(): HttpClient = discard
proc destroyHTTPClient*(self: var HttpClient) = discard
proc constructHTTPClient*(a1: var HttpClient): HttpClient = discard

proc connected*(self: var HttpClient): bool =
  self.client.connected()

proc disconnect*(self: var HttpClient; preserveClient: bool = false) =
  if self.connected():
    if self.client.available() > 0:
      DEBUG_HTTPCLIENT("[HTTP-Client][end] still data in buffer (%d), clean up.\n", self.client.available())
      while self.client.available() > 0:
        discard self.client.read()
    if self.reuse and self.canReuse:
      DEBUG_HTTPCLIENT("[HTTP-Client][end] tcp keep open for reuse\n")
    else:
      DEBUG_HTTPCLIENT("[HTTP-Client][end] tcp stop\n")
      discard self.client.stop()

  else:
    DEBUG_HTTPCLIENT("[HTTP-Client][end] tcp is closed\n")

proc connect*(self: var HttpClient): bool =
  if self.reuse and self.canReuse and self.connected():
    DEBUG_HTTPCLIENT("[HTTP-Client] connect: already connected, reusing connection\n");

    # clear _client's output (all of it, no timeout)
    while self.client.available() > 0:
      discard self.client.stream.readAll()

    return true

  if self.client.getPcb().isNil:
    DEBUG_HTTPCLIENT("[HTTP-Client] connect: HTTPClient::begin was not called or returned error\n");
    return false

  self.client.setTimeout(self.tcpTimeout)

  if not self.client.connect(self.host, self.port):
    DEBUG_HTTPCLIENT("[HTTP-Client] failed connect to %s:%u\n", self.host.cstring, self.port)
    return false

  DEBUG_HTTPCLIENT("[HTTP-Client] connected to %s:%u\n", self.host.cstring, self.port)
  self.client.setNoDelay(true)
  return self.connected()

proc clear*(self: var HttpClient) =
  self.returnCode = 0
  self.size = -1
  self.headers = ""
  self.currentHeaders = newHttpHeaders()
  self.location = ""
  self.payload.reset()
  self.userAgent = defaultUserAgent
  self.tcpTimeout = HttpClientDefaultTcpTimeout
  self.chunkedDecoder.reset()

proc beginInternal*(self: var HttpClient; url: string; expectedProtocol: string): bool =
  let parsed = parseUri(url)

  DEBUG_HTTPCLIENT("[HTTP-Client][begin] url: %s\n", url)
  self.clear()

  self.protocol = parsed.scheme.toLower()
  if self.protocol == "http":
    self.port = Port(80)
  elif self.protocol == "https":
    self.port = Port(443)
  else:
    DEBUG_HTTPCLIENT("[HTTP-Client][begin] unsupported protocol: %s\n", self.protocol.cstring)
    return false

  if parsed.port != "":
    try:
      self.port = Port(parseInt(parsed.port))
    except ValueError:
      discard

  let oldHost = self.host
  self.host = parsed.hostname
  if oldHost != "" and self.host != oldHost:
    self.canReuse = false
    self.disconnect(true)

  self.uri.scheme = self.protocol
  self.uri.opaque = false
  self.uri.username = parsed.username
  self.uri.password = parsed.password
  self.uri.hostname = parsed.hostname
  self.uri.port = $self.port
  self.uri.path = parsed.path
  self.uri.query = parsed.query
  self.uri.anchor = parsed.anchor

  if not self.clientGiven:
    self.client.reset()
    self.client.init(tls = self.protocol == "https", sniHostname = self.host)

  DEBUG_HTTPCLIENT("[HTTP-Client][begin] host: %s port: %d url: %s\n", self.host.cstring, self.port.uint16, ($self.uri).cstring)

  return true

proc begin*(self: var HttpClient; url: string): bool =
  let index = url.find(':')
  if index < 0:
    DEBUG_HTTPCLIENT("[HTTP-Client][begin] failed to parse protocol\n")
    return false

  let protocol = url[0..<index].toLower()
  if protocol != "http" and protocol != "https":
    DEBUG_HTTPCLIENT("[HTTP-Client][begin] unknown protocol '%s'\n", protocol.cstring)
    return false

  # self.port = if protocol == "https": Port(443) else: Port(80)

  return self.beginInternal(url, protocol)

proc begin*(self: var HttpClient; host: string; port: Port; path: string = "/"; https: bool = false): bool =
  if self.host != host:
    self.canReuse = false
    self.disconnect(true)

  var uri = initUri()

  uri.hostname = host
  uri.port = $port
  uri.path = path
  let protocol = if https: "https" else: "http"

  return self.beginInternal($uri, protocol)

# proc begin*(self: var HttpClient; url: string; httpsFingerprint: array[20, uint8]): bool =
#   # setFingerprint(httpsFingerprint)
#   return self.begin(url)

# proc begin*(self: var HttpClient; host: string; port: Port; uri: string; httpsFingerprint: array[20, uint8]): bool =
#   # setFingerprint(httpsFingerprint)
#   return self.begin(host, port, uri)

proc begin*(self: var HttpClient; client: TcpContext; url: string): bool =
  let index = url.find(':')
  if index < 0:
    DEBUG_HTTPCLIENT("[HTTP-Client][begin] failed to parse protocol\n")
    return false

  let protocol = url[0..<index].toLower()
  if protocol != "http" and protocol != "https":
    DEBUG_HTTPCLIENT("[HTTP-Client][begin] unknown protocol '%s'\n", protocol.cstring)
    return false

  self.client = client
  self.clientGiven = true

  return self.beginInternal(url, protocol)

proc begin*(self: var HttpClient; client: TcpContext; host: string; port: Port; path: string = "/"; https: bool = false): bool =
  # Disconnect when reusing HTTPClient to talk to a different host
  if self.host != "" and self.host != host:
    self.canReuse = false
    self.disconnect(true)

  self.client = client
  self.clientGiven = true

  return self.begin(host, port, path, https)

proc finish*(self: var HttpClient) =
  self.disconnect(true)
  self.clear()
  self.clientGiven = false

proc setReuse*(self: var HttpClient; reuse: bool) =
  self.reuse = reuse

proc setUserAgent*(self: var HttpClient; userAgent: string) =
  self.userAgent = userAgent

proc setAuthorization*(self: var HttpClient; user: string; password: string) =
  if user.len > 0 and password.len > 0:
    let auth = user & ":" & password
    self.base64Authorization = base64.encode(auth)
  else:
    self.base64Authorization = ""

proc setAuthorization*(self: var HttpClient; auth: string) =
  if auth.len > 0:
    self.base64Authorization = auth

proc setTimeout*(self: var HttpClient; timeout: uint) =
  self.tcpTimeout = timeout
  if self.connected():
    self.client.setTimeout(timeout)

proc setFollowRedirects*(self: var HttpClient; follow: FollowRedirectsT) =
  self.followRedirects = follow

proc setRedirectLimit*(self: var HttpClient; limit: Natural) =
  self.redirectLimit = limit

proc setURL*(self: var HttpClient; url: string): bool =
  if url.len > 0 and url.startsWith("/"):
    self.uri = parseUri(url)
    self.clear()
    return true

  if not url.startsWith(self.protocol & ":"):
    DEBUG_HTTPCLIENT("[HTTP-Client][setURL] new URL not the same protocol, expected '%s', URL: '%s'\n", self.protocol.cstring, url.cstring)
    return false

  self.canReuse = false
  self.disconnect(true)
  return self.beginInternal(url, "")

proc useHttp1_0*(self: var HttpClient; usehttp1_0: bool = true) =
  self.useHttp1_0 = usehttp1_0
  self.reuse = not usehttp1_0

proc returnError*(self: var HttpClient; error: HttpCode | HttpClientError): int =
  error.ord

proc addHeader*(self: var HttpClient; name: string; value: string) =
  # not allow set of Header handled by code
  if name.toLower() in ["connection", "user-agent", "host", "authorization"]:
    return

  self.currentHeaders[name] = value

# proc collectHeaders*(self: var HttpClient; headerKeys: openArray[string]) =
#   discard

proc sendHeaders*(self: var HttpClient; httpMethod: HttpMethod): bool =
  if not self.connected():
    return false

  var header = newStringOfCap(200)
  header.add($httpMethod)
  header.add(" ")
  if self.uri.path.len > 0:
    header.add(self.uri.path)
    if self.uri.query.len > 0:
      header.add('?')
      header.add(self.uri.query)
  else:
    header.add('/')

  header.add(" HTTP/1.")
  header.add(if self.useHttp1_0: '0' else: '1')

  header.add("\r\nHost: ")
  header.add(self.host)
  if self.port != Port(80) and self.port != Port(443):
    header.add(':')
    header.add($self.port)

  if self.userAgent.len != 0:
    header.add("\r\nUser-Agent: ")
    header.add(self.userAgent)

  if not self.useHttp1_0:
    header.add("\r\nAccept-Encoding: identity;q=1,chunked;q=0.1,*;q=0")

  if self.base64Authorization.len != 0:
    header.add("\r\nAuthorization: Basic ")
    header.add(self.base64Authorization)

  header.add("\r\nConnection: ")
  header.add(if self.reuse: "keep-alive" else: "close")
  header.add("\r\n")

  header.add(self.headers)
  header.add("\r\n")

  DEBUG_HTTPCLIENT("[HTTP-Client] sending request header\n-----\n%s-----\n", header.cstring)
  # transfer all of it, with timeout
  return newStringStream(header).pipe(self.client.stream) == header.len

proc available*(self: var HttpClient): int =
  return self.client.available()

proc handleHeaderResponse*(self: var HttpClient): int =
  if not self.connected():
    return self.returnError(ErrNotConnected)

  self.clear()

  self.canReuse = self.reuse

  var transferEncoding: string

  self.transferEncoding = HTTPC_TE_IDENTITY
  var lastDataTime = getAbsoluteTime()

  while self.connected():
    let len = self.client.available()
    if len > 0:
      var headerSeparator = -1
      var headerLine: string
      discard self.client.stream.readLine(headerLine)

      lastDataTime = getAbsoluteTime()

      DEBUG_HTTPCLIENT("[HTTP-Client][handleHeaderResponse] RX: '%s'\n", headerLine.cstring)

      if headerLine.startsWith("HTTP/1."):
        const httpVersionIdx = "HTTP/1.".len
        self.canReuse = self.canReuse and headerLine[httpVersionIdx] != '0'
        self.returnCode = try: parseInt(headerLine[httpVersionIdx + 2 ..< headerLine.find(' ', httpVersionIdx + 2)]) except ValueError: 0
        self.canReuse = self.canReuse and self.returnCode.ord > 0 and self.returnCode.ord < 500

      elif (headerSeparator = headerLine.find(':'); headerSeparator) > 0:
        let headerName = headerLine[0..<headerSeparator]
        let headerValue = headerLine[headerSeparator+1..^1].strip()

        case headerName.toLower().strip():
        of "content-length":
          self.size = try: parseInt(headerValue) except ValueError: -1
        of "connection":
          if self.canReuse:
            if headerValue.find("close") >= 0 and headerValue.find("keep-alive") < 0:
              self.canReuse = false
        of "transfer-encoding":
          transferEncoding = headerValue
        of "location":
          self.location = headerValue
        of "content-type":
          self.contentType = headerValue

        # for (size_t i = 0; i < _headerKeysCount; i++) {
        #   if (_currentHeaders[i].key.equalsIgnoreCase(headerName)) {
        #     if (_currentHeaders[i].value != "") {
        #       // Existing value, append this one with a comma
        #       _currentHeaders[i].value += ',';
        #       _currentHeaders[i].value += headerValue;
        #     } else {
        #       _currentHeaders[i].value = headerValue;
        #     }
        #     break; // We found a match, stop looking
        #   }
        # }
        continue

      if headerLine.len == 0:
        DEBUG_HTTPCLIENT("[HTTP-Client][handleHeaderResponse] code: %d\n", self.returnCode)

        if self.size > 0:
          DEBUG_HTTPCLIENT("[HTTP-Client][handleHeaderResponse] size: %d\n", self.size)

        if transferEncoding.len != 0:
          DEBUG_HTTPCLIENT("[HTTP-Client][handleHeaderResponse] Transfer-Encoding: %s\n", transferEncoding.cstring)
          if transferEncoding.toLower() == "chunked":
            self.transferEncoding = HTTPC_TE_CHUNKED
          else:
            self.returnCode = ErrEncoding.ord
            return self.returnCode
        else:
          self.transferEncoding = HTTPC_TE_IDENTITY

        if self.returnCode <= 0:
          DEBUG_HTTPCLIENT("[HTTP-Client][handleHeaderResponse] Remote host is not an HTTP Server!\n")
          self.returnCode = ErrNoHttpServer.ord

        return self.returnCode

    else:
      if diffUs(lastDataTime, getAbsoluteTime()) > self.tcpTimeout.int64 * 1000:
        return self.returnError(ErrReadTimeout)

  return self.returnError(ErrConnectionLost)


proc sendRequest*(self: var HttpClient; httpMethod: HttpMethod; payload: ptr byte = nil; size: int = 0): int =
  var httpMethod = httpMethod
  var payload = payload
  var size = size

  var code: int
  var redirect = false
  var redirectCount: Natural = 0

  while true:
    # wipe out any existing headers from previous request
    self.currentHeaders = newHttpHeaders()

    DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] type: '%s' redirCount: %d\n", ($httpMethod).cstring, redirectCount)

    # connect to server
    if not self.connect():
      return self.returnError(ErrConnectionFailed)

    self.addHeader("Content-Length", if not payload.isNil and size > 0: $size else: $0)

    # send headers
    if not self.sendHeaders(httpMethod):
      return self.returnError(ErrSendHeaderFailed)

    # transfer all of it, with send-timeout
    if size > 0 and self.payload.pipe(self.client.stream, size = size) != size:
      return self.returnError(ErrSendPayloadFailed)

    # handle Server Response (Header)
    code = self.handleHeaderResponse()

    #
    # Handle redirections as stated in RFC document:
    # https://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    #
    # Implementing HTTP_CODE_FOUND as redirection with GET method,
    # to follow most of existing user agent implementations.
    #
    redirect = false
    if self.followRedirects != HTTPC_DISABLE_FOLLOW_REDIRECTS and redirectCount < self.redirectLimit and self.location.len > 0:
      case HttpCode(code):
      of HTTP_CODE_MOVED_PERMANENTLY,
         HTTP_CODE_TEMPORARY_REDIRECT:
        if self.followRedirects == HTTPC_FORCE_FOLLOW_REDIRECTS or httpMethod == HttpGet or httpMethod == HttpHead:
          inc(redirectCount)
          DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] following redirect (the same method): '%s' redirCount: %d\n", self.location.cstring, redirectCount)

          if not self.setURL(self.location):
            DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] failed setting URL for redirection\n")
            # no redirection
            break

          # redirect using the same request method and payload, different URL
          redirect = true

      # redirecting with method dropped to GET or HEAD
      # note: it does not need `HTTPC_FORCE_FOLLOW_REDIRECTS` for any method
      of HTTP_CODE_FOUND,
         HTTP_CODE_SEE_OTHER:
        inc(redirectCount)
        DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] following redirect (dropped to GET/HEAD): '%s' redirCount: %d\n", self.location.cstring, redirectCount)

        if not self.setURL(self.location):
          DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] failed setting URL for redirection\n")
          # no redirection
          break

        # redirect after changing method to GET/HEAD and dropping payload
        httpMethod = HttpGet
        payload = nil
        size = 0
        redirect = true
      else:
        discard

    if not redirect:
      break

  return code

# proc sendRequest*(self: var HTTPClient; `type`: string; payload: ptr uint8 = nil; size: csize_t = 0): int = discard
proc sendRequest*(self: var HTTPClient; httpMethod: HttpMethod; stream: Stream; size: int = 0): int =
  if stream.atEnd():
    return self.returnError(ErrNoStream)

  if not self.connect():
    return self.returnError(ErrConnectionFailed)

  if size > 0:
    self.addHeader("Content-Length", $size)

  if not self.sendHeaders(httpMethod):
    return self.returnError(ErrSendHeaderFailed)

  let transferred = stream.pipe(self.client.stream, size = size)
  if transferred != size:
    DEBUG_HTTPCLIENT("[HTTP-Client][sendRequest] short write, asked for %zu but got %zu failed.\n", size, transferred);
    return self.returnError(ErrSendPayloadFailed)

  return self.handleHeaderResponse()


proc get*(self: var HttpClient): int = self.sendRequest(HttpGet)
proc delete*(self: var HttpClient): int = self.sendRequest(HttpDelete)
proc post*(self: var HttpClient; payload: ptr byte): int = self.sendRequest(HttpPost, payload)
proc put*(self: var HttpClient; payload: ptr byte): int = self.sendRequest(HttpPut, payload)
proc patch*(self: var HttpClient; payload: ptr byte): int = self.sendRequest(HttpPatch, payload)

proc getSize*(self: var HttpClient): int =
  self.size

proc getLocation*(self: var HttpClient): string =
  self.location

proc getContentType*(self: var HttpClient): string =
  self.contentType

proc header*(self: var HttpClient; name: string): string =
  return self.currentHeaders.getOrDefault(name, @[""].HttpHeaderValues)

# proc header*(self: var HttpClient; i: int): string = discard
# proc headerName*(self: var HttpClient; i: int): string = discard

proc headers*(self: var HttpClient): int =
  self.currentHeaders.len

proc hasHeader*(self: var HttpClient; name: string): bool =
  self.currentHeaders.hasKey(name)

proc getStream*(self: var HttpClient): Stream =
  if self.connected():
    return self.client.stream
  DEBUG_HTTPCLIENT("[HTTP-Client] getStream: not connected\n");

proc read*(self: var HttpClient; n: Natural): string =
  # echo "READ ", (n, self.beforeBuffer.len)
  if n <= self.beforeBuffer.len:
    result.add(self.beforeBuffer[0 ..< n])
    self.beforeBuffer = self.beforeBuffer[n .. ^1]
    return result
  else:
    result.add(self.beforeBuffer)
    self.beforeBuffer = ""
  if not self.connected() and self.available() == 0: return result
  let stream = self.client.stream
  let endMs = makeTimeoutTimeMs(self.tcpTimeout.uint32)
  while diffUs(getAbsoluteTime(), endMs) > 0 and result.len < n and (self.connected() or self.available() > 0):
    if stream.atEnd(): continue
    case self.transferEncoding:
    of HTTPC_TE_IDENTITY:
      result.add(stream.readStr(n - result.len))
    of HTTPC_TE_CHUNKED:
      var line = stream.readStr(n - result.len)
      var bufLen = line.len.uint
      let ret = self.chunkedDecoder.decodeChunked(cast[ptr UncheckedArray[char]](line[0].addr), bufLen)
      if ret == -1:
        return result
      else:
        line.setLen(bufLen)
        result.add(line)
        if ret != -2:
          self.disconnect(true)
          return result

proc writeToStream*(self: var HTTPClient; writeStream: Stream): int =
  if writeStream.isNil:
    return self.returnError(ErrNoStream)

  # Only return error if not connected and no data available, because otherwise ::getString() will return an error instead of an empty
  # string when the server returned a http code 204 (no content)
  if not self.connected() and self.transferEncoding != HTTPC_TE_IDENTITY and self.size > 0:
    return self.returnError(ErrNotConnected)

  var len = self.size
  var ret = 0

  case self.transferEncoding:
  of HTTPC_TE_IDENTITY:
    # len < 0: transfer all of it, with timeout
    # len >= 0: max:len, with timeout
    ret = self.client.stream.pipe(writeStream, size = len)

    if len > 0 and ret != len:
      return self.returnError(ErrNoStream)

  of HTTPC_TE_CHUNKED:
    var size = 0
    while true:
      if not self.connected():
        return self.returnError(ErrConnectionLost)

      var chunkHeader: string
      discard self.client.stream.readLine(chunkHeader)

      if chunkHeader.len <= 0:
        return self.returnError(ErrReadTimeout)

      DEBUG_HTTPCLIENT("[HTTP-Client] chunk header: '%s'\n", chunkHeader.cstring)

      # read size of chunk
      discard parseHex(chunkHeader, len)
      DEBUG_HTTPCLIENT("[HTTP-Client] read chunk len: %d\n", len)
      size += len

      # data left?
      if len > 0:
        # read len bytes with timeout
        let r = self.client.stream.pipe(writeStream, size = len)
        if r != len:
          return self.returnError(ErrNoStream)

        ret += r

      else:
        if self.size <= 0:
          self.size = size

        if ret != self.size:
          return self.returnError(ErrStreamWrite)
        break

      var buf: array[2, char]
      let trailingSeqLen = self.client.stream.readData(addr(buf), sizeof(buf))
      if trailingSeqLen != 2 or buf[0] != '\r' or buf[1] != '\n':
        return self.returnError(ErrReadTimeout)

  self.disconnect(true)
  return ret

proc getString*(self: var HttpClient): string =
  if not self.payload.isNil:
    return self.payload.readAll()

  self.payload = newStringStream("")

  discard self.writeToStream(self.payload)
  self.payload.setPosition(0)
  return self.payload.readAll()

proc errorToString*(error: int): string = $HttpClientError(error)


# proc setSession*(self: var HTTPClient; session: ptr Session) =
#   tls().setSession(session)

# proc setInsecure*(self: var HTTPClient) =
#   tls().setInsecure()

# proc setKnownKey*(self: var HTTPClient; pk: ptr PublicKey;
#                  usages: cuint = br_Keytype_Keyx or br_Keytype_Sign) =
#   tls().setKnownKey(pk, usages)

# proc setFingerprint*(self: var HTTPClient; fingerprint: array[20, uint8]): bool =
#   return tls().setFingerprint(fingerprint)

# proc setFingerprint*(self: var HTTPClient; fpStr: cstring): bool =
#   return tls().setFingerprint(fpStr)

# proc allowSelfSignedCerts*(self: var HTTPClient) =
#   tls().allowSelfSignedCerts()

# proc setTrustAnchors*(self: var HTTPClient; ta: ptr X509List) =
#   tls().setTrustAnchors(ta)

# proc setX509Time*(self: var HTTPClient; now: TimeT) =
#   tls().setX509Time(now)

# proc setClientRSACert*(self: var HTTPClient; cert: ptr X509List; sk: ptr PrivateKey) {.
#     cdecl.} =
#   tls().setClientRSACert(cert, sk)

# proc setClientECCert*(self: var HTTPClient; cert: ptr X509List; sk: ptr PrivateKey;
#                      allowedUsages: cuint; certIssuerKeyType: cuint) =
#   tls().setClientECCert(cert, sk, allowedUsages, certIssuerKeyType)

# proc setBufferSizes*(self: var HTTPClient; recv: cint; xmit: cint) =
#   tls().setBufferSizes(recv, xmit)

# proc setCertStore*(self: var HTTPClient; certStore: ptr CertStoreBase) =
#   tls().setCertStore(certStore)

# proc setCiphers*(self: var HTTPClient; cipherAry: ptr uint16; cipherCount: cint): bool {.
#     cdecl.} =
#   return tls().setCiphers(cipherAry, cipherCount)

# proc setCiphers*(self: var HTTPClient; list: Vector[uint16]): bool =
#   return tls().setCiphers(list)

# proc setCiphersLessSecure*(self: var HTTPClient): bool =
#   return tls().setCiphersLessSecure()

# proc setSSLVersion*(self: var HTTPClient; min: uint32T = br_Tls10;
#                    max: uint32T = br_Tls12): bool =
#   return tls().setSSLVersion(min, max)

# proc setCACert*(self: var HTTPClient; rootCA: cstring) =
#   tls().setCACert(rootCA)

# proc setCertificate*(self: var HTTPClient; clientCa: cstring) =
#   tls().setCertificate(clientCa)

# proc setPrivateKey*(self: var HTTPClient; privateKey: cstring) =
#   tls().setPrivateKey(privateKey)

# proc loadCACert*(self: var HTTPClient; stream: var Stream; size: csize_t): bool =
#   return tls().loadCACert(stream, size)

# proc loadCertificate*(self: var HTTPClient; stream: var Stream; size: csize_t): bool {.
#     cdecl.} =
#   return tls().loadCertificate(stream, size)

# proc loadPrivateKey*(self: var HTTPClient; stream: var Stream; size: csize_t): bool {.
#     cdecl.} =
#   return tls().loadPrivateKey(stream, size)


# proc writeToStreamDataBlock*(self: var HttpClient; stream: ptr Stream; len: cint): cint = discard
