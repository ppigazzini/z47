// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file value.h
 */

#if !defined(VALUE_H)
#define VALUE_H

#include "c47.h"
#include <jim.h>

int convertRegisterToString (calcRegister_t regist, char *buffer, size_t bufferSize);
int dslParseParam           (Jim_Interp *interp, int16_t index, const char *arg, uint16_t *outParam);
int dslParseFlagArg         (Jim_Interp *interp, const char *arg, uint16_t *outParam);
int dslParseRegisterArg     (Jim_Interp *interp, int16_t op, const char *arg, uint16_t *outParam);
int parseValueToTempRegister(Jim_Interp *interp, const char *valueArg);

#endif // VALUE_H
