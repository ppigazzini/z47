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
 * \file sort.h
 * Comparing 2 strings, sorting strings.
 */
#if !defined(SORT_H)
  #define SORT_H

  #include <stdint.h>

  int32_t compareChar  (const char *char1, const char *char2);
  int32_t compareString(const char *stra, const char *strb, int32_t comparisonType);
#endif // !SORT_H
