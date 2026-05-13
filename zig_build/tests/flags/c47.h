// SPDX-License-Identifier: GPL-3.0-only

#ifndef C47_H
#define C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;

#define FLAG_BCD 0x8059
#define FLAG_SBfrac 0x8031
#define FLAG_SBtime 0x802d
#define FLAG_SBwoy 0x8057
#define FLAG_FRACT 0x8007
#define FLAG_IRFRAC 0x8047
#define FLAG_IRFRQ 0xc048
#define FLAG_CPXRES 0x8004
#define FLAG_TOPHEX 0x8058

#define SCRUPD_AUTO 0x00
#define SCRUPD_MANUAL_STATUSBAR 0x01

#define nbrOfElements(array) (sizeof(array) / sizeof((array)[0]))

extern uint64_t systemFlags0;
extern uint64_t systemFlags1;
extern uint32_t lastIntegerBase;
extern uint8_t screenUpdatingMode;

void fnRefreshState(void);
void reallyClearStatusBar(uint8_t info);
void fnChangeBaseJM(uint16_t base);

bool_t getSystemFlag(int32_t sf);
void setSystemFlag(unsigned int sf);
void clearSystemFlag(unsigned int sf);
void flipSystemFlag(unsigned int sf);
bool_t didSystemFlagChange(int32_t sf);
void setSystemFlagChanged(int32_t sf);
void setAllSystemFlagChanged(void);
void forceSystemFlag(unsigned int sf, int set);

#endif