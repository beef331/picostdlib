when defined(mock):
  include ./tcpclient_native
else:
  include ./tcpclient_lwip

when defined(runtests):
  var client: TcpClient
  if client.connect("djazz.se", Port(443), tls = true, "djazz.se"):
    echo "connected"

    echo client.write("GET / HTTP/1.1\r\nHost: djazz.se\r\n\r\n")
    echo "written"
    echo client.poll(5000)
    echo "poll"
    echo client.isConnected()
    echo client.read()
    echo "read"
    echo client.data
    client.data.setLen(0)
    echo client.read()
    echo "read"
    echo client.data

    client.close()
  else:
    echo "couldnt connect"
