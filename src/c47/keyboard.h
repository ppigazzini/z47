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
 * \file keyboard.h
 */
#if !defined(KEYBOARD_H)
#define KEYBOARD_H

#include <stdint.h>
#if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>
#endif // PC_BUILD
#include "typeDefinitions.h"


#if !defined(TESTSUITE_BUILD)
  int16_t determineFunctionKeyItem_C47(const char *data, bool_t shiftF, bool_t shiftG);
#endif // !TESTSUITE_BUILD


void leavePem        (void);
void showShiftState  (void);
void processKeyAction(int16_t item);

/**
 * Processing ENTER key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyEnter      (uint16_t unusedButMandatoryParameter);

/**
 * Processing EXIT key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyExit       (uint16_t unusedButMandatoryParameter);

/**
 * Processing CC key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyCC         (uint16_t unusedButMandatoryParameter);

/**
 * Processing BACKSPACE key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyBackspace  (uint16_t unusedButMandatoryParameter);

/**
 * Processing UP key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyUp         (uint16_t unusedButMandatoryParameter);

/**
 * Processing DOWN key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyDown       (uint16_t unusedButMandatoryParameter);

/**
 * Processing .d key.
 *
 * \param[in] unusedButMandatoryParameter
 */
void fnKeyDotD       (uint16_t unusedButMandatoryParameter);

void executeFunction(const char *data, int16_t item_);

#define ST_0_INIT     0     //STATE 0 INIT             //JM vv FN-DOUBLE
#define ST_1_PRESS1   1     //STATE 1 FIRST PRESS
#define ST_2_REL1     2     //STATE 2 FIRST RELEASE
#define ST_3_PRESS2   3     //STATE 3 SECOND PRESS     //Double click determination 2 to 3 < 75 ms.
#define ST_4_REL2     4     //STATE 4 SECOND RELEASE   //JM ^^


  #if defined(PC_BUILD)
/**
   * Simulate a function key click.
   *
   * \param notUsed The button to pass to btnFnPressed and btnFnReleased
   * \param data String containing the key ID
   */
  void btnFnClicked  (GtkWidget *notUsed, gpointer data);
  void btnFnClickedP (GtkWidget *notUsed, gpointer data);                     //JM
  void btnFnClickedR (GtkWidget *notUsed, gpointer data);                     //JM
  /**
   * A calc function key was pressed.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void btnFnPressed  (GtkWidget *notUsed, GdkEvent *event, gpointer data);

  /**
   * A calc function key was released.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void btnFnReleased (GtkWidget *notUsed, GdkEvent *event, gpointer data);

  /**
   * Simulate a button click.
   *
   * \param notUsed The button to pass to btnPressed and btnReleased
   * \param data String containing the key ID
   */
  void btnClicked    (GtkWidget *notUsed, gpointer data);
  void btnClickedP   (GtkWidget *notUsed, gpointer data);                     //JM
  void btnClickedR   (GtkWidget *notUsed, gpointer data);                     //JM
  /**
   * A calc button was pressed.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void btnPressed    (GtkWidget *notUsed, GdkEvent *event, gpointer data);

  /**
   * A calc button was released.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void frmCalcMouseButtonPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data);

  /**
   * A calc button was pressed.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void frmCalcMouseButtonReleased(GtkWidget *notUsed, GdkEvent *event, gpointer data);

  /**
   * A calc button was released.
   *
   * \param notUsed
   * \param data pointer to a string containing the key number pressed: 00=1/x, ..., 36=EXIT
   */
  void btnReleased   (GtkWidget *notUsed, GdkEvent *event, gpointer data);
#endif // PC_BUILD

void execAutoRepeat(uint16_t key);

  #if defined(DMCP_BUILD)
  void btnFnClicked (void *w, void *data);
  void btnFnPressed (void *data);
  void btnFnReleased(void *data);
  void btnClicked   (void *w, void *data);
  void btnPressed   (void *data);
  void btnReleased  (void *data);
  #endif // DMCP_BUILD

void setLastKeyCode  (int key);
#endif // !KEYBOARD_H
