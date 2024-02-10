/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */
#if !defined(DEBUG_H)
#define DEBUG_H

#include "defines.h"
#include "realType.h"
#include "typeDefinitions.h"
#include <stdint.h>
  #if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>
  #endif // PC_BUILD

#if(DEBUG_PANEL == 1)
  extern GtkWidget *lbl1[DEBUG_LINES], *lbl2[DEBUG_LINES];
  extern GtkWidget *btnBitFields, *btnFlags, *btnRegisters, *btnLocalRegisters, *btnTmpAndSavedStackRegisters;
  extern GtkWidget *chkHexaString;
  extern int16_t debugWidgetDx, debugWidgetDy;

  void   btnBitFieldsClicked          (GtkWidget* w ,gpointer data);
  void   btnFlagsClicked              (GtkWidget* w ,gpointer data);
  void   btnRegistersClicked          (GtkWidget* w ,gpointer data);
  void   btnLocalRegistersClicked     (GtkWidget* w ,gpointer data);
  void   btnStatisticalSumsClicked    (GtkWidget* w ,gpointer data);
  void   btnNamedVariablesClicked     (GtkWidget* w ,gpointer data);
  void   btnSavedStackRegistersClicked(GtkWidget* w ,gpointer data);
  void   chkHexaStringClicked         (GtkWidget* w ,gpointer data);
  void   refreshDebugPanel            (void);

  char * getDisplayFormatName               (uint16_t df);
  char * getTimeFormatName                  (bool_t tf);
  char * getDateFormatName                  (uint16_t df);
  char * getBooleanName                     (bool_t b);
  char * getRbrModeName                     (uint16_t mode);
  char * getRoundingModeName                (uint16_t rm);
  char * getCalcModeName                    (uint16_t cm);
  char * getNextCharName                    (uint16_t nc);
  char * getComplexUnitName                 (bool_t cu);
  char * getProductSignName                 (bool_t ps);
  char * getFractionTypeName                (bool_t ft);
  char * getFractionDenom1ModeName          (bool_t ft);
  char * getFractionDenom2ModeName          (bool_t ft);
  char * getRadixMarkName                   (bool_t rm);
  char * getDisplayOvrName                  (bool_t dio);
  char * getStackSizeName                   (bool_t ss);
  char * getComplexModeName                 (bool_t cm);
  char * getAlphaCaseName                   (uint16_t ac);
  char * getAlphaSelectionMenuName          (uint16_t alsm);
  char * getCursorFontName                  (uint16_t cf);
  char * getSystemFlagName                  (uint16_t sf);
  void   memoryDump                         (bool_t bitFields, bool_t globalFlags, bool_t globalRegisters, bool_t localFlags, bool_t FIRSTLOCALREGISTERs, bool_t otherVars);
#endif // (DEBUG_PANEL == 1)

#if(DEBUG_PANEL == 1) || (DEBUG_REGISTER_L == 1) || (DEBUG_STAT >= 1)
  void   formatReal34Debug                  (char *str, real34_t *real34);
  void   formatRealDebug                    (char *str, real_t *real);
  void   formatComplex34Debug               (char *str, void *addr);
#endif // (DEBUG_PANEL == 1) || (DEBUG_REGISTER_L == 1)  || (DEBUG_STAT >= 1)

const char *getDataTypeName               (uint16_t dt, bool_t article, bool_t padWithBlanks);
const char *getRegisterDataTypeName       (calcRegister_t regist, bool_t article, bool_t padWithBlanks);
const char *getRegisterTagName            (calcRegister_t regist, bool_t padWithBlanks);
const char *getShortIntegerModeName       (uint16_t im);
const char *getAngularModeName            (angularMode_t angularMode);
const char *getCurveFitModeName           (uint16_t selection);
const char *getCurveFitModeNames          (uint16_t selection);
const char *getCurveFitModeFormula        (uint16_t selection);
char *eatSpacesEnd                        (const char * ss);
char *eatSpacesMid                        (const char * ss);

//void  debugNIM                            (void); Never used

  #if defined(PC_BUILD)
  void dumpScreenToConsole(void);
  #endif // PC_BUILD

#if defined(PC_BUILD) || defined(TESTSUITE_BUILD)
  void testRegisters    (const char *text);
  void memoryDump2      (const char *text);
  void stackCheck       (const unsigned char *begin, const unsigned char *end, int size, const char *where);
  void initStackCheck   (unsigned char *begin, unsigned char *end, int size);
  void stackSmashingTest(void);
#endif // PC_BUILD || TESTSUITE_BUILD
#endif // !DEBUG_H
