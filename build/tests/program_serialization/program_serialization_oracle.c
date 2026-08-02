// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the program save/load lane: c43's OWN
// saveRestorePrograms.c, compiled under `oracle_` names so it links beside the
// Zig owner's exports of the same c43 names.
//
// This file used to be 183 hand-written lines modelling roughly a quarter of
// saveRestorePrograms.c, and it had drifted: it carried its own PROGRAM_VERSION
// and OLDEST_COMPATIBLE_PROGRAM_VERSION constants, it did not clear
// temporaryInformation at load entry, it lacked the RAM-full bound and the whole
// pre-load screening pass that refuses an overlong label or a non-item opcode,
// and it restored the saved program number on a save-error path where c43 does
// not. The lane reported all of that as parity (REPORT-31 M31-3).
//
// Nothing here may be edited to make the lane pass.

#include "c47.h"

#define fnSaveProgram oracle_fnSaveProgram
#define fnExportProgram oracle_fnExportProgram
#define fnLoadProgram oracle_fnLoadProgram
#define fnSaveAllPrograms oracle_fnSaveAllPrograms
#define fnPExport oracle_fnPExport
#define _saveProgram oracle_saveProgram
#define _exportProgram oracle_exportProgram
#define _fnExportProgram oracle_fnExportProgramImpl
#define indents oracle_indents

// c43 calls these before defining them. Declared after the renames so the
// declarations carry the same names as the definitions.
void _saveProgram(uint16_t label, ioFilePath_t path);
void _exportProgram(uint16_t label, ioFilePath_t path);

#include "../../../upstream/src/c47/saveRestorePrograms.c"
