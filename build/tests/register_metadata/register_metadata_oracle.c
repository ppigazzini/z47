// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the register-metadata lane: c43's OWN registers.c,
// compiled a second time into the full-core harness under `oracle_` names so it
// links beside the Zig owner that replaced it.
//
// WHAT THIS REPLACED (REPORT-31 M31-12). 1060 lines and 43 `oracle_*` functions
// hand-transliterating 42% of registers.c -- a fork, not an oracle. It could not
// see c43 move, and it had drifted: it carried the pre-SPARE reserved-variable
// model (an "ADM" entry at table index 26 where c43 has a placeholder), which is
// the divergence M31-11 had to land before this conversion could be honest.
//
// WHY A FULL-CORE DIFFERENTIAL AND NOT A LINKED UNIT ORACLE. M31-12 planned the
// unit shape on the strength of "registers.c compiles clean against upstream's
// own c47.h, 87 stubs". It does -- but the existing unit harness is not built on
// upstream's c47.h, it is built on a MOCK one whose `registerHeader_t` is a
// packed descriptor word rather than c43's bitfield struct. Compiling registers.c
// against that mock produces 424 errors, and the fix is not a few stubs: it is
// rebuilding the harness world (1649 lines of fake runtime, shared with the
// stack-state lane) on upstream's types.
//
// The deeper reason is the one that redirected M31-10. registers.c IS the
// register subsystem, so "share the state with the Zig owner" means sharing
// globalRegister, allNamedVariables, the RAM slab and the free list -- which is
// the whole calculator. In a full core all of that is shared by construction and
// the stub burden is ZERO. `charstring_diff` is the in-tree precedent for the
// shape; `calc_state_parity` is the one this follows directly.
//
// WHAT IT BUYS THAT NOTHING ELSE DID: c43's real 48-entry `allReservedVariables`
// table is now in the binary beside the Zig owner's, and the lane compares them
// entry by entry. That check is what would have caught the reserved-variable
// divergence in the first place, and the tree has never had it.
//
// Nothing here may be edited to make the lane pass.

// Every symbol registers.c gives external linkage. Derived mechanically:
//   nm -g --defined-only <registers.o> | awk '{print $3}'
// Re-derive it that way after a resync; registers.h does not list all of them.
#define allReservedVariables oracle_allReservedVariables
#define varDescr oracle_varDescr

#define getRegisterDataType oracle_getRegisterDataType
#define getRegisterDataPointer oracle_getRegisterDataPointer
#define getRegisterTag oracle_getRegisterTag
#define getRegisterMaxDataLengthInBlocks oracle_getRegisterMaxDataLengthInBlocks
#define getRegisterFullSizeInBlocks oracle_getRegisterFullSizeInBlocks
#define setRegisterDataType oracle_setRegisterDataType
#define setRegisterDataPointer oracle_setRegisterDataPointer
#define setRegisterTag oracle_setRegisterTag
#define setRegisterMaxDataLengthInBlocks oracle_setRegisterMaxDataLengthInBlocks

#define reallocateRegister oracle_reallocateRegister
#define clearRegister oracle_clearRegister
#define copySourceRegisterToDestRegister oracle_copySourceRegisterToDestRegister
#define allocateLocalRegisters oracle_allocateLocalRegisters
#define allocateNamedVariable oracle_allocateNamedVariable
#define allocateNamedVariableOnMiss oracle_allocateNamedVariableOnMiss
#define findNamedVariable oracle_findNamedVariable
#define findOrAllocateNamedVariable oracle_findOrAllocateNamedVariable
#define invalidateNamedVariableCache oracle_invalidateNamedVariableCache
#define namedVariableIsStats oracle_namedVariableIsStats
#define validateName oracle_validateName
#define isUniqueMenuName oracle_isUniqueMenuName
#define isFunctionAllowingNewVariable oracle_isFunctionAllowingNewVariable
#define indirectAddressing oracle_indirectAddressing
#define getRegParam oracle_getRegParam
#define clampShortIntegerRegistersToWordSize oracle_clampShortIntegerRegistersToWordSize
#define adjustResult oracle_adjustResult
#define saveLastX oracle_saveLastX

#define fnClearRegisters oracle_fnClearRegisters
#define fnClearAllVariables oracle_fnClearAllVariables
#define fnDeleteAllVariables oracle_fnDeleteAllVariables
#define fnDeleteVariable oracle_fnDeleteVariable
#define fnGetLocR oracle_fnGetLocR
#define fnRegClr oracle_fnRegClr
#define fnRegCopy oracle_fnRegCopy
#define fnRegSort oracle_fnRegSort
#define fnRegSwap oracle_fnRegSwap
#define fnToReal oracle_fnToReal

#define printC47ShortStringToConsole oracle_printC47ShortStringToConsole
#define printComplex34ToConsole oracle_printComplex34ToConsole
#define printLongIntegerToConsole oracle_printLongIntegerToConsole
#define printReal34ToConsole oracle_printReal34ToConsole
#define printRealInfoToConsole oracle_printRealInfoToConsole
#define printRealToConsole oracle_printRealToConsole
#define printRegisterDescriptorToConsole oracle_printRegisterDescriptorToConsole
#define printRegisterToConsole oracle_printRegisterToConsole
#define printStringToConsole oracle_printStringToConsole

#include "../../../upstream/src/c47/registers.c"
