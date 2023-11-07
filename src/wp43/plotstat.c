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

#include "plotstat.h"

#include "c43Extensions/addons.h"
#include "charString.h"
#include "constantPointers.h"
#include "config.h"
#include "curveFitting.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "keyboard.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/variance.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/graph.h"
#include "stack.h"
#include "stats.h"
#include "statusBar.h"
#include <math.h>
#include <string.h>
#include <time.h>

#include "wp43.h"


void fnPlotRegressionLine(uint16_t plotMode);



// This module originates and is part of the C43 fork, and is copied here.
// Do not change the shared functions otherwise the C43 fork will break. JM 2021-03-20

#if !defined(TESTSUITE_BUILD)
  static real_t RR,SMI,aa0,aa1,aa2,sa0, sa1; //L.R. variables
  static void drawline(uint16_t selection, real_t *RR, real_t *SMI, real_t *aa0, real_t *aa1, real_t *aa2, real_t *sa0, real_t *sa1);
#endif // !TESTSUITE_BUILD




float     graph_dx;           // Many unused functions in WP43. Do not change the variables.
float     graph_dy;
bool_t    roundedTicks;
bool_t    extentx;
bool_t    extenty;
bool_t    PLOT_VECT;
bool_t    PLOT_NVECT;
bool_t    PLOT_SCALE;
bool_t    Aspect_Square;
bool_t    PLOT_LINE;
bool_t    PLOT_CROSS;
bool_t    PLOT_BOX;
bool_t    PLOT_INTG;
bool_t    PLOT_DIFF;
bool_t    PLOT_RMS;
bool_t    PLOT_SHADE;
bool_t    PLOT_AXIS;
int8_t    PLOT_ZMX;
int8_t    PLOT_ZMY;
uint8_t   PLOT_ZOOM;
uint8_t   drawHistogram;

int8_t    plotmode;
float     tick_int_x;
float     tick_int_y;
float     x_min = 0;
float     x_max = 1;
float     y_min = 0;
float     y_max = 1;
uint32_t  xzero;
uint32_t  yzero;




void statGraphReset(void){
  graph_dx      = 0;
  graph_dy      = 0;
  roundedTicks  = true;
  extentx       = true;
  extenty       = true;
  PLOT_VECT     = false;
  PLOT_NVECT    = false;
  PLOT_SCALE    = false;
  Aspect_Square = true;
  PLOT_LINE     = false;
  PLOT_CROSS    = false;
  PLOT_BOX      = true;
  PLOT_INTG     = false;
  PLOT_DIFF     = false;
  PLOT_RMS      = false;
  PLOT_SHADE    = false;
  PLOT_AXIS     = false;
  PLOT_ZMX      = 0;
  PLOT_ZMY      = 0;
  PLOT_ZOOM     = 0;

  plotmode      = _SCAT;      //VECTOR or SCATTER
  tick_int_x    = 0;          //to show axis: tick_in_x & y = 10, PLOT_AXIS = true
  tick_int_y    = 0;
  y_min         = 0;
  y_max         = 1;
}


#if !defined(TESTSUITE_BUILD)
  float grf_x(int i) {
    if(keyWaiting()) {
       return 0;
    }
    float xf=0;
    real_t xr;

    calcRegister_t regStats = findNamedVariable(plotStatMx);
    if(regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t cols = stats.header.matrixColumns;
      real34ToReal(&stats.matrixElements[i * cols    ], &xr);
      realToFloat(&xr, &xf);
    }
    else {
      xf = 0;
    }
    return xf;
  }


  float grf_y(int i) {
    if(keyWaiting()) {
       return 0;
    }
    float yf=0;
    real_t yr;

    calcRegister_t regStats = findNamedVariable(plotStatMx);
    if(regStats != INVALID_VARIABLE) {
      real34Matrix_t stats;
      linkToRealMatrixRegister(regStats, &stats);
      const uint16_t cols = stats.header.matrixColumns;
      real34ToReal(&stats.matrixElements[i * cols + 1], &yr);
      realToFloat(&yr, &yf);
    }
    else {
      yf = 0;
    }
    return yf;
  }


  int16_t screen_window_x(float x_min, float x, float x_max) {
    int16_t temp; float tempr;

    if(Aspect_Square) {
      tempr = ((x - x_min) / (x_max - x_min) * (float)(SCREEN_HEIGHT_GRAPH - 1));
      if(tempr > 32766) {
        temp = 32767;
      }
      else {
        if(tempr < -32766) {
          temp = -32767;
        }
        else {
          temp = (int16_t) tempr;
        }
      }
      if(temp > SCREEN_HEIGHT_GRAPH-1) {
        temp = SCREEN_HEIGHT_GRAPH-1;
      }
      else if(temp < 0) {
        temp = 0;
      }
      return temp + SCREEN_WIDTH - SCREEN_HEIGHT_GRAPH;
    }
    else {  //FULL SCREEN
      tempr = ((x-x_min)/(x_max-x_min)*(float)(SCREEN_WIDTH_GRAPH-1));
      if(tempr > 32766) {
        temp = 32767;
      }
      else if(tempr < -32766) {
        temp = -32767;
      }
      else {
        temp = (int16_t) tempr;
      }
      //printf("--> %d (%f %f)  ",temp, x_min,x_max);
      if(temp > SCREEN_WIDTH_GRAPH - 1) {
        temp = SCREEN_WIDTH_GRAPH - 1;
      }
      else if(temp < 0) {
        temp = 0;
      }
      //printf("--> %d \n",temp);
      #if defined(PC_BUILD)
        if(temp<0 || temp>399) {
          printf("In function screen_window_x X EXCEEDED %d",temp);
        }
      #endif // PC_BUILD
      return temp;
    }
  }


  int16_t screen_window_y(float y_min, float y, float y_max) {
    int16_t temp, minn;
    float tempr;

    if(!Aspect_Square) {
      minn = SCREEN_NONSQ_HMIN;
    }
    else {
      minn = 0;
    }

    tempr = ((y - y_min) / (y_max - y_min) * (float)(SCREEN_HEIGHT_GRAPH - 1 - minn));
    if(tempr > 32766) {
      temp = 32767;
    }
    else {
      if(tempr < -32766) {
        temp = -32767;
      }
      else {
        temp = (int16_t) tempr;
      }
    }
    if(temp > SCREEN_HEIGHT_GRAPH - 1 - minn) {
      temp = SCREEN_HEIGHT_GRAPH - 1 - minn;
    }
    else if(temp < 0) {
      temp=0;
    }

    #if defined(PC_BUILD)
      if(SCREEN_HEIGHT_GRAPH-1 - temp<0 || SCREEN_HEIGHT_GRAPH-1 - temp>239) {
        printf("In function screen_window_y Y EXCEEDED %d %d",temp,SCREEN_HEIGHT_GRAPH-1 - temp);
      }
    #endif
    return (SCREEN_HEIGHT_GRAPH - 1 - temp);
  }
#endif // !TESTSUITE_BUILD


void placePixel(uint32_t x, uint32_t y) {
  #if !defined(TESTSUITE_BUILD)
  uint32_t minn;

  if(!Aspect_Square) {
    minn = SCREEN_NONSQ_HMIN;
  }
  else {
    minn = 0;
  }

  if(x < SCREEN_WIDTH_GRAPH && y < SCREEN_HEIGHT_GRAPH && y >= 1 + minn) {
    setBlackPixel(x, y);
  }
#endif //!TESTSUITE_BUILD
}


void removePixel(uint32_t x, uint32_t y) {
  #if !defined(TESTSUITE_BUILD)
  uint32_t minn;

  if(!Aspect_Square) {
    minn = SCREEN_NONSQ_HMIN;
  }
  else {
    minn = 0;
  }

  if(x < SCREEN_WIDTH_GRAPH && y < SCREEN_HEIGHT_GRAPH && y >= 1 + minn) {
    setWhitePixel(x, y);
  }
#endif //!TESTSUITE_BUILD
}


void clearScreenPixels(void) {
  #if !defined(TESTSUITE_BUILD)
  if(Aspect_Square) {
    lcd_fill_rect(SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH, 0, SCREEN_HEIGHT_GRAPH, SCREEN_HEIGHT_GRAPH, 0);
    lcd_fill_rect(0, Y_POSITION_OF_REGISTER_T_LINE, SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH, 171-5-Y_POSITION_OF_REGISTER_T_LINE+1, 0);
    lcd_fill_rect(19, 171-5, SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH-19+1, 5, 0);
  }
  else {
    lcd_fill_rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT_GRAPH, 0);
  }
#endif //!TESTSUITE_BUILD
}


#if !defined(TESTSUITE_BUILD)
void plotcross(uint16_t xn, uint8_t yn) {              // Plots line from xo,yo to xn,yn; uses temporary x1,y1
  plotline(max((int16_t)xn-2,0),max((int16_t)yn-2,0),xn+2,yn+2);                       //   PLOT a cross
  plotline(max((int16_t)xn-2,0),yn+2,xn+2,max((int16_t)yn-2,0));
}


void plotbox(uint16_t xn, uint8_t yn) {                // Plots line from xo,yo to xn,yn; uses temporary x1,y1
  plotline  (max((int16_t)xn-2,0),max((int16_t)yn-2,0),max((int16_t)xn-2,0),max((int16_t)yn-1,0));                       //   PLOT a box
  placePixel(max((int16_t)xn-1,0),max((int16_t)yn-2,0));
  plotline  (max((int16_t)xn-2,0),yn+2,max((int16_t)xn-2,0),yn+1);
  placePixel(max((int16_t)xn-1,0),yn+2);
  plotline  (xn+2,max((int16_t)yn-2,0),xn+1,max((int16_t)yn-2,0));
  placePixel(xn+2,max((int16_t)yn-1,0));
  plotline  (xn+2,yn+2,xn+2,yn+1);
  placePixel(xn+1,yn+2);
}


void plotrect(uint16_t a, uint8_t b, uint16_t c, uint8_t d) {                // Plots rectangle from xo,yo to xn,yn; uses temporary x1,y1
  plotline(a, b, c, b);
  plotline(a, b, a, d);
  plotline(c, d, c, b);
  plotline(c, d, a, d);
}


#if !defined(SAVE_SPACE_DM42_13GRF)
  static void plotHisto_col(uint16_t x, uint16_t y, uint16_t y_min, uint16_t y_wid, int16_t colw) {  //x is 0..(n-1)
    plotrect(max((int16_t)x - colw,0), y_min + y_wid,  x + colw, y);
    }
#endif //SAVE_SPACE_DM42_13GRF



void plotbox_fat(uint16_t xn, uint8_t yn) {                                         // Plots line from xo,yo to xn,yn; uses temporary x1,y1
  plotrect(max((int16_t)xn-3,0),max((int16_t)yn-3,0),xn+3,yn+3);
  plotrect(max((int16_t)xn-2,0),max((int16_t)yn-2,0),xn+2,yn+2);
}
#endif //!TESTSUITE_BUILD


void plotline(uint16_t xo, uint8_t yo, uint16_t xn, uint8_t yn) {                   // Plots line from xo,yo to xn,yn; uses temporary x1,y1
   pixelline(xo,yo,xn,yn,1);
 }

void plotline2(uint16_t xo, uint8_t yo, uint16_t xn, uint8_t yn) {                   // Plots line from xo,yo to xn,yn; uses temporary x1,y1
   pixelline(xo,yo,xn,yn,1);
   pixelline(max((int16_t)xo-1,0),yo,max((int16_t)xn-1,0),yn,1);
   pixelline(xo,max((int16_t)yo-1,0),xn,max((int16_t)yn-1,0),1);
   //   pixelline(xo+1,yo,xn+1,yn,1);   //Do not use the full doubling, without it give as nice profile if the slope changes
   //   pixelline(xo,yo+1,xn,yn+1,1);
 }


//Exhange the name of this routine with pixelline() above to try Bresenham
void pixelline(uint16_t xo, uint8_t yo, uint16_t xn, uint8_t yn, bool_t vmNormal) { // Plots line from xo,yo to xn,yn; uses temporary x1,y1
  #if defined(STATDEBUG_VERBOSE) && defined(PC_BUILD)
    printf("pixelline: xo,yo,xn,yn: %d %d   %d %d \n",xo,yo,xn,yn);
  #endif // STATDEBUG_VERBOSE && PC_BUILD

  //Bresenham line drawing: Pauli's link. Also here: http://forum.6502.org/viewtopic.php?f=10&t=2247&start=555
  int dx =  abs((int)(xn) - (int)(xo)), sx = (xo < xn ? 1 : -1);
  int dy = -abs((int)(yn) - (int)(yo)), sy = (yo < yn ? 1 : -1);
  int err = dx + dy, e2; /* error value e_xy */

  for(;;) {
    if(vmNormal) {
      placePixel(xo, yo);
    }
    else {
      removePixel(xo, yo);
    }
    if(xo==xn && yo==yn) {
      break;
    }
    e2 = 2*err;
    if(e2 >= dy) { /* e_xy+e_x > 0 */
      err += dy;
      xo += sx;
    }
    if(e2 <= dx) { /* e_xy+e_y < 0 */
      err += dx;
      yo += sy;
    }
  }
}



void graphAxisDraw (void){
#if !defined(SAVE_SPACE_DM42_13GRF)
  #if !defined(TESTSUITE_BUILD)
    if(x_min <= FLoatingMin || x_min >= FLoatingMax || x_max <= FLoatingMin || x_max >= FLoatingMax || y_min <= FLoatingMin || y_min >= FLoatingMax || y_max <= FLoatingMin || y_max >= FLoatingMax) {
      return;
    }
  uint32_t cnt;

  clearScreenPixels();
  //GRAPH ZERO AXIS
  yzero = screen_window_y(y_min,0,y_max);
  xzero = screen_window_x(x_min,0,x_max);

  uint32_t minnx, minny;
  if(!Aspect_Square) {
    minny = SCREEN_NONSQ_HMIN;
    minnx = 0;
  }
  else {
    minny = 0;
    minnx = SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH;
  }


  //SEPARATING LINE IF SQUARE
  cnt = minny;
  while(cnt!=SCREEN_HEIGHT_GRAPH) {
    if(Aspect_Square) {
        setBlackPixel(minnx-1,cnt);
        setBlackPixel(minnx-2,cnt);
    }
    cnt++;
  }

    #if defined(STATDEBUG) && defined(PC_BUILD)
    printf("xzero=%d yzero=%d   \n",(int)xzero,(int)yzero);
    #endif // STATDEBUG && PC_BUILD

  float x;
  float y;

  if( PLOT_AXIS && !(yzero == SCREEN_HEIGHT_GRAPH-1 || yzero == minny)) {
    //DRAW XAXIS
    if(Aspect_Square) {
      cnt = minnx;
    }
    else {
      cnt = 0;
    }

    while(cnt != SCREEN_WIDTH_GRAPH - 1) {
      setBlackPixel(cnt,yzero);
        #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("cnt=%d   \n",(int)cnt);
        #endif // STATDEBUG && PC_BUILD
      cnt++;
    }

   force_refresh(timed);

   if(0<x_max && 0>x_min) {
     for(x=0; x<=x_max; x+=tick_int_x) {                         //draw x ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
         printf(">> x=%d   \n",(int)x);
          #endif // STATDEBUG && PC_BUILD
       cnt = screen_window_x(x_min,x,x_max);
       //printf(">>>>>A %f %d ",x,cnt);
       setBlackPixel(cnt,min(yzero+1,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-1,minny));                    //tick
     }
     for(x=0; x>=x_min; x+=-tick_int_x) {                        //draw x ticks
       cnt = screen_window_x(x_min,x,x_max);
       //printf(">>>>>B %f %d ",x,cnt);
       setBlackPixel(cnt,min(yzero+1,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-1,minny));                    //tick
     }
     for(x=0; x<=x_max; x+=tick_int_x*5) {                       //draw x ticks
       cnt = screen_window_x(x_min,x,x_max);
       setBlackPixel(cnt,min(yzero+2,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-2,minny));                    //tick
       setBlackPixel(cnt,min(yzero+3,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-3,minny));                    //tick
     }
     for(x=0; x>=x_min; x+=-tick_int_x*5) {                      //draw x ticks
       cnt = screen_window_x(x_min,x,x_max);
       setBlackPixel(cnt,min(yzero+2,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-2,minny));                    //tick
       setBlackPixel(cnt,min(yzero+3,SCREEN_HEIGHT_GRAPH-1));    //tick
       setBlackPixel(cnt,max(yzero-3,minny));                    //tick
     }
   }
   else {
     for(x=x_min; x<=x_max; x+=tick_int_x) {                     //draw x ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>x=%d   \n",(int)x);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_x(x_min,x,x_max);
        //printf(">>>>>A %f %d ",x,cnt);
          setBlackPixel(cnt,min(yzero+1,SCREEN_HEIGHT_GRAPH-1)); //tick
          setBlackPixel(cnt,max(yzero-1,minny));                 //tick
       }
      for(x=x_min; x<=x_max; x+=tick_int_x*5) {                  //draw x ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>>x=%d   \n",(int)x);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_x(x_min,x,x_max);
          setBlackPixel(cnt,min(yzero+2,SCREEN_HEIGHT_GRAPH-1)); //tick
          setBlackPixel(cnt,max(yzero-2,minny));                 //tick
          setBlackPixel(cnt,min(yzero+3,SCREEN_HEIGHT_GRAPH-1)); //tick
          setBlackPixel(cnt,max(yzero-3,minny));                 //tick
       }
     }
   }

  if( PLOT_AXIS && !(xzero == SCREEN_WIDTH-1 || xzero == minnx)) {
    //Write North arrow
    if(PLOT_NVECT) {
      char tmpString2[100];
      showString("N", &standardFont, xzero-4, minny+14, vmNormal, true, true);
      showString("x", &standardFont, xzero-4, minny+28, vmNormal, true, true);
      tmpString2[0]=(char)((uint8_t)0x80 | (uint8_t)0x22);
      tmpString2[1]=0x06;
      tmpString2[2]=0;
      showString(tmpString2, &standardFont, xzero-4, minny+0, vmNormal, true, true);
    }

    //DRAW YAXIS
    lcd_fill_rect(xzero,minny,1,SCREEN_HEIGHT_GRAPH-minny,0xFF);

    force_refresh(timed);
    if(0<y_max && 0>y_min) {
      for(y=0; y<=y_max; y+=tick_int_y) {                     //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-1,0),cnt);                    //tick
        setBlackPixel(min(xzero+1,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
      for(y=0; y>=y_min; y+=-tick_int_y) {                    //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-1,0),cnt);                    //tick
        setBlackPixel(min(xzero+1,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
      for(y=0; y<=y_max; y+=tick_int_y*5) {                   //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-2,0),cnt);                    //tick
        setBlackPixel(min(xzero+2,SCREEN_WIDTH_GRAPH-1),cnt); //tick
        setBlackPixel(max(xzero-3,0),cnt);                    //tick
        setBlackPixel(min(xzero+3,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
      for(y=0; y>=y_min; y+=-tick_int_y*5) {                  //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>>>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-2,0),cnt);                    //tick
        setBlackPixel(min(xzero+2,SCREEN_WIDTH_GRAPH-1),cnt); //tick
        setBlackPixel(max(xzero-3,0),cnt);                    //tick
        setBlackPixel(min(xzero+3,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
    }
    else {
      for(y=y_min; y<=y_max; y+=tick_int_y) {                 //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>>>>>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-1,0),cnt);                    //tick
        setBlackPixel(min(xzero+1,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
      for(y=y_min; y<=y_max; y+=tick_int_y*5) {               //draw y ticks
          #if defined(STATDEBUG) && defined(PC_BUILD)
          printf(">>>>>>>>y=%d   \n",(int)y);
          #endif // STATDEBUG && PC_BUILD
        cnt = screen_window_y(y_min,y,y_max);
        setBlackPixel(max(xzero-2,0),cnt);                    //tick
        setBlackPixel(min(xzero+2,SCREEN_WIDTH_GRAPH-1),cnt); //tick
        setBlackPixel(max(xzero-3,0),cnt);                    //tick
        setBlackPixel(min(xzero+3,SCREEN_WIDTH_GRAPH-1),cnt); //tick
      }
    }
  }
  force_refresh(timed);
  #endif
#endif //SAVE_SPACE_DM42_13GRF
}


float auto_tick(float tick_int_f) {
#if !defined(SAVE_SPACE_DM42_13GRF)
  char tmpString2[100];

  if(!roundedTicks) {
    return tick_int_f;
  }
  //Obtain scaling of ticks, to about 20 intervals left to right.
  //graphtype tick_int_f = (x_max-x_min)/20;                                                 //printf("tick interval:%f ",tick_int_f);
  snprintf(tmpString2, 100, "%.1e", tick_int_f);
  char tx[4];
  tx[0] = tmpString2[0]; //expecting the form 6.5e+01
  tx[1] = tmpString2[1]; //the decimal radix is copied over, so region setting should not affect it
  tx[2] = tmpString2[2]; //the exponent is stripped
  tx[3] = 0;
  //printf("tick0 %f orgstr %s tx %s \n",tick_int_f, tmpString2, tx);
  tick_int_f = strtof (tx, NULL);
  //tick_int_f = (float)(tx[0]-48) + (float)(tx[2]-48)/10.0f;
  //printf("tick1 %f orgstr %s tx %s \n",tick_int_f, tmpString2, tx);

  if(tick_int_f > 0   && tick_int_f <=  0.3) {
    tmpString2[0] = '0';
    tmpString2[2] = '2';
  }
  else if(tick_int_f > 0.3 && tick_int_f <=  0.6) {
    tmpString2[0] = '0';
    tmpString2[2] = '5';
  }
  else if(tick_int_f > 0.6 && tick_int_f <=  1.3) {
    tmpString2[0] = '1';
    tmpString2[2] = '0';
  }
  else if(tick_int_f > 1.3 && tick_int_f <=  1.7) {
    tmpString2[0] = '1';
    tmpString2[2] = '5';
  }
  else if(tick_int_f > 1.7 && tick_int_f <=  3.0) {
    tmpString2[0] = '2';
    tmpString2[2] = '0';
  }
  else if(tick_int_f > 3.0 && tick_int_f <=  6.5) {
    tmpString2[0] = '5';
    tmpString2[2] = '0';
  }
  else if(tick_int_f > 6.5 && tick_int_f <=  9.9) {
    tmpString2[0] = '7';
    tmpString2[2] = '5';
  }

  tick_int_f = strtof (tmpString2, NULL);                                        //printf("string:%s converted:%f \n",tmpString2, tick_int_f);

  //printf("tick2 %f str %s tx %s \n",tick_int_f, tmpString, tx);
#endif // !SAVE_SPACE_DM42_13GRF
  return tick_int_f;
}


void graph_axis (void){
#if !defined(SAVE_SPACE_DM42_13GRF)
  #if !defined(TESTSUITE_BUILD)
    graph_dx = 0; //XXX override manual setting from GRAPH to auto, temporarily. Can program these to fixed values.
    graph_dy = 0;

    if(graph_dx == 0) {
      tick_int_x = auto_tick((x_max-x_min)/20);
    }
    else {
      tick_int_x = graph_dx;
    }

    if(graph_dy == 0) {
      tick_int_y = auto_tick((y_max-y_min)/20);
    }
    else {
      tick_int_y = graph_dy;
    }
  #endif // !TESTSUITE_BUILD
  graphAxisDraw();
#endif //SAVE_SPACE_DM42_13GRF
}


char * radixProcess(char *output, const char * ss) {  //  .  HIERDIE WERK GLAD NIE
  int8_t ix = 0, iy = 0;

  while( ss[ix] != 0 ){
    if(ss[ix]==',' || ss[ix]=='.') {
      output[iy++] = RADIX34_MARK_CHAR;
    }
    else
    if(ss[ix]=='#') {
      output[iy++] = ';';
    }
    else {
      output[iy++] = ss[ix];
    }
    ix++;
  }
  output[iy] = '\0';
  return output;
}


void nanCheck(char* s02) {
  if(stringByteLength(s02) > 2) {
    for(int ix = 2; s02[ix]!=0; ix++) {
      if(s02[ix]=='n' && s02[ix-1]=='a' && s02[ix-2]=='n') {
        s02[ix] = 'N';
        s02[ix-2] = 'N';
      }
    }
  }
}

void eformat (char* s02, const char* s01, double inreal, uint8_t prec, const char* s05) {
  char s03[100];
  char tmpbuf[PLOT_TMP_BUF_SIZE];

  if(((fabs(inreal) > 1000000.0 || fabs(inreal) < 0.001)) && (inreal != 0.0)) {
    sprintf(s03,"%.*e",prec,inreal);
  }
  else {
    sprintf(s03,"%.*f",prec,inreal);
  }
  strcpy(s02,s01);
  if(inreal > 0) {
    strcat(s02,"");  //in place of negative sign
  }
  strcat(s02,eatSpacesMid(radixProcess(tmpbuf, s03)));
  strcat(s02,s05);
  nanCheck(s02);
}


void eformat_fix3 (char* s02, const char* s01, double inreal) {
  char *sign;
  char s03[100]; char s04[100];
  char tmpbuf[PLOT_TMP_BUF_SIZE];

  s04[0]=0;
  if(inreal<0.0) {
    sign = "-";
    inreal = -inreal;
  }
  else {
    sign = " ";                              //changed from 0.001 to force more digits
  }
  if(((fabs(inreal) > 100000000.0f || fabs(inreal) < 0.1f)) && (inreal != 0.0f)) {
    sprintf(s03,"%s%.3e",sign,inreal);
  }
  else {
    sprintf(s03,"%s%.3f",sign,inreal);
  }

  strcpy(s02,s01);

  if(inreal > 0) {
    strcpy(s04, " ");  //in place of negative sign
  }
  strcat(s04,s03);
  strcat(s02,eatSpacesMid(radixProcess(tmpbuf, s04)));
  nanCheck(s02);
}


char * padEquals(char *output, const char * ss) {
  int8_t ix = 0, iy = 0;

  while( ss[ix] != 0 ){
    if(!(ss[ix] & 0x80)) {
      if(ss[ix]=='=') {
        output[iy++] = STD_SPACE_PUNCTUATION[0];
        output[iy++] = STD_SPACE_PUNCTUATION[1];
        output[iy++] = '=';
        output[iy++] = STD_SPACE_PUNCTUATION[0];
        output[iy++] = STD_SPACE_PUNCTUATION[1];
      }
      else {
        output[iy++] = ss[ix];
      }
    }
    else {
      output[iy++] = ss[ix];
      if(ss[ix+1] != 0) {
        output[iy++] = ss[++ix];
      }
    }
    ix++;
  }
  output[iy] = '\0';
  return output;
}


//parts taken from:
//  http://jkorpela.fi/c/eng.html
//  David Hoerl
static char *eng(char *result, double value, int digits) {
  double display, fract, old;
  int expof10;
  char *sign;

  // assert(isnormal(value)); // could also return NULL

  if(value < 0.0) {
    sign = "-";
    value = -value;
  }
  else {
    sign = " ";
  }

  old = value;

  // correctly round to desired precision
  expof10 = lrint( floor( log10(value) ) );
  value *= pow(10.0, digits - 1 - expof10);

  fract = modf(value, &display);
  if(fract >= 0.5) {
    display += 1.0;
  }

  value = display * pow(10.0, expof10 - digits + 1);


  if(expof10 > 0) {
    expof10 = (expof10/3)*3;
  }
  else {
    expof10 = ((-expof10+3)/3)*(-3);
  }

  value *= pow(10.0, -expof10);
  if(value >= 1000.0) {
    value /= 1000.0;
    expof10 += 3;
  }
  else if(value >= 100.0) {
         digits -= 2;
  }
  else if(value >= 10.0) {
    digits -= 1;
  }

  if(isnan(old) || isinf(old)) {
    sprintf(result, "%s%f", sign, old);
  }
  else if(old>999.9       && old<100000.0) {
    sprintf(result,"%s%.i",     sign, (int)old);
  }
  else if(old>99.9999     && old<1000.0  ) {
    sprintf(result,"%s%.i",     sign, (int)old);
  }
  else if(old>9.99999     && old<100.0   ) {
    sprintf(result,"%s%.*f",    sign, 1+digits+1-3, old);
  }
  else if(old>0.999999    && old<10.0    ) {
    sprintf(result,"%s%.*f",    sign, digits+2-3  , old);
  }
  else if(old>0.0999999   && old<1.0     ) {
    sprintf(result,"%s%.*f",    sign, 2+digits+3-3, old);
  }
  else if(old>0.00999999  && old<0.1     ) {
    sprintf(result,"%s%.*f",    sign, 1+digits+4-3, old);
  }
  else if(old == 0.0) {
    sprintf(result,"%s%.*f",    " ",  digits-1    , old);
  }
  else if(digits-1 <= 0) {
    sprintf(result,"%s%.0fe%d", sign, value, expof10);
  }
  else {
    sprintf(result,"%s%.*fe%d", sign, digits-1, value, expof10);
  }
  return result;
}


void eformat_eng2 (char* s02, const char* s01, double inreal, int8_t digits, const char* s05) {
  char s03[100];
  char tmpbuf[PLOT_TMP_BUF_SIZE];

  strcpy(s03,eng(tmpbuf, inreal, digits));
  strcpy(s02,s01);
  strcat(s02,eatSpacesMid(radixProcess(tmpbuf, s03)));
  strcat(s02,s05);
  nanCheck(s02);
}


#define horOffsetR 109+5 //digit righ side aliognment
#define autoinc 20 //text line spacing
#define autoshift -5 //text line spacing
#define horOffset 1 //labels from the left


#if !defined(TESTSUITE_BUILD)
  int32_t statMxN(void) {
    uint16_t rows = 0;

    if(plotStatMx[0]=='D') {
      return 0;                //Only allow S and H
    }
    else {
      calcRegister_t regStats = findNamedVariable(plotStatMx);
      if(regStats == INVALID_VARIABLE) {
        return 0;
      }
      else {
        if(isStatsMatrix(&rows,plotStatMx)) {
          real34Matrix_t stats;
          linkToRealMatrixRegister(regStats, &stats);
          return stats.header.matrixRows;
        }
        else {
          return 0;
        }
      }
    }
  }
#endif // !TESTSUITE_BUILD


void graphPlotstat(uint16_t selection){
#if !defined(SAVE_SPACE_DM42_13GRF)
  #if defined(STATDEBUG) && defined(PC_BUILD)
    printf("#####>>> graphPlotstat: selection:%u:%s  lastplotmode:%u  lrSelection:%u lrChosen:%u\n",selection, getCurveFitModeName(selection), lastPlotMode, lrSelection, lrChosen);
  #endif // STATDEBUG && PC_BUILD
  #if !defined(TESTSUITE_BUILD)
  uint16_t  cnt, ix, statnum;
  uint16_t  xo, xn, xN;
  uint8_t   yo, yn, yN;
  float x;
  float y;

  statnum = 0;
  if(calcMode == CM_GRAPH) {
    roundedTicks = true;
   }
   else {
     roundedTicks = false;
   }

  //  graphAxisDraw();                        //Draw the axis on any uncontrolled scale to start. Maybe optimize by remembering if there is an image on screen Otherwise double axis draw.
  graph_axis();
  plotmode = _SCAT;

    if((plotStatMx[0]=='S' && checkMinimumDataPoints(const_2)) ||
      (plotStatMx[0]=='D' && drawMxN() >= 2) ||
      (plotStatMx[0]=='H' && statMxN() >= 3)) {
      switch(plotStatMx[0]) {
        case 'S': realToInt32(SIGMA_N, statnum); break;
        case 'D': statnum = drawMxN();           break;
        case 'H': statnum = statMxN();           break;
        default: ;
      }
      #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("graphPlotstat: statnum n=%d\n",statnum);
      #endif // STATDEBUG && PC_BUILD


    //AUTOSCALE
    x_min = FLoatingMax;
    x_max = FLoatingMin;
    y_min = FLoatingMax;
    y_max = FLoatingMin;
    #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("Axis0: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
    #endif // STATDEBUG && PC_BUILD


    //#################################################### vvv SCALING LOOP  vvv
    for(cnt=0; (cnt < statnum); cnt++) {
      #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("Axis0a: x: %f y: %f   \n",grf_x(cnt), grf_y(cnt));
      #endif // STATDEBUG && PC_BUILD
      if(grf_x(cnt) < x_min) {
        x_min = grf_x(cnt);
      }
      if(grf_x(cnt) > x_max) {
        x_max = grf_x(cnt);
      }
      if(grf_y(cnt) < y_min) {
        y_min = grf_y(cnt);
      }
      if(grf_y(cnt) > y_max) {
        y_max = grf_y(cnt);
      }
      #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("Axis0b: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
      #endif // STATDEBUG && PC_BUILD
      if(keyWaiting()) {
        return;
      }
    }
    //##  ################################################## ^^^ SCALING LOOP ^^^
      #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("Axis1a: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
      #endif // STATDEBUG && PC_BUILD

      if(x_min <= FLoatingMin || x_max <= FLoatingMin || y_min <= FLoatingMin || y_max <= FLoatingMin) {
        goto scaleMinusInfinity;
      }
      if(x_min >= FLoatingMax || x_max >= FLoatingMax || y_min >= FLoatingMax || y_max >= FLoatingMax) {
        goto scalePlusInfinity;
      }

    //Check and correct if min and max is swapped
    if(x_min>0.0f && x_min > x_max) {
      x_min = x_min - (-x_max+x_min)* 1.1f;
    }
    if(x_min<0.0f && x_min > x_max) {
      x_min = x_min + (-x_max+x_min)* 1.1f;
    }
    #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("Axis1b: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
    #endif // STATDEBUG && PC_BUILD

    //Always include the 0 axis
    if(!extentx) {
      if(x_min>0.0f && x_max>0.0f) {
        if(x_min<=x_max) {
          x_min = -0.05f*x_max;
        }
        else {
          x_min = 0.0f;
        }
      }
      if(x_min<0.0f && x_max<0.0f) {
        if(x_min>=x_max) {
          x_min = -0.05f*x_max;
        }
        else {
          x_max = 0.0f;
        }
      }
    }
    if(!extenty) {
      if(y_min>0.0f && y_max>0.0f) {
        if(y_min<=y_max) {
          y_min = -0.05f*y_max;
        }
        else {
          y_min = 0.0f;
        }
      }
      if(y_min<0.0f && y_max<0.0f) {
        if(y_min>=y_max) {
          y_min = -0.05f*y_max;
        }
        else {
          y_max = 0.0f;
        }
      }
    }

    //Cause scales to be the same
    if(PLOT_SCALE) {
      x_min = min(x_min,y_min);
      x_max = max(x_max,y_max);
      y_min = x_min;
      y_max = x_max;
    }

    //Calc zoom scales
    if(PLOT_ZMX != 0) {
      x_min = pow(2.0f,-PLOT_ZMX) * x_min;
      x_max = pow(2.0f,-PLOT_ZMX) * x_max;
    }
    if(PLOT_ZMY != 0) {
      y_min = pow(2.0f,-PLOT_ZMY) * y_min;
      y_max = pow(2.0f,-PLOT_ZMY) * y_max;
    }
      #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("Axis2: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
      #endif // STATDEBUG && PC_BUILD

    float dx = x_max-x_min;
    float dy = y_max-y_min;

    if(dy == 0.0f) {
      dy = 1.0f;
      y_max = y_min + dy/2.0f;
      y_min = y_max - dy;
    }
    if(dx == 0.0f) {
      dx = 1.0f;
      x_max = x_min + dx/2.0f;
      x_min = x_max - dx;
    }

      /*
      (pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03))) / 20
      0 1/20      = 0.05  * 2 = 0.10    width: dx * 1.10       Reference 1
      1 4,5/20    = 0.23  * 2 = 0.45    width: dx * 1.45       factor 1.32
      2 20,25/20  = 1.01  * 2 = 2.03    width: dx * 2.03       factor 2.75
      3 91,125/20 = 4.56  * 2 = 9.11    width: dx * 10.11      factor 9.19
      ( (int8_t)(PLOT_ZOOM & 0x03) == 0 ? 1.0f : (int8_t)(PLOT_ZOOM & 0x03) == 1 ? 4.5f : (int8_t)(PLOT_ZOOM & 0x03) == 2 ? 20.25f : 91.125f )
      */
      float histofactor = drawHistogram == 0 ? 1 : 1/zoomfactor * (((float)statnum + 2.0f)  /  ((float)(statnum) - 1.0f) - 1)/2;     //Create space on the sides of the graph for the wider histogram columns
      float plotzoomx = pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03));
      float plotzoomy = drawHistogram == 1 ? 1 : plotzoomx;

      x_min = x_min - dx * histofactor * zoomfactor * plotzoomx;
      y_min = y_min - dy * histofactor * zoomfactor * plotzoomy;
      x_max = x_max + dx * histofactor * zoomfactor * plotzoomx;
      y_max = y_max + dy * histofactor * zoomfactor * plotzoomy;
      if(drawHistogram == 1) {
        y_min = 0;
      }
      #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("Axis3a: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
      #endif // STATDEBUG && PC_BUILD

    //graphAxisDraw();
    if(calcMode == CM_GRAPH) {
      roundedTicks = true;
    }
    else {
      roundedTicks = false;
    }

    if(x_min <= FLoatingMin || x_max <= FLoatingMin || y_min <= FLoatingMin || y_max <= FLoatingMin) {
       goto scaleMinusInfinity;
     }
     if(x_min >= FLoatingMax || x_max >= FLoatingMax || y_min >= FLoatingMax || y_max >= FLoatingMax) {
       goto scalePlusInfinity;
     }



    graph_axis();
    yn = screen_window_y(y_min,grf_y(0),y_max);
    xn = screen_window_x(x_min,grf_x(0),x_max);
    xN = xn;
    yN = yn;
      #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("Axis3c: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
      #endif // STATDEBUG && PC_BUILD

      int16_t colw = (int16_t) (
                                 (  (screen_window_x(x_min,grf_x(1),x_max) - screen_window_x(x_min,grf_x(0),x_max))  / 2.0f  )
                                ) - 1;
      //#################################################### vvv MAIN GRAPH LOOP vvv
      for(ix = 0; (ix < statnum); ++ix) {
        x = grf_x(ix);
        y = grf_y(ix);
        xo = xN;
        yo = yN;
        xN = screen_window_x(x_min,x,x_max);
        yN = screen_window_y(y_min,y,y_max);

        #if defined(STATDEBUG) && defined(PC_BUILD)
          printf("plotting graph table[%d] = x:%f y:%f xN:%d yN:%d drawHistogram:%d ", ix, x, y, xN, yN, drawHistogram);
        #endif // STATDEBUG && PC_BUILD

      int16_t minN_y,minN_x;
      if(!Aspect_Square) {
        minN_y = SCREEN_NONSQ_HMIN;
        minN_x = 0;
      }
      else {
        minN_y = 0;
        minN_x = SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH;
      }
      if(xN<SCREEN_WIDTH_GRAPH && xN>minN_x && yN<SCREEN_HEIGHT_GRAPH && yN>minN_y) {
        yn = yN;
        xn = xN;

          if(drawHistogram != 0) {
            plotHisto_col(xN, yN, minN_y, SCREEN_HEIGHT_GRAPH - minN_y, colw);
          }

        if(PLOT_CROSS) {
            #if defined(STATDEBUG) && defined(PC_BUILD)
            printf("Plotting cross to x=%d y=%d\n",xn,yn);
            #endif // STATDEBUG && PC_BUILD
          plotcross(xn,yn);
        }

        if(PLOT_BOX) {
            #if defined(STATDEBUG) && defined(PC_BUILD)
            printf("Plotting box to x=%d y=%d\n",xn,yn);
            #endif // STATDEBUG && PC_BUILD
          plotbox_fat(xn,yn);
        }

        if(PLOT_LINE) {
            #if defined(STATDEBUG) && defined(PC_BUILD)
            printf("Plotting line to x=%d y=%d\n",xn,yn);
            #endif // STATDEBUG && PC_BUILD
          plotline(xo, yo, xn, yn);
        }
      }
      else {
          #if defined(PC_BUILD)
          printf("Not plotted point: (%u %u) ",xN,yN);
            if(xN >= SCREEN_WIDTH_GRAPH) {
              printf("x>>%u ", SCREEN_WIDTH_GRAPH);
            }
            else if(xN <= minN_x) {
              printf("x<<%u ", minN_x);
            }

            if(yN >= SCREEN_HEIGHT_GRAPH) {
              printf("y>>%u ", SCREEN_HEIGHT_GRAPH);
            }
            else if(yN <= 1+minN_y) {
              printf("y<<%u ", 1+minN_y);
            }
          printf("\n");
          //printf("Not plotted: xN=%d<SCREEN_WIDTH_GRAPH=%d && xN=%d>minN_x=%d && yN=%d<SCREEN_HEIGHT_GRAPH=%d && yN=%d>1+minN_y=%d\n",xN,SCREEN_WIDTH_GRAPH,xN,minN_x,yN,SCREEN_HEIGHT_GRAPH,yN,1+minN_y);
          #endif // PC_BUILD
      }
      if(keyWaiting()) {
         return;
      }
    }
    //#################################################### ^^^ MAIN GRAPH LOOP ^^^

    if(calcMode == CM_GRAPH) {
      int16_t index = -1;

      char ss[100], tt[100];
      char tmpbuf[PLOT_TMP_BUF_SIZE];
      int32_t n;
      eformat_eng2(ss,"(",x_max, 2,"");
      eformat_eng2(tt,radixProcess(tmpbuf, "#"),y_max,2,")");
      strcat(tt,padEquals(tmpbuf, ss));
      n = showString(padEquals(tmpbuf, ss), &standardFont, 160-2-3-2 - stringWidth(tt, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index + 2       +autoshift, vmNormal, false, false);
      eformat_eng2(ss, radixProcess(tmpbuf, "#"), y_max, 2, ")");
      showString(padEquals(tmpbuf, ss), &standardFont, n+3,       Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++      +autoshift + 2, vmNormal, false, false);
      eformat_eng2(ss, "(", x_min, 2, "");
      n = showString(padEquals(tmpbuf, ss), &standardFont,horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index    -2  +autoshift + 2, vmNormal, false, false);
      eformat_eng2(ss, radixProcess(tmpbuf, "#"), y_min, 2, ")");
      showString(padEquals(tmpbuf, ss), &standardFont, n+3,       Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++  -2  +autoshift + 2, vmNormal, false, false);

      eformat_eng2(ss, "x: ", tick_int_x, 2, "/tick");
      showString(padEquals(tmpbuf, ss), &standardFont,horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ + 2       + autoshift, vmNormal, false, false);
      eformat_eng2(ss, "y: ", tick_int_y, 2, "/tick");
      showString(padEquals(tmpbuf, ss), &standardFont,horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ + 2       + autoshift, vmNormal, false, false);
      }


    if(drawHistogram == 1 && selection == 0) { // HISTO
      int32_t n;
      float lB, hB, nB;
      real_t lBr, hBr, nBr;
      char ss[100], tt[100];
      char tmpbuf[PLOT_TMP_BUF_SIZE];
      int16_t index = -1;
      real34ToReal(&loBinR ,&lBr);
      real34ToReal(&hiBinR ,&hBr);
      real34ToReal(&nBins  ,&nBr);
      realToFloat(&lBr, &lB);
      realToFloat(&hBr, &hB);
      realToFloat(&nBr, &nB);

      strcpy(ss,histElementXorY == 1 ? "Histogram(y)" : "Histogram(x)");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);

      eformat_eng2(ss, "(", x_max, 2, "");
      eformat_eng2(tt,radixProcess(tmpbuf, "#"),y_max,2,")");
      strcat(tt, padEquals(tmpbuf, ss));
      n = showString(padEquals(tmpbuf, ss), &standardFont, 160-2-3-2 - stringWidth(tt, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index + 2   -3  +autoshift, vmNormal, false, false);
      eformat_eng2(ss, radixProcess(tmpbuf, "#"), y_max, 2, ")");
      showString(padEquals(tmpbuf, ss), &standardFont, n+3,           Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++  -3  + autoshift + 2, vmNormal, false, false);

      eformat_eng2(ss, "(", x_min, 2, "");
      n = showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index    -6  + autoshift + 2, vmNormal, false, false);
      eformat_eng2(ss, radixProcess(tmpbuf, "#"), y_min, 2, ")");
      showString(padEquals(tmpbuf, ss), &standardFont, n+3,           Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++  -6  + autoshift + 2, vmNormal, false, false);

      strcpy(ss,"Bin centres:");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);
      eformat_eng2(ss,"",lB,3,"");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -4 +autoshift, vmNormal, false, false);
      strcpy(ss,STD_DOWN_ARROW "BIN" "=");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);

      eformat_eng2(ss,"",hB,3,"");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
      strcpy(ss,STD_UP_ARROW "BIN" "=");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);

      eformat_eng2(ss,"",nB,3,"");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
      strcpy(ss,"nBINS" "=");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);
      eformat_eng2(ss,"",(hB-lB)/nB,3,"");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
      strcpy(ss,"Width" "=");
      showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);

    }




  }
  else {
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "There is no statistical data available!");
      moreInfoOnError("In function graphPlotstat:", errorMessage, NULL, NULL);
    #endif
  }
 return;


  scalePlusInfinity:
  displayCalcErrorMessage(ERROR_OVERFLOW_PLUS_INF, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "Plus Infinity encountered!");
    moreInfoOnError("In function graphPlotstat:", errorMessage, NULL, NULL);
  #endif
  return;

  scaleMinusInfinity:
  displayCalcErrorMessage(ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "Minus Infinity encountered!");
    moreInfoOnError("In function graphPlotstat:", errorMessage, NULL, NULL);
  #endif


 #endif // !TESTSUITE_BUILD)
#endif //SAVE_SPACE_DM42_13GRF
}


#if !defined(TESTSUITE_BUILD)
  void demo_plot(void) {
    int8_t ix;
    time_t t;

    srand((unsigned) time(&t));
    runFunction(ITM_CLSIGMA);
    plotSelection = 0;
    srand((unsigned int)time(NULL));
    for(ix=0; ix!=40; ix++) {
      int mv = 11000 + rand() % 110 - 55;
      //instrument measuring RMS voltage of an 11 kV installation, with +- 0.1% variance, offset to the + for convenience

      setSystemFlag(FLAG_ASLIFT);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE, amNone);
      int32ToReal34(mv+rand()%4-2,REGISTER_REAL34_DATA(REGISTER_X));
      // reading 1 has additional +0 to +3 variance to the said random number

      setSystemFlag(FLAG_ASLIFT);
      liftStack();
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE, amNone);
      int32ToReal34(mv+rand()%4-2,REGISTER_REAL34_DATA(REGISTER_X));
      // reading 2 has additional +0 to +3 variance to the said random number

      runFunction(ITM_SIGMAPLUS);
    }
  }
#endif // !TESTSUITE_BUILD


void graphDrawLRline(uint16_t selection) {
  #if !defined(TESTSUITE_BUILD)
    //demo_plot();
    if(selection != 0) {
      processCurvefitSelection(selection, &RR, &SMI, &aa0, &aa1, &aa2);
      realMultiply(&RR,&RR,&RR,&ctxtReal39);
      if(orOrtho(selection) == CF_ORTHOGONAL_FITTING) {
        processCurvefitSA(&sa0, &sa1);
      }
      drawline(selection, &RR, &SMI, &aa0, &aa1, &aa2, &sa0, &sa1);
    }
  #endif // !TESTSUITE_BUILD
}


#if !defined(TESTSUITE_BUILD)
 static void drawline(uint16_t selection, real_t *RR, real_t *SMI, real_t *aa0, real_t *aa1, real_t *aa2, real_t *sa0, real_t *sa1) {
#if !defined(SAVE_SPACE_DM42_13GRF)
    int32_t n = 0;
    uint16_t NN;
    char tmpbuf[PLOT_TMP_BUF_SIZE];

    switch(plotStatMx[0]) {
      case 'S': realToInt32(SIGMA_N, n); break;
      case 'D': n = drawMxN();           break;
      case 'H': n = statMxN();           break;
      default: ;
    }
    #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("drawline: n=%d\n",n);
    #endif // STATDEBUG && PC_BUILD

    NN = (uint16_t) n;
    bool_t isValidDraw =
         selection != 0
      && n >= (int32_t)minLRDataPoints(selection)
      && !realCompareGreaterThan(RR, const_1)
      && !realIsNaN(RR)
      && !realIsNaN(aa0)
      && !realIsNaN(aa1)
      && (!realIsNaN(aa2) || minLRDataPoints(selection)==2)
      && (!realIsNaN(SMI) || !(orOrtho(selection) & CF_ORTHOGONAL_FITTING));

    #if defined(STATDEBUG) && defined(PC_BUILD)
      printf("#####>>> drawline: selection:%u:%s  lastplotmode:%u  lrSelection:%u lrChosen:%u\n", selection, getCurveFitModeName(selection), lastPlotMode, lrSelection, lrChosen);
    #endif //  STATDEBUG && PC_BUILD
    float rr, smi, a0, a1, a2, ssa0, ssa1;
    char ss[100], tt[100];

    real_t XX, YY;
    if(!selection) {
      return;
    }

    realToFloat(RR , &rr );
    realToFloat(SMI, &smi);
    realToFloat(aa0, &a0 );
    realToFloat(aa1, &a1 );
    realToFloat(aa2, &a2 );
    realToFloat(sa0, &ssa0 );
    realToFloat(sa1, &ssa1 );

    if(isValidDraw) {
      #if defined(STATDEBUG) && defined(PC_BUILD)
        printf("plotting line: a2 %f a1 %f a0 %f\n", a2, a1, a0);
      #endif // STATDEBUG && PC_BUILD
      if((selection==0 && a2 == 0 && a1 == 0 && a0 == 0)) {
        #if defined(STATDEBUG) && defined(PC_BUILD)
          printf("return, nothing selected, zero parameters, nothing to draw\n");
        #endif // STATDEBUG && PC_BUILD
        return;
      }
      double  ix;
      uint16_t  xo = 0, xn, xN = 0;
      uint8_t   yo = 0, yn, yN = 0;
      double    x = x_min;
      double    y = 0.0;
      int16_t   Intervals = numberIntervals; //starting point to calculate dx
      uint16_t  iterations = 0;
      double    intervalW = (double)(x_max-x_min)/(double)(Intervals);

      int16_t minN_y,minN_x;
      if(!Aspect_Square) {
        minN_y = SCREEN_NONSQ_HMIN;
        minN_x = 0;
      }
      else {
        minN_y = 0;
        minN_x = SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH;
      }
      for(ix = (double)x_min-intervalW; iterations < 2000 && x < x_max+(x_max-x_min)*0.5 && xN < SCREEN_WIDTH-1; iterations++) {       //Variable accuracy line plot
        xo = xN;
        yo = yN;
        uint16_t xx;
        for( xx=0; xx<14; xx++) {      //the starting point is ix + dx where dx=2^-0*interval and reduce it to dx=2^-31*interval until dy<=2
          x = ix + intervalW / ((double)((uint16_t) 1 << xx));
          if(USEFLOATING == useREAL4) {
            //TODO create REAL from x (double) if REALS will be used
            //snprintf(ss,100,"%f",x); stringToReal(ss,&XX,&ctxtReal4);
            convertDoubleToReal(x, &XX, &ctxtReal4);
          }
          else {
            if(USEFLOATING == useREAL39) {
              //TODO create REAL from x (double) if REALS will be used
              //snprintf(ss,100,"%f",x); stringToReal(ss,&XX,&ctxtReal39);
              convertDoubleToReal(x, &XX, &ctxtReal39);
            }
          }
          yIsFnx( USEFLOATING, selection, x, &y, a0, a1, a2, &XX, &YY, RR, SMI, aa0, aa1, aa2);
          xN = screen_window_x(x_min,(float)x,x_max);
          yN = screen_window_y(y_min,(float)y,y_max);
          if((abs((int)yN-(int)yo)<=2 /*&& abs((int)xN-(int)xo)<=2*/) || iterations == 0 || xN <= minN_x) {
            break;
          }
        }
        ix = x;
        //printf("### iter:%u ix=%20lf xx=%i x=%lf y=%lf xN=%u yN=%u\n",iterations,ix,xx,x,y,xN,yN);
        if(iterations > 0) {  //Allow for starting values to accumulate in the registers at ix = 0
          #if defined(STATDEBUG) && defined(PC_BUILD)
            printf("plotting graph: iter:%u ix:%f I.vals:%u ==>xmin:%f (x:%f) xmax:%f ymin:%f (y:%f) ymax:%f xN:%d yN:%d \n",iterations,ix,Intervals,x_min,x,x_max,y_min,y,y_max,  xN,yN);
          #endif // STATDEBUG && PC_BUILD
          #define tol 4
          if(xN<SCREEN_WIDTH_GRAPH && xN>minN_x && yN<SCREEN_HEIGHT_GRAPH-tol && yN>minN_y) {
            yn = yN;
            xn = xN;
            #if defined(STATDEBUG_VERBOSE) && defined(PC_BUILD)
              printf("Plotting box to x=%d y=%d\n",xn,yn);
            #endif // STATDEBUG && PC_BUILD
            if(fittedcurveboxes) {
              plotbox(xn,yn);
            }
            if(xo < SCREEN_WIDTH_GRAPH && xo > minN_x && yo < SCREEN_HEIGHT_GRAPH-tol && yo > minN_y) {
              #if defined(STATDEBUG_VERBOSE) && defined(PC_BUILD)
                printf("Plotting line to x=%d y=%d\n",xn,yn);
              #endif // STATDEBUG && PC_BUILD
              plotline2(xo, yo, xn, yn);
            }
          }
          else {
            #if defined(STATDEBUG) && defined(PC_BUILD)
              printf("Not plotted line: (%u %u) ",xN,yN);
              if(xN >= SCREEN_WIDTH_GRAPH) {
                printf("x>>%u ", SCREEN_WIDTH_GRAPH);
              }
              else if(xN <= minN_x) {
                printf("x<<%u ", minN_x);
              }
              if(yN >= SCREEN_HEIGHT_GRAPH) {
                printf("y>>%u ", SCREEN_HEIGHT_GRAPH);
              }
              else if(yN <= 1+minN_y) {
                printf("y<<%u ", 1+minN_y);
              }
              printf("\n");
            #endif // STATDEBUG && PC_BUILD
          }
        }
      }
      #if defined(PC_BUILD)
        printf("Drawline: %u / 2000 iterations\n",iterations);
      #endif // PC_BUILD
    }


    int16_t index = -1;
    if(selection!=0) {
      strcpy(ss,eatSpacesEnd(getCurveFitModeName(selection)));
      if(lrCountOnes(lrSelection)>1 && selection == lrChosen) {
        strcat(ss,lrChosen == 0 ? "" : STD_SUP_ASTERISK);
      }
      showString(ss, &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -10 +autoshift, vmNormal, false, false);
      if(selection != CF_GAUSS_FITTING && selection != CF_CAUCHY_FITTING) {
        strcpy(ss,"y="); strcat(ss,getCurveFitModeFormula(selection));
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7 +autoshift, vmNormal, false, false);
      }
      else {
        strcpy(ss,"y="); strcat(ss,getCurveFitModeFormula(selection));
        showString(          ss,  &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7 +autoshift, vmNormal, false, false);
      }
    }

    if(isValidDraw) {
      if(softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_PLOT_STAT) {
        sprintf(ss, "%u",NN);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -2 +autoshift, vmNormal, false, false);
        sprintf(ss, STD_SPACE_PUNCTUATION STD_SPACE_PUNCTUATION "n=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ -2 +autoshift, vmNormal, false, false);
      }

      if(orOrtho(selection) != CF_ORTHOGONAL_FITTING) {
        eformat_eng2(ss, "", a0, 3, "");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -4 +autoshift, vmNormal, false, false);
        strcpy(ss, "a" STD_SUB_0 "=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);

        eformat_eng2(ss, "", a1, 3, "");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
        strcpy(ss, "a" STD_SUB_1 "=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);

        if(selection == CF_PARABOLIC_FITTING || selection == CF_GAUSS_FITTING || selection == CF_CAUCHY_FITTING) {
          eformat_eng2(ss, "", a2, 3, "");
          showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
          strcpy(ss, "a" STD_SUB_2 "=");
          showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);
        }

        eformat(ss, "", rr, 4, "");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  +2  +autoshift, vmNormal, false, false);
        strcpy(ss, "r" STD_SUP_2 "=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   +2 +autoshift, vmNormal, false, false);

        eformat_eng2(ss,"(",x_max,2,"");
        uint16_t ssw = showStringEnhanced(padEquals(tmpbuf, ss),&standardFont,0,0,vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_LF);
        eformat_eng2(tt,radixProcess(tmpbuf, "#"),y_max,2,")");
        uint16_t ttw = showStringEnhanced(padEquals(tmpbuf, tt),&standardFont,0,0,vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_LF);
        n = showString(padEquals(tmpbuf, ss), &standardFont,160-3-2-ssw-ttw, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index + 2       +autoshift, vmNormal, false, false);
        showString(padEquals(tmpbuf, tt), &standardFont,n+3, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ +autoshift + 2, vmNormal, false, false);
        eformat_eng2(ss, "(", x_min, 2, "");
        n = showString(padEquals(tmpbuf, ss), &standardFont,horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index    -2  +autoshift + 2, vmNormal, false, false);
        eformat_eng2(ss,radixProcess(tmpbuf, "#"),y_min,2,")");
        showString(padEquals(tmpbuf, ss), &standardFont,n+3,       Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++  -2  +autoshift + 2, vmNormal, false, false);

      }
      else {                          //ORTHOF
        eformat_fix3(ss, "", a0);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -4 +autoshift, vmNormal, false, false);
        strcpy(ss, "a" STD_SUB_0 "=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);

        eformat_fix3(ss, "",ssa0);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -4 +autoshift, vmNormal, false, false);
        strcpy(ss, "    " STD_PLUS_MINUS);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -4 +autoshift, vmNormal, false, false);

        eformat_fix3(ss, "", a1);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
        strcpy(ss, "a" STD_SUB_1 "=");
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);

        eformat_fix3(ss, "", ssa1);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  -1 +autoshift, vmNormal, false, false);
        strcpy(ss, "    " STD_PLUS_MINUS);
        showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   -1 +autoshift, vmNormal, false, false);

        if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PLOT_STAT) {
          if(n >= 30) {
            eformat_eng2(ss, "", smi, 3, "");
          }
          else {
            strcpy(ss,"  | n < 30");
          }

          showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  +1 +autoshift, vmNormal, false, false);
          strcpy(ss,"s" STD_SUB_m STD_SUB_i "=");
          showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   +1 +autoshift, vmNormal, false, false);
        }
        else {
          eformat(ss, "", rr, 4, "");
          showString(padEquals(tmpbuf, ss), &standardFont, horOffsetR - stringWidth(ss, &standardFont, false, false), Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index  +2  +autoshift, vmNormal, false, false);
          strcpy(ss, "r" STD_SUP_2 "=");
          showString(padEquals(tmpbuf, ss), &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++   +2 +autoshift, vmNormal, false, false);
        }

        //eformat(ss,"x,y" STD_SUB_m STD_SUB_i STD_SUB_n "=", x_min,5);
        //showString(ss, &standardFont, 0, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ -2 +autoshift, vmNormal, false, false);
        //eformat(ss,"x,y" STD_SUB_m STD_SUB_a STD_SUB_x "=", x_max,5);
        //showString(ss, &standardFont, 0, Y_POSITION_OF_REGISTER_Z_LINE + autoinc*index++ -2 +autoshift, vmNormal, false, false);
      }
    }
    else {
      if(n < 0) {
        showString("invalid n", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
      }
      else if(isnan(a0) || isnan(a1) || (isnan(a2) && minLRDataPoints(selection)!=2) ) {
        if(selection & 448) {
          showString("invalid a0,a1,a2", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
        }
        else {
          showString("invalid a0,a1", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
      }
      }
      else if((orOrtho(selection) & CF_ORTHOGONAL_FITTING) && isnan(smi)) {
        showString("invalid smi", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
      }
      else if(rr>1 || isnan(rr)) {
        showString("invalid r", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
      }
      else if(NN < minLRDataPoints(selection) ) {
        showString("insufficient data", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
        sprintf(ss," %u < %u", NN,minLRDataPoints(selection));
        showString(ss, &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
        }
      else if(selection == 0) {
        showString("No Valid L.R.", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
      }
      else {
        showString("L.R. error", &standardFont, horOffset, Y_POSITION_OF_REGISTER_Z_LINE + autoinc * index++ -7+2 +autoshift, vmNormal, false, false);
    }
  }
#endif // !SAVE_SPACE_DM42_13GRF
  }
#endif // !TESTSUITE_BUILD


void fnPlotCloseSmi(uint16_t unusedButMandatoryParameter){
  fnKeyExit(0);
  #if defined(DEBUGUNDO)
    printf(">>> Undo from fnPlotCloseSmi\n");
  #endif // DEBUGUNDO
  fnMinExpStdDev(0);
  temporaryInformation = TI_SCATTER_SMI;
}


//** Called from keyboard
//** plotSelection = 0 means that no curve fit is plotted
//
void fnPlotStat(uint16_t plotMode){
#if !defined(TESTSUITE_BUILD)
#if !defined(SAVE_SPACE_DM42_13GRF)
    //restoreStats();
  switch(plotMode) {
      case PLOT_GRAPH: {
        drawHistogram = 0;
        if(plotStatMx[0] != 'D') {
          strcpy(plotStatMx, "DrwMX");
        }
                      break;
      }
    case PLOT_ORTHOF:
    case PLOT_START:
    case PLOT_REV:
    case PLOT_NXT:
      case PLOT_LR: {
        drawHistogram = 0;
        if(plotStatMx[0] != 'S') {
          strcpy(plotStatMx, "STATS");
        }
        break;
      }
      case H_PLOT: {
        drawHistogram = 1;
        if(plotStatMx[0] != 'H') {
          strcpy(plotStatMx, "HISTO");
        }
        break;
      }
      case H_NORM: {
        drawHistogram = 1;
        if(plotStatMx[0] != 'H') { //???
          strcpy(plotStatMx, "HISTO");
        }
        strcpy(statMx,"HISTO");
        calcSigma(0);
        plotMode = PLOT_LR;
        lastPlotMode = PLOT_START;
        lrSelectionHistobackup = lrSelection;
        lrChosenHistobackup = lrChosen;
        fnCurveFitting(CF_GAUSS_FITTING);
        break;
      }
      default: {
        break;
      }
  }

    #if defined(STATDEBUG) && defined(PC_BUILD)
    printf("fnPlotStat1: plotSelection = %u; Plotmode=%u\n",plotSelection,plotMode);
    printf("#####>>> fnPlotStat1: plotSelection:%u:%s  Plotmode:%u lastplotmode:%u  lrSelection:%u lrChosen:%u plotStatMx:%s\n",plotSelection, getCurveFitModeName(plotSelection), plotMode, lastPlotMode, lrSelection, lrChosen, plotStatMx);
      if( (plotStatMx[0]=='S' && checkMinimumDataPoints(const_2)) ||
          (plotStatMx[0]=='D' && drawMxN() >= 2) ||
          (plotStatMx[0]=='H' && statMxN() >= 3) ) {
        int16_t cnt = 0;
        switch(plotStatMx[0]) {
          case 'S': realToInt32(SIGMA_N, cnt); break;
          case 'D': cnt = drawMxN();           break;
          case 'H': cnt = statMxN();           break;
          default: ;
        }
      printf("Stored values %i\n",cnt);
    }
    #endif //STATDEBUG

    if((plotStatMx[0]=='S' && checkMinimumDataPoints(const_2)) ||
       (plotStatMx[0]=='D' && drawMxN() >= 2) ||
       (plotStatMx[0]=='H' && statMxN() >= 3) ) {
      PLOT_SCALE = false;

      #if !defined(TESTSUITE_BUILD)
      if(!(lastPlotMode == PLOT_NOTHING || lastPlotMode == PLOT_START)) {
        plotMode = lastPlotMode;
      }
      calcMode = CM_PLOT_STAT;
      if(plotMode != PLOT_GRAPH) {
        statGraphReset();
      }

      if(plotMode == PLOT_START) {
        plotSelection = 0;
        roundedTicks = false;
      }
      else {
        if(plotMode == PLOT_GRAPH) {
          calcMode = CM_GRAPH;
          plotSelection = 0;
          PLOT_AXIS     = true;
          PLOT_LINE     = true;
          PLOT_BOX      = false;
          roundedTicks  = true;
        }
        else {
          if(plotMode == PLOT_LR && lrSelection != 0) {
            plotSelection = lrSelection;
            roundedTicks = false;
          }
            else {
              if(plotMode == H_PLOT || plotMode == H_NORM) {
                 calcMode = CM_PLOT_STAT;
              }
            }
        }
      }

      hourGlassIconEnabled = true;
      showHideHourGlass();

        #if defined(DMCP_BUILD)
        lcd_refresh();
      #else // !DMCP_BUILD
        refreshLcd(NULL);
      #endif // DMCP_BUILD

        switch(plotMode) {
          case H_PLOT:
          case H_NORM:
            showSoftmenu(-MNU_HPLOT);
            break;
          case PLOT_GRAPH:
            showSoftmenu(-MNU_GRAPH);
            break;
          case PLOT_LR:
            if(drawHistogram == 0) {
              showSoftmenu(-MNU_PLOT_LR);
            }
            else {
              showSoftmenu(-MNU_HPLOT);
            }
            break;
        case PLOT_NXT:
        case PLOT_REV:
          showSoftmenu(-MNU_PLOT_LR);
          break;
        case PLOT_ORTHOF:
        case PLOT_START:
          PLOT_SCALE = true;
            showSoftmenu(-MNU_PLOT_STAT);
          break;
        case PLOT_NOTHING:
          break;
          default: ;
      }

      if((plotMode != PLOT_START) && (plotMode != PLOT_GRAPH) && (plotMode != H_PLOT) && (plotMode != H_NORM)) {
        fnPlotRegressionLine(plotMode);
      }
      else {
        lastPlotMode = plotMode;
      }
      #endif // !TESTSUITE_BUILD

  }
  else {
    calcMode = CM_NORMAL;
    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "There is no statistical/plot data available!");
      moreInfoOnError("In function fnPlotStat:", errorMessage, NULL, NULL);
    #endif
  }
#endif // SAVE_SPACE_DM42_13GRF
#endif // !TESTSUITE_BUILD
}


void fnPlotRegressionLine(uint16_t plotMode){
#if !defined(SAVE_SPACE_DM42_13GRF)
  #if defined(STATDEBUG) && defined(PC_BUILD)
    printf("fnPlotRegressionLine: plotSelection = %u; Plotmode=%u\n", plotSelection, plotMode);
  #endif // STATDEBUG && PC_BUILD

  switch(plotMode) {
    case PLOT_ORTHOF: {
      plotSelection = CF_ORTHOGONAL_FITTING;
      lrChosen = CF_ORTHOGONAL_FITTING;
      break;
    }

      //Show data and one curve fit selected: Scans lrSelection from LSB and stop after the first one is found. If a chosen curve is there, override.
      //printf("#####X %u %u \n",plotSelection, lrSelection);
    case PLOT_NXT: {
      plotSelection = plotSelection << 1;
      if(plotSelection == 0){
        plotSelection = 1;
      }

      while((plotSelection != ( (lrSelection == 0 ? 1023 : lrSelection) & plotSelection)) && (plotSelection < 1024)){ //fast forward to selected LR
        plotSelection = plotSelection << 1;
      }

      if(plotSelection >= 1024) {
        plotSelection = 0;  //purposely change to zero graph display to give a no-line view
      }
      break;
    }

    case PLOT_REV: {
      if(plotSelection == 0){
        plotSelection = 1024; //wraparound, will still shift right 1
      }
      plotSelection = plotSelection >> 1;
      if(plotSelection >= 1024){
        plotSelection = 0;  //purposely change to zero graph display to give a no line view
      }

      while((plotSelection != ( (lrSelection == 0 ? 1023 : lrSelection) & plotSelection)) && (plotSelection < 1024) && (plotSelection > 0)){ //fast forward to selected LR
        plotSelection = plotSelection >> 1;
      }

      break;
    }

    case PLOT_LR: {
      //Show data and one curve fit selected: Scans lrSelection from LSB and stop after the first one is found. If a chosen curve is there, override.
      plotSelection = lrChosen;
      if(plotSelection == 0) {
        plotSelection = 1;
      }
      while((plotSelection != ( (lrSelection == 0 ? 1023 : lrSelection) & plotSelection)) && (plotSelection < 1024)){
        plotSelection = plotSelection << 1;
      }
      if(plotSelection >= 1024) {
        plotSelection = 0;  //purposely change to zero graph display
      }
      break;
    }

    case PLOT_START: {
      plotMode = PLOT_ORTHOF;
      break;
    }

    case PLOT_NOTHING: {
      break;
    }

    default: {
      break;
    }
  }
#endif // !SAVE_SPACE_DM42_13GRF
}


void fnPlotZoom(uint16_t unusedButMandatoryParameter){
   PLOT_ZOOM = (PLOT_ZOOM + 1) & 0x03;
   switch(calcMode) {
    case CM_PLOT_STAT: {
      if(PLOT_ZOOM != 0) {
         PLOT_AXIS = true;
      }
      else {
         PLOT_AXIS = false;
      }
       break;
    }
    case CM_GRAPH: {
         PLOT_AXIS = true;
         break;
    }
    default: {
      break;
    }
   }
  #if !defined(TESTSUITE_BUILD)
     void refreshScreen(void);
  #endif // !TESTSUITE_BUILD
}


