// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>

#include "c47.h"

uint16_t z47_memory_runtime_get_ram_size_in_blocks(void) {
  return RAM_SIZE_IN_BLOCKS;
}

freeMemoryRegion_t z47_memory_runtime_get_free_region(uint16_t index) {
  return freeMemoryRegions[index];
}

void z47_memory_runtime_set_free_region(uint16_t index, freeMemoryRegion_t region) {
  freeMemoryRegions[index] = region;
}

uint16_t z47_memory_runtime_to_c47_mem_ptr(uint8_t *memPtr) {
  return TO_C47MEMPTR(memPtr);
}

void *z47_memory_runtime_copy_bytes(void *dest, const void *source, uint32_t n) {
  if(n == 0) {
    return dest;
  }

  return xcopy(dest, source, n);
}

void z47_memory_runtime_handle_resize_program_memory_out_of_memory(uint16_t deltaBlocks) {
  #if defined(DMCP_BUILD)
    (void)deltaBlocks;
    backToSystem(NOPARAM);
  #else
    int32_t freeMemory = 0;

    for(int32_t i = 0; i < numberOfFreeMemoryRegions; i++) {
      freeMemory += freeMemoryRegions[i].sizeInBlocks;
    }

    printf("\nOUT OF MEMORY\nMemory claimed: %" PRIu64 " bytes\nFragmented free memory: %" PRIu64 " bytes\n",
           (uint64_t)TO_BYTES(deltaBlocks),
           (uint64_t)TO_BYTES(freeMemory));
    exit(-3);
  #endif
}

void *z47_memory_runtime_alloc_gmp_bytes(size_t sizeInBytes) {
  return malloc(sizeInBytes);
}

void *z47_memory_runtime_realloc_gmp_bytes(void *pcMemPtr, size_t newSizeInBytes) {
  return realloc(pcMemPtr, newSizeInBytes);
}

void z47_memory_runtime_free_gmp_bytes(void *pcMemPtr) {
  free(pcMemPtr);
}

#if !defined(DMCP_BUILD)
void debugMemory(const char *message) {
  printf("\n%s\nC47 owns %6" PRIu64 " bytes and GMP owns %6" PRIu64 " bytes (%" PRId32 " bytes free)\n",
         message,
         (uint64_t)TO_BYTES(c47MemInBlocks),
         (uint64_t)gmpMemInBytes,
         getFreeRamMemory());
  printf("    Addr   Size\n");
  for(int32_t i = 0; i < numberOfFreeMemoryRegions; i++) {
    printf("%2" PRId32 "%6u%7u\n", i, freeMemoryRegions[i].blockAddress, freeMemoryRegions[i].sizeInBlocks);
  }
  printf("\n");
}
#endif