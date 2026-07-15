// SPDX-License-Identifier: GPL-3.0-only
//
// The shared solver/plot/integrate context: which program and variable the
// SOLVE/PLOT/INTEGRATE engines are currently bound to, the solver status word,
// and the active equation formula id. This is base calculator state (it is part
// of the saved backup) read across the analysis engine via `extern var`; it was
// defined in the shell globals hub (c47.zig) but belongs in the base kernel so
// the headless engine does not reach up into shell for it. Symbols, types and
// zero-initialisers are unchanged, so every extern consumer resolves as before.

const calcRegister_t = i16;
const INVALID_VARIABLE: u16 = 2199;

pub export var currentSolverStatus: u16 = 0;
pub export var currentSolverVariable: u16 = 0;
pub export var currentSolverProgram: u16 = 0;
pub export var currentSolverNestingDepth: u16 = 0;
pub export var currentFormula: u16 = 0;
pub export var numberOfFormulae: u16 = 0;
pub export var graphVariabl1: calcRegister_t = 0; // the plot/graph variable the RPN grapher samples
pub export var currentMvarLabel: u16 = INVALID_VARIABLE; // the active MVAR (solver-menu) label
