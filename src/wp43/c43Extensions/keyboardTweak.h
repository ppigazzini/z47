/* This file is part of WP43.
 *
 * WP43 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * WP43 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with WP43.  If not, see <http://www.gnu.org/licenses/>.
 */

/* ADDITIONAL C43 functions and routines */


/********************************************//**
 * \file keyboardTweak.h
 ***********************************************/

#if !defined(KEYBOARDTWEAK_H)
#define KEYBOARDTWEAK_H

#include "defines.h"
#include "typeDefinitions.h"
#include <stdint.h>
#if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>
#endif // PC_BUILD

//#if defined(DMCP_BUILD)
//extern uint32_t nextTimerRefresh;
//#endif // DMCP_BUILD

void     keyClick(uint8_t length);

void     showAlphaModeonGui   (void);
void     resetShiftState      (void);
void     showShiftState       (void);
void     fnSHIFTf(uint16_t unusedButMandatoryParameter);
void     fnSHIFTg(uint16_t unusedButMandatoryParameter);
void     fnSHIFTfg(uint16_t unusedButMandatoryParameter);

#if !defined(TESTSUITE_BUILD)
void     show_f_jm           (void);
void     show_g_jm           (void);
void     clear_fg_jm         (void);
void     fg_processing_jm    (void);
bool_t   Check_SigmaPlus_Assigned(int16_t  * result, int16_t tempkey);

bool_t   func_lookup         (int16_t  fn, int16_t itemShift, int16_t *funk);
void     execFnTimeout       (uint16_t key                    );                         //dr - delayed call of the primary function key
void     shiftCutoff         (uint16_t unusedButMandatoryParameter);     //dr - press shift three times within one second to call HOME timer
void     Check_MultiPresses  (int16_t  * result, int8_t key_no);
void     Setup_MultiPresses  (int16_t  result                 );
int16_t  nameFunction        (int16_t fn, bool_t shiftF, bool_t shiftG);   //JM LONGPRESS FN
void     resetKeytimers      (void);
#endif // !TESTSUITE_BUILD

uint16_t numlockReplacements(uint16_t id, int16_t item, bool_t NL, bool_t SHFT, bool_t GSHFT);
bool_t keyReplacements(int16_t item, int16_t * item1, bool_t NL, bool_t SHFT, bool_t GSHFT);

#if defined(PC_BUILD)
void     btnFnPressed_StateMachine (GtkWidget *unused, gpointer data);
void     btnFnReleased_StateMachine(GtkWidget *unused, gpointer data);
#endif // PC_BUILD


#if defined(DMCP_BUILD)
#define BUFFER_FAIL     0                                   //vv dr - internal keyBuffer POC
#define BUFFER_SUCCESS  1
#define BUFFER_MASK (BUFFER_SIZE-1) // Klammern auf keinen Fall vergessen

typedef struct {
  uint8_t   data[BUFFER_SIZE];
  #if defined(BUFFER_CLICK_DETECTION)
  uint32_t  time[BUFFER_SIZE];
  #endif // BUFFER_CLICK_DETECTION
  uint8_t   read;   // zeigt auf das Feld mit dem ältesten Inhalt
  uint8_t   write;  // zeigt immer auf leeres Feld
} kb_buffer_t;

void     keyBuffer_pop        ();
uint8_t  inKeyBuffer          (uint8_t byte);
#if defined(BUFFER_CLICK_DETECTION)
#if defined(BUFFER_KEY_COUNT)
uint8_t  outKeyBuffer         (uint8_t *pByte, uint8_t *pByteCount, uint32_t *pTime, uint32_t *pTimeSpan_1, uint32_t *pTimeSpan_B);
#else // !BUFFER_KEY_COUNT
uint8_t  outKeyBuffer         (uint8_t *pByte, uint32_t *pTime, uint32_t *pTimeSpan_1, uint32_t *pTimeSpan_B);
#endif // BUFFER_KEY_COUNT
#else // !BUFFER_CLICK_DETECTION
#if defined(BUFFER_KEY_COUNT)
uint8_t  outKeyBuffer         (uint8_t *pByte, uint8_t *pByteCount);
#else // !BUFFER_KEY_COUNT
uint8_t  outKeyBuffer         (uint8_t *pByte);
#endif // BUFFER_KEY_COUNT
#endif // BUFFER_CLICK_DETECTION
uint8_t  outKeyBufferDoubleClick();
bool_t   fullKeyBuffer        ();
bool_t   emptyKeyBuffer       ();                           //^^


void     btnFnPressed_StateMachine (void *unused, void *data);
void     btnFnReleased_StateMachine(void *unused, void *data);
#endif // DMCP_BUILD

void fnCla                   (uint16_t unusedButMandatoryParameter);
void fnCln                   (uint16_t unusedButMandatoryParameter);

void fnT_ARROW(uint16_t command);

void     refreshModeGui       (void);

#endif // !KEYBOARDTWEAK_H
