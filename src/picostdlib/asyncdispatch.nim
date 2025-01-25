import std/deques
import std/heapqueue
import std/asyncmacro
import std/asyncfutures
import ./pico/async_context

export asyncfutures, asyncmacro, async_context

var currentAsyncContext*: ptr AsyncContext
var whenPendingWorker = AsyncWhenPendingWorker()


type
  Dispatcher* = ref object of RootObj
    callbacks: Deque[proc () {.gcsafe.}]
    timers: HeapQueue[ref AsyncAtTimeWorker]

proc `<`(a, b: ref AsyncAtTimeWorker): bool =
  ## used for timers' HeapQueue
  a.nextTime < b.nextTime

proc newDispatcher(): owned Dispatcher =
  # echo "creating new dispatcher"
  new result
  result.callbacks = initDeque[proc () {.closure, gcsafe.}]()
  result.timers = initHeapQueue[ref AsyncAtTimeWorker]()

var asyncDispatcher {.threadvar.}: Dispatcher
var asyncDidSomeWork {.threadvar.}: bool

proc getDispatcher(): Dispatcher =
  if asyncDispatcher.isNil:
    asyncDispatcher = newDispatcher()
  result = asyncDispatcher

proc processPendingCallbacks(dispatcher: Dispatcher; didSomeWork: var bool) =
  # echo "processing ", dispatcher.callbacks.len, " callback(s)"
  while dispatcher.callbacks.len > 0:
    var cb = dispatcher.callbacks.popFirst()
    cb()
    didSomeWork = true

proc destroyDispatcher*() =
  if not asyncDispatcher.isNil:
    var didSomeWork: bool
    asyncDispatcher.processPendingCallbacks(didSomeWork)
    asyncDispatcher = nil

proc whenWorkPendingCb(context: ptr AsyncContext; worker: ptr AsyncWhenPendingWorker) {.cdecl.} =
  getDispatcher().processPendingCallbacks(asyncDidSomeWork)

proc dispatcherCallSoon*(cbproc: proc () {.gcsafe.}) =
  let dispatcher = getDispatcher()
  dispatcher.callbacks.addLast(cbproc)

  if currentAsyncContext.isNil:
    dispatcher.processPendingCallbacks(asyncDidSomeWork)
  else:
    whenPendingWorker.doWork = whenWorkPendingCb
    discard currentAsyncContext.addWhenPendingWorker(whenPendingWorker.addr)
    currentAsyncContext.setWorkPending(whenPendingWorker.addr)

asyncfutures.setCallSoonProc(dispatcherCallSoon)

proc runOnce(timeout: int): bool =
  let dispatcher = getDispatcher()

  var didSomeWork = false
  if currentAsyncContext.isNil:
    dispatcher.processPendingCallbacks(didSomeWork)
  else:
    asyncDidSomeWork = false
    currentAsyncContext.waitForWorkMs(timeout.uint32)
    currentAsyncContext.poll()
    didSomeWork = asyncDidSomeWork
  return didSomeWork

proc poll*(timeout = 500) =
  ## Waits for completion events and processes them.
  discard runOnce(timeout)

proc runForever*() =
  ## Begins a never ending global dispatcher poll loop.
  while true:
    poll()

proc waitFor*[T](fut: Future[T]): T =
  ## **Blocks** the current thread until the specified future completes.
  while not fut.finished:
    poll()

  fut.read

proc timerWorkerCb(context: ptr AsyncContext; worker: ptr AsyncAtTimeWorker) {.cdecl.} =
  let dispatcher = getDispatcher()
  for i in 0 ..< dispatcher.timers.len:
    let timer = dispatcher.timers[i]
    if cast[ptr AsyncAtTimeWorker](timer) == worker:
      let future = cast[Future[void]](worker.userData)
      if not future.failed and not future.finished:
        future.complete()
      dispatcher.timers.del(i)
      return
  raise newException(CatchableError, "AsyncAtTimeWorker not found is heapqueue")

proc sleepAsync*(ms: int): Future[void] =
  if currentAsyncContext.isNil:
    raise newException(CatchableError, "No AsyncContext provided")

  let dispatcher = getDispatcher()
  var retFuture = newFuture[void]("sleepAsync")
  let expireAt = makeTimeoutTimeMs(ms.uint32)
  let worker = new(AsyncAtTimeWorker)
  worker.userData = cast[pointer](retFuture)
  worker.doWork = timerWorkerCb
  discard currentAsyncContext.addAtTimeWorkerAt(cast[ptr AsyncAtTimeWorker](worker), expireAt)
  dispatcher.timers.push(worker)
  return retFuture


proc withTimeout*[T](fut: Future[T], timeout: int): owned(Future[bool]) =
  ## Returns a future which will complete once `fut` completes or after
  ## `timeout` milliseconds has elapsed.
  ##
  ## If `fut` completes first the returned future will hold true,
  ## otherwise, if `timeout` milliseconds has elapsed first, the returned
  ## future will hold false.

  var retFuture = newFuture[bool]("withTimeout")
  var timeoutFuture = sleepAsync(timeout)
  fut.addCallback(proc () =
    if not retFuture.finished:
      if fut.failed:
        retFuture.fail(fut.error)
      else:
        retFuture.complete(true)
  )
  timeoutFuture.callback =
    proc () =
      if not retFuture.finished:
        retFuture.complete(false)
  return retFuture
