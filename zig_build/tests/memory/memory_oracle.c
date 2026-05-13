// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void oracle_freeC47Blocks(void *pcMemPtr, size_t sizeInBlocks);

#define getFreeRamMemory oracle_getFreeRamMemory
#define isMemoryBlockAvailable oracle_isMemoryBlockAvailable
#define allocC47Blocks oracle_allocC47Blocks
#define reallocC47Blocks oracle_reallocC47Blocks
#define reduceC47Blocks oracle_reduceC47Blocks
#define freeC47Blocks oracle_freeC47Blocks
#define allocGmp oracle_allocGmp
#define reallocGmp oracle_reallocGmp
#define freeGmp oracle_freeGmp
#define resizeProgramMemory oracle_resizeProgramMemory

#define malloc z47_memory_runtime_alloc_gmp_bytes
#define realloc z47_memory_runtime_realloc_gmp_bytes
#define free z47_memory_runtime_free_gmp_bytes
#define xcopy z47_memory_runtime_copy_bytes

#include "../../../src/c47/memory.c"