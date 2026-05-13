// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

bool_t z47_flags_retained_getFlag(uint16_t flag);
void z47_flags_retained_fnGetSystemFlag(uint16_t systemFlag);
void z47_flags_retained_fnSetFlag(uint16_t flag);
void z47_flags_retained_fnClearFlag(uint16_t flag);
void z47_flags_retained_fnFlipFlag(uint16_t flag);
void z47_flags_retained_fnClFAll(uint16_t confirmation);
void z47_flags_retained_fnIsFlagClear(uint16_t flag);
void z47_flags_retained_fnIsFlagSet(uint16_t flag);
void z47_flags_retained_fnIsFlagClearClear(uint16_t flag);
void z47_flags_retained_fnIsFlagSetClear(uint16_t flag);
void z47_flags_retained_fnIsFlagClearSet(uint16_t flag);
void z47_flags_retained_fnIsFlagSetSet(uint16_t flag);
void z47_flags_retained_fnIsFlagClearFlip(uint16_t flag);
void z47_flags_retained_fnIsFlagSetFlip(uint16_t flag);
void z47_flags_retained_SetSetting(uint16_t jmConfig);

bool_t getFlag(uint16_t flag) {
  return z47_flags_retained_getFlag(flag);
}

void fnGetSystemFlag(uint16_t systemFlag) {
  z47_flags_retained_fnGetSystemFlag(systemFlag);
}

void fnSetFlag(uint16_t flag) {
  z47_flags_retained_fnSetFlag(flag);
}

void fnClearFlag(uint16_t flag) {
  z47_flags_retained_fnClearFlag(flag);
}

void fnFlipFlag(uint16_t flag) {
  z47_flags_retained_fnFlipFlag(flag);
}

void fnClFAll(uint16_t confirmation) {
  z47_flags_retained_fnClFAll(confirmation);
}

void fnIsFlagClear(uint16_t flag) {
  z47_flags_retained_fnIsFlagClear(flag);
}

void fnIsFlagSet(uint16_t flag) {
  z47_flags_retained_fnIsFlagSet(flag);
}

void fnIsFlagClearClear(uint16_t flag) {
  z47_flags_retained_fnIsFlagClearClear(flag);
}

void fnIsFlagSetClear(uint16_t flag) {
  z47_flags_retained_fnIsFlagSetClear(flag);
}

void fnIsFlagClearSet(uint16_t flag) {
  z47_flags_retained_fnIsFlagClearSet(flag);
}

void fnIsFlagSetSet(uint16_t flag) {
  z47_flags_retained_fnIsFlagSetSet(flag);
}

void fnIsFlagClearFlip(uint16_t flag) {
  z47_flags_retained_fnIsFlagClearFlip(flag);
}

void fnIsFlagSetFlip(uint16_t flag) {
  z47_flags_retained_fnIsFlagSetFlip(flag);
}

void SetSetting(uint16_t jmConfig) {
  z47_flags_retained_SetSetting(jmConfig);
}