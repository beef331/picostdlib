import picostdlib
import picostdlib/pico/filesystem

# see hello_filesystem_sd.nims

const csPin = Gpio(22) # Change to the pin your sdcard uses

stdioInitAll()

var sd: ptr Blockdevice
var fat: ptr Filesystem

proc fsInit(): bool =
  sd = blockdeviceSdCreate(spi0, DefaultSpiTxPin, DefaultSpiRxPin, DefaultSpiSckPin, csPin, 24 * MHz, false)
  fat = filesystemFatCreate()
  var err = fsMount("/sd", fat, sd)
  if err != 0:
    echo "fs_mount error: ", strerror(errno)
    echo fsStrerror(err)
    filesystemFatFree(fat)
    blockdeviceSdFree(sd)
    return false

  return true

if not fsInit():
  echo "Failed to mount filesystem!"
else:
  echo "Successfully mounted filesystem"

  block:
    echo "writing file"
    var fp = open("/sd/HELLO.txt", fmWrite)
    fp.writeLine("Hello world")
    close(fp)

  block:
    echo "reading file"
    var fp = open("/sd/HELLO.txt", fmRead)
    let buffer = fp.readAll()
    close(fp)
    echo "HELLO.TXT: ", buffer

  echo "list files in sdcard root:"
  for file in fsWalkDir("/sd"):
    echo file

  echo "unmounting: ", fsStrerror(fsUnmount("/sd"))

  filesystemFatFree(fat)
  blockdeviceSdFree(sd)

while true:
  tightLoopContents()
