import picostdlib
import picostdlib/hardware/dma

## Use the DMA to copy data between two buffers in memory.

# Data will be copied from src to dst
let src = "Hello, world! (from DMA)"
var dst = newString(src.len)

stdioInitAll()

# Get a free channel, panic() if there are none
let chan = dmaClaimUnusedChannel(true).DmaChannel

# 8 bit transfers. Both read and write address increment after each
# transfer (each pointing to a location in src or dst respectively).
# No DREQ is selected, so the DMA transfers as fast as it can.

var c = chan.getDefaultConfig()

chan.configure(
  c.addr,            # The configuration we just created
  dst[0].addr,       # The initial write address
  src[0].unsafeAddr, # The initial read address
  src.len.cuint,     # Number of transfers; in this case each is 1 byte.
  true               # Start immediately.
)

# We could choose to go and do something else whilst the DMA is doing its
# thing. In this case the processor has nothing else to do, so we just
# wait for the DMA to finish.
chan.waitForFinishBlocking()

# The DMA has now copied our text from the transmit buffer (src) to the
# receive buffer (dst), so we can print it out from there.
echo dst
