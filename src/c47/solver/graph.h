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

/********************************************//** //JM
 * \file jmgraph.c Graphing module
 ***********************************************/


#if !defined(GRAPH_H)
#define GRAPH_H

#include "typeDefinitions.h"
#include <stdint.h>

extern char plotStatMx[8];

#define EQ_SOLVE 0   //fnEqSolvGraph
#define EQ_PLOT  1   //graph_eqn

void    fnEqSolvGraph (uint16_t func);
void    graph_eqn(uint16_t unusedButMandatoryParameter);
void    graph_stat(uint16_t unusedButMandatoryParameter);
int32_t drawMxN(void);
void    fnClDrawMx(void);
#endif // !GRAPH_H
