import std/net
import std/nativesockets

type
  TcpClient* = object
    socket*: Socket
    data*: string

proc close*(self: var TcpClient) =
  self.socket.close()

proc isConnected*(self: var TcpClient): bool =
  return self.socket.getFd().int > 0

proc connect*(self: var TcpClient; host: string; port: Port; tls: bool = false; sniHostname = ""): bool =
  self.socket = dial(host, port)

  when defined(ssl):
    if tls:
      try:
        wrapConnectedSocket(newContext(), self.socket, handshakeAsClient, sniHostname)
      except:
        self.socket.close()
        raise getCurrentException()

  return self.isConnected()

proc poll*(self: var TcpClient; timeoutUs: Natural = 1000): int =
  var fds = @[self.socket.getFd()]
  return selectRead(fds, timeoutUs div 1000)

proc write*(self: var TcpClient; data: openArray[byte]|openArray[char]|string): int =
  when data is not string:
    let str = newString(data)
    copyMem(str.cstring, data[0].unsafeAddr, data.len)
    self.socket.send(str)
    return str.len
  else:
    echo "WRITE ", data
    self.socket.send(data)
    return data.len

proc read*(self: var TcpClient): int =
  let dataRead = self.socket.recv(1024)
  self.data.add(dataRead)
  return dataRead.len

