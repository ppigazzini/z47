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

/**
 * \file softmenus.h
 * List of softmenus and related functions.
 */
#if !defined(SOFTMENUS_H)
#define SOFTMENUS_H

#include "defines.h"
#include "typeDefinitions.h"
#include <stdint.h>

int16_t currentMenu(void);


uint8_t *getNthString           (uint8_t *ptr, int16_t n); // Starting with string 0 (the 1st string is returned for n=0)
void     fnDynamicMenu          (uint16_t unusedButMandatoryParameter);

void     fnExitAllMenus         (uint16_t unusedButMandatoryParameter);
  #if !defined(TESTSUITE_BUILD)
  /**
   * Displays one softkey.
   *
   * \param[in] label      Text to display
   * \param[in] xSoftkey   x location of softkey: from 0 (left) to 5 (right)
   * \param[in] ySoftKey   y location of softkey: from 0 (bottom) to 2 (top)
   * \param[in] videoMode  Video mode normal or reverse
   * \param[in] topLine    Draw a top line
   * \param[in] bottomLine Draw a bottom line
   */

  bool_t maxfgLines             (int16_t y);
  void   showSoftkey            (const char *label, int16_t xSoftkey, int16_t ySoftKey, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText);     //dr);
  void   showKey                (const char *label, int16_t x1, int16_t x2, int16_t y1, int16_t y2, bool_t rightMostSlot, videoMode_t videoMode, bool_t topLine, bool_t bottomLine, int8_t showCb, int16_t showValue, const char *showText);
  void   greyOutBox             (int16_t x1, int16_t x2, int16_t y1, int16_t y2);

/**
   * Displays the current part of the displayed softmenu.
   */
  bool_t isFunctionItemAMenu(int16_t item);
  void   showSoftmenuCurrentPart(void);

  /**
   * Displays a softmenu.
   *
   * \param[in] id ID of softmenu
   */
  void   showSoftmenu           (int16_t id);
  void   changeToALPHA(void);
  void   changeToHOME(void);
  void   changeToPFN(void);

  bool_t setCurrentUserMenu     (int16_t item, char* funcParam);
  bool_t createHOME(void);
  bool_t createPFN(void);

  /**
   * Pops a softmenu from the softmenu stack.
   */
  void   popSoftmenu            (void);

  void   setCatalogLastPos      (void);
  bool_t currentSoftmenuScrolls (void);
  bool_t isAlphabeticSoftmenu   (void);
  bool_t isJMAlphaSoftmenu      (int16_t menuId);             //JM
  bool_t isJMAlphaOnlySoftmenu  (void);                       //JM

  int16_t mm(int16_t id);                                     //JM
  extern TO_QSPI const int16_t menu_HOME[];                //JM

#endif // !TESTSUITE_BUILD
void   fnBaseMenu               (uint16_t unusedButMandatoryParameter);
char    *dynmenuGetLabel        (int16_t menuitem);
char    *dynmenuGetLabelWithDup (int16_t menuitem, int16_t *dupNum);
void    fnDumpMenus            (uint16_t unusedButMandatoryParameter);  //JM
extern  bool_t BASE_OVERRIDEONCE;
#endif // !SOFTMENUS_H
