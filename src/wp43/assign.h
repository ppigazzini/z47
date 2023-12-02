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
 * \file assign.h
 */
#if !defined(ASSIGN_H)
  #define ASSIGN_H

  #include <stdint.h>
  #include "typeDefinitions.h"

  void fnAssign                   (uint16_t mode);

  void fnDeleteMenu               (uint16_t id);

  void updateAssignTamBuffer      (void);

  void _assignItem                (userMenuItem_t *menuItem);
  void assignToMyMenu             (uint16_t position);
  void assignToMyAlpha            (uint16_t position);
  void assignToUserMenu           (uint16_t position);
  void assignToKey                (const char *data);

  void initUserKeyArgument        (void);
  void setUserKeyArgument         (uint16_t position, const char *name);
  void createMenu                 (const char *name);

  void assignEnterAlpha           (void);
  void assignLeaveAlpha           (void);
  void assignGetName1             (void);
  void assignGetName2             (void);
  
  /**
   * Remove assignments for user items
   *
   * \param[in] item         Category of user items to be removed:
   *                          - ITM_XEQ for user programs, 
   *                          - ITM_RCL for User variables, 
   *                          - -MNU_DYNAMIC for user defined menus
   *            userItemName Pointer to the item name to be removed
   *                         If the name is an empty string, all assigned items within the category will be removed
   *                         ex: ITM_XEQ, "Prog1" will remove all assignments of the program "Prog1"
   *                             ITM_XEQ, ""      will remove all assignments of all programs
   */
  void removeUserItemAssignments  (int16_t item, char *userItemName);

  /**
   * Delete all user menus and user menus assignments
   *
   */
  void deleteUserMenus            (void);
#endif // !ASSIGN_H