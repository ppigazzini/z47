// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the matrix-editor lane: c43's OWN ui/matrixEditor.c,
// compiled a second time into the full-core harness under `oracle_` names so it
// links beside the Zig owners that replaced it (src/shell/matrix_editor/).
//
// FUNCTIONS ARE RENAMED, DATA IS SHARED. Every function the file gives external
// linkage becomes `oracle_<name>`, so the two implementations can be called side
// by side. The file's seven variables are not renamed: shared code on both sides
// writes them -- getMatrixFromRegister fills openMatrixMIMPointer and
// fnIndexMatrix sets matrixIndex -- so a private oracle copy would hold stale
// state the moment the oracle called into the shared core. They are declared
// weak here instead, and the owner's strong definitions are the ones linked. The
// harness re-seeds them before each side runs, which is what keeps one side's
// state out of the other's.
//
// Derived mechanically:
//   nm -g --defined-only <matrix_editor_oracle.o> | awk '$2=="T"{print $3}'
// and the variables from the same listing's D and B rows. Re-derive it that way
// after a resync rather than reading the header; a missed function is a
// duplicate-symbol link error.
//
// Nothing here may be edited to make the lane pass.

#define _fnInsCol oracle__fnInsCol
#define _fnInsRow oracle__fnInsRow
#define fnAddCol oracle_fnAddCol
#define fnAddRow oracle_fnAddRow
#define fnDelCol oracle_fnDelCol
#define fnDelRow oracle_fnDelRow
#define fnEditMatrix oracle_fnEditMatrix
#define fnGoToColumn oracle_fnGoToColumn
#define fnGoToElement oracle_fnGoToElement
#define fnGoToRow oracle_fnGoToRow
#define fnIncDecI oracle_fnIncDecI
#define fnIncDecJ oracle_fnIncDecJ
#define fnInsCol oracle_fnInsCol
#define fnInsRow oracle_fnInsRow
#define fnOldMatrix oracle_fnOldMatrix
#define fnSetGrowMode oracle_fnSetGrowMode
#define getComplexMatrixColumnWidths oracle_getComplexMatrixColumnWidths
#define getIRegisterAsInt oracle_getIRegisterAsInt
#define getJRegisterAsInt oracle_getJRegisterAsInt
#define getRealMatrixColumnWidths oracle_getRealMatrixColumnWidths
#define getRealMatrixIntegerColumns oracle_getRealMatrixIntegerColumns
#define mimAddNumber oracle_mimAddNumber
#define mimEnter oracle_mimEnter
#define mimFinalize oracle_mimFinalize
#define mimRestore oracle_mimRestore
#define mimRunFunction oracle_mimRunFunction
#define restoreMatrixIndexState oracle_restoreMatrixIndexState
#define saveMatrixIndexState oracle_saveMatrixIndexState
#define setIRegisterAsInt oracle_setIRegisterAsInt
#define setJRegisterAsInt oracle_setJRegisterAsInt
#define showComplexMatrix oracle_showComplexMatrix
#define showMatrixEditor oracle_showMatrixEditor
#define showRealMatrix oracle_showRealMatrix
#define wrapIJ oracle_wrapIJ

#pragma weak matrixIndex
#pragma weak openMatrixMIMPointer
#pragma weak scrollColumn
#pragma weak scrollRow
#pragma weak shadowI
#pragma weak shadowJ
#pragma weak tmpRow

#include "../../../upstream/src/c47/ui/matrixEditor.c"
