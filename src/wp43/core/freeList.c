/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "core/freeList.h"

#include <stdint.h>
#include <stdlib.h>
#include "charString.h"
#include "config.h"
#include "debug.h"
#include "items.h"

#include "wp43.h"

void *freeListAlloc(size_t sizeInBlocks) {
  uint16_t minSizeInBlocks = 65535u, minBlock = C47_NULL;
  int i;
  void *pcMemPtr;

  if(sizeInBlocks == 0) {
    sizeInBlocks = 1;
  }

  #if !defined(DMCP_BUILD)
    //if(debugMemAllocation) {
    //  printf("Allocating %" PRIu64 " bytes (%" PRIu16 " blocks)\n", (uint64_t)TO_BYTES(sizeInBlocks), sizeInBlocks);
    //}
  #endif // !DMCP_BUILD

  // Search the smalest hole where the claimed block fits
  //debugMemory();
  for(i=0; i<numberOfFreeMemoryRegions; i++) {
    if(freeMemoryRegions[i].sizeInBlocks == sizeInBlocks) {
      #if !defined(DMCP_BUILD)
        //if(debugMemAllocation) {
        //  printf("The block found is the size of the one claimed at address %u\n", freeMemoryRegions[i].blockAddress);
        //}
      #endif // !DMCP_BUILD
      pcMemPtr = TO_PCMEMPTR(freeMemoryRegions[i].blockAddress);
      xcopy(freeMemoryRegions + i, freeMemoryRegions + i + 1, (numberOfFreeMemoryRegions - i - 1) * sizeof(freeMemoryRegion_t));
      numberOfFreeMemoryRegions--;
      //debugMemory("freeListAlloc: found a memory region with the exact requested size!");
      return pcMemPtr;
    }
    else if(freeMemoryRegions[i].sizeInBlocks > sizeInBlocks && freeMemoryRegions[i].sizeInBlocks < minSizeInBlocks) {
      minSizeInBlocks = freeMemoryRegions[i].sizeInBlocks;
      minBlock = i;
    }
  }

  if(minBlock == C47_NULL) {
    #if defined(DMCP_BUILD)
      //backToSystem(NOPARAM);
    #else // !DMCP_BUILD
      minSizeInBlocks = 0;
      for(i=0; i<numberOfFreeMemoryRegions; i++) {
        minSizeInBlocks += freeMemoryRegions[i].sizeInBlocks;
      }
      printf("\nOUT OF MEMORY\nMemory claimed: %" PRIu64 " bytes\nFragmented free memory: %u bytes\n", (uint64_t)TO_BYTES(sizeInBlocks), TO_BYTES(minSizeInBlocks));
      //exit(-3);
    #endif // DMCP_BUILD
    return NULL;
  }

  #if !defined(DMCP_BUILD)
    //if(debugMemAllocation) {
    //  printf("The block found is larger than the one claimed\n");
    //}
  #endif // !DMCP_BUILD
  pcMemPtr = TO_PCMEMPTR(freeMemoryRegions[minBlock].blockAddress);
  freeMemoryRegions[minBlock].blockAddress += sizeInBlocks;
  freeMemoryRegions[minBlock].sizeInBlocks -= sizeInBlocks;

  //debugMemory("freeListAlloc: allocated within the smalest memory region found that is large enough.");
  return pcMemPtr;
}

void *freeListRealloc(void *pcMemPtr, size_t oldSizeInBlocks, size_t newSizeInBlocks) {
  void *newMemPtr;

  // GMP never calls realloc with pcMemPtr beeing NULL
  if(oldSizeInBlocks == 0) {
    oldSizeInBlocks = 1;
  }

  if(newSizeInBlocks == 0) {
    newSizeInBlocks = 1;
  }

  #if !defined(DMCP_BUILD)
    //printf("Allocating %zd bytes and freeing %zd blocks\n", newSizeInBlocks, oldSizeInBlocks);
  #endif // !DMCP_BUILD

  if((newMemPtr = freeListAlloc(newSizeInBlocks))) {
    xcopy(newMemPtr, pcMemPtr, TO_BYTES(min(newSizeInBlocks, oldSizeInBlocks)));
    freeListFree(pcMemPtr, oldSizeInBlocks);

    return newMemPtr;
  }
  else { // not enough memory!
    return NULL;
  }
}

void freeListFree(void *pcMemPtr, size_t sizeInBlocks) {
  uint16_t ramPtr, addr;
  int32_t i, j;
  bool_t done;

  // GMP never calls free with pcMemPtr beeing NULL
  if(pcMemPtr == NULL) {
    return;
  }

  if(sizeInBlocks == 0) {
    sizeInBlocks = 1;
  }
  ramPtr = TO_C47MEMPTR(pcMemPtr);
  #if !defined(DMCP_BUILD)
    //printf("Freeing %zd bytes\n", TO_BYTES(sizeInBlocks));
  #endif // !DMCP_BUILD

  done = false;

  // is the freed block just before an other free block?
  addr = ramPtr + sizeInBlocks;
  for(i=0; i<numberOfFreeMemoryRegions && freeMemoryRegions[i].blockAddress<=addr; i++) {
    if(freeMemoryRegions[i].blockAddress == addr) {
      freeMemoryRegions[i].blockAddress = ramPtr;
      freeMemoryRegions[i].sizeInBlocks += sizeInBlocks;
      sizeInBlocks = freeMemoryRegions[i].sizeInBlocks;
      j = i;
      done = true;
      break;
    }
  }

  // is the freed block just after an other free block?
  for(i=0; i<numberOfFreeMemoryRegions && freeMemoryRegions[i].blockAddress+freeMemoryRegions[i].sizeInBlocks<=ramPtr; i++) {
    if(freeMemoryRegions[i].blockAddress + freeMemoryRegions[i].sizeInBlocks == ramPtr) {
      freeMemoryRegions[i].sizeInBlocks += sizeInBlocks;
      if(done) {
        xcopy(freeMemoryRegions + j, freeMemoryRegions + j + 1, (numberOfFreeMemoryRegions - j - 1) * sizeof(freeMemoryRegion_t));
        numberOfFreeMemoryRegions--;
      }
      else {
        done = true;
      }
      break;
    }
  }

  #if defined(PC_BUILD)
    // check for overlap
    for(i=1; i<numberOfFreeMemoryRegions; i++) {
      if((freeMemoryRegions[i-1].blockAddress + freeMemoryRegions[i-1].sizeInBlocks) >= freeMemoryRegions[i].blockAddress) {
        printf("\n*** Free memory regions overlap!\n");
        printf("*** This suggests there was double-free!\n");
        printf("Free blocks (%" PRId32 "):\n", numberOfFreeMemoryRegions);
        for(j=0; j<numberOfFreeMemoryRegions; j++) {
          printf("  %2" PRId32 " starting at %5" PRIu16 ": %5" PRIu16 " blocks = %6" PRIu32 " bytes\n", j, freeMemoryRegions[j].blockAddress, freeMemoryRegions[j].sizeInBlocks, TO_BYTES((uint32_t)freeMemoryRegions[j].sizeInBlocks));
        }
        break;
      }
    }
  #endif // PC_BUILD

  // new free block
  if(!done) {
    if(numberOfFreeMemoryRegions == MAX_FREE_REGION) {
      #if defined(DMCP_BUILD)
        backToSystem(NOPARAM);
      #else // !DMCP_BUILD
        printf("\n**********************************************************************\n");
        printf("* The maximum number of free memory blocks has been exceeded!        *\n");
        printf("* This number must be increased or the compaction function improved. *\n");
        printf("**********************************************************************\n");
        exit(-2);
      #endif // DMCP_BUILD
    }

    i = 0;
    while(i<numberOfFreeMemoryRegions && freeMemoryRegions[i].blockAddress < ramPtr) {
      i++;
    }

    if(i < numberOfFreeMemoryRegions) {
      xcopy(freeMemoryRegions + i + 1, freeMemoryRegions + i, (numberOfFreeMemoryRegions - i) * sizeof(freeMemoryRegion_t));
    }

    freeMemoryRegions[i].blockAddress = ramPtr;
    freeMemoryRegions[i].sizeInBlocks = sizeInBlocks;
    numberOfFreeMemoryRegions++;
  }

  //debugMemory("freeListFree : end");
}
