// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file dsl.c
 * \brief Jim Tcl-based DSL for calculator control
 */

#include "c47.h"
#include "c47-gtk.h"
#include "value.h"

#if defined(PC_BUILD)

#include "assign.h"
#include "calcMode.h"
#include "keyboard.h"
#include "softmenus.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

// Name of the output file written by --dslcommands
const char *dslOpsFileName = "t47-op-commands.txt";

// Global state - declared in gtkGui.c
extern bool_t scriptingActive;
extern bool_t headlessMode;
extern bool_t dumpDslCmds;

static FILE *dslDumpFile = NULL;

// External declaration for _ioFileNameOverride from hal/io.c
extern char _ioFileNameOverride[C47_PATH_MAX];

// Jim interpreter instance
static Jim_Interp *g_dsl_interpreter = NULL;

// True after asn resolve (itemToBeAssigned may still be ITM_NULL == 0).
static bool_t dslAsnHaveItem = FALSE;

// clang-format off
/** runCatalogFunctionByName result codes */
enum {
  CATFN_NOT_FOUND = 0,
  CATFN_OK        = 1,
  CATFN_ERROR     = -1
};
// clang-format on

// =====================================================================
// Helper functions not worth extracting to a separate module
// =====================================================================

/**
 * Wait until calculator program execution has fully returned control.
 *
 * DSL contract: xeq must not return while the execution engine is still
 * running (or internally paused as part of run-state handling).
 */
static void waitForEngineReturn(void) {
  while(programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED || programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED) {
    g_main_context_iteration(g_main_context_default(), TRUE);
  }

  // Drain remaining UI work queued by the final refresh path.
  refresh_gui();
}

/**
 * Resolve script-provided program filename in the same spirit as UI READP:
 * if a relative path does not exist as-is, also try PROGRAMS/<name>.
 */
static void setReadpFilenameOverride(const char *filename) {
  if(g_file_test(filename, G_FILE_TEST_EXISTS)) {
    strncpy(_ioFileNameOverride, filename, C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
    return;
  }

  if(strchr(filename, '/') == NULL) {
    char fallback[C47_PATH_MAX];
    snprintf(fallback, sizeof(fallback), "%s/%s", PROGRAMS_DIR, filename);
    if(g_file_test(fallback, G_FILE_TEST_EXISTS)) {
      strncpy(_ioFileNameOverride, fallback, C47_PATH_MAX - 1);
      _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
      return;
    }
  }

  // Let fnLoadProgram report the open/read failure with the original value.
  strncpy(_ioFileNameOverride, filename, C47_PATH_MAX - 1);
  _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
}

/**
 * True when the catalog item expects a script-supplied argument (TAM in UI).
 */
static bool_t itemNeedsScriptArgs(int16_t index) {
  uint16_t p = indexOfItems[index].param;
  return TM_VALUE <= p && p <= TM_CMP;
}

/**
 * Number of Tcl string args required after the command name, or -1 if unsupported.
 */
static int expectedScriptArgCount(int16_t index) {
  switch(indexOfItems[index].status & PTP_STATUS) {
    case PTP_NONE:
      return 0;
    case PTP_REGISTER:
    case PTP_LABEL:
    case PTP_DECLARE_LABEL:
    case PTP_FLAG:
    case PTP_COMPARE:
    case PTP_NUMBER_8:
    case PTP_NUMBER_16:
    case PTP_NUMBER_8_16:
    case PTP_SKIP_BACK:
    case PTP_SHUFFLE:
    case PTP_MENU:
      return 1;
    default:
      return -1;
  }
}

/**
 * Headless DSL has no GUI refresh loop, so a command that queued a plot
 * (GRAPHMODE) would only render during snap's own redraw.  Render it now.
 */
static void dslRenderPendingPlot(void) {
  if(GRAPHMODE) {
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(211);                //dsl.c owns trace id range 210..219
  }
}

/**
 * Run one catalog function, with optional script args parsed per
 * items.c metadata.  The item index is validated, and the function
 * is called with the parsed parameter.
 */
static int runCatalogItem(Jim_Interp *interp, int16_t index, int argArgc, Jim_Obj *const *argArgv, const char *cmdName) {
  if(index < 0 || index >= LAST_ITEM) {
    Jim_SetResultFormatted(interp, "%s: invalid catalog index %d", cmdName, index);
    return JIM_ERR;
  }

  if(index == ITM_DELITM) {
    Jim_SetResultFormatted(interp, "%s: DELITM not supported in scripts yet", cmdName);
    return JIM_ERR;
  }

  item_t item = indexOfItems[index];
  bool_t needsArgs = itemNeedsScriptArgs(index);
  int expected = needsArgs ? expectedScriptArgCount(index) : 0;

  if(needsArgs && expected < 0) {
    Jim_SetResultFormatted(interp, "%s: '%s' not scriptable", cmdName, item.itemCatalogName);
    return JIM_ERR;
  }

  if(!needsArgs) {
    if(argArgc != 0) {
      Jim_SetResultFormatted(interp, "%s: wrong # args: expected 0, got %d", cmdName, argArgc);
      return JIM_ERR;
    }
    printf("Calling argless catalog function %s, index %d\n", item.itemCatalogName, index);
    fflush(stdout);
    reallyRunFunction(index, item.param);
    dslRenderPendingPlot();
    return JIM_OK;
  }

  if(argArgc != expected) {
    Jim_SetResultFormatted(interp, "%s: wrong # args: expected %d, got %d", cmdName, expected, argArgc);
    return JIM_ERR;
  }

  uint16_t param;
  const char *argstr = Jim_String(argArgv[0]);
  if(dslParseParam(interp, index, argstr, &param) != JIM_OK) {
    return JIM_ERR;
  }
  printf("Calling catalog function %s(%s), index %d\n", item.itemCatalogName, argstr, index);
  fflush(stdout);
  reallyRunFunction(index, param);
  dslRenderPendingPlot();
  return JIM_OK;
}

/**
 * cmdCatalogFn index - Calls a built-in catalog function by its item index.
 * This binds CAT FCNS to Tcl commands.
 */
static int cmdCatalogFn(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  int index = (int)(intptr_t)Jim_CmdPrivData(interp);
  return runCatalogItem(interp, (int16_t)index, argc - 1, argv + 1, argv[0] ? Jim_String(argv[0]) : "command");
}

/**
 * Register a catalog function directly if its name happens to be a
 * valid Tcl identifier.
 */
static bool_t registerCatFn(Jim_Interp *interp, const char *name, void *idx, char *cmdName, bool_t skipUtf8Identity) {
  if(!name || !name[0]) {
    return FALSE;
  }
  stringToUtf8(name, (uint8_t *)cmdName);
  if(skipUtf8Identity && strcmp(name, cmdName) == 0) {
    return FALSE;  // already registered it under the primary name
  }
  if(compareString(name, name, CMP_NAME) != 0) {
    return FALSE;  // not a "name"
  }
  static const char *exprCommands[] = {"+", "-", "*", "/", "%", NULL};
  for(int i = 0; exprCommands[i] != NULL; ++i) {
    if(strcmp(cmdName, exprCommands[i]) == 0) {
      return FALSE;  // do not shadow Jim expr arithmetic commands
    }
  }
  for(int i = 0; cmdName[i]; ++i) {
    unsigned char c = (unsigned char)cmdName[i];
    if(c == '$' || c == ';' || c == '"' || c == '\\' || c == '[' || c == ']' || c == '{' || c == '}' || c == '(' || c == ')') {
      return FALSE;  // refuse commands likely to cause Jim parsing errors
    }
  }
  for(int i = 0; cmdName[i]; ++i) {
    unsigned char c = (unsigned char)cmdName[i];
    if(c < 0x80) {
      cmdName[i] = tolower(c);
    }
  }
  Jim_CreateCommand(interp, cmdName, cmdCatalogFn, idx, NULL);
  return TRUE;
}

/**
 * Look up a catalog function by name and run it.  Core of catfn and
 * the by-name fallback in xeq.
 */
static int runCatalogFunctionByName(Jim_Interp *interp, const char *fnName, int argArgc, Jim_Obj *const *argArgv, const char *cmdName) {
  char internalName[64];
  static const size_t max = sizeof(internalName) / 2;

  if(strlen(fnName) >= max) {
    Jim_SetResultFormatted(interp, "%s: '%s' exceeds max length %d", cmdName, fnName, max);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)fnName, internalName);
  for(int i = 0; i < LAST_ITEM; ++i) {
    item_t item = indexOfItems[i];
    const char *catName = item.itemCatalogName;
    if((item.status & CAT_STATUS) == CAT_FNCT && compareString(internalName, catName, CMP_NAME) == 0) {  //change here to slacken the character check for commands: CMP_CLEANED_STRING_ONLY
      return runCatalogItem(interp, (int16_t)i, argArgc, argArgv, cmdName) == JIM_OK ? CATFN_OK : CATFN_ERROR;
    }
  }
  return CATFN_NOT_FOUND;
}

// =====================================================================
// DSL command implementations
// =====================================================================

/*
 * flag <name> - Get flag state (1 or 0)
 * flag <name> <value> - Set flag (1=set, 0=clear), return new state
 */
static int flagCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "flag: missing flag argument", -1);
    return JIM_ERR;
  }

  const char *flagArg = Jim_String(argv[1]);
  uint16_t param;

  if(dslParseFlagArg(interp, flagArg, &param) != JIM_OK) {
    return JIM_ERR;
  }
  int32_t flagNum = (int32_t)param;

  if(argc == 2) {
    char resultStr[32];
    snprintf(resultStr, sizeof(resultStr), "%d", (getSystemFlag(flagNum)) ? 1 : 0);
    Jim_SetResultString(interp, resultStr, -1);
    return JIM_OK;
  }

  if(argc != 3) {
    Jim_SetResultFormatted(interp, "flag: wrong # args: expected 1 or 2, got %d", argc - 1);
    return JIM_ERR;
  }

  const char *valueArg = Jim_String(argv[2]);
  long newValue;

  if(valueArg[0] == '\0' || valueArg[strspn(valueArg, "0123456789")] != '\0') {
    Jim_SetResultFormatted(interp, "flag: expected numeric value, got '%s'", valueArg);
    return JIM_ERR;
  }

  newValue = strtol(valueArg, NULL, 10);

  if(newValue != 0 && newValue != 1) {
    Jim_SetResultFormatted(interp, "flag: value must be 0 or 1, got %ld", newValue);
    return JIM_ERR;
  }

  if(newValue == 1) {
    setSystemFlag(flagNum);
  } else {
    clearSystemFlag(flagNum);
  }

  char resultStr[32];
  snprintf(resultStr, sizeof(resultStr), "%d", (getSystemFlag(flagNum)) ? 1 : 0);
  Jim_SetResultString(interp, resultStr, -1);
  return JIM_OK;
}

/**
 * reg <name> <value> - Set register, return new value
 */
static int regCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "reg: missing register argument", -1);
    return JIM_ERR;
  }

  const char *regArg = Jim_String(argv[1]);
  uint16_t param;

  if(dslParseRegisterArg(interp, ITM_RCL, regArg, &param) != JIM_OK) {
    return JIM_ERR;
  }
  calcRegister_t regist = (calcRegister_t)param;

  if(!regInRange(regist)) {
    Jim_SetResultFormatted(interp, "invalid register: '%s'", regArg);
    return JIM_ERR;
  }

  if(argc == 2) {
    char buffer[1024];
    convertRegisterToString(regist, buffer, sizeof(buffer));
    Jim_SetResultString(interp, buffer, -1);
    return JIM_OK;
  }

  if(argc != 3) {
    Jim_SetResultFormatted(interp, "reg: wrong # args: expected 1 or 2, got %d", argc - 1);
    return JIM_ERR;
  }

  const char *valueArg = Jim_String(argv[2]);

  // Parse value string into temporary register
  if(parseValueToTempRegister(interp, valueArg) != JIM_OK) {
    return JIM_ERR;
  }

  // Copy from temp to target register
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, regist);

  char buffer[1024];
  convertRegisterToString(regist, buffer, sizeof(buffer));
  Jim_SetResultString(interp, buffer, -1);
  return JIM_OK;
}

/**
 * var <name> - Get variable contents
 * var <name> <value> - Set variable, return new value
 */
static int varCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "var: missing variable argument", -1);
    return JIM_ERR;
  }

  const char *varArg = Jim_String(argv[1]);
  uint16_t param;

  if(dslParseRegisterArg(interp, ITM_INPUT, varArg, &param) != JIM_OK) {
    return JIM_ERR;
  }
  calcRegister_t regist = (calcRegister_t)param;

  if(!regInRange(regist)) {
    Jim_SetResultFormatted(interp, "invalid variable: '%s'", varArg);
    return JIM_ERR;
  }

  if(argc == 2) {
    char buffer[1024];
    convertRegisterToString(regist, buffer, sizeof(buffer));
    Jim_SetResultString(interp, buffer, -1);
    return JIM_OK;
  }

  if(argc != 3) {
    Jim_SetResultFormatted(interp, "var: wrong # args: expected 1 or 2, got %d", argc - 1);
    return JIM_ERR;
  }

  const char *valueArg = Jim_String(argv[2]);

  // Parse value string into temporary register
  if(parseValueToTempRegister(interp, valueArg) != JIM_OK) {
    return JIM_ERR;
  }

  // Copy from temp to target register
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, regist);

  char buffer[1024];
  convertRegisterToString(regist, buffer, sizeof(buffer));
  Jim_SetResultString(interp, buffer, -1);
  return JIM_OK;
}

/**
 * catfn <name> - Calls a built-in catalog function by its name.
 * This is slow due to a linear lookup over a large table.  Prefer
 * the direct call by index by using the item name as a command,
 * when it is a legal Tcl identifier.
 */
static int catfnCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "catfn: missing function name", -1);
    return JIM_ERR;
  }
  const char *fnName = Jim_String(argv[1]);
  int found = runCatalogFunctionByName(interp, fnName, argc - 2, argv + 2, "catfn");
  if(found == CATFN_OK) {
    return JIM_OK;
  }
  if(found == CATFN_ERROR) {
    return JIM_ERR;
  }
  Jim_SetResultFormatted(interp, "catfn: '%s' not in the function catalog", fnName);
  return JIM_ERR;
}

/**
 * item <number> - Calls a built-in catalog function by its numeric item code.
 * Useful for items not registered in the catalog: bypasses name lookup entirely.
 */
static int itemCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "item: missing item number", -1);
    return JIM_ERR;
  }
  jim_wide itemNr;
  if(Jim_GetWide(interp, argv[1], &itemNr) != JIM_OK) {
    Jim_SetResultFormatted(interp, "item: '%#s' is not an integer", argv[1]);
    return JIM_ERR;
  }
  if(itemNr <= 0 || itemNr >= LAST_ITEM) {
    Jim_SetResultFormatted(interp, "item: item number %lld out of range (1..%d)", (long long)itemNr, LAST_ITEM - 1);
    return JIM_ERR;
  }
  int effectiveArgc = argc - 2;
  for(int i = 2; i < argc; ++i) {
    const char *s = Jim_String(argv[i]);
    if(s != NULL && s[0] == '#') {
      effectiveArgc = i - 2;
      break;
    }
  }
  return runCatalogItem(interp, (int16_t)itemNr, effectiveArgc, argv + 2, "item");
}

/**
 * Copy a Jim string object into a null-terminated C buffer.
 * Jim list elements may not be NUL-terminated when Jim_String is used directly.
 */
static int dslJimObjToCString(Jim_Interp *interp, Jim_Obj *obj, char *buf, size_t bufSize, const char *cmd) {
  int len;
  const char *s = Jim_GetString(obj, &len);

  if(len < 0 || (size_t)len >= bufSize) {
    Jim_SetResultFormatted(interp, "%s: string too long (%d bytes, max %zu)", cmd, len, bufSize - 1);
    return JIM_ERR;
  }
  memcpy(buf, s, (size_t)len);
  buf[len] = '\0';
  return JIM_OK;
}

/**
 * Copy a UTF-8 script string into aimBuffer for assignGetName1().
 */
static void dslSetAimBuffer(const char *label) {
  char internalName[AIM_BUFFER_LENGTH];

  utf8ToString((const uint8_t *)label, internalName);
  internalName[AIM_BUFFER_LENGTH - 1] = '\0';
  xcopy(aimBuffer, internalName, (uint32_t)strlen(internalName));
  aimBuffer[strlen(internalName)] = '\0';
}

/**
 * Leave assign mode the same way a successful softkey assign does.
 */
static void dslFinishAssign(void) {
  calcMode = previousCalcMode;
  shiftF = shiftG = false;
  catalog = CATALOG_NONE;
  screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
  screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
  refreshScreen(210);                  //dsl.c owns trace id range 210..219
  screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
}

/**
 * Resolve a label into itemToBeAssigned via assignGetName1().
 */
static int dslAsnResolveLabel(Jim_Interp *interp, const char *label) {
  char internalName[AIM_BUFFER_LENGTH];

  utf8ToString((const uint8_t *)label, internalName);
  internalName[AIM_BUFFER_LENGTH - 1] = '\0';

  if(compareString(internalName, "NULL", CMP_NAME) == 0) {
    itemToBeAssigned = ITM_NULL;
    dslAsnHaveItem = TRUE;
    return JIM_OK;
  }

  dslSetAimBuffer(label);
  assignGetName1();

  if(itemToBeAssigned == ASSIGN_CLEAR) {
    Jim_SetResultFormatted(interp, "asn: unknown assignable name '%s'", label);
    return JIM_ERR;
  }

  dslAsnHaveItem = TRUE;
  return JIM_OK;
}

/**
 * Parse a non-negative integer Tcl argument.
 */
static int dslParseIntArg(Jim_Interp *interp, const char *cmdName, const char *arg, long minVal, long maxVal, long *outVal) {
  char *end = NULL;

  if(arg[0] == '\0' || arg[strspn(arg, "0123456789")] != '\0') {
    Jim_SetResultFormatted(interp, "%s: expected integer, got '%s'", cmdName, arg);
    return JIM_ERR;
  }

  *outVal = strtol(arg, &end, 10);
  if(*outVal < minVal || *outVal > maxVal) {
    Jim_SetResultFormatted(interp, "%s: value %ld out of range [%ld..%ld]", cmdName, *outVal, minVal, maxVal);
    return JIM_ERR;
  }

  return JIM_OK;
}

/**
 * Assign itemToBeAssigned to a softmenu slot on the current menu.
 */
static int dslAsnAssignSlot(Jim_Interp *interp, long fwRow, long col, bool_t finish) {
  long position;
  int16_t menuId;

  if(fwRow < 0 || fwRow > 2 || col < 1 || col > 6) {
    Jim_SetResultFormatted(interp, "asn: row must be 0..2 and column 1..6, got row %ld col %ld", fwRow, col);
    return JIM_ERR;
  }

  if(!dslAsnHaveItem) {
    Jim_SetResultString(interp, "asn: nothing to assign (use 'asn resolve' first)", -1);
    return JIM_ERR;
  }

  position = fwRow * 6 + (col - 1);
  menuId = currentMenu();

  switch(-menuId) {
    case MNU_MyMenu:
      assignToMyMenu((uint16_t)position);
      break;
    case MNU_MyAlpha:
      assignToMyAlpha((uint16_t)position);
      break;
    case MNU_DYNAMIC:
      assignToUserMenu((uint16_t)position);
      break;
    case MNU_HOME:
      if(!setCurrentUserMenu(-MNU_DYNAMIC, "HOME")) {
        Jim_SetResultString(interp, "asn: failed to open HOME menu", -1);
        return JIM_ERR;
      }
      assignToUserMenu((uint16_t)position);
      break;
    case MNU_PFN:
      if(!setCurrentUserMenu(-MNU_DYNAMIC, "P.FN")) {
        Jim_SetResultString(interp, "asn: failed to open P.FN menu", -1);
        return JIM_ERR;
      }
      assignToUserMenu((uint16_t)position);
      break;
    default:
      Jim_SetResultFormatted(interp, "asn: cannot assign to menu '%s'", indexOfItems[-menuId].itemCatalogName);
      return JIM_ERR;
  }

  if(finish) {
    dslFinishAssign();
    dslAsnHaveItem = FALSE;
  }

  return JIM_OK;
}

/**
 * menu <name> - Open a softmenu by catalog name (MyMenu via fnBaseMenu).
 */
static int menuCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  char internalName[64];

  if(argc != 2) {
    Jim_SetResultFormatted(interp, "menu: wrong # args: expected 1, got %d", argc - 1);
    return JIM_ERR;
  }

  utf8ToString((const uint8_t *)Jim_String(argv[1]), internalName);
  internalName[sizeof(internalName) - 1] = '\0';

  if(compareString(internalName, "MyMenu", CMP_NAME) == 0 || compareString(internalName, "MyM", CMP_NAME) == 0) {
    fnBaseMenu(0);
    return JIM_OK;
  }

  for(int i = 0; softmenu[i].menuItem != 0; ++i) {
    int16_t menuItem = softmenu[i].menuItem;
    const char *catName = indexOfItems[-menuItem].itemCatalogName;
    const char *smName = indexOfItems[-menuItem].itemSoftmenuName;

    if(compareString(internalName, catName, CMP_NAME) == 0 || (smName[0] != '\0' && compareString(internalName, smName, CMP_NAME) == 0)) {
      showSoftmenu(menuItem);
      return JIM_OK;
    }
  }

  Jim_SetResultFormatted(interp, "menu: '%s' not found", Jim_String(argv[1]));
  return JIM_ERR;
}

/**
 * asn - Assign-to-softkey operations (wraps fnAssign / assignGetName1).
 */
static int asnCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc == 1) {
    fnAssign(0);
    dslAsnHaveItem = FALSE;
    return JIM_OK;
  }

  const char *sub = Jim_String(argv[1]);

  if(strcmp(sub, "resolve") == 0) {
    char labelBuf[AIM_BUFFER_LENGTH];

    if(argc != 3) {
      Jim_SetResultFormatted(interp, "asn: wrong # args: expected 'asn resolve name', got %d args", argc - 1);
      return JIM_ERR;
    }
    if(dslJimObjToCString(interp, argv[2], labelBuf, sizeof(labelBuf), "asn") != JIM_OK) {
      return JIM_ERR;
    }
    return dslAsnResolveLabel(interp, labelBuf);
  }

  if(strcmp(sub, "to") == 0) {
    long fwRow;
    long col;

    if(argc != 4) {
      Jim_SetResultFormatted(interp, "asn: wrong # args: expected 'asn to row col', got %d args", argc - 1);
      return JIM_ERR;
    }
    if(dslParseIntArg(interp, "asn", Jim_String(argv[2]), 0, 2, &fwRow) != JIM_OK) {
      return JIM_ERR;
    }
    if(dslParseIntArg(interp, "asn", Jim_String(argv[3]), 1, 6, &col) != JIM_OK) {
      return JIM_ERR;
    }
    return dslAsnAssignSlot(interp, fwRow, col, TRUE);
  }

  if(argc == 3 || argc == 4) {
    long fwRow;
    long col;

    if(dslParseIntArg(interp, "asn", Jim_String(argv[1]), 0, 2, &fwRow) != JIM_OK) {
      return JIM_ERR;
    }
    if(dslParseIntArg(interp, "asn", Jim_String(argv[2]), 1, 6, &col) != JIM_OK) {
      return JIM_ERR;
    }
    if(argc == 3) {
      return JIM_OK;
    }

    char labelBuf[AIM_BUFFER_LENGTH];

    if(dslJimObjToCString(interp, argv[3], labelBuf, sizeof(labelBuf), "asn") != JIM_OK) {
      return JIM_ERR;
    }
    if(labelBuf[0] == '\0') {
      return JIM_OK;
    }

    if(dslAsnResolveLabel(interp, labelBuf) != JIM_OK) {
      return JIM_ERR;
    }
    return dslAsnAssignSlot(interp, fwRow, col, TRUE);
  }

  Jim_SetResultString(interp, "asn: usage: asn | asn resolve <name> | asn to <row> <col> | asn <row> <col> [<label>]", -1);
  return JIM_ERR;
}

/**
 * readp <filename> - Load a program from file (like READP menu command)
 */
static int readpCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "readp: missing filename", -1);
    return JIM_ERR;
  }

  const char *filename = Jim_String(argv[1]);

  lastErrorCode = ERROR_NONE;
  setReadpFilenameOverride(filename);
  fnLoadProgram(0);

  if(temporaryInformation != TI_PROGRAM_LOADED) {
    const char *detail = (lastErrorCode != ERROR_NONE)
        ? errorMessages[lastErrorCode]
        : "unknown error";
    Jim_SetResultFormatted(interp, "readp: failed to load '%s': %s", filename, detail);
    return JIM_ERR;
  }

  return JIM_OK;
}

/**
 * xportp <labelname> <filename> - Export a program to RTF (like the XPORTP menu command).
 */
static int xportpCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc != 3) {
    Jim_SetResultFormatted(interp, "xportp: wrong # args: expected <label> <filename>, got %d", argc - 1);
    return JIM_ERR;
  }

  const char *labelName = Jim_String(argv[1]);
  const char *filename = Jim_String(argv[2]);
  char internalLabel[64];
  static const size_t maxLabel = sizeof(internalLabel) / 2;

  if(strlen(labelName) >= maxLabel) {
    Jim_SetResultFormatted(interp, "xportp: '%s' exceeds max length %d", labelName, maxLabel);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)labelName, internalLabel);
  calcRegister_t label = findNamedLabel(internalLabel, GLOBAL_LABELS);
  if(label == INVALID_VARIABLE) {
    Jim_SetResultFormatted(interp, "xportp: '%s' not found as a global label", labelName);
    return JIM_ERR;
  }

  strncpy(_ioFileNameOverride, filename, C47_PATH_MAX - 1);
  _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';

  lastErrorCode = ERROR_NONE;
  reallyRunFunction(ITM_EXPORTP, (uint16_t)label);

  if(lastErrorCode != ERROR_NONE) {
    Jim_SetResultFormatted(interp, "xportp: export of '%s' failed: %s", labelName, errorMessages[lastErrorCode]);
    return JIM_ERR;
  }

  return JIM_OK;
}

/**
 * xeq <labelname> - Execute a label, emulating the XEQ key action
 */

#undef UTF8_FAIL_DEBUG

static int xeqCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "xeq: missing label name", -1);
    return JIM_ERR;
  }
  const char *labelName = Jim_String(argv[1]);
  char internalLabel[64];
  static const size_t maxLabel = sizeof(internalLabel) / 2;

  // labelName is UTF-8 from Jim but findNamedLabel compares CMP_BINARY against internal-encoded labels, so non-ASCII never
  // matches (gamma 0xCE 0xB3 UTF-8 vs 0x83 0xB3 internal). Convert here as runCatalogFunctionByName does; not in findNamedLabel
  if(strlen(labelName) >= maxLabel) {
    Jim_SetResultFormatted(interp, "xeq: '%s' exceeds max length %d", labelName, maxLabel);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)labelName, internalLabel);
  calcRegister_t label = findNamedLabel(internalLabel, STRING_LABEL_VARIABLE);

  if(label == INVALID_VARIABLE) {
    // Original UTF-8 labelName here, not internalLabel: runCatalogFunctionByName does its own utf8ToString.
    int found = runCatalogFunctionByName(interp, labelName, argc - 2, argv + 2, "xeq");
    if(found == CATFN_OK) {
      return JIM_OK;
    }
    if(found == CATFN_ERROR) {
      return JIM_ERR;
    }
    #if defined(UTF8_FAIL_DEBUG)
      // Label lookup missed. Dump both encodings so a conversion fault is visible.
      // utf8 is the raw Jim input, internal is what findNamedLabel actually searched for.
      printf("xeq: miss; utf8='%s' internal=", labelName);
      for(const unsigned char *p = (const unsigned char *)internalLabel; *p; ++p) {
        printf("%02X ", *p);
      }
      printf("\n");
    #endif // UTF8_FAIL_DEBUG
    Jim_SetResultFormatted(interp, "xeq: '%s' not found as label or function", labelName);
    return JIM_ERR;
  }

  dynamicMenuItem = -1;  // clear stale dynamic menu context
  reallyRunFunction(ITM_XEQ, (uint16_t)label);
  waitForEngineReturn();
  dslRenderPendingPlot();
  return JIM_OK;
}

/**
 * Helper for pressOne() to handle the common elements for each keypress.
 */
static int injectScriptKey(Jim_Interp *interp, const char *keyCode, uint32_t keyval) {
  if(!scriptInjectGtkKey(keyval)) {
    Jim_SetResultFormatted(interp, "press: failed to inject key '%s'", keyCode);
    return JIM_ERR;
  }
  return JIM_OK;
}

/**
 * pressOne <keycode> - Fake a Gtk keypress event for a single
 * calculator keyboard key.  At the moment, it only understands
 * events corresponding to ASCII characters, plus a symbolic "ENTER".
 */
static int pressOne(Jim_Interp *interp, const char *keyCode) {
  if(keyCode[0] == 'F' && keyCode[1] >= '1' && keyCode[1] <= '6' && keyCode[2] == '\0') {
    btnFnClicked(NULL, (gpointer)(keyCode + 1));
    return JIM_OK;
  }
  if(strcmp(keyCode, "@f") == 0) {
    shiftF = !shiftF;
    if(shiftF) {
      shiftG = false;
    }
    return JIM_OK;
  }
  if(strcmp(keyCode, "@g") == 0) {
    shiftG = !shiftG;
    if(shiftG) {
      shiftF = false;
    }
    return JIM_OK;
  }
  if(strncmp(keyCode, "@k ", 3) == 0) {
    const char *keyId = keyCode + 3;
    if(strlen(keyId) != 2 || keyId[0] < '0' || keyId[0] > '9' || keyId[1] < '0' || keyId[1] > '9') {
      Jim_SetResultFormatted(interp, "press: invalid @k token '%s' (expected '@k NN')", keyCode);
      return JIM_ERR;
    }
    btnClicked(NULL, (gpointer)keyId);
    return JIM_OK;
  }

  if(strlen(keyCode) == 1) {
    /* Presume the ASCII value of the char == the GTK_KEY_* value */
    uint32_t keyval = (uint32_t)(unsigned char)keyCode[0];
    return injectScriptKey(interp, keyCode, keyval);
  } else if(strcasecmp(keyCode, "ENTER") == 0) {
    /* The Gtk "Return" keypress event code is ugly; allow the user
           to give this symbolic name instead. */
    return injectScriptKey(interp, keyCode, GDK_KEY_Return);
  } else if(strcasecmp(keyCode, "R/S") == 0) {
    /* to give this symbolic name instead. */
    return injectScriptKey(interp, keyCode, GDK_KEY_backslash);
  }

  Jim_SetResultFormatted(interp, "press: Invalid key code '%s' (expected single char, Enter/Return, or 2 digits)", keyCode);
  return JIM_ERR;
}

/**
 * nim <string> - Add a string to the NIM buffer
 */
static int nimCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "nim: missing string argument", -1);
    return JIM_ERR;
  }
  printf("NIM: ");  // NIM sequentially accepts numerals and - as typed. That means -4.5E-5 is to be entered as [4.5 - E5 -] and this is automated below
  const char *start = Jim_String(argv[1]);
  bool_t inExponent = FALSE;
  bool_t mantissaNeg = FALSE;
  bool_t exponentNeg = FALSE;
  bool_t signEmitted = FALSE;  // mantissa CHS already sent before E
  for(const char *p = start; *p != 0; p++) {
    printf("%c", *p);
    int16_t item;
    if(*p >= '0' && *p <= '9') {
      item = ITM_0 + (*p - '0');
    } else if(*p == '.' || *p == ',') {
      item = ITM_PERIOD;
    } else if(*p == '-') {
      // Defer the sign: a leading '-' negates the mantissa, a '-' right after E negates the exponent. Either
      // way the CHS is applied after that component's digits, simulate key entry (you type 4 then CHS, not -4).
      if(!inExponent && p == start) {
        mantissaNeg = TRUE;
      } else if(inExponent && (*(p - 1) == 'e' || *(p - 1) == 'E')) {
        exponentNeg = TRUE;
      } else {
        printf("\n");
        fflush(stdout);
        Jim_SetResultFormatted(interp, "nim: unexpected '-' at position %d", (int)(p - start));
        return JIM_ERR;
      }
      continue;
    } else if(*p == 'e' || *p == 'E') {
      // Mantissa is complete: emit its deferred sign before the E.
      if(mantissaNeg && !signEmitted) {
        addItemToNimBuffer(ITM_CHS);
        refreshRegisterLine(REGISTER_X);
        signEmitted = TRUE;
      }
      inExponent = TRUE;
      item = ITM_EXPONENT;
    } else if(*p == ' ') {
      //break;  // space terminates the number
      continue;  // skip embedded spaces
    } else {
      printf("\n");
      fflush(stdout);
      Jim_SetResultFormatted(interp, "nim: invalid character '%c' (expected 0-9, . , - e E or space)", *p);
      return JIM_ERR;
    }
    addItemToNimBuffer(item);
    refreshRegisterLine(REGISTER_X);
  }
  // Emit any still-pending signs at end of number.
  if(mantissaNeg && !signEmitted) {
    addItemToNimBuffer(ITM_CHS);  // no exponent: mantissa sign at end
    refreshRegisterLine(REGISTER_X);
  }
  if(exponentNeg) {
    addItemToNimBuffer(ITM_CHS);  // exponent sign at end
    refreshRegisterLine(REGISTER_X);
  }

  printf("\n");
  fflush(stdout);
  closeNim();
  return JIM_OK;
}

/**
 * press <keycode> - Press a keyboard key (like pressing the button)
 */
static int pressCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "press: missing key code argument", -1);
    return JIM_ERR;
  }

  if(Jim_IsList(argv[1])) {
    int listLen = Jim_ListLength(interp, argv[1]);
    for(int i = 0; i < listLen; i++) {
      Jim_Obj *elemObj;
      if(Jim_ListIndex(interp, argv[1], i, &elemObj, JIM_NONE) != JIM_OK) {
        return JIM_ERR;
      }
      const char *keyCode = Jim_String(elemObj);
      if(pressOne(interp, keyCode) != JIM_OK) {
        return JIM_ERR;
      }
    }
  } else {
    const char *keyCode = Jim_String(argv[1]);
    if(pressOne(interp, keyCode) != JIM_OK) {
      return JIM_ERR;
    }
  }

  return JIM_OK;
}

/**
 * loadst [<filename>] - Load state from file
 */
static int loadstCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc > 1) {
    strncpy(_ioFileNameOverride, Jim_String(argv[1]), C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
  }

  fnLoad(LM_STATE_LOAD);
  return JIM_OK;
}

/**
 * savest [<filename>] - Save state to file
 */
static int savestCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc > 1) {
    strncpy(_ioFileNameOverride, Jim_String(argv[1]), C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
  }

  fnSave(SM_STATE_SAVE);
  return JIM_OK;
}

/**
 * impreg [<filename>] - Import a data (.d47) register file, IMPORTr with a filename override so the
 * GTK file chooser is bypassed in headless runs. Mirrors loadst.
 */
static int impregCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc > 1) {
    strncpy(_ioFileNameOverride, Jim_String(argv[1]), C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
  }

  fnLoadRegisters(NOPARAM);
  return JIM_OK;
}

/**
 * expreg <register> [<filename>] - Export one register to a data (.d47) file, EXPreg with a filename
 * override so the GTK file chooser is bypassed in headless runs. Mirrors savest; register as for reg.
 */
static int expregCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc < 2) {
    Jim_SetResultString(interp, "expreg: missing register argument", -1);
    return JIM_ERR;
  }

  uint16_t param;
  if(dslParseRegisterArg(interp, ITM_STO, Jim_String(argv[1]), &param) != JIM_OK) {
    return JIM_ERR;
  }

  if(argc > 2) {
    strncpy(_ioFileNameOverride, Jim_String(argv[2]), C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';
  }

  fnSaveRegister(param);
  return JIM_OK;
}

/**
 * tsvfnSet <path> - Set the TSV file name override
 */
static void tsvfnSet(const char *baseName) {
  snprintf(filename_csv, sizeof(filename_csv), "%s.T47.TSV", baseName);
  preventFilenameTimeout();
  clearSystemFlag(FLAG_PRTACT);
  printf("Overrode TSV file name to %s\n", filename_csv);
  fflush(stdout);
}

/**
 * tsvfnClear - Clear the TSV file name override
 */
static void tsvfnClear(void) {
  cancelFilename = true;
  filename_csv[0] = '\0';
  mem__32 = 0;
  printf("Cleared TSV file name override\n");
  fflush(stdout);
}

/**
 * snap [<basename>] - Wrap SNAP, producing basename.bmp and
 *                     basename.REGS.TSV output files.
 */
static int snapCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc > 1) {
    const char *baseName = Jim_String(argv[1]);
    char bmpFileName[C47_PATH_MAX];
    char regsPath[FILENAMELEN];

    snprintf(bmpFileName, sizeof(bmpFileName), "%s.bmp", baseName);
    strncpy(_ioFileNameOverride, bmpFileName, C47_PATH_MAX - 1);
    _ioFileNameOverride[C47_PATH_MAX - 1] = '\0';

    snprintf(regsPath, sizeof(regsPath), "%s.REGS.TSV", baseName);
    tsvfnSet(regsPath);
  }

  fnSNAP(0);
  if(argc > 1) {
    tsvfnClear();
  }

  return JIM_OK;
}

/**
 * tsvfn [<path>] - Set the TSV output file name.  Affects virtual
 * printing, stats, graphs…  With no argument: clear the override.
 */
static int tsvfnCmd(Jim_Interp *interp, int argc, Jim_Obj *const *argv) {
  if(argc > 1) {
    tsvfnSet(Jim_String(argv[1]));
  } else {
    tsvfnClear();
  }
  return JIM_OK;
}

static void reportIfDslErrorAndEnd(Jim_Interp *interp, int ret) {
  if(ret != JIM_OK) {
    const char *errorMsg = Jim_GetString(Jim_GetResult(interp), NULL);
    fprintf(stderr, "%s\n", errorMsg);
    fflush(stderr);

    // Try to get and print stack trace
    Jim_Obj *traceObj = Jim_GetVariableStr(interp, "errorInfo", 0);
    if(traceObj) {
      const char *trace = Jim_GetString(traceObj, NULL);
      fprintf(stderr, "%s\n", trace);
      fflush(stderr);
    }
  } else {
    printf("End of script.\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
    printRegisterToConsole(REGISTER_X, "Register X:", "\n");
    fflush(stdout);
  }
}

// =====================================================================
// DSL Execution - Reads a line at a time from the script and passes it
// to Jim Tcl for evaluation.
// =====================================================================

int executeScript(const char *scriptFile) {
  int ret;

  Jim_Interp *interp = g_dsl_interpreter;
  if(strcmp(scriptFile, "-") == 0) {
    ret = Jim_Eval(interp, "package require aio;"
                           "eval [info source [stdin read] stdin 1]");
  } else {
    // Read from file
    ret = Jim_EvalFile(interp, scriptFile);
  }

  reportIfDslErrorAndEnd(interp, ret);

  return ret;
}

int executeCommand(const char *command) {
  int ret;

  Jim_Interp *interp = g_dsl_interpreter;
  ret = Jim_Eval(interp, command);

  reportIfDslErrorAndEnd(interp, ret);

  return ret;
}

// =====================================================================
// DSL initialization
// =====================================================================

void initDSL(void) {
  scriptingActive = TRUE;

  // unbuffered for the DSL session so all output is visible immediately.
  setvbuf(stdout, NULL, _IONBF, 0);
  setvbuf(stderr, NULL, _IONBF, 0);

  // Create Jim interpreter
  Jim_Interp *interp = g_dsl_interpreter = Jim_CreateInterp();

  // Register core Tcl commands
  Jim_RegisterCoreCommands(interp);
  Jim_InitStaticExtensions(interp);

  // Register 🟧 CAT FCNS entries as global commands.
  char cmdName[64];
  size_t added = 0, total = 0;
  if(dumpDslCmds) {
    dslDumpFile = fopen(dslOpsFileName, "w");
    if(dslDumpFile != NULL) {
      fprintf(dslDumpFile, "C47/R47 ops registered as T47 commands\n");
      fprintf(dslDumpFile, "\n");
      fprintf(dslDumpFile, "%s\t%s\t%s\t%s\n", "nnnn", "reg", "cat", "menu");
      fprintf(dslDumpFile, "%s\t%s\t%s\t%s\n", "----", "---", "---", "----");
    }
  }
  for(int i = 0; i < LAST_ITEM; ++i) {
    item_t item = indexOfItems[i];
    if((item.status & CAT_STATUS) == CAT_FNCT) {
      ++total;
      void *idx = (void *)(intptr_t)i;
      char catName[64];
      char smName[64];
      stringToUtf8(item.itemCatalogName, (uint8_t *)catName);
      stringToUtf8(item.itemSoftmenuName, (uint8_t *)smName);
      // Pass the original internal names to registerCatFn; it converts to UTF-8 itself. The catName/smName UTF-8
      // copies above are only for the dump columns. Passing them in here would double-convert and corrupt glyphs.
      bool_t reg = registerCatFn(interp, item.itemCatalogName, idx, cmdName, FALSE);
      if(!reg) {
        reg = registerCatFn(interp, item.itemSoftmenuName, idx, cmdName, TRUE);
      }
      if(reg) {
        ++added;
        if(dslDumpFile != NULL) {
          fprintf(dslDumpFile, "%d\t%s\t%s\t%s\n", i, cmdName, catName, smName);
        }
      }
    }
  }
  if(dslDumpFile != NULL) {
    fprintf(dslDumpFile, "\nRegistered %zu of %zu possible catalog functions.\n", added, total);
    fclose(dslDumpFile);
    dslDumpFile = NULL;
    printf("Registered commands written to %s.\n", dslOpsFileName);
    fflush(stdout);
    exit(0);
  }
  printf("Registered %zu of %zu possible catalog functions for T47.\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n", added, total);
  fflush(stdout);

  // Register DSL commands afterward so that our commands having the
  // same name as catalog functions override them.
  // clang-format off
  Jim_CreateCommand(interp, "asn",    asnCmd,    NULL, NULL);
  Jim_CreateCommand(interp, "catfn",  catfnCmd,  NULL, NULL);
  Jim_CreateCommand(interp, "flag",   flagCmd,   NULL, NULL);
  Jim_CreateCommand(interp, "item",   itemCmd,   NULL, NULL);
  Jim_CreateCommand(interp, "loadst", loadstCmd, NULL, NULL);
  Jim_CreateCommand(interp, "menu",   menuCmd,   NULL, NULL);
  Jim_CreateCommand(interp, "nim",    nimCmd,    NULL, NULL);
  Jim_CreateCommand(interp, "reg",    regCmd,    NULL, NULL);
  Jim_CreateCommand(interp, "readp",  readpCmd,  NULL, NULL);
  Jim_CreateCommand(interp, "savest", savestCmd, NULL, NULL);
  Jim_CreateCommand(interp, "impreg", impregCmd, NULL, NULL);
  Jim_CreateCommand(interp, "expreg", expregCmd, NULL, NULL);
  Jim_CreateCommand(interp, "snap",   snapCmd,   NULL, NULL);
  Jim_CreateCommand(interp, "tsvfn",  tsvfnCmd,  NULL, NULL);
  Jim_CreateCommand(interp, "var",    varCmd,    NULL, NULL);
  Jim_CreateCommand(interp, "xeq",    xeqCmd,    NULL, NULL);
  Jim_CreateCommand(interp, "xportp", xportpCmd, NULL, NULL);
  // clang-format on
  if(!headlessMode) {
    // Conditionally add commands that require the GTK GUI
    Jim_CreateCommand(interp, "press", pressCmd, NULL, NULL);
  }
}

// =====================================================================
// DSL cleanup
// =====================================================================

void cleanupDSL(void) {
  if(g_dsl_interpreter) {
    Jim_FreeInterp(g_dsl_interpreter);
    g_dsl_interpreter = NULL;
  }
}

#endif
