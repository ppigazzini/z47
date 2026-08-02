// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file dsl.h
 */

#if !defined(DSL_H)
#define DSL_H

void initDSL(void);
int executeScript(const char *scriptFile);
void cleanupDSL(void);
int executeCommand(const char *command);

extern const char* dslOpsFileName;

#endif // DSL_H
