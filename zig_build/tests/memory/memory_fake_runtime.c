// SPDX-License-Identifier: GPL-3.0-only

#include "memory_test_runtime.h"

typedef enum {
  ALLOC_KIND_NONE = 0,
  ALLOC_KIND_C47 = 1,
  ALLOC_KIND_GMP = 2,
} alloc_kind_t;

typedef struct {
  void *ptr;
  alloc_kind_t kind;
} allocation_slot_t;

static uint32_t fakeRam[RAM_SIZE_IN_BLOCKS];
static freeMemoryRegion_t freeMemoryRegionsStorage[MAX_FAKE_FREE_REGIONS];
static allocation_slot_t allocationSlots[MAX_FAKE_ALLOCATIONS];

freeMemoryRegion_t *freeMemoryRegions = freeMemoryRegionsStorage;
freeMemoryRegion_t allocatedMemoryRegions[MAX_FAKE_ALLOCATIONS];
int32_t numberOfFreeMemoryRegions = 0;
int32_t numberOfAllocatedMemoryRegions = 0;
uint8_t *beginOfProgramMemory = NULL;
uint8_t *firstFreeProgramByte = NULL;
size_t gmpMemInBytes = 0;
size_t c47MemInBlocks = 0;

static bool_t freeListAllocShouldFail = false;
static bool_t freeListReallocShouldFail = false;
static bool_t gmpAllocShouldFail = false;
static bool_t gmpReallocShouldFail = false;

static uint32_t freeListAllocCalls = 0;
static uint32_t freeListReallocCalls = 0;
static uint32_t freeListReduceCalls = 0;
static uint32_t freeListFreeCalls = 0;
static uint32_t gmpAllocCalls = 0;
static uint32_t gmpReallocCalls = 0;
static uint32_t gmpFreeCalls = 0;
static uint32_t copyBytesCalls = 0;
static uint32_t resizeProgramOomCalls = 0;
static size_t lastFreeListAllocSize = 0;
static size_t lastFreeListReallocOldSize = 0;
static size_t lastFreeListReallocNewSize = 0;
static size_t lastFreeListReduceOldSize = 0;
static size_t lastFreeListReduceNewSize = 0;
static size_t lastFreeListFreeSize = 0;
static size_t lastGmpAllocSize = 0;
static size_t lastGmpReallocSize = 0;
static uint32_t lastCopyBytes = 0;
static uint16_t lastResizeProgramOomDelta = 0;

static allocation_slot_t *findAllocationSlot(const void *ptr) {
  size_t index;

  for(index = 0; index < MAX_FAKE_ALLOCATIONS; index++) {
    if(allocationSlots[index].ptr == ptr) {
      return &allocationSlots[index];
    }
  }

  return NULL;
}

static allocation_slot_t *reserveAllocationSlot(void) {
  size_t index;

  for(index = 0; index < MAX_FAKE_ALLOCATIONS; index++) {
    if(allocationSlots[index].ptr == NULL) {
      return &allocationSlots[index];
    }
  }

  return NULL;
}

static void registerAllocation(void *ptr, alloc_kind_t kind) {
  allocation_slot_t *slot;

  if(ptr == NULL) {
    return;
  }

  slot = reserveAllocationSlot();
  if(slot == NULL) {
    free(ptr);
    return;
  }

  slot->ptr = ptr;
  slot->kind = kind;
}

static void forgetAllocation(void *ptr) {
  allocation_slot_t *slot = findAllocationSlot(ptr);

  if(slot == NULL) {
    return;
  }

  slot->ptr = NULL;
  slot->kind = ALLOC_KIND_NONE;
}

uint16_t memoryParityToC47MemPtr(const void *ptr) {
  if(ptr == NULL) {
    return C47_NULL;
  }

  return (uint16_t)((const uint32_t *)ptr - fakeRam);
}

void *memoryParityToPcMemPtr(uint16_t ptr) {
  if(ptr == C47_NULL || ptr >= RAM_SIZE_IN_BLOCKS) {
    return NULL;
  }

  return fakeRam + ptr;
}

static void resetCounters(void) {
  freeListAllocCalls = 0;
  freeListReallocCalls = 0;
  freeListReduceCalls = 0;
  freeListFreeCalls = 0;
  gmpAllocCalls = 0;
  gmpReallocCalls = 0;
  gmpFreeCalls = 0;
  copyBytesCalls = 0;
  resizeProgramOomCalls = 0;
  lastFreeListAllocSize = 0;
  lastFreeListReallocOldSize = 0;
  lastFreeListReallocNewSize = 0;
  lastFreeListReduceOldSize = 0;
  lastFreeListReduceNewSize = 0;
  lastFreeListFreeSize = 0;
  lastGmpAllocSize = 0;
  lastGmpReallocSize = 0;
  lastCopyBytes = 0;
  lastResizeProgramOomDelta = 0;
}

void memoryParityReset(void) {
  size_t index;

  for(index = 0; index < MAX_FAKE_ALLOCATIONS; index++) {
    if(allocationSlots[index].ptr != NULL) {
      free(allocationSlots[index].ptr);
      allocationSlots[index].ptr = NULL;
      allocationSlots[index].kind = ALLOC_KIND_NONE;
    }
  }

  memset(fakeRam, 0, sizeof(fakeRam));
  memset(freeMemoryRegionsStorage, 0, sizeof(freeMemoryRegionsStorage));
  memset(allocatedMemoryRegions, 0, sizeof(allocatedMemoryRegions));
  numberOfFreeMemoryRegions = 0;
  numberOfAllocatedMemoryRegions = 0;
  beginOfProgramMemory = (uint8_t *)(fakeRam + (RAM_SIZE_IN_BLOCKS - 1));
  firstFreeProgramByte = beginOfProgramMemory + 2;
  gmpMemInBytes = 0;
  c47MemInBlocks = 0;
  freeListAllocShouldFail = false;
  freeListReallocShouldFail = false;
  gmpAllocShouldFail = false;
  gmpReallocShouldFail = false;
  resetCounters();
}

void memoryParitySeedRegions(const freeMemoryRegion_t *regions, int32_t count) {
  memset(freeMemoryRegionsStorage, 0, sizeof(freeMemoryRegionsStorage));
  numberOfFreeMemoryRegions = count;
  if(count > 0) {
    memcpy(freeMemoryRegionsStorage, regions, (size_t)count * sizeof(freeMemoryRegion_t));
  }
}

void memoryParitySeedProgramState(uint16_t beginBlock, uint32_t firstFreeOffsetBytes, const uint8_t *programBytes, uint32_t programByteCount) {
  beginOfProgramMemory = memoryParityToPcMemPtr(beginBlock);
  firstFreeProgramByte = beginOfProgramMemory + firstFreeOffsetBytes;
  if(programBytes != NULL && programByteCount > 0) {
    memcpy(beginOfProgramMemory, programBytes, programByteCount);
  }
}

void memoryParitySetCounters(size_t c47Blocks, size_t gmpBytes) {
  c47MemInBlocks = c47Blocks;
  gmpMemInBytes = gmpBytes;
}

void memoryParitySetFailureModes(bool_t freeListAllocFail, bool_t freeListReallocFail, bool_t gmpAllocFail, bool_t gmpReallocFail) {
  freeListAllocShouldFail = freeListAllocFail;
  freeListReallocShouldFail = freeListReallocFail;
  gmpAllocShouldFail = gmpAllocFail;
  gmpReallocShouldFail = gmpReallocFail;
}

void *memoryParityMakeC47Allocation(size_t sizeInBlocks) {
  void *ptr = malloc(TO_BYTES(sizeInBlocks == 0 ? 1 : sizeInBlocks));
  registerAllocation(ptr, ALLOC_KIND_C47);
  return ptr;
}

void *memoryParityMakeGmpAllocation(size_t sizeInBytes) {
  void *ptr = malloc(sizeInBytes == 0 ? 1 : sizeInBytes);
  registerAllocation(ptr, ALLOC_KIND_GMP);
  return ptr;
}

void memoryParityCapture(memory_parity_snapshot_t *snapshot) {
  memset(snapshot, 0, sizeof(*snapshot));
  snapshot->c47_mem_in_blocks = c47MemInBlocks;
  snapshot->gmp_mem_in_bytes = gmpMemInBytes;
  snapshot->number_of_free_regions = numberOfFreeMemoryRegions;
  memcpy(snapshot->free_regions, freeMemoryRegionsStorage, sizeof(snapshot->free_regions));
  snapshot->begin_of_program_block = memoryParityToC47MemPtr(beginOfProgramMemory);
  snapshot->first_free_program_byte_offset = firstFreeProgramByte == NULL ? UINT32_MAX : (uint32_t)(firstFreeProgramByte - (uint8_t *)fakeRam);
  memcpy(snapshot->ram_bytes, fakeRam, sizeof(snapshot->ram_bytes));
  snapshot->free_list_alloc_calls = freeListAllocCalls;
  snapshot->free_list_realloc_calls = freeListReallocCalls;
  snapshot->free_list_reduce_calls = freeListReduceCalls;
  snapshot->free_list_free_calls = freeListFreeCalls;
  snapshot->gmp_alloc_calls = gmpAllocCalls;
  snapshot->gmp_realloc_calls = gmpReallocCalls;
  snapshot->gmp_free_calls = gmpFreeCalls;
  snapshot->copy_bytes_calls = copyBytesCalls;
  snapshot->resize_program_oom_calls = resizeProgramOomCalls;
  snapshot->last_free_list_alloc_size = lastFreeListAllocSize;
  snapshot->last_free_list_realloc_old_size = lastFreeListReallocOldSize;
  snapshot->last_free_list_realloc_new_size = lastFreeListReallocNewSize;
  snapshot->last_free_list_reduce_old_size = lastFreeListReduceOldSize;
  snapshot->last_free_list_reduce_new_size = lastFreeListReduceNewSize;
  snapshot->last_free_list_free_size = lastFreeListFreeSize;
  snapshot->last_gmp_alloc_size = lastGmpAllocSize;
  snapshot->last_gmp_realloc_size = lastGmpReallocSize;
  snapshot->last_copy_bytes = lastCopyBytes;
  snapshot->last_resize_program_oom_delta = lastResizeProgramOomDelta;
}

void *freeListAlloc(size_t sizeInBlocks) {
  void *ptr;

  freeListAllocCalls++;
  lastFreeListAllocSize = sizeInBlocks;
  if(freeListAllocShouldFail) {
    return NULL;
  }

  ptr = malloc(TO_BYTES(sizeInBlocks == 0 ? 1 : sizeInBlocks));
  registerAllocation(ptr, ALLOC_KIND_C47);
  return ptr;
}

void *freeListRealloc(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks) {
  allocation_slot_t *slot;
  void *newPtr;

  freeListReallocCalls++;
  lastFreeListReallocOldSize = oldSizeInBlocks;
  lastFreeListReallocNewSize = newSizeInBlocks;
  if(freeListReallocShouldFail) {
    return NULL;
  }

  newPtr = realloc(pcMemPtr, TO_BYTES(newSizeInBlocks == 0 ? 1 : newSizeInBlocks));
  if(newPtr == NULL) {
    return NULL;
  }

  slot = findAllocationSlot(pcMemPtr);
  if(slot != NULL) {
    slot->ptr = newPtr;
  } else {
    registerAllocation(newPtr, ALLOC_KIND_C47);
  }

  return newPtr;
}

void freeListReduce(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks) {
  (void)pcMemPtr;
  freeListReduceCalls++;
  lastFreeListReduceOldSize = oldSizeInBlocks;
  lastFreeListReduceNewSize = newSizeInBlocks;
}

void freeListFree(void *pcMemPtr, size_t sizeInBlocks) {
  freeListFreeCalls++;
  lastFreeListFreeSize = sizeInBlocks;
  if(pcMemPtr == NULL) {
    return;
  }

  free(pcMemPtr);
  forgetAllocation(pcMemPtr);
}

void *xcopy(void *dest, const void *source, uint32_t n) {
  return memmove(dest, source, n);
}

uint16_t z47_memory_runtime_get_ram_size_in_blocks(void) {
  return RAM_SIZE_IN_BLOCKS;
}

freeMemoryRegion_t z47_memory_runtime_get_free_region(uint16_t index) {
  return freeMemoryRegionsStorage[index];
}

void z47_memory_runtime_set_free_region(uint16_t index, freeMemoryRegion_t region) {
  freeMemoryRegionsStorage[index] = region;
}

uint16_t z47_memory_runtime_to_c47_mem_ptr(uint8_t *memPtr) {
  return memoryParityToC47MemPtr(memPtr);
}

void *z47_memory_runtime_copy_bytes(void *dest, const void *source, uint32_t n) {
  copyBytesCalls++;
  lastCopyBytes = n;
  if(n == 0 || dest == NULL || source == NULL) {
    return dest;
  }

  return memmove(dest, source, n);
}

void z47_memory_runtime_handle_resize_program_memory_out_of_memory(uint16_t deltaBlocks) {
  resizeProgramOomCalls++;
  lastResizeProgramOomDelta = deltaBlocks;
}

void *z47_memory_runtime_alloc_gmp_bytes(size_t sizeInBytes) {
  void *ptr;

  gmpAllocCalls++;
  lastGmpAllocSize = sizeInBytes;
  if(gmpAllocShouldFail) {
    return NULL;
  }

  ptr = malloc(sizeInBytes == 0 ? 1 : sizeInBytes);
  registerAllocation(ptr, ALLOC_KIND_GMP);
  return ptr;
}

void *z47_memory_runtime_realloc_gmp_bytes(void *pcMemPtr, size_t newSizeInBytes) {
  allocation_slot_t *slot;
  void *newPtr;

  gmpReallocCalls++;
  lastGmpReallocSize = newSizeInBytes;
  if(gmpReallocShouldFail) {
    return NULL;
  }

  newPtr = realloc(pcMemPtr, newSizeInBytes == 0 ? 1 : newSizeInBytes);
  if(newPtr == NULL) {
    return NULL;
  }

  slot = findAllocationSlot(pcMemPtr);
  if(slot != NULL) {
    slot->ptr = newPtr;
  } else {
    registerAllocation(newPtr, ALLOC_KIND_GMP);
  }

  return newPtr;
}

void z47_memory_runtime_free_gmp_bytes(void *pcMemPtr) {
  gmpFreeCalls++;
  if(pcMemPtr == NULL) {
    return;
  }

  free(pcMemPtr);
  forgetAllocation(pcMemPtr);
}