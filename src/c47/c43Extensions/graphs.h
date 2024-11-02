/* This file is part of C47.
 *
 * W43 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * C47 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with C47.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//** //JM
 * \file graph.c Graphing module
 ***********************************************/

/* ADDITIONAL C43 functions and routines */

//graphs.h

#if !defined(GRAPHS_H)
#define GRAPHS_H

#include "typeDefinitions.h"
#include <stdint.h>

//Graph functions
void    graph_reset        (void);
void    fnClGrf            (uint16_t unusedButMandatoryParameter);
void    fnPline            (uint16_t unusedButMandatoryParameter);
void    fnPcros            (uint16_t unusedButMandatoryParameter);
void    fnPbox             (uint16_t unusedButMandatoryParameter);
void    fnPintg            (uint16_t unusedButMandatoryParameter);
void    fnPdiff            (uint16_t unusedButMandatoryParameter);
void    fnPrms             (uint16_t unusedButMandatoryParameter);
void    fnPvect            (uint16_t unusedButMandatoryParameter);
void    fnPNvect           (uint16_t unusedButMandatoryParameter);
void    fnScale            (uint16_t unusedButMandatoryParameter);
void    fnPshade           (uint16_t unusedButMandatoryParameter);
void    fnComplexPlot      (uint16_t unusedButMandatoryParameter);
void    fnPMzoom           (uint16_t param);
void    fnPx               (uint16_t unusedButMandatoryParameter);
void    fnPy               (uint16_t unusedButMandatoryParameter);
void    fnListXY           (uint16_t unusedButMandatoryParameter);
void    fnStatList         (void);
void    graph_plotmem      (void);
void    fnPlotSQ           (uint16_t unusedButMandatoryParameter);
void    fnPlotReset        (uint16_t unusedButMandatoryParameter);
void    fnPlotStatAdv      (uint16_t unusedButMandatoryParameter);

#define plotstat true
void graphResetCommon      (void);
void graph_Include0        (bool_t mode,  uint16_t statnum); //using global: extentx, x_min, x_max, extenty, y_min, y_max
extern  bool_t   extentx;
extern  bool_t   extenty;
extern  float    x_min;
extern  float    x_max;
extern  float    y_min;
extern  float    y_max;
extern  bool_t   PLOT_SCALE;
extern  int8_t   PLOT_ZMY;


#endif // !GRAPHS_H
