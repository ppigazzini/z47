// SPDX-License-Identifier: GPL-3.0-only
//
// The storage behind the core-to-shell hook table declared in host.zig.
//
// It lives in its own file, compiled into ONE object per executable, because
// every build object that reaches the ABI seam compiles its own copy of
// host.zig. Module-scope storage there would give each object a private hook
// table: the shell's install would reach only the object the installer itself
// was compiled into, and every other core owner would keep the headless default
// for the whole run. That was a live defect, not a hypothetical -- it made the
// solver's mid-solve refreshScreen a no-op and cost a full afternoon of
// bisection.
//
// One definition, taken `extern` by everyone else, is the portable way to say
// that. Weak linkage expresses the same intent and is NOT portable here: it
// folds on ELF, leaves each object with its own table on Mach-O and COFF, and
// keeps every discarded copy's storage in .bss, which overran the DM42's SRAM
// budget. Do not reintroduce it.
//
// The names are C-ABI symbols because that is what makes them one thing across
// objects. Nothing outside host.zig should touch them.

const bool_t = u8; // the C-ABI bool the shell owners export (realType.h)

pub export var z47HostExitKeyWaitingHook: ?*const fn () callconv(.c) bool_t = null;
pub export var z47HostCheckHalfSecHook: ?*const fn () callconv(.c) bool_t = null;
pub export var z47HostProgressHalfSecHook: ?*const fn (u8, [*c]u8, i32, bool_t, bool_t, bool_t) callconv(.c) bool_t = null;
pub export var z47HostRequestRefreshHook: ?*const fn (u16) callconv(.c) void = null;
pub export var z47HostReportBugErrorHook: ?*const fn (u8, i16) callconv(.c) void = null;
pub export var z47HostShowBugScreenHook: ?*const fn ([*:0]const u8) callconv(.c) void = null;
pub export var z47HostReportBadTypeDetailHook: ?*const fn (i16) callconv(.c) void = null;
