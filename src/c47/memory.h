// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file memory.h
 */
#if !defined(MEMORY_H)
  #define MEMORY_H

  // The 6 followoing functions are only there to know who allocates and frees memory
  void    *allocC47Blocks       (size_t sizeInBlocks);
  void    *reallocC47Blocks     (void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
  void    reduceC47Blocks       (void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks);
  void    freeC47Blocks         (void *pcMemPtr, size_t sizeInBlocks);

  void    *allocGmp             (size_t sizeInBytes);
  void    *reallocGmp           (void *pcMemPtr, size_t oldSizeInBytes, size_t newSizeInBytes);
  void    freeGmp               (void *pcMemPtr, size_t sizeInBytes);

  int32_t getFreeRamMemory      (void);
  void    resizeProgramMemory   (uint16_t newSizeInBlocks);
  bool_t  isMemoryBlockAvailable(size_t sizeInBlocks);

  #if !defined(DMCP_BUILD)
    void    debugMemory         (const char *message);
  #endif // !DMCP_BUILD

  #if defined(PC_BUILD)
    void ramDump(void);
  #endif // PC_BUILD

  // The following macros are for avoid crash in case that the memory is full. The corresponding label `cleanup_***` is needed AFTER freeing the memory.
  #define checkedAllocate2(var, size, label) do { var = allocC47Blocks(size); if(!var) {displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE); goto label; } } while(0)
  #define checkedAllocate(var, size) checkedAllocate2(var, size, cleanup_##var)
#endif // !MEMORY_H
