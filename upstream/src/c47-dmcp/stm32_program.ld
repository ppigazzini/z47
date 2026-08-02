/******************************************************************************************************
 *  File        : stm32_flash.ld
 *  Abstract    : Linker script for STM32L476ZG Device with 1024KByte FLASH, 96KByte RAM
 *                Set heap size, stack size and stack location according to application requirements.
 *                Set memory bank area and size if external memory is used.
 *  Target      : STMicroelectronics STM32
 *  Distribution: The file is distributed as is, without any warranty of any kind.
 *  Swissmicros - ld script for STM32 + QSPI
 *****************************************************************************************************/

/******************************************************************************************************
 * The memory map below has been compiled by Martin (aka Over_score) and therefore is NOT the absolute truth!
 *
 * FLASH   0x08000000 1024Kb       Code of functions is located here
 *         0x081FFFFF
 *
 * SRAM2   0x10000000   32Kb       Global variables
 *         0x10007FFF
 *
 * SRAM1   0x20000000   96Kb       Local variables and malloc allocations
 *         0x20017FFF
 *
 * QSPI    0x90000000 2048Kb
 *         0x901FFFFF
 *
 *****************************************************************************************************/

/* Specify the memory areas */
MEMORY {
  FLASH   (rx) : ORIGIN = 0x08050000, LENGTH =  704K
  SRAM2  (xrw) : ORIGIN = 0x10000000, LENGTH =   16K     /* Why not 32K? */
  SRAM1  (xrw) : ORIGIN = 0x20000000, LENGTH =   96K
  QSPI    (rx) : ORIGIN = 0x90000000, LENGTH = 2048K-12K /* a 4K block from 0x901FD000 to 0x901FDFFF is reserved by DMCP */
}

/* Entry Point */
ENTRY(Program_Entry)

/* Define output sections */
SECTIONS {
  .qspi : {
    . = ALIGN(8);
    _qspi_start = .;   /* create a global symbol at qspi start */
    KEEP(*(.qspi_dm42))      /* Added by Didier: dm42 qspi section at the beginning of the qspi memory */
    KEEP(*(.qspi_data))      /* .qspi  sections */
    KEEP(*(.rodata))         /* Added by Martin .rodata  sections (constants, strings, etc.) */
    KEEP(*(.rodata*str1.1))  /* Added by Martin .rodata  sections (constants, strings, etc.) */

    /* Cold read-only tables that -fdata-sections gives a .rodata.<symbol> name to, so they miss the
       exact-name pattern above and fall through to internal FLASH. Listed individually rather than
       globbed with *(.rodata*): a glob would also match .rodata.prog_info, and since ld assigns an
       input section to the first matching output section in script order, prog_info would land in
       QSPI. The .pgm is built by objcopy --remove-section .qspi, so it would ship without the magic
       at 0x08050000 and the loader would reject it.
       Deliberately NOT moved: the decNumber combination tables and __gmp_digit_value_tab /
       __gmpn_clz_tab / __gmp_binvert_limb_table. Those are random-access lookups in the innermost
       decimal and limb loops, the Cortex-M4 has no D-cache, and the STM32L476 ART accelerator caches
       internal-FLASH instruction fetch only, so a QSPI read there costs on every operation. */
    KEEP(*(.rodata.__gmpn_bases))         /* radix conversion, get_str/set_str display path only */
    KEEP(*(.rodata.default_state))        /* GMP Mersenne Twister seed, one call site */
    KEEP(*(.rodata.invsqrttab))
    KEEP(*(.rodata.vexp*))
    KEEP(*(.rodata.vlog*))
    KEEP(*(.rodata.__gmp_fib_table))
    KEEP(*(.rodata.__gmp_oddfac_table))
    /* mpn_fft_table is read-only because FFT_TABLE_ATTRS defaults to "static const"
       (gmp-impl.h:2349). A tune build redefines it to empty and makes the table writable
       (gmp-impl.h:5066, inside #if TUNE_PROGRAM_BUILD), which we do not build. */
    KEEP(*(.rodata.mpn_fft_table))
    KEEP(*(.rodata.angle_ids*))

    . = ALIGN(8);
    _qspi_end = .;     /* define a global symbols at end of qspi */
  } >QSPI /* AT> FLASH */

  /* Constant data goes into FLASH */
  .rodata : {
    KEEP(*(.rodata.prog_info)) /* Program info */
    . = ALIGN(64);
    *(.rodata)         /* .rodata  sections (constants, strings, etc.) */
    *(.rodata*)        /* .rodata* sections (constants, strings, etc.) */
    . = ALIGN(8);
  } >FLASH

  _qspi_init_base = LOADADDR(.qspi);
  _qspi_init_length = SIZEOF(.qspi);

  /* The program code and other data goes into FLASH */
  .text : {
    . = ALIGN(8);
    *(.text)           /* .text  sections (code) */
    *(.text*)          /* .text* sections (code) */
    *(.glue_7)         /* glue arm to thumb code */
    *(.glue_7t)        /* glue thumb to arm code */
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(8);
    _etext = .;        /* define a global symbols at end of code */
  } >FLASH

  .ARM.extab   : {
    . = ALIGN(8);
    *(.ARM.extab* .gnu.linkonce.armextab.*)
    . = ALIGN(8);
  } >FLASH

  .ARM : {
    . = ALIGN(8);
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
    . = ALIGN(8);
  } >FLASH

  .preinit_array     : {
    . = ALIGN(8);
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(8);
  } >FLASH

  .init_array : {
    . = ALIGN(8);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(8);
  } >FLASH

  .fini_array : {
    . = ALIGN(8);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(8);
  } >FLASH

  /* used by the startup to initialize data */
  _sidata = LOADADDR(.data);

  /* Initialized data sections goes into SRAM2, load LMA copy after code */
  .data : {
    . = ALIGN(8);
    _sdata = .;        /* create a global symbol at data start */
    *(.data.sdb)       /* SDB at the beginning of the RAM0 */
    *(.data)           /* .data  sections */
    *(.data*)          /* .data* sections */

    . = ALIGN(8);
    _edata = .;        /* define a global symbol at data end */
  } >SRAM2 AT> FLASH

  /* Uninitialized data section */
  . = ALIGN(4);
  .bss : {
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
    __bss_end__ = _ebss;
  } >SRAM2 AT> SRAM2

  /* Remove information from the standard libraries */
  /DISCARD/ : {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
    libgmp.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
}

/* The DMCP system data block sits at a fixed 0x10002000, inside SRAM2, so .bss growing past it corrupts firmware state
   with no diagnostic. Fail the link instead. */
ASSERT(_ebss <= 0x10002000, "Error: .bss reaches the DMCP system data block at 0x10002000. Reduce static data.")
