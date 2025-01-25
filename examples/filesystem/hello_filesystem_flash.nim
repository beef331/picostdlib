import picostdlib
import picostdlib/pico/filesystem

# see hello_filesystem_flash.nims

stdioInitAll()

if not fsInit():
  echo "Failed to mount filesystem!"
else:
  echo "Successfully mounted filesystem"

  block:
    echo "writing file"
    var fp = open("/HELLO.txt", fmWrite)
    fp.writeLine("Hello world")
    close(fp)

  block:
    echo "reading file"
    var fp = open("/HELLO.txt", fmRead)
    let buffer = fp.readAll()
    close(fp)
    echo "HELLO.TXT: ", buffer

  echo "list files in root:"
  for file in fsWalkDir("/"):
    echo file

  echo "unmounting: ", fsStrerror(fsUnmount("/"))

while true:
  tightLoopContents()
