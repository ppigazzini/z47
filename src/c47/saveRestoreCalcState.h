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
 * \file saveRestoreCalcState.h
 */
#if !defined(SAVERESTORECALCSTATE_H)
  #define SAVERESTORECALCSTATE_H

  #include <stdint.h>

  #define autoLoad   0
  #define manualLoad 1
  #define stateLoad  2
  #define autoSave   3
  #define manualSave 4
  #define stateSave  5

  #if defined(PC_BUILD) || defined(DMCP_BUILD)
    void   saveCalc      (void);
    void   restoreCalc   (void);
  #endif // PC_BUILD || DMCP_BUILD

  void     fnSave        (uint16_t unusedButMandatoryParameter);
  void     fnLoad        (uint16_t loadMode);
  void     fnSaveAuto    (void);
  void     fnLoadAuto    (void);
  void     fnLoadedFile  (uint16_t unusedButMandatoryParameter);
  uint8_t  stringToUint8 (const char *str);
  uint16_t stringToUint16(const char *str);
  uint32_t stringToUint32(const char *str);
  uint64_t stringToUint64(const char *str);
  int8_t   stringToInt8  (const char *str);
  int16_t  stringToInt16 (const char *str);
  int32_t  stringToInt32 (const char *str);
  int64_t  stringToInt64 (const char *str);
  float    stringToFloat (const char *str);
  double   stringToDouble(const char *str);

  void     readLine      (char *line);

  void     doLoad        (uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, uint16_t loadType);

  void     fnDeleteBackup(uint16_t confirmation);

#endif // !SAVERESTORECALCSTATE_H
