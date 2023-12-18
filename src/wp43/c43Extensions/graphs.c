// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//** //JM
 * \file graphs.c Graphing module
 ***********************************************/

/* C43 functions and routines written by JM, adapted from C43 to WP43 by JM */

#include "c43Extensions/graphs.h"

#include "charString.h"
#include "constantPointers.h"
#include "error.h"
#include "c43Extensions/addons.h"
#include "c43Extensions/graphText.h"
#include "items.h"
#include "math.h"
#include "plotstat.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/graph.h"
#include "stats.h"
#include "statusBar.h"
#include <string.h>

#include "wp43.h"

//#define STATDEBUG

bool_t    invalid_intg = true;
bool_t    invalid_diff = true;
bool_t    invalid_rms  = true;


void graph_reset(void){
  graph_dx      = 0;
  graph_dy      = 0;
  extentx       = false;
  extenty       = false;
  PLOT_VECT     = false;
  PLOT_NVECT    = false;
  PLOT_SCALE    = false;
  Aspect_Square = true;
  PLOT_LINE     = true;
  PLOT_CROSS    = false;
  PLOT_BOX      = false;
  PLOT_INTG     = false;
  PLOT_DIFF     = false;
  PLOT_RMS      = false;
  PLOT_SHADE    = false;
  PLOT_AXIS     = true;
  PLOT_ZMX      = 0;
  PLOT_ZMY      = 0;
  plotmode      = _SCAT;
}


void fnClGrf(uint16_t unusedButMandatoryParameter) {
  graph_reset();
  fnClDrawMx();
  strcpy(plotStatMx,"DrwMX");
  fnRefreshState();                //jm
}


void fnPline(uint16_t unusedButMandatoryParameter) {
  PLOT_LINE = !PLOT_LINE;
  if(!PLOT_LINE && !PLOT_CROSS && !PLOT_BOX) {
    PLOT_BOX = true;
  }
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPcros(uint16_t unusedButMandatoryParameter) {
  PLOT_CROSS = !PLOT_CROSS;
  if(PLOT_CROSS) {
    PLOT_BOX = false;
  }
  if(!PLOT_LINE && !PLOT_CROSS && !PLOT_BOX) {
    PLOT_LINE = true;
  }
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPbox (uint16_t unusedButMandatoryParameter) {
  PLOT_BOX = !PLOT_BOX;
  if(PLOT_BOX) {
    PLOT_CROSS = false;
  }
  if(!PLOT_LINE && !PLOT_CROSS && !PLOT_BOX) {
    PLOT_LINE = true;
  }
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPintg (uint16_t unusedButMandatoryParameter) {
  PLOT_INTG = !PLOT_INTG;
  if(!PLOT_INTG) {
    PLOT_SHADE = false;
  }
  PLOT_VECT  = false;
  PLOT_NVECT = false;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPdiff (uint16_t unusedButMandatoryParameter) {
  PLOT_DIFF  = !PLOT_DIFF;
  PLOT_VECT  = false;
  PLOT_NVECT = false;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPrms (uint16_t unusedButMandatoryParameter) {
  PLOT_RMS   = !PLOT_RMS;
  PLOT_VECT  = false;
  PLOT_NVECT = false;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPzoom (uint16_t param) {
  if(param == 1) {
    if(PLOT_ZMX < 0+3) {
      PLOT_ZMX++;
    }
    else {
      PLOT_ZMX = 0-1;
    }
    fnRefreshState();                //jm
    fnPlotSQ(0);
  }
  else if(param == 2) {
    if(PLOT_ZMY < 0+3) {
      PLOT_ZMY++;
    }
    else {
      PLOT_ZMY = 0-1;
    }
    fnRefreshState();
    fnPlotSQ(0);
  }
}


void fnPvect (uint16_t unusedButMandatoryParameter) {
  PLOT_VECT = !PLOT_VECT;
  if(PLOT_VECT) {
    PLOT_NVECT = false;
  }
  PLOT_INTG    = false;
  PLOT_DIFF    = false;
  PLOT_RMS     = false;
  PLOT_SHADE   = false;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPNvect (uint16_t unusedButMandatoryParameter) {
  PLOT_NVECT = !PLOT_NVECT;
  if(PLOT_NVECT) {
    PLOT_VECT = false;
  }
  PLOT_INTG   = false;
  PLOT_DIFF   = false;
  PLOT_RMS    = false;
  PLOT_SHADE  = false;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnScale (uint16_t unusedButMandatoryParameter) {
  PLOT_SCALE = !PLOT_SCALE;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPshade (uint16_t unusedButMandatoryParameter) {
  PLOT_SHADE = !PLOT_SHADE;
  if(PLOT_SHADE) {
    PLOT_INTG = true;
  }
  PLOT_VECT   = false;
  PLOT_NVECT  = false;
 fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPx (uint16_t unusedButMandatoryParameter) {
  extentx = !extentx;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPy (uint16_t unusedButMandatoryParameter) {
  extenty = !extenty;
  fnRefreshState();                //jm
  fnPlotSQ(0);
}


void fnPlotReset(uint16_t unusedButMandatoryParameter) {
  graph_dx      = 0;
  graph_dy      = 0;
  extentx       = true;
  extenty       = true;
  PLOT_VECT     = false;
  PLOT_NVECT    = false;
  PLOT_SCALE    = false;
  //Aspect_Square = true;
  PLOT_LINE     = true;
  PLOT_CROSS    = true;
  PLOT_BOX      = false;
  PLOT_INTG     = false;
  PLOT_DIFF     = false;
  PLOT_RMS      = false;
  PLOT_SHADE    = false;
  PLOT_AXIS     = true;
  PLOT_ZMX      = 0;
  PLOT_ZMY      = 0;
  PLOT_ZOOM     = 0;

  plotmode      = _SCAT;      //VECTOR or SCATTER
  tick_int_x    = 0;          //to show axis: tick_in_x & y = 10, PLOT_AXIS = true
  tick_int_y    = 0;

#if !defined(TESTSUITE_BUILD)
  fnPlotStatAdv(0);
  //fnPlotSQ(0);
#endif // !TESTSUITE_BUILD
}


void fnPlotSQ(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
  #if defined(DMCP_BUILD)
    lcd_refresh();
  #else // !DMCP_BUILD
    refreshLcd(NULL);
  #endif // DMCP_BUILD
  PLOT_AXIS = true;
//  hourGlassIconEnabled = true;
  //showHideHourGlass();
  Aspect_Square = true;
  if(!GRAPHMODE) {
    previousCalcMode = calcMode;
  }
  if(previousCalcMode == CM_GRAPH || previousCalcMode == CM_PLOT_STAT) {
    previousCalcMode = CM_NORMAL;
  }

  if(!GRAPHMODE) { //Change over hourglass to the left side
    clearScreenOld(clrStatusBar, !clrRegisterLines, !clrSoftkeys);
  }
  calcMode = CM_GRAPH;
  hourGlassIconEnabled = true;       //clear the current portion of statusbar
  showHideHourGlass();
  refreshStatusBar();

  calcMode = CM_GRAPH;
    if(softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_PLOT) {
      showSoftmenu(-MNU_PLOT);                         //JM MENU Prevent resetting the softmenu to the default no 1 page position
    }
  #endif // !TESTSUITE_BUILD
  doRefreshSoftMenu = true;             //Plot graph is part of refreshScreen
}


void fnListXY(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
  if((plotStatMx[0]=='S' ? statMxN() >= 1 : false) || (plotStatMx[0]=='D' ? drawMxN() >= 1 : false)) {
    calcMode = CM_LISTXY; //Used to view graph/listing
    ListXYposition = 0;
    }
  #endif // !TESTSUITE_BUILD
}


//added this, to add a new command to plot advanced from the STATS
#if !defined(TESTSUITE_BUILD)
  void fnPlotStatAdv(uint16_t unusedButMandatoryParameter) {
    lastPlotMode = PLOT_NOTHING;
    strcpy(plotStatMx, "STATS");
    PLOT_LINE = true;
    PLOT_SHADE = true;
    fnPlotSQ(0);
  }
#endif // !TESTSUITE_BUILD


#if !defined(TESTSUITE_BUILD)
  void plotarrow(uint16_t xo, uint8_t yo, uint16_t xn, uint8_t yn) {              // Plots line from xo,yo to xn,yn; uses temporary x1,y1
    float dx, dy, ddx, dydx, zz, zzz;
    dydx = yn-yo;
    ddx = xn-xo;
    zz  = sqrt(dydx*dydx + ddx*ddx);
    zzz = 3;
    dy  = dydx * (zzz/zz);
    dx  = ddx * (zzz/zz);
    #if defined(STATDEBUG)
      printf("%d %d  %d %d  ddx=%f, dydx=%f, zz=%f  zzz=%f, dx=%f, dy=%f \n", xo, yo, xn, yn, ddx, dydx, zz, zzz, dx, dy);
    #endif // STATDEBUG
    if(!(xo==xn && yo==yn)){
      plotline(xn+(-3*dx +dy), yn+(-3*dy -dx), xn, yn);
      plotline(xn+(-3*dx -dy), yn+(-3*dy +dx), xn, yn);
    }
    else {
      placePixel(xn,yn);
    }
  }


  void plotdeltabig(uint16_t xn, uint8_t yn) {              // Plots ldifferential sign; uses temporary x1,y1
    plotline(xn+0,   yn-2,   xn+0+5, yn-2+8);
    plotline(xn+0+5, yn-2+8, xn+0-5, yn-2+8);
    plotline(xn+0-5, yn-2+8, xn+0,   yn-2  );
  }


  void plotdelta(uint16_t xn, uint8_t yn) {             // Plots ldifferential sign; uses temporary x1,y1
    placePixel(xn+0, yn-2);                             //   PLOT a delta
    placePixel(xn-1, yn-1);
    placePixel(xn-1, yn+0);
    placePixel(xn-2, yn+1);
    placePixel(xn-2, yn+2);
    placePixel(xn+1, yn-1);
    placePixel(xn+1, yn-0);
    placePixel(xn+2, yn+1);
    placePixel(xn+2, yn+2);
    placePixel(xn-1, yn+2);
    placePixel(xn,   yn+2);
    placePixel(xn+1, yn+2);
  }


  void plotintbig(uint16_t xn, uint8_t yn) {            // Plots integral sign; uses temporary x1,y1
    plotline(xn-0, yn-2,   xn+3, yn-2);
    plotline(xn-0, yn-2+1, xn+3, yn-2+1);
    plotline(xn-3, yn-2+8, xn+0, yn-2+8);
    plotline(xn-3, yn-2+9, xn+0, yn-2+9);

    plotline(xn+0, yn-2+7, xn+0, yn-2+0);
    plotline(xn+1, yn-2+7, xn+1, yn-2+0);
  }


  void plotint(uint16_t xn, uint8_t yn) {               // Plots integral sign; uses temporary x1,y1
    placePixel(xn,   yn);                               //   PLOT a I
    placePixel(xn,   yn-1);
    placePixel(xn,   yn-2);
    placePixel(xn,   yn+1);
    placePixel(xn,   yn+2);
    placePixel(xn+1, yn-2);
    placePixel(xn-1, yn+2);
  }


  void plotrms(uint16_t xn, uint8_t yn) {               // Plots line from xo,yo to xn,yn; uses temporary x1,y1
    placePixel(xn+1, yn-1);                             //   PLOT a box
    placePixel(xn-1, yn-1);
    placePixel(xn-0, yn-1);
    placePixel(xn+1, yn);                               //   PLOT a box
    placePixel(xn-1, yn);
    placePixel(xn-0, yn);
    placePixel(xn+1, yn+1);                             //   PLOT a box
    placePixel(xn-1, yn+1);
    placePixel(xn-0, yn+1);

  }


  void plottriangle(uint16_t a, uint8_t b, uint16_t c, uint8_t d) {                // Plots rectangle from xo,yo to xn,yn; uses temporary x1,y1
    plotline(a, b, c, b);
    plotline(a, b, c, d);
    plotline(c, d, c, b);
  }
#endif  // !TESTSUITE_BUILD


//###################################################################################
void convertDigits(char * refstr, uint16_t ii, uint16_t * oo, char * outstr) {
  switch(refstr[ii]) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9': outstr[(*oo)++] = 0xa0; outstr[(*oo)++] = refstr[ii] + (0x80 - 48); break; //.
    case 'x': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xb3; break; //x ok
    case 'y': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xb4; break; //y ok
    case 'a': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0x9c; break; //a ok
    case 's': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xae; break; //s ok
    case ':': outstr[(*oo)++] = 0xa2; outstr[(*oo)++] = 0x36; break; //: ok
    case '+': outstr[(*oo)++] = 0xa0; outstr[(*oo)++] = 0x8a; break; //+ ok
    case '-': outstr[(*oo)++] = 0xa0; outstr[(*oo)++] = 0x8b; break; //- ok
    case '.': outstr[(*oo)++] = 0xa0; outstr[(*oo)++] = 0x1a; break; //. ok
    case '/': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0x25; break; /// ok
    case 't': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xaf; break; //t \xa4\xaf
    case 'i': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xa4; break; //i ok
    case 'c': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0x9e; break; //c ok
    case 'k': outstr[(*oo)++] = 0xa4; outstr[(*oo)++] = 0xa6; break; //k ok
    default:  outstr[(*oo)++] = refstr[ii];
  }
}


void graph_text(void) {
  #if !defined(TESTSUITE_BUILD)
    uint32_t ypos = Y_POSITION_OF_REGISTER_T_LINE -11 + 12 * 5 -45;
    uint16_t ii;
    static uint16_t oo;
    static char outstr[300];
    char ss[100], tt[100];
    char tmpbuf[PLOT_TMP_BUF_SIZE];
    int32_t n;
    eformat_eng2(ss, "(", x_max, 2, "");
    uint16_t ssw = showStringEnhanced(padEquals(tmpbuf, ss), &standardFont, 0, 0,vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_LF);
    eformat_eng2(tt, radixProcess(tmpbuf, "#"), y_max, 2, ")");
    uint16_t ttw = showStringEnhanced(padEquals(tmpbuf, tt), &standardFont, 0, 0,vmNormal, false, false, NO_compress, NO_raise, NO_Show, NO_LF);
    ypos += 38;
    n = showString(padEquals(tmpbuf, ss), &standardFont, 160-3-2-ssw-ttw, ypos, vmNormal, false, false);
    showString(padEquals(tmpbuf, tt), &standardFont, n+3, ypos, vmNormal, false, false);
    eformat_eng2(ss, "(", x_min, 2, "");
    ypos += 19;
    n = showString(padEquals(tmpbuf, ss), &standardFont,1, ypos, vmNormal, false, false);
    eformat_eng2(ss, radixProcess(tmpbuf, "#"), y_min, 2, ")");
    showString(padEquals(tmpbuf, ss), &standardFont, n+3,  ypos, vmNormal, false, false);
    ypos -= 38;

    snprintf(tmpString, TMP_STR_LENGTH, "  y %.3f/tick  ", tick_int_y);
    ii = 0;
    oo = 0;
    outstr[0] = 0;
    while(tmpString[ii] != 0) {
      convertDigits(tmpString, ii, &oo,outstr);
      ii++;
    }
    outstr[oo] = 0;
    showString(outstr, &standardFont, 1, ypos, vmNormal, true, true);  //JM
    ypos -= 12;

    snprintf(tmpString, TMP_STR_LENGTH, "  x %.3f/tick  ", tick_int_x);
    ii = 0;
    oo = 0;
    outstr[0] = 0;
    while(tmpString[ii] != 0) {
      convertDigits(tmpString, ii,&oo,outstr);
      ii++;
    }
    outstr[oo] = 0;
    showString(outstr, &standardFont, 1, ypos, vmNormal, true, true);  //JM
    ypos -= 12;


    uint32_t minnx, minny;
    if(!Aspect_Square) {
      minny = SCREEN_NONSQ_HMIN;
      minnx = 0;
    }
    else {
      minny = 0;
      minnx = SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH;
    }
    tmpString[0] = 0;                                  //If the axis is on the edge supress it, and label accordingly
    uint8_t axisdisp =  (!(yzero == SCREEN_HEIGHT_GRAPH-1 || yzero == minny) ? 2 : 0)
                      + (!(xzero == SCREEN_WIDTH-1        || xzero == minnx) ? 1 : 0);
    switch(axisdisp) {
      case 0: strcpy(tmpString,"            ");                    break;
      case 1: snprintf(tmpString, TMP_STR_LENGTH, "  y-axis x 0"); break;
      case 2: snprintf(tmpString, TMP_STR_LENGTH, "  x-axis y 0"); break;
      case 3: snprintf(tmpString, TMP_STR_LENGTH, "  axis 0.0 ");  break;
      default: ;
    }

    //Change to the small characters and fabricate a small = char
    ii = 0;
    oo = 0;
    outstr[0] = 0;
    while(tmpString[ii] != 0) {
      convertDigits(tmpString, ii, &oo, outstr);
      ii++;
    }
    outstr[oo] = 0;
    ii = showString(outstr, &standardFont, 1, ypos, vmNormal, true, true);  //JM
    if(tmpString[ stringByteLength(tmpString)-1 ] == '0') {
      #define sp 15
      plotline((uint16_t)(ii-17), (uint8_t)(ypos+2+sp), (uint16_t)(ii-11), (uint8_t)(ypos+2+sp));
      plotline((uint16_t)(ii-17), (uint8_t)(ypos+1+sp), (uint16_t)(ii-11), (uint8_t)(ypos+1+sp));
      plotline((uint16_t)(ii-17), (uint8_t)(ypos-1+sp), (uint16_t)(ii-11), (uint8_t)(ypos-1+sp));
      plotline((uint16_t)(ii-17), (uint8_t)(ypos-2+sp), (uint16_t)(ii-11), (uint8_t)(ypos-2+sp));
    }
    ypos += 48 + 2*19;

    if(PLOT_INTG && !invalid_intg) {
      snprintf(tmpString, TMP_STR_LENGTH, "  Trapezoid integral");
      showStringC43(tmpString, numSmall, nocompress, 1, ypos, vmNormal, true, true);  //JM
      plotintbig(5, ypos+4+4-2);
      plotrect(5+4-1, (ypos+4+4-2+2)-1, 5+4+2, (ypos+4+4-2+2)+2);
      ypos += 20;
    }

    if(PLOT_DIFF && !invalid_diff) {
      snprintf(tmpString, TMP_STR_LENGTH, "  Num. differential");
      showStringC43(tmpString, numSmall, nocompress, 1, ypos, vmNormal, true, true);  //JM
      plotdeltabig(6, ypos+4+4-2);
      ypos += 20;
    }

    if(PLOT_RMS && !invalid_rms) {
      snprintf(tmpString, TMP_STR_LENGTH, "  RMSy");
      showStringC43(tmpString, numSmall, nocompress, 1, ypos, vmNormal, true, true);  //JM
      plotrms(6, ypos+4+4-2);
      plotrect(6-1, (ypos+4+4-2)-1, 6+2, (ypos+4+4-2)+2);
      ypos += 20;
    }

    force_refresh(timed);
  #endif // !TESTSUITE_BUILD
}


//####################################################
//######### PLOT MEM #################################
//####################################################
void graph_plotmem(void) {
  #if !defined(SAVE_SPACE_DM42_13GRF_JM)
    #if !defined(TESTSUITE_BUILD)
      #if defined(STATDEBUG) && defined(PC_BUILD)
        uint16_t i;
        int16_t cnt1;
        cnt1 = drawMxN();
        printf("Stored values n=%i of matrix:%s\n",cnt1, plotStatMx);
        for(i = 0; i < cnt1; ++i) {
          printf("i = %3u x = %9f; y = %9f\n", i, grf_x(i), grf_y(i));
        }
      #endif // STATDEBUG && PC_BUILD

      if(!reDraw) {
        #if defined(PC_BUILD) && defined(MONITOR_CLRSCR)
          printf("graph_plotmem: Not reDrawing, text only\n");
        #endif // PC_BUILD &&MONITOR_CLRSCR
        clearScreenGraphs(1, clrTextArea, !clrGraphArea);
        graph_text();
        return;
      } else {
        #if defined(PC_BUILD) && defined(MONITOR_CLRSCR)
          printf("graph_plotmem: Drawing\n");
        #endif // PC_BUILD &&MONITOR_CLRSCR
        clearScreenGraphs(2, !clrTextArea, clrGraphArea);
        reDraw = false; //draw now and block reDraw in the next round
      } //continue with draw

      #if defined (LOW_GRAPH_ACC)
        //Change to SDIGS digit operation for graphs;
        ctxtReal34.digits = significantDigitsForScreen;
        ctxtReal39.digits = significantDigitsForScreen+3;
        ctxtReal51.digits = significantDigitsForScreen+3;
        ctxtReal75.digits = significantDigitsForScreen+3;
      #endif //LOW_GRAPH_ACC
      regStatsXY = findNamedVariable(plotStatMx);
      uint16_t cnt, ix, statnum;
      int16_t xo, xn, xN;
      int16_t yo, yn, yN;
      int16_t yN0 = 0, yN1 = 0;
      float x;
      float y;
      float sx, sy;
      float ddx = FLoatingMax;
      float dydx = FLoatingMax;
      float inty = 0;
      float inty0 = 0;
      float inty_off = 0;
      float rmsy = 0;

      statnum = 0;

      if((plotStatMx[0]=='S' ? statMxN() >= 2 : false) || (plotStatMx[0]=='D' ? drawMxN() >= 2:false)) {
        if(plotStatMx[0]=='S') {
          statnum = statMxN();  //          realToInt32(SIGMA_N, statnum);
        }
        else {
          statnum = drawMxN();
        }
        #if defined(STATDEBUG)
          printf("points n=%d\n", statnum);
        #endif // STATDEBUG
      }

      if(statnum >= 2) {
        //GRAPH SETUP

        roundedTicks = true;
        graph_axis();                        //Draw the axis on any uncontrolled scale to start. Maybe optimize by remembering if there is an image on screen Otherwise double axis draw.
        if(PLOT_AXIS) {
          graph_text();
        }

      if(PLOT_VECT || PLOT_NVECT) {
        plotmode = _VECT;
      }
      else {
        plotmode = _SCAT;
      }

        if(PLOT_INTG) {
          rmsy = fabs(grf_y(0));
          for(ix = 0; (ix < statnum); ++ix) {
            rmsy = sqrt((rmsy * rmsy * ix + grf_y(ix) * grf_y(ix)) / (ix+1.0));      // Changed rmsy to use the standard RMS calc, and not shoft it to the trapezium x-centre
          }
        inty_off = rmsy;
        }

        //AUTOSCALE
        x_min = FLoatingMax;
        x_max = FLoatingMin;
        y_min = FLoatingMax;
        y_max = FLoatingMin;
        #if defined(STATDEBUG)
          printf("Axis0: x: %f -> %f y: %f -> %f   \n", x_min, x_max, y_min, y_max);
        #endif // STATDEBUG
        if(plotmode != _VECT) {
          invalid_intg = false;                                                      //integral scale
          invalid_diff = false;                                                      //Differential dydx scale
          invalid_rms  = false;                                                      //RMSy

//#################################################### vvv SCALING LOOP DIFF INTG RMS vvv #########################
/**/      if(PLOT_DIFF || PLOT_INTG || PLOT_RMS) {
/**/        inty = inty_off;                                                          //  integral starting constant co-incides with graph
/**/        if(PLOT_RMS) {
/**/          rmsy = fabs(grf_y(0));
/**/        }
/**/
/**/        for(ix = 0; (ix < statnum); ++ix) {
/**/          if(ix != 0) {
/**/            ddx = grf_x(ix) - grf_x(ix-1);                                            //used in DIFF and INT
/**/            if(ddx<=0) {                                                              //Cannot get slop or area if x is not growing in positive dierection
/**/              x_min = FLoatingMax;
/**/              x_max = FLoatingMin;
/**/              y_min = FLoatingMax;
/**/              y_max = FLoatingMin;
/**/              invalid_diff = true;
/**/              invalid_intg = true;
/**/              invalid_rms  = true;
/**/              break;
/**/            }
/**/            else {
/**/              if(grf_x(ix) < x_min) {
/**/                x_min = grf_x(ix);
/**/              }
/**/              if(grf_x(ix) > x_max) {
/**/                x_max = grf_x(ix);
/**/              }
/**/              if(PLOT_DIFF) {
/**/                //plotDiff(); //dydx                                            //Differential
/**/                if(ddx != 0) {
/**/                  if(ix == 1) {                               // only two samples available
/**/                    dydx = (grf_y(ix) - grf_y(ix-1)) / ddx;   // Differential
/**/                  }
/**/                  else if(ix >= 2) {                          // ix >= 2 three samples available 0 1 2
/**/                    dydx = (grf_y(ix-2) - 4.0 * grf_y(ix-1) + 3.0 * grf_y(ix)) / 2.0 / ddx; //ChE 205 — Formulas for Numerical Differentiation, formule 32
/**/                  }
/**/                }
/**/                else {
/**/                  dydx = FLoatingMax;
/**/                }
/**/
/**/                if(dydx < y_min) {
/**/                  y_min = dydx;
/**/                }
/**/                if(dydx > y_max) {
/**/                  y_max = dydx;
/**/                }
/**/              }
/**/              if(PLOT_INTG) {
/**/                inty = inty + (grf_y(ix) + grf_y(ix-1)) / 2 * ddx;
/**/                if(inty < y_min) {
/**/                  y_min = inty;
/**/                }
/**/                if(inty > y_max) {
/**/                  y_max = inty;
/**/                }
/**/              }
/**/              if(PLOT_RMS) {
/**/                rmsy = sqrt((rmsy * rmsy * ix + grf_y(ix) * grf_y(ix)) / (ix+1.0));      // Changed rmsy to use the standard RMS calc, and not shoft it to the trapezium x-centre
/**/                if(rmsy < y_min) {
/**/                  y_min = rmsy;
/**/                }
/**/                if(rmsy > y_max) {
/**/                  y_max = rmsy;
/**/                }
/**/              }
/**/            }
/**/          }
/**/          if(keyWaiting()) {
/**/             return;
/**/          }
/**/        }
/**/      }
//#################################################### ^^^ SCALING LOOP ^^^ #########################

          #if defined(STATDEBUG)
            printf("Axis0b1: x: %f -> %f y: %f -> %f  %d \n", x_min, x_max, y_min, y_max, invalid_diff);
          #endif // STATDEBUG

//#################################################### vvv SCALING LOOP  vvv #########################
/**/      uint16_t y_maxcnt=2;
/**/      uint16_t y_mincnt=2;
/**/      float a0,a1,a2,a3,a4,a5,a6,a7,a8;   //Digital filter to get rid of short sharp peak like some asymptotes
/**/      float aa = 1;
/**/      a0 = 0;
/**/      a1 = 0;
/**/      a2 = 0;
/**/      a3 = 0;
/**/      a4 = 0;
/**/      a5 = 0;
/**/      a6 = 0;
/**/      a7 = 0;
/**/      a8 = 0;
/**/
/**/      if(PLOT_BOX || PLOT_LINE || PLOT_CROSS || !(PLOT_DIFF || PLOT_INTG)) {  //XXXX
/**/        for(cnt=0; (cnt < statnum); cnt++) {
/**/          #if defined(STATDEBUG)
/**/            printf("Axis0a: cnt/statnum: %i/%i  x: %f y: %f   \n", cnt, statnum, grf_x(cnt), grf_y(cnt));
/**/          #endif // STATDEBUG
/**/          if(grf_x(cnt) < x_min) {
/**/            x_min = grf_x(cnt);
/**/          }
/**/          if(grf_x(cnt) > x_max) {
/**/            x_max = grf_x(cnt);
/**/          }
/**/          a8 = a7;
/**/          a7 = a6;
/**/          a6 = a5;
/**/          a5 = a4;
/**/          a4 = a3;
/**/          a3 = a2;
/**/          a2 = a1;
/**/          a1 = a0;
/**/          a0 = grf_y(cnt);
/**/          aa = a8*0.2 + a7 *0.2 + a6*0.1 + a5*0.1 + a4*0.1 + a3*0.1 + a2*0.1 + a1*0.1;
/**/          if(aa != 0 && fabs(a0/aa) < 3) {
/**/            aa = a0 * 1.1;
/**/          }
/**/          //printf("%f %f %f %f %f %f %f %f %f  %f\n", a8, a7, a6, a5, a4, a3, a2, a1, a0, aa);
/**/          if(aa < y_min) {
/**/            y_mincnt++;
/**/            if(fabs(aa / y_min) < 4 || aa == a0 * 1.1) {
/**/              if(aa < y_min) {
/**/               y_min = aa;
/**/              }
/**/              y_mincnt=0;
/**/            }
/**/            else if(y_mincnt==3) {
/**/              y_min = aa;
/**/              y_mincnt=0;
/**/            }
/**/          }
/**/          else {
/**/           y_mincnt=0;
/**/          }
/**/
/**/          if(aa > y_max) {
/**/            y_maxcnt++;
/**/            if(fabs(aa / y_max) < 4 || aa == a0 * 1.1) {
/**/              if(aa>y_max) y_max = aa;
/**/              y_maxcnt=0;
/**/            }
/**/            else if(y_maxcnt==3) {
/**/              y_max = aa;
/**/              y_maxcnt=0;
/**/            }
/**/          } else y_maxcnt=0;
/**/
/**/          #if defined(STATDEBUG)
/**/            printf("Axis0b: x: %f -> %f y: %f -> %f   \n", x_min, x_max, y_min, y_max);
/**/          #endif // STATDEBUG
/**/          if(keyWaiting()) {
/**/            return;
/**/          }
/**/        }
/**/      }
/**/    }
/**/
/**/    else {                 //VECTOR
/**/      sx =0;
/**/      sy =0;
/**/      for(cnt=0; (cnt < statnum); cnt++) {            //### Note XXX E- will stuff up statnum!
/**/        sx = sx + (!PLOT_NVECT ? grf_x(cnt) : grf_y(cnt));
/**/        sy = sy + (!PLOT_NVECT ? grf_y(cnt) : grf_x(cnt));
/**/        if(sx < x_min) {
/**/          x_min = sx;
/**/        }
/**/        if(sx > x_max) {
/**/          x_max = sx;
/**/        }
/**/        if(sy < y_min) {
/**/          y_min = sy;
/**/        }
/**/        if(sy > y_max) {
/**/          y_max = sy;
/**/        }
/**/        if(keyWaiting()) {
/**/          return;
/**/        }
/**/      }
/**/    }
//#################################################### ^^^ SCALING LOOP ^^^ #########################


        //Manipulate the obtained axes positions
        #if defined(STATDEBUG)
          printf("Axis1a: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG

        //Check and correct if min and max is swapped
        if(x_min>0.0f && x_min > x_max) {
          x_min = x_min - (-x_max+x_min)* 1.1f;
        }
        if(x_min<0.0f && x_min > x_max) {
          x_min = x_min + (-x_max+x_min)* 1.1f;
        }
        #if defined(STATDEBUG)
          printf("Axis1b: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG


        //Always include the 0 axis
        if(!extentx) {
          if(x_min > 0.0f && x_max > 0.0f) {
            if(x_min <= x_max) {
              x_min = -0.05f * x_max;
            }
            else {
              x_min = 0.0f;
            }
          }
          if(x_min < 0.0f && x_max < 0.0f) {
            if(x_min >= x_max) {
              x_min = -0.05f * x_max;
            }
            else {
              x_max = 0.0f;
            }
          }
        }
        if(!extenty) {
          if(y_min > 0.0f && y_max > 0.0f) {
            if(y_min <= y_max) {
              y_min = -0.05f * y_max;
            }
            else {
              y_min = 0.0f;
            }
          }
          if(y_min < 0.0f && y_max < 0.0f) {
            if(y_min >= y_max) {
              y_min = -0.05f * y_max;
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
        #if defined(STATDEBUG)
          printf("Axis2: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG

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

        x_min = x_min - dx * zoomfactor * (pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03)));
        y_min = y_min - dy * zoomfactor * (pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03)));
        x_max = x_max + dx * zoomfactor * (pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03)));
        y_max = y_max + dy * zoomfactor * (pow(4.5f, (int8_t)(PLOT_ZOOM & 0x03)));
        #if defined(STATDEBUG) && defined(PC_BUILD)
          printf("Axis3a: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG


        roundedTicks = true;
        graph_axis();
        if(PLOT_AXIS) {
          graph_text();
        }

        #if defined(STATDEBUG)
          printf("Axis3b: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG


        if(plotmode != _VECT) {
          yn = screen_window_y(y_min,grf_y(0),y_max);
          xn = screen_window_x(x_min,grf_x(0),x_max);
          xN = xn;
          yN = yn;
        }
        else {
          yn = screen_window_y(y_min,0,y_max);
          xn = screen_window_x(x_min,0,x_max);
          xN = xn;
          yN = yn;
        }

        #if defined(STATDEBUG)
          printf("Axis3c: x: %f -> %f y: %f -> %f   \n",x_min, x_max, y_min, y_max);
        #endif // STATDEBUG

        sx = 0;
        sy = 0;
        //GRAPH
        ix = 0;
        inty = inty_off;                                                         //  integral starting constant co-incides with graph
        rmsy = 0;
        if(PLOT_RMS) {
          rmsy = fabs(grf_y(0));
        }

        //#################################################### vvv MAIN GRAPH LOOP vvv #########################
        for(ix = 0; (ix < statnum); ++ix) {
          if(plotmode != _VECT) {
            x = 0;
            y = 0;

            if(ix !=0 && ( (PLOT_DIFF && !invalid_diff) || (PLOT_INTG && !invalid_intg) || (PLOT_RMS && !invalid_rms) )) {
              ddx = grf_x(ix) - grf_x(ix-1);
              if(PLOT_DIFF && ddx != 0) {
                if(ix == 1) {                               // only two samples available
                  dydx = (grf_y(ix) - grf_y(ix-1)) / ddx;   // Differential
                }
                else { //if(ix >= 2)                        // ix >= 2 three samples available 0 1 2
                  dydx = ( grf_y(ix-2) - 4.0 * grf_y(ix-1) + 3.0 * grf_y(ix) ) / 2.0 / ddx; //ChE 205 — Formulas for Numerical Differentiation, formule 32
                }
              }
              else {
                dydx = FLoatingMax;
              }

              x = (grf_x(ix) + grf_x(ix-1))/2;
              if(PLOT_DIFF) {
                y = dydx;                 //y is the default graph
              }
              if(PLOT_RMS)  {
                rmsy = sqrt ( (rmsy * rmsy * ix + grf_y(ix) * grf_y(ix)) / (ix+1.0) );      // Changed rmsy to use the standard RMS calc, and not shoft it to the trapezium x-centre
                y = rmsy;                 //y is the default graph
              }
              if(PLOT_INTG) {
                inty0 = inty;
                inty = inty + (grf_y(ix) + grf_y(ix-1)) / 2 * ddx;
                y = inty;                 //y is the default graph
              }
            }

            if(PLOT_BOX || PLOT_LINE || PLOT_CROSS) {
              x = grf_x(ix);
              y = grf_y(ix);
            }
          }
          else {
            sx = sx + (!PLOT_NVECT ? grf_x(ix) : grf_y(ix));
            sy = sy + (!PLOT_NVECT ? grf_y(ix) : grf_x(ix));
            x = sx;
            y = sy;
          }
          xo = xN;
          yo = yN;
          xN = screen_window_x(x_min,x,x_max);
          yN0 = yN1;
          yN1 = screen_window_y_nolimit(y_min,y,y_max);
          yN = yN1;


          #if defined(STATDEBUG)
            printf("xN = %d : (x_min=%f,x=%f,x_max=%f) \n",xN, x_min,x,x_max);
            printf("yN = %d yN0 = %d yN1 = %d : (y_min=%f,y=%f,y_max=%f) \n",yN, yN0, yN1, y_min,y,y_max);
            printf("plotting graph table[%d] = x:%f y:%f dydx:%f inty:%f xN:%d yN:%d ", ix, x, y, dydx, inty, xN, yN);
            printf(" ... x-ddx/2=%d dydx=%d inty=%d\n", screen_window_x(x_min, x-ddx/2, x_max), screen_window_y(y_min, dydx, y_max), screen_window_y(y_min, inty, y_max));
          #endif // STATDEBUG


          bool_t outOfScreen = ((yN1 > SCREEN_HEIGHT_GRAPH - 1) && (yN0 > SCREEN_HEIGHT_GRAPH - 1)) || ((yN1 < 0) && (yN0 < 0));
          if(yN1 != yN0 && !outOfScreen && (
            ((yN1 <= SCREEN_HEIGHT_GRAPH - 1 && yN1 >= 0) && (yN0 > SCREEN_HEIGHT_GRAPH - 1 || yN0 < 0)) //||
         //   ((yN0 <= SCREEN_HEIGHT_GRAPH - 1 && yN0 >= 0) && (yN1 > SCREEN_HEIGHT_GRAPH - 1 || yN1 < 0))
            )) {

            int16_t dY1 = yN0 > SCREEN_HEIGHT_GRAPH - 1 ? SCREEN_HEIGHT_GRAPH - 1 - yN1 : yN1;
            float dxN = ((float)dY1)/((float)(yN1-yN0))*(float)(xN-xo);
            if(dxN<-25) dxN = -25; else if(dxN>25) dxN = 25;
            xo += (xN-xo)-max((int16_t)dxN,-(int16_t)dxN);
            yo = yN0 > SCREEN_HEIGHT_GRAPH - 1 ? SCREEN_HEIGHT_GRAPH - 1 : 0;
          }

          if(xN > SCREEN_WIDTH_GRAPH - 1) xN = SCREEN_WIDTH_GRAPH - 1;
          if(yN > SCREEN_HEIGHT_GRAPH - 1) yN = SCREEN_HEIGHT_GRAPH - 1;
          if(yN < 0) yN = 0;

          int16_t minN_y, minN_x;
          if(!Aspect_Square) {
            minN_y = SCREEN_NONSQ_HMIN; minN_x = 0;
          }
          else {
            minN_y = 0;
            minN_x = SCREEN_WIDTH-SCREEN_HEIGHT_GRAPH;
          }
          if((xN < SCREEN_WIDTH_GRAPH && xN >= minN_x && yN < SCREEN_HEIGHT_GRAPH && yN >= minN_y) && !outOfScreen)  {
            //yo = yn;                              //old , new, to be able to draw a line between samples
            yn = yN;
            //xo = xn;
            xn = xN;

            #if defined(STATDEBUG)
              printf("invalid_diff=%d invalid_intg=%d invalid_rms=%d \n", invalid_diff, invalid_intg, invalid_rms);
            #endif // STATDEBUG

            if(plotmode != _VECT) {
              #if defined(STATDEBUG)
                printf("Not _VECT\n");
              #endif // STATDEBUG

              if(PLOT_CROSS) {
                #if defined(STATDEBUG)
                  printf("Plotting cross to x=%d y=%d\n", xn, yn);
                #endif // STATDEBUG
                plotcross(xn,yn);
              }

              if(PLOT_BOX) {
                #if defined(STATDEBUG)
                  printf("Plotting box to x=%d y=%d\n", xn, yn);
                #endif // STATDEBUG
                plotbox(xn,yn);
              }
              //else placePixel(xn,yn);

              if(PLOT_DIFF && !invalid_diff && ix != 0) {
                #if defined(STATDEBUG)
                  printf("Plotting Delta x=%f dy=%f \n", x - ddx/2, dydx);
                #endif // STATDEBUG
                plotdelta(screen_window_x( x_min, x - ddx/2, x_max), screen_window_y(y_min, dydx, y_max));
              }


              if(PLOT_RMS && !invalid_rms && ix != 0) {
                #if defined(STATDEBUG)
                  printf("Plotting RMSy x=%f rmsy=%f \n", x - ddx/2, rmsy);
                #endif // STATDEBUG
                plotrms(screen_window_x(x_min, x - ddx/2, x_max), screen_window_y(y_min, rmsy, y_max));
              }


              if(PLOT_INTG && !invalid_intg && ix !=0) {
                #if defined(STATDEBUG)
                  printf("Plotting Integral x=%f intg(x)=%f\n", x-ddx/2, inty);
                #endif // STATDEBUG
                uint16_t xN0   = screen_window_x(x_min, grf_x(ix-1), x_max);
                //uint16_t xN1   = screen_window_x(x_min, grf_x(ix), x_max);
                uint16_t yNoff = screen_window_y(y_min, inty_off, y_max);
                uint16_t yN0   = screen_window_y(y_min, inty0, y_max);
                uint16_t yNintg= screen_window_y(y_min, inty, y_max);
                uint16_t xAvg  = ((xN0+xN) >> 1);

                if(abs((int16_t)(xN-xN0)>=6)) {
                  plotint( xAvg, yNintg );
                }
                else {
                  //placePixel(xAvg, yNintg);
                  plotrect(xAvg-1, yNintg-1, xAvg+1, yNintg+1);
                }

                if(abs((int16_t)(xN-xN0) >= 6)) {
                  plotline(xN,     yNintg, xAvg+2, yNintg);
                  plotline(xAvg-2, yNintg, xN0,    yNintg);
                }
                else if(abs((int16_t)(xN-xN0) >= 4)) {
                  plotline(xN,     yNintg, xAvg+2, yNintg);
                  plotline(xAvg-2, yNintg, xN0,    yNintg);
                }

                if(PLOT_SHADE) {
                  if(abs((int16_t)(xN-xN0) >= 6)) {
                    plotrect(xN0, yNoff, xN, yN0);
                    plotrect(xN0, yN0,   xN, yNintg);
                    plotline(xN0, yN0,   xN, yNintg);
                  }
                  else {
                    plotrect(xN0, yNoff, xN, yNintg);
                    plotrect(xN0, yN0,   xN, yNintg);
                  }
                }
              }
            }
            else {
              #if defined(STATDEBUG)
                printf("Plotting arrow\n");
              #endif // STATDEBUG
              plotarrow(xo, yo, xn, yn);
            }

            if(PLOT_LINE) {
              #if defined(STATDEBUG)
                printf("Plotting line from xo=%d yo=%d to x=%d y=%d\n", xo, yo, xn, yn);
              #endif // STATDEBUG
              plotline2(xo, yo, xn, yn);
            }
          }
          else {
            #if defined(PC_BUILD)
              printf("Not plotted: ");
              if(!(xN < SCREEN_WIDTH_GRAPH)) {
                printf("NOT xN<SCREEN_WIDTH_GRAPH; ");
              }
              if(!(xN >= minN_x)) {
                printf("NOT xN>=minN_x; ");
              }
              if(!(yN < SCREEN_HEIGHT_GRAPH)) {
                printf("NOT yN<SCREEN_HEIGHT_GRAPH");
              }
              if(!(yN >= minN_y)) {
                printf("NOT yN>=minN_y; ");
              }
              printf("Not plotted: xN=%d<SCREEN_WIDTH_GRAPH=%d && xN=%d>=minN_x=%d && yN=%d<SCREEN_HEIGHT_GRAPH=%d && yN=%d>=minN_y=%d\n", xN, SCREEN_WIDTH_GRAPH, xN, minN_x, yN, SCREEN_HEIGHT_GRAPH, yN, minN_y);
            #endif // PC_BUILD
          }
          if(keyWaiting()) {
            return;
          }
        }
        //#################################################### ^^^ MAIN GRAPH LOOP ^^^ #########################
      }
      else {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "There is no statistical data available!");
          moreInfoOnError("In function graph_plotmem:", errorMessage, NULL, NULL);
        #endif // EXTRA_INFO_ON_CALC_ERROR == 1
      }

      #if defined (LOW_GRAPH_ACC)
        //Change to normal operation for graphs;
        ctxtReal34.digits = 34;
        ctxtReal39.digits = 39;
        ctxtReal51.digits = 51;
        ctxtReal75.digits = 75;
      #endif //LOW_GRAPH_ACC
    #endif // !TESTSUITE_BUILD
  #endif // !SAVE_SPACE_DM42_13GRF_JM
}


//-----------------------------------------------------//-----------------------------------------------------
void fnStatList() {
  #if !defined(TESTSUITE_BUILD)
    char tmpstr1[100], tmpstr2[100];
    int16_t ix, ixx, statnum;

    clearScreen();
    refreshStatusBar();

    if(PLOT_VECT || PLOT_NVECT) {
      plotmode = _VECT;
    }
    else {
      plotmode = _SCAT;
    }

    if(regStatsXY != INVALID_VARIABLE && 
      ((plotStatMx[0] == 'S' ? statMxN() >= 1 : false) || (plotStatMx[0]=='D' ? drawMxN() >= 1 : false))) {

      if(plotStatMx[0] == 'S') {
        statnum = realToInt32C47(SIGMA_N);
      }
      else {
        statnum = drawMxN();
      }
      runFunction(ITM_NSIGMA);
      sprintf(tmpString, "Stat data: N = %d", statnum);

      runFunction(ITM_DROP);
      print_linestr(tmpString, true);
      #if defined(STATDEBUG)
        printf("Stat data %d - %d (%s)\n",statnum-1, max(0, statnum-1-6), tmpString );
      #endif // STATDEBUG

      if(ListXYposition > 0) {
        ListXYposition = 0;
      }
      else if(statnum - (min(10,statnum)-1) - 1 + ListXYposition < 0) {
        ListXYposition = - (statnum - (min(10,statnum)-1) - 1);
      }

      for(ix = 0; (ix < min(10,statnum)); ++ix) {
        ixx = statnum - ix - 1 + ListXYposition;

        if(((fabs(grf_x(ixx)) > 0.000999 || grf_x(ixx) == 0) && fabs(grf_x(ixx)) < 1000000)) {
          sprintf(tmpstr1,"[%3d] x%19.7f, ",ixx+1, grf_x(ixx));
        }
        else {
          sprintf(tmpstr1,"[%3d] x%19.7e, ",ixx+1, grf_x(ixx)); //round(grf_x(ixx)*1e10)/1e10);
        }

        if(((fabs(grf_y(ixx)) > 0.000999 || grf_y(ixx) == 0) && fabs(grf_y(ixx)) < 1000000)) {
          sprintf(tmpstr2,"y%19.7f", grf_y(ixx));
        }
        else {
          sprintf(tmpstr2,"y%19.7e", grf_y(ixx)); //round(grf_y(ixx)*1e10)/1e10);
        }

        strcat(tmpstr1,tmpstr2);

        print_numberstr(tmpstr1,false);
        #if defined(STATDEBUG)
          printf("%d:%s\n",ixx,tmpstr1);
        #endif // STATDEBUG
      }
    }
  #endif // !TESTSUITE_BUILD
}
