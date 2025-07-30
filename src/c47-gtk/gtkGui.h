// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file gtkGui.h
 */

#if !defined(GTKGUI_H)
  #define GTKGUI_H

#if !defined(TESTSUITE_BUILD)
  void btn_Clicked_Gen(bool_t shF, bool_t shG, char *st);
  void fnOff                       (uint16_t unsuedParamButMandatory);
  
  void check_all_btn_widgets_for_consistency();

  /**
   * Sets the calc mode to normal.
   */
  void calcModeNormal              (void);

  /**
   * Sets the calc mode to alpha input mode.
   *
   * \param[in] unusedButMandatoryParameter
   */
  void calcModeAim                 (uint16_t unusedButMandatoryParameter);

  /**
   * Sets the calc mode to number input mode.
   *
   * \param[in] unusedButMandatoryParameter
   */
  void calcModeNim                 (uint16_t unusedButMandatoryParameter);

  /**
   * Sets the calc mode to alpha selection menu if needed.
   */
  void enterAsmModeIfMenuIsACatalog(int16_t id);

  /**
   * Leaves the alpha selection mode.
   */
  void leaveAsmMode                (void);
  #endif // !TESTSUITE_BUILD

  #if defined(PC_BUILD)
    extern char modelString[50];
    extern bool_t enableFunctionKeysDisplay;
  /**
   * \struct gdkKeyMap_t
   * Structure keeping the mapping between character items and GDK_KEY values.
   */
  typedef struct {
    int16_t   item;
    uint32_t  gdkKey;
  } gdkKeyMap_t;

  /**
   * \struct deadKeys_t
   * Structure keeping the mapping between character items and their equivalent when dead keys are used.
   */
  typedef struct {
    int16_t   item;
    int16_t   item_macron;
    int16_t   item_acute;
    int16_t   item_breve;
    int16_t   item_grave;
    int16_t   item_diaresis;
    int16_t   item_tilde;
    int16_t   item_circ;
    int16_t   item_caron;
    int16_t   item_ogonek;
    int16_t   item_ring;
    int16_t   item_cedilla;
    int16_t   item_stroke;
    int16_t   item_dot;
  }   deadKeysMap_t;
    /**
     * Creates the calc's GUI window with all the widgets.
     */
    void     setupUI                     (void);
  #endif // PC_BUILD

#endif // !GTKGUI_H
