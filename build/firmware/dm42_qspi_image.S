// SPDX-License-Identifier: GPL-3.0-only
//
// The stock DM42 QSPI image, first in the C47 DM42 QSPI, as c47.c's
// IMPORT_BIN(".qspi_dm42", DM42_QSPI_BIN, DM42_qspi) places it: the DM42
// program keeps finding its own QSPI data after a C47 QSPI is flashed.
// stm32_program.ld KEEPs .qspi_dm42 ahead of every other input of the .qspi
// output section. DM42_QSPI_BIN is the quoted image path, which
// build/firmware.zig passes only to C47 builds for the DM42 board.

  .section .qspi_dm42
  .balign 4
  .global DM42_qspi
DM42_qspi:
  .incbin DM42_QSPI_BIN
  .global _sizeof_DM42_qspi
  .set _sizeof_DM42_qspi, . - DM42_qspi
  .balign 4
