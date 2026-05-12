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

#include "../../../src/c47/stack.c"
