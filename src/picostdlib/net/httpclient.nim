import std/uri, std/strutils, std/httpcore, std/parseutils, std/tables
import ./picosocket
import ./common

export common, httpcore, tables

when not defined(release) or defined(debugHttp):
  template debugv(text: string) = echo text
else:
  template debugv(text: string) = discard

const DefaultUserAgent = "picostdlib/1.0.0"

type
  ChunkedParseState = enum
    ParseHeader
    ParseBody
    ParseComplete

  ResponseParseState = enum
    StateInvalid
    StateHeaderFirst
    StateHeaders
    StateBody

  HttpVersion* = enum
    Http1_0
    Http1_1

  HttpTransferEncoding* = enum
    TransferIdentity
    TransferChunked

  HttpResponse* = object
    version*: HttpVersion
    code*: HttpCode
    status*: string
    contentLength*: int
    contentType*: string
    location*: string
    transferEncoding*: HttpTransferEncoding
    headers*: Table[string, string]

  HttpClient* = ref object
    socket: Socket[SOCK_STREAM]

    connectCb: HttpCallback
    recvCb*: proc (data: string)

    # request
    reqUri: Uri
    reqHeaders: Table[string, string]
    useHttp1_0: bool
    base64Authorization: string
    userAgent: string
    timeoutMs: int
    canReuse: bool
    reqMethod: HttpMethod

    # response
    response*: HttpResponse

    # response parsing state
    resState: ResponseParseState
    resRecv: string
    lastHeaderName: string
    chunkedState: ChunkedParseState
    chunkedRemaining: int

  HttpCallback* = proc (response: HttpResponse)

proc newHttpClient*(): HttpClient =
  new(result)
  result.userAgent = DefaultUserAgent
  result.timeoutMs = 30 * 1000
  result.reqMethod = HttpGet
  result.recvCb = proc (data: string) = discard

proc setUrl*(self: HttpClient; url: string) = self.reqUri = parseUri(url)

proc sendRequest*(self: HttpClient; httpMethod: HttpMethod; payload: string = ""; cb: HttpCallback)

proc parseFirstHeaderLine(self: HttpClient; line: string): bool =
  var linei = 0
  var le = skipIgnoreCase(line, "HTTP/", linei)
  if le <= 0:
    echo "invalid http response, `" & line & "`"
    return false
  linei.inc(le)
  le = skipIgnoreCase(line, "1.1", linei)
  if le > 0: self.response.version = Http1_1
  else:
    le = skipIgnoreCase(line, "1.0", linei)
    if le <= 0:
      echo "unsupported http version, `" & line & "`"
      return false
    self.response.version = Http1_0
  linei.inc(le)
  self.canReuse = self.canReuse and self.response.version == Http1_1
  linei.inc(skipWhitespace(line, linei))
  var versionStr: string
  le = parseUntil(line, versionStr, ' ', linei)
  if le <= 0:
    echo "unsupported http response code, `" & line & "`"
    return false
  self.response.status = line[linei .. ^1]
  linei.inc(le)
  linei.inc() # Skip space
  self.response.code = HttpCode(try: parseInt(versionStr) except ValueError: 0)
  self.canReuse = self.canReuse and self.response.code.ord > 0 and self.response.code.ord < 500
  return true

proc parseHeaderLine*(self: HttpClient; line: string): bool =
  if line[0] in {' ', '\t'}:
    if self.lastHeaderName == "":
      # Some extra unparsable lines in the HTTP output - we ignore them
      discard
    else:
      # Check if it's a multiline header value, if so, append to the header we're currently parsing
      # This works because a line with a header must start with the header name without any leading space
      # See https://datatracker.ietf.org/doc/html/rfc7230, section 3.2 and 3.2.4
      # Multiline headers are deprecated in the spec, but it's better to parse them than crash
      self.response.headers[self.lastHeaderName].add("\n" & line)
  else:
    var name = ""
    var linei = 0
    var le = parseUntil(line, name, ':', linei)
    if le <= 0:
      echo "Invalid headers - received empty header name"
      return false
    if line.len == le:
      echo "Invalid headers - no colon after header name"
      return false
    linei.inc(le) # Skip the parsed header name
    linei.inc() # Skip :
    name = name.toLower().strip()
    let value = line[linei .. ^1].strip()

    case name:
    of "content-length":
      self.response.contentLength = try: parseInt(value) except ValueError: -1
    of "content-type":
      self.response.contentType = value
    of "location":
      self.response.location = value
    of "connection":
      if self.canReuse:
        if value.find("close") >= 0 and value.find("keep-alive") < 0:
          self.canReuse = false
    of "transfer-encoding":
      self.response.transferEncoding = if value == "chunked": TransferChunked else: TransferIdentity
    else:
      self.response.headers[name] = value
      self.lastHeaderName = name # Remember the header name for the possible multi-line header


  return true

proc handleChunked(self: HttpClient) =
  if self.resRecv.len == 0: return
  case self.chunkedState:
  of ParseHeader:
    let le = self.resRecv.find(httpNewLine)
    if le == -1: return
    self.chunkedRemaining = fromHex[int](self.resRecv[0 ..< le])
    if self.chunkedRemaining == 0:
      if self.resRecv.find(httpNewLine, le + 2) != le + 2:
        return
      echo "parsed chunking complete!"
      self.resRecv = ""
      self.chunkedState = ParseComplete
      return
    self.resRecv = self.resRecv[(le + 2) .. ^1]
    self.chunkedState = ParseBody
    self.handleChunked()

  of ParseBody:
    if self.resRecv.len - 2 >= self.chunkedRemaining:
      let body = self.resRecv[0 ..< self.chunkedRemaining]
      self.resRecv = self.resRecv[self.chunkedRemaining + 2 .. ^1]
      self.chunkedRemaining -= body.len
      assert(self.chunkedRemaining == 0)
      self.recvCb(body)
      self.chunkedState = ParseHeader
      self.handleChunked()
    elif self.resRecv.len <= self.chunkedRemaining:
      let bodylen = self.resRecv.len
      self.recvCb(move self.resRecv)
      self.resRecv = ""
      self.chunkedRemaining -= bodylen

  of ParseComplete:
    return


proc handleRecv(self: HttpClient) =
  if self.resRecv.len == 0: return
  case self.resState:
    of StateInvalid: discard
    of StateHeaderFirst, StateHeaders:
      let linebreakPos = self.resRecv.find(httpNewLine)
      if linebreakPos == -1:
        return
      let headerLine = self.resRecv[0..<linebreakPos]
      self.resRecv = self.resRecv[linebreakPos+2 .. ^1]
      if self.resState == StateHeaderFirst:
        if not self.parseFirstHeaderLine(headerLine):
          self.resState = StateInvalid
          return
        self.lastHeaderName = ""
        self.resState = StateHeaders
      elif headerLine == "":
        # finished recieving headers
        if self.response.location.len > 0:
          self.setUrl(self.response.location)
          discard self.socket.close()
          self.socket = nil
          if self.response.code == Http301 or self.response.code == Http307:
            # TODO: reuse payload...
            self.sendRequest(self.reqMethod, "", self.connectCb)
            return
          elif self.response.code == Http302 or self.response.code == Http303:
            # clean payload
            self.sendRequest(HttpGet, "", self.connectCb)
            return

        self.connectCb(self.response)
        self.response.headers.clear()
        self.resState = StateBody
      else:
        if not self.parseHeaderLine(headerLine):
          self.resState = StateInvalid
          return
      self.handleRecv()
    of StateBody:
      if self.response.transferEncoding == TransferChunked:
        self.handleChunked()
      else:
        self.recvCb(move self.resRecv)
        self.resRecv = ""


proc sendHeaders(self: HttpClient) =
  var header = ""
  header.add($self.reqMethod)
  header.add(" ")
  if self.reqUri.path.len > 0:
    header.add(self.reqUri.path)
    if self.reqUri.query.len > 0:
      header.add('?')
      header.add(self.reqUri.query)
  else:
    header.add('/')

  header.add(" HTTP/1.")
  header.add(if self.useHttp1_0: '0' else: '1')

  header.add(httpNewLine & "Host: ")
  header.add(self.reqUri.hostname)
  if not (self.reqUri.scheme.toLower() == "http" and self.reqUri.port == "80") and
     not (self.reqUri.scheme.toLower() == "https" and self.reqUri.port == "443"):
    header.add(':')
    header.add(self.reqUri.port)

  if self.userAgent.len != 0:
    header.add(httpNewLine & "User-Agent: ")
    header.add(self.userAgent)

  if self.base64Authorization.len != 0:
    header.add(httpNewLine & "Authorization: Basic ")
    header.add(self.base64Authorization)

  header.add(httpNewLine & "Connection: ")
  header.add(if self.canReuse: "keep-alive" else: "close")
  header.add(httpNewLine)

  for name, value in self.reqHeaders:
    header.add(name)
    header.add(": ")
    header.add(value)
    header.add(httpNewLine)

  header.add(httpNewLine)

  assert(header.len == self.socket.write(header))

proc connect(self: HttpClient; cb: proc (success: bool)) =
  if not self.socket.isNil and self.socket.isConnected():
    cb(true)
    return

  self.socket = newSocket(SOCK_STREAM)

  self.socket.setTimeout(self.timeoutMs)

  let protocol = self.reqUri.scheme.toLower()
  if protocol == "http":
    if self.reqUri.port == "":
      self.reqUri.port = "80"
  elif protocol == "https":
    if self.reqUri.port == "":
      self.reqUri.port = "443"
    self.socket.setSecure(self.reqUri.hostname)
  else:
    echo "unsupported protocol: ", self.reqUri.scheme
    cb(false)
    return

  debugv(":httpc connecting to " & self.reqUri.hostname & ":" & $self.reqUri.port)

  if not self.socket.connect(self.reqUri.hostname, Port(parseInt(self.reqUri.port)), cb):
    debugv(":httpc failed connect to " & self.reqUri.hostname & ":" & $self.reqUri.port)
    cb(false)
    return

  self.socket.setNoDelay(true)

  self.resState = StateHeaderFirst
  self.response.reset()
  self.response.contentLength = -1

  let innerSelf = self
  self.socket.recvCb = proc(len: uint16; totLen: uint16) =
    debugv(":httpc recv - len: " & $len & " totLen: " & $totLen)
    innerSelf.resRecv &= innerSelf.socket.readStr(len)
    innerSelf.handleRecv()

proc addHeader*(self: HttpClient; name: string; value: string) =
  if name.toLower() in ["connection", "user-agent", "host", "authorization"]:
    return

  self.reqHeaders[name] = value

proc sendRequest*(self: HttpClient; httpMethod: HttpMethod; payload: string = ""; cb: HttpCallback) =
  self.connectCb = cb
  self.connect(proc (success: bool) =
    if not success:
      self.response.reset()
      self.response.contentLength = -1
      self.connectCb(self.response)
      self.connectCb = nil
      return
    self.reqMethod = httpMethod
    self.sendHeaders()
    # assert(payload.len == self.socket.write(payload))
    # discard self.socket.flush())
  )

proc get*(self: HttpClient; cb: HttpCallback) {.inline.} = self.sendRequest(HttpGet, cb = cb)
proc delete*(self: HttpClient; cb: HttpCallback) {.inline.} = self.sendRequest(HttpDelete, cb = cb)
proc post*(self: HttpClient; payload: string; cb: HttpCallback) {.inline.} = self.sendRequest(HttpPost, payload, cb)
proc put*(self: HttpClient; payload: string; cb: HttpCallback) {.inline.} = self.sendRequest(HttpPut, payload, cb)
proc patch*(self: HttpClient; payload: string; cb: HttpCallback) {.inline.} = self.sendRequest(HttpPatch, payload, cb)

