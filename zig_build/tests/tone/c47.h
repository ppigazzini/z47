// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_TONE_TEST_C47_H
#define Z47_TONE_TEST_C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;

#define TO_QSPI
#define FLAG_QUIET 0x8019

bool_t getSystemFlag(int32_t sf);
void audioTone(uint32_t frequency);
void lcd_refresh(void);
void refreshLcd(void *unusedData);

#endif