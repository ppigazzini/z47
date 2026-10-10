// SPDX-License-Identifier: GPL-3.0-only

#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "memory_test_runtime.h"

static int reportScalarMismatch(const char *name,
                                uint32_t argument,
                                uint64_t expected_result,
                                uint64_t actual_result,
                                const memory_parity_snapshot_t *expected_snapshot,
                                const memory_parity_snapshot_t *actual_snapshot) {
  int failures = 0;

  if(expected_result != actual_result) {
    fprintf(stderr, "%s(%#x) result mismatch: expected %" PRIu64 " actual %" PRIu64 "\n", name, argument, expected_result, actual_result);
    failures++;
  }

  if(memcmp(expected_snapshot, actual_snapshot, sizeof(*expected_snapshot)) != 0) {
    fprintf(stderr, "%s(%#x) state mismatch\n", name, argument);
    failures++;
  }

  return failures;
}

static int reportPointerMismatch(const char *name,
                                 uint32_t argument,
                                 bool_t expected_non_null,
                                 bool_t actual_non_null,
                                 const memory_parity_snapshot_t *expected_snapshot,
                                 const memory_parity_snapshot_t *actual_snapshot) {
  return reportScalarMismatch(name, argument, expected_non_null, actual_non_null, expected_snapshot, actual_snapshot);
}

static int runGetFreeCase(const freeMemoryRegion_t *regions, int32_t count) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  uint32_t expected_result;
  uint32_t actual_result;

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  expected_result = oracle_getFreeRamMemory();
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  actual_result = getFreeRamMemory();
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("getFreeRamMemory", (uint32_t)count, expected_result, actual_result, &expected_snapshot, &actual_snapshot);
}

static int runAvailabilityCase(uint32_t case_id,
                               const freeMemoryRegion_t *regions,
                               int32_t count,
                               size_t size_in_blocks,
                               uint16_t num_blocks,
                               float extra_fraction) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  bool_t expected_result;
  bool_t actual_result;

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  expected_result = oracle_isMemoryBlockAvailable(size_in_blocks, num_blocks, extra_fraction);
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  actual_result = isMemoryBlockAvailable(size_in_blocks, num_blocks, extra_fraction);
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("isMemoryBlockAvailable", case_id, expected_result, actual_result, &expected_snapshot, &actual_snapshot);
}

static int runAllocC47Case(size_t starting_c47_blocks,
                           size_t size_in_blocks,
                           bool_t should_fail) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  bool_t expected_non_null;
  bool_t actual_non_null;

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  memoryParitySetFailureModes(should_fail, false, false, false);
  expected_non_null = oracle_allocC47Blocks(size_in_blocks) != NULL;
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  memoryParitySetFailureModes(should_fail, false, false, false);
  actual_non_null = allocC47Blocks(size_in_blocks) != NULL;
  memoryParityCapture(&actual_snapshot);

  return reportPointerMismatch("allocC47Blocks", (uint32_t)size_in_blocks, expected_non_null, actual_non_null, &expected_snapshot, &actual_snapshot);
}

static int runReallocC47Case(size_t starting_c47_blocks,
                             size_t old_size_in_blocks,
                             size_t new_size_in_blocks,
                             bool_t should_fail) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  bool_t expected_non_null;
  bool_t actual_non_null;
  void *expected_ptr;
  void *actual_ptr;

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  memoryParitySetFailureModes(false, should_fail, false, false);
  expected_ptr = memoryParityMakeC47Allocation(old_size_in_blocks);
  expected_non_null = oracle_reallocC47Blocks(expected_ptr, old_size_in_blocks, new_size_in_blocks) != NULL;
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  memoryParitySetFailureModes(false, should_fail, false, false);
  actual_ptr = memoryParityMakeC47Allocation(old_size_in_blocks);
  actual_non_null = reallocC47Blocks(actual_ptr, old_size_in_blocks, new_size_in_blocks) != NULL;
  memoryParityCapture(&actual_snapshot);

  return reportPointerMismatch("reallocC47Blocks", (uint32_t)new_size_in_blocks, expected_non_null, actual_non_null, &expected_snapshot, &actual_snapshot);
}

static int runReduceC47Case(size_t starting_c47_blocks,
                            size_t old_size_in_blocks,
                            size_t new_size_in_blocks) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  void *expected_ptr;
  void *actual_ptr;

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  expected_ptr = memoryParityMakeC47Allocation(old_size_in_blocks);
  oracle_reduceC47Blocks(expected_ptr, old_size_in_blocks, new_size_in_blocks);
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  actual_ptr = memoryParityMakeC47Allocation(old_size_in_blocks);
  reduceC47Blocks(actual_ptr, old_size_in_blocks, new_size_in_blocks);
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("reduceC47Blocks", (uint32_t)new_size_in_blocks, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runFreeC47Case(size_t starting_c47_blocks,
                          size_t size_in_blocks,
                          bool_t use_null_pointer) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  void *expected_ptr = NULL;
  void *actual_ptr = NULL;

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  if(!use_null_pointer) {
    expected_ptr = memoryParityMakeC47Allocation(size_in_blocks);
  }
  oracle_freeC47Blocks(expected_ptr, size_in_blocks);
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(starting_c47_blocks, 0);
  if(!use_null_pointer) {
    actual_ptr = memoryParityMakeC47Allocation(size_in_blocks);
  }
  freeC47Blocks(actual_ptr, size_in_blocks);
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("freeC47Blocks", (uint32_t)size_in_blocks, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runAllocGmpCase(size_t starting_gmp_bytes,
                           size_t size_in_bytes,
                           bool_t should_fail) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  bool_t expected_non_null;
  bool_t actual_non_null;

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  memoryParitySetFailureModes(false, false, should_fail, false);
  expected_non_null = oracle_allocGmp(size_in_bytes) != NULL;
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  memoryParitySetFailureModes(false, false, should_fail, false);
  actual_non_null = allocGmp(size_in_bytes) != NULL;
  memoryParityCapture(&actual_snapshot);

  return reportPointerMismatch("allocGmp", (uint32_t)size_in_bytes, expected_non_null, actual_non_null, &expected_snapshot, &actual_snapshot);
}

static int runReallocGmpCase(size_t starting_gmp_bytes,
                             size_t old_size_in_bytes,
                             size_t new_size_in_bytes,
                             bool_t should_fail) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  bool_t expected_non_null;
  bool_t actual_non_null;
  void *expected_ptr;
  void *actual_ptr;

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  memoryParitySetFailureModes(false, false, false, should_fail);
  expected_ptr = memoryParityMakeGmpAllocation(TO_BYTES(TO_BLOCKS(old_size_in_bytes)));
  expected_non_null = oracle_reallocGmp(expected_ptr, old_size_in_bytes, new_size_in_bytes) != NULL;
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  memoryParitySetFailureModes(false, false, false, should_fail);
  actual_ptr = memoryParityMakeGmpAllocation(TO_BYTES(TO_BLOCKS(old_size_in_bytes)));
  actual_non_null = reallocGmp(actual_ptr, old_size_in_bytes, new_size_in_bytes) != NULL;
  memoryParityCapture(&actual_snapshot);

  return reportPointerMismatch("reallocGmp", (uint32_t)new_size_in_bytes, expected_non_null, actual_non_null, &expected_snapshot, &actual_snapshot);
}

// GMP takes no NULL from its allocator: memory.c paints the bug screen and ends
// the process, exit(255) on the host. A stop cannot be compared in-process, so
// each side runs the failing call in a child of its own, and the two children
// are compared by how they ended and by the message they painted.
typedef struct {
  bool_t exited;
  int code;
  char message[64];
} gmp_stop_t;

// A child that neither stops nor returns within this many seconds is killed by
// SIGALRM, which reads as not having exited.
#define GMP_STOP_BUDGET_SECONDS 10

static gmp_stop_t runGmpStop(bool_t realloc_case, bool_t use_oracle) {
  gmp_stop_t stop;
  int fds[2];
  int status = 0;
  ssize_t length;
  pid_t pid;

  memset(&stop, 0, sizeof(stop));
  if(pipe(fds) != 0) {
    return stop;
  }

  fflush(stdout);
  fflush(stderr);
  pid = fork();
  if(pid == 0) {
    void *ptr;

    close(fds[0]);
    alarm(GMP_STOP_BUDGET_SECONDS);
    memoryParityReset();
    memoryParitySetBugScreenFd(fds[1]);
    if(realloc_case) {
      memoryParitySetCounters(0, 8);
      memoryParitySetFailureModes(false, false, false, true);
      ptr = memoryParityMakeGmpAllocation(TO_BYTES(TO_BLOCKS(5)));
      ptr = use_oracle ? oracle_reallocGmp(ptr, 5, 9) : reallocGmp(ptr, 5, 9);
    }
    else {
      memoryParitySetCounters(0, 4);
      memoryParitySetFailureModes(false, false, true, false);
      ptr = use_oracle ? oracle_allocGmp(5) : allocGmp(5);
    }
    (void)ptr;
    _exit(0); // reached only when the failing call returned instead of stopping
  }

  close(fds[1]);
  if(pid < 0) {
    close(fds[0]);
    return stop;
  }
  length = read(fds[0], stop.message, sizeof(stop.message) - 1);
  if(length < 0) {
    length = 0;
  }
  stop.message[length] = 0;
  close(fds[0]);
  if(waitpid(pid, &status, 0) == pid && WIFEXITED(status)) {
    stop.exited = true;
    stop.code = WEXITSTATUS(status);
  }
  return stop;
}

static int runGmpStopCase(const char *name, bool_t realloc_case) {
  const gmp_stop_t expected = runGmpStop(realloc_case, true);
  const gmp_stop_t actual = runGmpStop(realloc_case, false);
  int failures = 0;

  if(!expected.exited || expected.code != 255 || expected.message[0] == 0) {
    fprintf(stderr, "%s: c43 did not stop with the bug screen and exit(255) (exited %d, code %d)\n", name, expected.exited, expected.code);
    failures++;
  }
  if(expected.exited != actual.exited || expected.code != actual.code) {
    fprintf(stderr, "%s stop mismatch: expected exited %d code %d, actual exited %d code %d\n", name, expected.exited, expected.code, actual.exited, actual.code);
    failures++;
  }
  if(strcmp(expected.message, actual.message) != 0) {
    fprintf(stderr, "%s bug screen mismatch: expected \"%s\" actual \"%s\"\n", name, expected.message, actual.message);
    failures++;
  }
  return failures;
}

static int runFreeGmpCase(size_t starting_gmp_bytes,
                          size_t size_in_bytes,
                          bool_t use_null_pointer) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;
  void *expected_ptr = NULL;
  void *actual_ptr = NULL;

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  if(!use_null_pointer) {
    expected_ptr = memoryParityMakeGmpAllocation(TO_BYTES(TO_BLOCKS(size_in_bytes)));
  }
  oracle_freeGmp(expected_ptr, size_in_bytes);
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySetCounters(0, starting_gmp_bytes);
  if(!use_null_pointer) {
    actual_ptr = memoryParityMakeGmpAllocation(TO_BYTES(TO_BLOCKS(size_in_bytes)));
  }
  freeGmp(actual_ptr, size_in_bytes);
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("freeGmp", (uint32_t)size_in_bytes, 0, 0, &expected_snapshot, &actual_snapshot);
}

static int runResizeProgramCase(uint32_t case_id,
                                const freeMemoryRegion_t *regions,
                                int32_t count,
                                uint16_t begin_block,
                                uint32_t first_free_offset_bytes,
                                const uint8_t *program_bytes,
                                uint32_t program_byte_count,
                                uint16_t new_size_in_blocks) {
  memory_parity_snapshot_t expected_snapshot;
  memory_parity_snapshot_t actual_snapshot;

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  memoryParitySeedProgramState(begin_block, first_free_offset_bytes, program_bytes, program_byte_count);
  oracle_resizeProgramMemory(new_size_in_blocks);
  memoryParityCapture(&expected_snapshot);

  memoryParityReset();
  memoryParitySeedRegions(regions, count);
  memoryParitySeedProgramState(begin_block, first_free_offset_bytes, program_bytes, program_byte_count);
  resizeProgramMemory(new_size_in_blocks);
  memoryParityCapture(&actual_snapshot);

  return reportScalarMismatch("resizeProgramMemory", case_id, 0, 0, &expected_snapshot, &actual_snapshot);
}

int main(void) {
  int failures = 0;
  static const freeMemoryRegion_t free_regions_case1[] = {
    { .blockAddress = 4, .sizeInBlocks = 3 },
    { .blockAddress = 12, .sizeInBlocks = 5 },
  };
  static const freeMemoryRegion_t free_regions_case2[] = {
    { .blockAddress = 10, .sizeInBlocks = 8 },
  };
  static const freeMemoryRegion_t free_regions_case3[] = {
    { .blockAddress = 4, .sizeInBlocks = 3 },
    { .blockAddress = 10, .sizeInBlocks = 3 },
    { .blockAddress = 20, .sizeInBlocks = 2 },
  };
  static const freeMemoryRegion_t resize_increase_regions[] = {
    { .blockAddress = 0, .sizeInBlocks = 8 },
    { .blockAddress = 48, .sizeInBlocks = 6 },
  };
  static const freeMemoryRegion_t resize_decrease_regions[] = {
    { .blockAddress = 0, .sizeInBlocks = 8 },
    { .blockAddress = 50, .sizeInBlocks = 4 },
  };
  static const uint8_t increase_program_bytes[] = {
    0x01, 0x02, 0x03, 0x04,
    0x05, 0x06, 0x07, 0x08,
    0x09, 0x0a, 0x0b, 0x0c,
    0x0d, 0x0e, 0x0f, 0x10,
  };
  static const uint8_t decrease_program_bytes[] = {
    0x21, 0x22, 0x23, 0x24,
    0x25, 0x26, 0x27, 0x28,
    0x29, 0x2a, 0x2b, 0x2c,
    0x2d, 0x2e, 0x2f, 0x30,
    0x31, 0x32, 0x33, 0x34,
    0x35, 0x36, 0x37, 0x38,
  };

  failures += runGetFreeCase(free_regions_case1, 2);
  failures += runAvailabilityCase(1, free_regions_case2, 1, 3, 2, 0.0f);
  failures += runAvailabilityCase(2, free_regions_case3, 3, 2, 3, 0.5f);
  failures += runAvailabilityCase(3, free_regions_case3, 3, 4, 2, 0.25f);

  failures += runAllocC47Case(7, 3, false);
  failures += runAllocC47Case(7, 3, true);
  failures += runReallocC47Case(9, 2, 5, false);
  failures += runReallocC47Case(9, 2, 5, true);
  failures += runReduceC47Case(11, 5, 2);
  failures += runReduceC47Case(11, 5, 0);
  failures += runFreeC47Case(9, 4, false);
  failures += runFreeC47Case(9, 4, true);

  failures += runAllocGmpCase(4, 5, false);
  failures += runGmpStopCase("allocGmp", false);
  failures += runReallocGmpCase(8, 5, 9, false);
  failures += runGmpStopCase("reallocGmp", true);
  failures += runFreeGmpCase(12, 9, false);
  failures += runFreeGmpCase(12, 9, true);

  failures += runResizeProgramCase(1, resize_increase_regions, 2, 60, 6, increase_program_bytes, sizeof(increase_program_bytes), 6);
  failures += runResizeProgramCase(2, resize_decrease_regions, 2, 58, 10, decrease_program_bytes, sizeof(decrease_program_bytes), 3);

  if(failures != 0) {
    fprintf(stderr, "%d memory parity checks failed\n", failures);
    return 1;
  }

  puts("memory parity checks passed");
  return 0;
}
