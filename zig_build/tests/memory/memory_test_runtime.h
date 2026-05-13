// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MEMORY_TEST_RUNTIME_H
#define Z47_MEMORY_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  size_t c47_mem_in_blocks;
  size_t gmp_mem_in_bytes;
  int32_t number_of_free_regions;
  freeMemoryRegion_t free_regions[MAX_FAKE_FREE_REGIONS];
  uint16_t begin_of_program_block;
  uint32_t first_free_program_byte_offset;
  uint8_t ram_bytes[RAM_SIZE_IN_BLOCKS * BYTES_PER_BLOCK];
  uint32_t free_list_alloc_calls;
  uint32_t free_list_realloc_calls;
  uint32_t free_list_reduce_calls;
  uint32_t free_list_free_calls;
  uint32_t gmp_alloc_calls;
  uint32_t gmp_realloc_calls;
  uint32_t gmp_free_calls;
  uint32_t copy_bytes_calls;
  uint32_t resize_program_oom_calls;
  size_t last_free_list_alloc_size;
  size_t last_free_list_realloc_old_size;
  size_t last_free_list_realloc_new_size;
  size_t last_free_list_reduce_old_size;
  size_t last_free_list_reduce_new_size;
  size_t last_free_list_free_size;
  size_t last_gmp_alloc_size;
  size_t last_gmp_realloc_size;
  uint32_t last_copy_bytes;
  uint16_t last_resize_program_oom_delta;
} memory_parity_snapshot_t;

uint32_t oracle_getFreeRamMemory(void);
bool_t oracle_isMemoryBlockAvailable(size_t sizeInBlocks, uint16_t numBlocks, float extraFraction);
void *oracle_allocC47Blocks(size_t sizeInBlocks);
void *oracle_reallocC47Blocks(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void oracle_reduceC47Blocks(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void oracle_freeC47Blocks(void *pcMemPtr, size_t sizeInBlocks);
void *oracle_allocGmp(size_t sizeInBytes);
void *oracle_reallocGmp(void *pcMemPtr, size_t oldSizeInBytes, size_t newSizeInBytes);
void oracle_freeGmp(void *pcMemPtr, size_t sizeInBytes);
void oracle_resizeProgramMemory(uint16_t newSizeInBlocks);

void memoryParityReset(void);
void memoryParitySeedRegions(const freeMemoryRegion_t *regions, int32_t count);
void memoryParitySeedProgramState(uint16_t beginBlock, uint32_t firstFreeOffsetBytes, const uint8_t *programBytes, uint32_t programByteCount);
void memoryParitySetCounters(size_t c47Blocks, size_t gmpBytes);
void memoryParitySetFailureModes(bool_t freeListAllocFail, bool_t freeListReallocFail, bool_t gmpAllocFail, bool_t gmpReallocFail);
void *memoryParityMakeC47Allocation(size_t sizeInBlocks);
void *memoryParityMakeGmpAllocation(size_t sizeInBytes);
void memoryParityCapture(memory_parity_snapshot_t *snapshot);

#endif