// SPDX-License-Identifier: GPL-3.0-only
//
// Calendar configuration the engine's date functions read: the Gregorian
// epoch, the two-digit-year century pivot, and the first-day/first-week rules.
//
// Base calculator state relocated out of the shell globals hub; symbols, types
// and initialisers are byte-identical, so every extern consumer resolves as before.

pub export var firstGregorianDay: u32 = 0; // Gregorian calendar epoch
pub export var lastCenturyHighUsed: u16 = 0; // two-digit-year century pivot
pub export var firstDayOfWeek: u8 = 1; // first day of the week
pub export var firstWeekOfYearDay: u8 = 4; // first-week-of-year rule day
