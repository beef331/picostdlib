import ../lock_core
export lock_core

import ../../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_util/include".}
{.push header: "pico/util/queue.h".}

let PicoQueueMaxLevel* {.importc: "PICO_QUEUE_MAX_LEVEL".}: bool

type
  Queue* {.importc: "queue_t".} = object
    core* {.importc: "core".}: LockCore
    data* {.importc: "data".}: ptr uint8
    wptr* {.importc: "wptr".}: uint16
    rptr* {.importc: "rptr".}: uint16
    elementSize* {.importc: "element_size".}: uint16
    elementCount* {.importc: "element_count".}: uint16
    maxLevel* {.importc: "max_level".}: uint16 # Requires PICO_QUEUE_MAX_LEVEL

proc initWithSpinlock*(q: ptr Queue; elementSize: cuint; elementCount: cuint; spinlockNum: cuint) {.importc: "queue_init_with_spinlock".}
  ## Initialise a queue with a specific spinlock for concurrency protection
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param element_size Size of each value in the queue
  ## \param element_count Maximum number of entries in the queue
  ## \param spinlock_num The spin ID used to protect the queue

proc init*(q: ptr Queue; elementSize: cuint; elementCount: cuint) {.importc: "queue_init".}
  ## Initialise a queue, allocating a (possibly shared) spinlock
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param element_size Size of each value in the queue
  ## \param element_count Maximum number of entries in the queue

proc free*(q: ptr Queue) {.importc: "queue_free".}
  ## Destroy the specified queue.
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ##
  ## Does not deallocate the queue_t structure itself.

proc getLevelUnsafe*(q: ptr Queue): cuint {.importc: "queue_get_level_unsafe".}
  ## Unsafe check of level of the specified queue.
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \return Number of entries in the queue
  ##
  ## This does not use the spinlock, so may return incorrect results if the
  ## spin lock is not externally locked

proc getLevel*(q: ptr Queue): cuint {.importc: "queue_get_level".}
  ## Check of level of the specified queue.
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \return Number of entries in the queue

proc getMaxLevel*(q: ptr Queue): cuint {.importc: "queue_get_max_level".}
  ## Returns the highest level reached by the specified queue since it was created
  ## or since the max level was reset
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \return Maximum level of the queue
  ##
  ## Requires PICO_QUEUE_MAX_LEVEL

proc resetMaxLevel*(q: ptr Queue) {.importc: "queue_reset_max_level".}
  ## Reset the highest level reached of the specified queue.
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ##
  ## Requires PICO_QUEUE_MAX_LEVEL

proc isEmpty*(q: ptr Queue): bool {.importc: "queue_is_empty".}
  ## Check if queue is empty
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \return true if queue is empty, false otherwise
  ##
  ## This function is interrupt and multicore safe.

proc isFull*(q: ptr Queue): bool {.importc: "queue_is_full".}
  ## Check if queue is full
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \return true if queue is full, false otherwise
  ##
  ## This function is interrupt and multicore safe.

## nonblocking queue access functions:

proc tryAdd*(q: ptr Queue; data: pointer): bool {.importc: "queue_try_add".}
  ## Non-blocking add value queue if not full
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to value to be copied into the queue
  ## \return true if the value was added
  ##
  ## If the queue is full this function will return immediately with false, otherwise
  ## the data is copied into a new value added to the queue, and this function will return true.

proc tryRemove*(q: ptr Queue; data: pointer): bool {.importc: "queue_try_remove".}
  ## Non-blocking removal of entry from the queue if non empty
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to the location to receive the removed value
  ## \return true if a value was removed
  ##
  ## If the queue is not empty function will copy the removed value into the location provided and return
  ## immediately with true, otherwise the function will return immediately with false.

proc tryPeek*(q: ptr Queue; data: pointer): bool {.importc: "queue_try_peek".}
  ## Non-blocking peek at the next item to be removed from the queue
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to the location to receive the peeked value
  ## \return true if there was a value to peek
  ##
  ## If the queue is not empty this function will return immediately with true with the peeked entry
  ## copied into the location specified by the data parameter, otherwise the function will return false.

## blocking queue access functions:

proc queueAddBlocking*(q: ptr Queue; data: pointer) {.importc: "queue_add_blocking".}
  ## Blocking add of value to queue
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to value to be copied into the queue
  ##
  ## If the queue is full this function will block, until a removal happens on the queue

proc removeBlocking*(q: ptr Queue; data: pointer) {.importc: "queue_remove_blocking".}
  ## Blocking remove entry from queue
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to the location to receive the removed value
  ##
  ## If the queue is empty this function will block until a value is added.

proc queuePeekBlocking*(q: ptr Queue; data: pointer) {.importc: "queue_peek_blocking".}
  ## Blocking peek at next value to be removed from queue
  ##
  ## \param q Pointer to a queue_t structure, used as a handle
  ## \param data Pointer to the location to receive the peeked value
  ##
  ## If the queue is empty function will block until a value is added

{.pop.}
