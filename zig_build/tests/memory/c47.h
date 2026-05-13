// SPDX-License-Identifier: GPL-3.0-only

#ifndef C47_H
#define C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

typedef bool bool_t;

typedef struct {
  uint16_t blockAddress;
  uint16_t sizeInBlocks;
} freeMemoryRegion_t;

#define BPB 2
#define BYTES_PER_BLOCK (1u << BPB)
#define TO_BLOCKS(n) ((((uint32_t)(n)) + (BYTES_PER_BLOCK - 1u)) >> BPB)
#define TO_BYTES(n) (((uint32_t)(n)) << BPB)

#define RAM_SIZE_IN_BLOCKS 64
#define C47_NULL 65535u
#define MAX_FAKE_FREE_REGIONS 8
#define MAX_FAKE_ALLOCATIONS 64

uint16_t memoryParityToC47MemPtr(const void *ptr);
void *memoryParityToPcMemPtr(uint16_t ptr);

#define TO_PCMEMPTR(p) memoryParityToPcMemPtr((uint16_t)(p))
#define TO_C47MEMPTR(p) memoryParityToC47MemPtr(p)

extern freeMemoryRegion_t *freeMemoryRegions;
extern freeMemoryRegion_t allocatedMemoryRegions[MAX_FAKE_ALLOCATIONS];
extern int32_t numberOfFreeMemoryRegions;
extern int32_t numberOfAllocatedMemoryRegions;
extern uint8_t *beginOfProgramMemory;
extern uint8_t *firstFreeProgramByte;
extern size_t gmpMemInBytes;
extern size_t c47MemInBlocks;

void *freeListAlloc(size_t sizeInBlocks);
void *freeListRealloc(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void freeListReduce(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void freeListFree(void *pcMemPtr, size_t sizeInBlocks);

void *xcopy(void *dest, const void *source, uint32_t n);

uint16_t z47_memory_runtime_get_ram_size_in_blocks(void);
freeMemoryRegion_t z47_memory_runtime_get_free_region(uint16_t index);
void z47_memory_runtime_set_free_region(uint16_t index, freeMemoryRegion_t region);
uint16_t z47_memory_runtime_to_c47_mem_ptr(uint8_t *memPtr);
size_t z47_memory_runtime_scale_extra_size(size_t sizeInBlocks, float extraFraction);
void *z47_memory_runtime_copy_bytes(void *dest, const void *source, uint32_t n);
void z47_memory_runtime_handle_resize_program_memory_out_of_memory(uint16_t deltaBlocks);
void *z47_memory_runtime_alloc_gmp_bytes(size_t sizeInBytes);
void *z47_memory_runtime_realloc_gmp_bytes(void *pcMemPtr, size_t newSizeInBytes);
void z47_memory_runtime_free_gmp_bytes(void *pcMemPtr);

uint32_t getFreeRamMemory(void);
bool_t isMemoryBlockAvailable(size_t sizeInBlocks, uint16_t numBlocks, float extraFraction);
void *allocC47Blocks(size_t sizeInBlocks);
void *reallocC47Blocks(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void reduceC47Blocks(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
void freeC47Blocks(void *pcMemPtr, size_t sizeInBlocks);
void *allocGmp(size_t sizeInBytes);
void *reallocGmp(void *pcMemPtr, size_t oldSizeInBytes, size_t newSizeInBytes);
void freeGmp(void *pcMemPtr, size_t sizeInBytes);
void resizeProgramMemory(uint16_t newSizeInBlocks);

#endif