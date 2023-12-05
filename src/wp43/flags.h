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

/********************************************//**
 * \file flags.h
 ***********************************************/
#if !defined(FLAGS_H)
  #define FLAGS_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  void   synchronizeLetteredFlags(void);
  bool_t getFlag                 (uint16_t flag);
  void   fnGetSystemFlag         (uint16_t systemFlag);
  void   fnSetFlag               (uint16_t flag);
  void   fnClearFlag             (uint16_t flag);
  void   fnFlipFlag              (uint16_t flag);
  void   fnClFAll                (uint16_t confirmation);
  void   fnIsFlagClear           (uint16_t flag);
  void   fnIsFlagSet             (uint16_t flag);
  void   fnIsFlagClearClear      (uint16_t flag);
  void   fnIsFlagSetClear        (uint16_t flag);
  void   fnIsFlagClearSet        (uint16_t flag);
  void   fnIsFlagSetSet          (uint16_t flag);
  void   fnIsFlagClearFlip       (uint16_t flag);
  void   fnIsFlagSetFlip         (uint16_t flag);
  void   fnIsFlagSetFlip         (uint16_t flag);
  void   SetSetting              (uint16_t jmConfig);

  void setSystemFlag(unsigned int sf);
  void clearSystemFlag(unsigned int sf);
  void flipSystemFlag(unsigned int sf);
  void forceSystemFlag(unsigned int sf, int v);

#endif // !FLAGS_H
