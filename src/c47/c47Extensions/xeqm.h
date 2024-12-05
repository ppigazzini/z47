// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/* ADDITIONAL C47 functions and routines */

/********************************************//**
 * \file xeqm.h
 ***********************************************/
#if !defined(XEQM_H)
#define XEQM_H

#include "typeDefinitions.h"
#include <stdint.h>


#define XEDIT 1
#define XSWAP 0
extern bool_t running_program_jm;

bool_t strcompare            (const char *in1, const char *in2);
bool_t getXeqmText           (int16_t com, char *str);
void capture_sequence        (char *origin, uint16_t item);
void XEQMENU_loadAllfromdisk (void);
void fnXSWAP                 (uint16_t unusedButMandatoryParameter);

#endif // !XEQM_H
