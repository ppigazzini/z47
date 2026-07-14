// SPDX-License-Identifier: GPL-3.0-only
//
// Keyboard and input-entry state the headless engine reads to drive key
// handling, long-press timing, alpha case and catalog navigation.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var currentKeyCode: u8 = 0; // last key code; polled for R/S/EXIT during long ops
pub export var FN_key_pressed: i16 = 0; // function key currently pressed
pub export var FN_state: u8 = 0; // function-key state machine
pub export var LongPressM: u8 = 0; // long-press state of the M key
pub export var DM_Cycling: u8 = 0; // date/mode key-cycling state
pub export var DRG_Cycling: u8 = 0; // degree/radian/grad key-cycling state
pub export var Input_Default: u8 = 0; // default input mode
pub export var alphaCase: u8 = 0; // alpha entry case (upper/lower)
pub export var catalog: i16 = 0; // active catalog index
