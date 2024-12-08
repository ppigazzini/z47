// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/* ADDITIONAL C47 functions and routines */

/********************************************//**
 * \file xeqm.h
 ***********************************************/
#if !defined(XEQM_H)
#define XEQM_H

#define XEDIT 1
#define XSWAP 0

bool_t strcompare            (const char *in1, const char *in2);
bool_t getXeqmText           (int16_t com, char *str);
void fnXSWAP                 (uint16_t unusedButMandatoryParameter);

#endif // !XEQM_H
