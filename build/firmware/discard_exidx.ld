/* z47-owned supplementary linker fragment, applied before the upstream
 * stm32_program.ld via an additional -T.
 *
 * The Zig-generated frontier object always emits an .ARM.exidx (exception
 * index) section, even with unwind_tables = .none, because the ARM EABI gives
 * every function at least a CANTUNWIND entry. The upstream C is compiled with
 * -fno-unwind-tables and has none. This is harmless while all code lives in
 * FLASH, but once rarely-used owner code is placed in the executable QSPI region
 * (0x90000000) to free the 704 KB main FLASH, the exidx CANTUNWIND entries hold
 * R_ARM_PREL31 relocations to that code that overflow the +-1 GB PREL31 range.
 *
 * Freestanding DMCP firmware never unwinds (no C++ exceptions, no backtrace
 * unwinder), so the exception index is dead weight. Discarding it both fixes the
 * QSPI relocation overflow and reclaims the exidx bytes from FLASH. The upstream
 * script's __exidx_start/__exidx_end then bracket an empty range, which is the
 * correct "no unwind data" state.
 */
SECTIONS {
  /DISCARD/ : {
    *(.ARM.exidx*)
    *(.ARM.extab*)
    *(.gnu.linkonce.armexidx.*)
    *(.gnu.linkonce.armextab.*)
  }
}
