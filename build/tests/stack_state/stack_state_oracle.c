// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void oracle_undo(void);

#define fnClX oracle_fnClX
#define fnClearStack oracle_fnClearStack
#define liftStack oracle_liftStack
#define _Drop oracle__Drop
#define fnDrop oracle_fnDrop
#define fnDropY oracle_fnDropY
#define fnDropZ oracle_fnDropZ
#define fnDropT oracle_fnDropT
#define fnDropN oracle_fnDropN
#define fnRollUp oracle_fnRollUp
#define fnRollDown oracle_fnRollDown
#define fnDisplayStack oracle_fnDisplayStack
#define fnSwapX oracle_fnSwapX
#define fnSwapY oracle_fnSwapY
#define fnSwapZ oracle_fnSwapZ
#define fnSwapT oracle_fnSwapT
#define fnSwapN oracle_fnSwapN
#define fnDupN oracle_fnDupN
#define fnSwapXY oracle_fnSwapXY
#define fnShuffle oracle_fnShuffle
#define fnFillStack oracle_fnFillStack
#define fnGetStackSize oracle_fnGetStackSize
#define saveForUndo oracle_saveForUndo
#define fnUndo oracle_fnUndo
#define undo oracle_undo
#define fillStackWithReal0 oracle_fillStackWithReal0

// `clearRegister` is deliberately NOT renamed (REPORT-31 M31-20). It is a
// registers.c function, not a stack.c one, so in this lane it is ENVIRONMENT --
// shared by both implementations, exactly as the report's rule says a stub should
// be. It used to be renamed onto a 60-line hand-written body here, which made it a
// second reference nobody had checked; the ten registers.c functions that body
// covered are compared against c43's own registers.c in register_metadata_parity
// now.

#include "../../../upstream/src/c47/stack.c"

uint8_t z47_registers_get_reg_clr_range(uint16_t *s, uint16_t *n);
uint8_t z47_registers_get_reg_swap_range(uint16_t *s, uint16_t *n, uint16_t *d);
uint8_t z47_registers_get_reg_copy_params(bool_t *f, uint16_t *s, uint16_t *n, uint16_t *d);
void z47_registers_fnRegCopy(uint16_t unusedButMandatoryParameter);
void z47_registers_fnToReal(uint16_t unusedButMandatoryParameter);
bool_t z47_registers_adjust_result_no_drop_y(calcRegister_t res, bool_t setCpxRes, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3);
bool_t z47_registers_adjust_result_no_drop_y_no_cpxres(calcRegister_t res, calcRegister_t op1, calcRegister_t op2, calcRegister_t op3);
void z47_registers_sort_reg(uint16_t range_start, uint16_t range_end);

