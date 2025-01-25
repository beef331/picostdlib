import std/strutils
import picostdlib
import picostdlib/lib/littlefs

const partitionSize = 848 * 1024
template startAddress: uint32 = XipBase + FlashSizeBytes - partitionSize
const partitionName = "Hello LittleFS!"

stdioInitAll()

var lfs: LittleFS
lfs.init(start = startAddress, size = partitionSize)

bi_decl_include()
bi_decl(bi_block_device(
  BINARY_INFO_MAKE_TAG('N', 'I'),
  "\"" & partitionName & "\"",
  startAddress,
  partitionSize,
  nil,
  {FlagRead, FlagWrite, FlagPtUnknown}
))

if not lfs.mount():
  echo "Failed to mount LittleFS!"
else:
  echo "Successfully mounted LittleFS at 0x", startAddress.uint64.toHex(), ", size ", partitionSize div 1024, " kilobytes"

  lfs.unmount()
