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
#define FLAG_TDM24 0x8000
#define FLAG_CPXj 0x8005
#define FLAG_POLAR 0x8006
#define FLAG_FRACT 0x8007
#define FLAG_PROPFR 0x8008
#define FLAG_DENANY 0x8009
#define FLAG_DENFIX 0x800a
#define FLAG_CARRY 0x800b
#define FLAG_OVERFLOW 0x800c
#define FLAG_LEAD0 0x800d
#define FLAG_IRFRAC 0x8047
#define FLAG_IRFRQ 0xc048
#define FLAG_CPXRES 0x8004
#define FLAG_SPCRES 0x8017
#define FLAG_SSIZE8 0x8018
#define FLAG_MULTx 0x801b
#define FLAG_ENGOVR 0x801c
#define FLAG_PRTACT 0xc020
#define FLAG_HPRP 0x802b
#define FLAG_HPBASE 0x803c
#define FLAG_2TO10 0x803d
#define FLAG_FRCYC 0x8041
#define FLAG_NUMLOCK 0x8043
#define FLAG_CPXMULT 0x8044
#define FLAG_ERPN 0x8045
#define FLAG_LARGELI 0x8046
#define FLAG_DREAL 0x804a
#define FLAG_CPXPLOT 0x804b
#define FLAG_SHOWX 0x804c
#define FLAG_SHOWY 0x804d
#define FLAG_PBOX 0x804e
#define FLAG_PCROS 0x804f
#define FLAG_PPLUS 0x8050
#define FLAG_PLINE 0x8051
#define FLAG_SCALE 0x8052
#define FLAG_VECT 0x8053
#define FLAG_NVECT 0x8054
#define FLAG_MNUp1 0x8056
#define FLAG_TOPHEX 0x8058
#define FLAG_PCURVE 0x805a
#define FLAG_BASE_MYM 0x805c
#define FLAG_G_DOUBLETAP 0x805d
#define FLAG_BASE_HOME 0x805e
#define FLAG_MYM_TRIPLE 0x805f
#define FLAG_HOME_TRIPLE 0x8060
#define FLAG_SHFT_4s 0x8061
#define FLAG_FGLNLIM 0x8062
#define FLAG_FGLNFUL 0x8063
#define FLAG_FGGR 0x8064
#define FLAG_NORM 0x8068
#define FLAG_ALPHA 0x800e
#define FLAG_AMORT_HP12C 0x8011
#define FLAG_TRACE 0x8013
#define FLAG_K 111
#define FLAG_M 211
#define FLAG_W 224

#define NUMBER_OF_GLOBAL_FLAGS 112
#define NUMBER_OF_LOCAL_FLAGS 32
#define LAST_LOCAL_FLAG 143

#define TI_NO_INFO 0
#define TI_FALSE 12
#define TI_TRUE 13
#define TI_CLEAR_ALL_FLAGS 96

#define NOT_CONFIRMED 9878

#define AC_UPPER 0
#define AC_LOWER 1

#define NC_NORMAL 0
#define NC_SUBSCRIPT 1
#define NC_SUPERSCRIPT 2

#define JC_NL 197
#define JC_UC 198
#define JC_SS 214

#define TF_H24 230
#define TF_H12 231
#define CU_I 232
#define CU_J 233
#define PS_DOT 234
#define PS_CROSS 235
#define SS_4 236
#define SS_8 237
#define CM_RECTANGULAR 238
#define CM_POLAR 239
#define DO_SCI 240
#define DO_ENG 241

#define ITM_DREAL 1899

#define PGM_STOPPED 0
#define PGM_RUNNING 1
#define PGM_WAITING 2

#define SCRUPD_AUTO 0x00
#define SCRUPD_MANUAL_STATUSBAR 0x01

#define nbrOfElements(array) (sizeof(array) / sizeof((array)[0]))

extern uint64_t systemFlags0;
extern uint64_t systemFlags1;
extern uint32_t lastIntegerBase;
extern uint8_t screenUpdatingMode;
extern uint16_t globalFlags[8];
extern uint32_t *currentLocalFlags;
extern uint8_t temporaryInformation;
extern uint8_t programRunStop;
extern uint8_t alphaCase;
extern uint8_t scrLock;
extern uint8_t nextChar;

void fnRefreshState(void);
void reallyClearStatusBar(uint8_t info);
void fnChangeBaseJM(uint16_t base);
void showAlphaModeonGui(void);

bool_t getFlag(uint16_t flag);
bool_t getSystemFlag(int32_t sf);
void fnGetSystemFlag(uint16_t systemFlag);
void fnSetFlag(uint16_t flag);
void fnClearFlag(uint16_t flag);
void fnFlipFlag(uint16_t flag);
void fnClFAll(uint16_t confirmation);
void SetSetting(uint16_t jmConfig);
void setSystemFlag(unsigned int sf);
void clearSystemFlag(unsigned int sf);
void flipSystemFlag(unsigned int sf);
bool_t didSystemFlagChange(int32_t sf);
void setSystemFlagChanged(int32_t sf);
void setAllSystemFlagChanged(void);
void forceSystemFlag(unsigned int sf, int set);

#endif