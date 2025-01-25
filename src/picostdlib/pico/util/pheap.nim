import ../../helpers
{.localPassC: "-I" & picoSdkPath & "/src/common/pico_util/include".}
{.push header: "pico/util/pheap.h".}

# let PicoPheapMaxEntries* {.importc: "PICO_PHEAP_MAX_ENTRIES".}: cuint
const PICO_PHEAP_MAX_ENTRIES* {.intdefine.} = 255

# public heap_node ids are numbered from 1 (0 means none)
when PICO_PHEAP_MAX_ENTRIES < 256:
  type PheapNodeId* {.importc: "pheap_node_id_t".} = uint8
elif PICO_PHEAP_MAX_ENTRIES < 65535:
  type PheapNodeId* {.importc: "pheap_node_id_t".} = uint16
else:
  {.error: "invalid PICO_PHEAP_MAX_ENTRIES".}

type
  PheapNode* {.importc: "pheap_node_t".} = object
    child*, sibling*, parent*: PheapNodeId

  PheapComparator* {.importc: "pheap_comparator".} = proc (userData: pointer; a, b: PheapNodeId): bool {.cdecl.}
    ## A user comparator function for nodes in a pairing heap.
    ##
    ## \return true if a < b in natural order. Note this relative ordering must be stable from call to call.

  Pheap* {.importc: "pheap_t".} = object
    nodes*: ptr PheapNode
    comparator*: PheapComparator
    userData* {.importc: "user_data".}: pointer
    maxNodes* {.importc: "max_nodes".}: PheapNodeId
    rootId* {.importc: "root_id".}: PheapNodeId
    # we remove from head and add to tail to stop reusing the same ids
    freeHeadId* {.importc: "free_head_id".}: PheapNodeId
    freeTailId* {.importc: "free_tail_id".}: PheapNodeId


proc phCreate*(maxNodes: cuint; comparator: PheapComparator; userData: pointer): ptr Pheap {.importc: "ph_create".}
  ## Create a pairing heap, which effectively maintains an efficient sorted ordering
  ## of nodes. The heap itself stores no user per-node state, it is expected
  ## that the user maintains a companion array. A comparator function must
  ## be provided so that the heap implementation can determine the relative ordering of nodes
  ##
  ## \param max_nodes the maximum number of nodes that may be in the heap (this is bounded by
  ##                  PICO_PHEAP_MAX_ENTRIES which defaults to 255 to be able to store indexes
  ##                  in a single byte).
  ## \param comparator the node comparison function
  ## \param user_data a user data pointer associated with the heap that is provided in callbacks
  ## \return a newly allocated and initialized heap

proc clear*(heap: ptr Pheap) {.importc: "ph_clear".}
  ## Removes all nodes from the pairing heap
  ## \param heap the heap

proc destroy*(heap: ptr Pheap) {.importc: "ph_destroy".}
  ## De-allocates a pairing heap
  ##
  ## Note this method must *ONLY* be called on heaps created by ph_create()
  ## \param heap the heap

proc newNode*(heap: ptr Pheap): PheapNodeId {.importc: "ph_new_node".}
  ## Allocate a new node from the unused space in the heap
  ##
  ## \param heap the heap
  ## \return an identifier for the node, or 0 if the heap is full

proc insertNode*(heap: ptr Pheap; id: PheapNodeId): PheapNodeId {.importc: "ph_insert_node".}
  ## Inserts a node into the heap.
  ##
  ## This method inserts a node (previously allocated by ph_new_node())
  ## into the heap, determining the correct order by calling
  ## the heap's comparator
  ##
  ## \param heap the heap
  ## \param id the id of the node to insert
  ## \return the id of the new head of the pairing heap (i.e. node that compares first)

proc peekHead*(heap: ptr Pheap): PheapNodeId {.importc: "ph_peek_head".}
  ## Returns the head node in the heap, i.e. the node
  ## which compares first, but without removing it from the heap.
  ##
  ## \param heap the heap
  ## \return the current head node id

proc removeHead*(heap: ptr Pheap; free: bool): PheapNodeId {.importc: "ph_remove_head".}
  ## Remove the head node from the pairing heap. This head node is
  ## the node which compares first in the logical ordering provided
  ## by the comparator.
  ##
  ## Note that in the case of free == true, the returned id is no longer
  ## allocated and may be re-used by future node allocations, so the caller
  ## should retrieve any per node state from the companion array before modifying
  ## the heap further.
  ##
  ## @param heap the heap
  ## @param free true if the id is also to be freed; false if not - useful if the caller
  ##        may wish to re-insert an item with the same id)
  ## @return the old head node id.

proc removeAndFreeHead*(heap: ptr Pheap): PheapNodeId {.importc: "ph_remove_and_free_head".}
  ## Remove the head node from the pairing heap. This head node is
  ## the node which compares first in the logical ordering provided
  ## by the comparator.
  ##
  ## Note that the returned id will be freed, and thus may be re-used by future node allocations,
  ## so the caller should retrieve any per node state from the companion array before modifying
  ## the heap further.
  ##
  ## @param heap the heap
  ## @return the old head node id.

proc removeAndFreeNode*(heap: ptr Pheap; id: PheapNodeId): bool {.importc: "ph_remove_and_free_node".}
  ## Remove and free an arbitrary node from the pairing heap. This is a more
  ## costly operation than removing the head via ph_remove_and_free_head()
  ##
  ## @param heap the heap
  ## @param id the id of the node to free
  ## @return true if the the node was in the heap, false otherwise

proc containsNode*(heap: ptr Pheap; id: PheapNodeId): bool {.importc: "ph_contains_node".}
  ## Determine if the heap contains a given node. Note containment refers
  ## to whether the node is inserted (ph_insert_node()) vs allocated (ph_new_node())
  ##
  ## @param heap the heap
  ## @param id the id of the node
  ## @return true if the heap contains a node with the given id, false otherwise.

proc freeNode*(heap: ptr Pheap; id: PheapNodeId) {.importc: "ph_free_node".}
  ## Free a node that is not currently in the heap, but has been allocated
  ##
  ## @param heap the heap
  ## @param id the id of the node

proc dump*(heap: ptr Pheap; dumpKey: proc (id: PheapNodeId; userData: pointer) {.cdecl.}; userData: pointer) {.importc: "ph_dump".}
  ## Print a representation of the heap for debugging
  ##
  ## @param heap the heap
  ## @param dump_key a method to print a node value
  ## @param user_data the user data to pass to the dump_key method

proc postAllocInit*(heap: ptr Pheap; maxNodes: cuint; comparator: PheapComparator; userData: pointer) {.importc: "ph_post_alloc_init".}
  ## Initialize a statically allocated heap (ph_create() using the C heap).
  ## The heap member `nodes` must be allocated of size max_nodes.
  ##
  ## @param heap the heap
  ## @param max_nodes the max number of nodes in the heap (matching the size of the heap's nodes array)
  ## @param comparator the comparator for the heap
  ## @param user_data the user data for the heap.

{.pop.}
