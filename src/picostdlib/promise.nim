import std/deques
import std/sequtils
import std/asyncfutures

export asyncfutures

type
  PromiseError* = object of CatchableError

  PromiseState* = enum
    Pending
    Resolved
    Rejected

  PromiseOnResolveCb*[T] = proc (value: T): T
  PromiseOnRejectCb* = proc (reason: ref PromiseError): ref PromiseError
  PromiseResolveFn*[T] = proc (value: T)
  PromiseRejectFn* = proc (reason: ref PromiseError)

  PromiseCallback[T] = object
    onResolveCb: PromiseOnResolveCb[T]
    onRejectCb: PromiseOnRejectCb
    resolveFn: PromiseResolveFn[T]
    rejectFn: PromiseRejectFn


  PromiseBase* = ref object of RootObj
    state: PromiseState
    reason: ref PromiseError

  Promise*[T] = ref object of PromiseBase
    callbacks: Deque[PromiseCallback[T]]
    value: T

proc state*(self: PromiseBase): PromiseState = return self.state

template read*[T](self: Promise[T]): T = self.value
proc reason*(self: PromiseBase): ref PromiseError = return self.reason

proc notify[T](self: Promise[T])

proc resolve*[T](self: Promise[T]; value: T) =
  if self.state != Pending:
    raise newException(ValueError, "This promise already has state " & $self.state)
  self.value = value
  self.state = Resolved
  self.notify()

proc reject*(self: Promise; reason: ref PromiseError) =
  if self.state != Pending:
    raise newException(ValueError, "This promise already has state " & $self.state)
  self.reason = reason
  self.state = Rejected
  self.notify()

proc newPromise*[T](fn: proc(resolve: proc (value: T); reject: PromiseRejectFn)): owned Promise[T] =
  let promise = Promise[T](state: Pending)
  promise.callbacks = initDeque[PromiseCallback[T]](2)
  try:
    fn(proc (value: T) =
      promise.resolve(value)
    , proc (reason: ref PromiseError) =
      promise.reject(reason)
    )
  except PromiseError as reason:
    promise.reject(reason)
  return promise

proc then*[T](self: Promise[T]; onResolved: PromiseOnResolveCb[T] = nil; onRejected: PromiseOnRejectCb = nil): owned Promise[T] =
  let promise = self
  return newPromise[T](proc(resolve: PromiseResolveFn[T], reject: proc(reason: ref PromiseError)) =
    promise.callbacks.addLast(PromiseCallback[T](onResolveCb: onResolved, onRejectCb: onRejected, resolveFn: resolve, rejectFn: reject))
    promise.notify()
  )

proc catch*[T](self: Promise[T]; onReject: PromiseOnRejectCb): owned Promise[T] =
  return self.then(nil, onReject)

proc resolve*[T](_: typedesc[Promise[T]]; value: T): owned Promise[T] =
  return newPromise[T](proc (resolve: PromiseResolveFn[T]; reject: PromiseRejectFn) =
    resolve(value)
  )

proc reject*[T](_: typedesc[Promise[T]]; reason: ref PromiseError): owned Promise[T] =
  return newPromise[T](proc (resolve: PromiseResolveFn[T]; reject: PromiseRejectFn) =
    reject(reason)
  )

proc notify[T](self: Promise[T]) =
  var promise = self
  asyncfutures.callSoon(proc () {.gcsafe.} =
    if promise.state == Pending: return
    while promise.callbacks.len > 0:
      let callback = promise.callbacks.popFirst
      try:
        if promise.state == Resolved:
          if not callback.onResolveCb.isNil:
            callback.resolveFn(callback.onResolveCb(promise.read()))
          else:
            callback.resolveFn(promise.read())
        else:
          if not callback.onRejectCb.isNil:
            callback.rejectFn(callback.onRejectCb(promise.reason))
          else:
            callback.rejectFn(promise.reason)
      except PromiseError as reason:
        callback.rejectFn(reason)
  )


proc all*[T](_: typedesc[Promise[T]]; promises: varargs[Promise[T]]): owned Promise[seq[T]] =
  var promises = promises.toSeq()
  return newPromise[seq[T]](proc (resolve: PromiseResolveFn[seq[T]]; reject: PromiseRejectFn) =
    var results = newSeq[T]()
    let promiseCount = promises.len
    var promisesResolved = 0
    results.setLen(promiseCount)
    for i, promise in promises.pairs:
      discard promise.then(proc (value: T): T =
        results[i] = value
        inc(promisesResolved)
        if promisesResolved == promiseCount:
          resolve(results)
        return value
      , proc (reason: ref PromiseError): ref PromiseError = reject(reason); return reason)
  )

proc race*[T](_: typedesc[Promise[T]]; promises: varargs[Promise[T]]): owned Promise[T] =
  var promises = promises.toSeq()
  return newPromise[T](proc (resolve: PromiseResolveFn[T]; reject: PromiseRejectFn) =
    let promiseCount = promises.len
    var promiseResolved = false
    for i, promise in promises.pairs:
      discard promise.then(proc (value: T): T =
        if not promiseResolved:
          promiseResolved = true
          resolve(promise)
        return value
      , proc (reason: ref PromiseError): ref PromiseError = reject(reason); return reason)
  )

proc toFuture*[T](self: Promise[T]): owned Future[T] =
  let future = newFuture[T]("promise.toFuture")
  discard self.then(proc (value: T): T = future.complete(value), proc (reason: ref PromiseError): ref PromiseError = future.fail(reason))
  return future
