import picostdlib
import picostdlib/pico/async_context
import picostdlib/asyncdispatch
import picostdlib/promise

stdioInitAll()

type
  State = object
    counter: int

let led = DefaultLedPin
led.init()
led.setDir(Out)
led.put(Low)

var state: State
var complete = false

proc atTimeWorkerCb(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker) {.cdecl.} =
  let state = cast[ptr State](worker.userData)
  inc(state.counter)
  echo "at time worker fired! ", state.counter
  complete = true

proc asyncable(): Future[int] {.async.} =
  assert 4321 == await Promise.resolve(4321).toFuture()
  var i = 0
  while true:
    await sleepAsync(200)
    led.put(High)
    await sleepAsync(100)
    led.put(Low)
    inc(i)
  return 123

proc performTest(context: ptr AsyncContext; blocking: bool) =

  complete = false

  var atTimeWorker = AsyncAtTimeWorker(userData: state.addr, doWork: atTimeWorkerCb)
  assert context.addAtTimeWorkerInMs(atTimeWorker.addr, 3_000)

  echo "waiting for blinking"
  var blinky = asyncable()

  waitFor(sleepAsync(2_000) or blinky)

  echo "stopping blinky"
  blinky.complete(0)
  led.put(Low)

  echo "waiting for complete..."

  waitFor(sleepAsync(500))

  # context.poll()

  while not complete:
    if blocking:
      wfe()
    else:
      context.waitForWorkMs(5_000)
      echo "polling"
      context.poll()

  echo "test complete!!"

proc testPollingAsync() =
  var asyncPoll: AsyncContextPoll

  assert asyncPoll.addr.init()
  let context = asyncPoll.core.addr
  defer:
    destroyDispatcher()
    currentAsyncContext = nil
    context.deinit()

  currentAsyncContext = context

  echo "running test using AsyncContextPoll"
  GC_fullCollect()
  echo "before:\n", GC_getStatistics()
  performTest(context, false)
  GC_fullCollect()
  echo "after: \n", GC_getStatistics()

proc testBackgroundThreadAsync() =
  var asyncThread: AsyncContextThreadsafeBackground
  var cfg = asyncContextThreadsafeBackgroundDefaultConfig()

  assert asyncThread.addr.init(cfg.addr)
  let context = asyncThread.core.addr
  defer:
    destroyDispatcher()
    currentAsyncContext = nil
    context.deinit()

  currentAsyncContext = context

  echo "running test using AsyncContextThreadsafeBackground"

  GC_fullCollect()
  echo "before:\n", GC_getStatistics()
  performTest(context, true)
  GC_fullCollect()
  echo "after: \n", GC_getStatistics()

while true:
  testPollingAsync()

  testBackgroundThreadAsync()
