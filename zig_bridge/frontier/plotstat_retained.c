// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnPlotStat z47_frontier_retained_fnPlotStat
#define fnPlotRegressionLine z47_frontier_retained_fnPlotRegressionLine
#include "../../src/c47/plotstat.c"

void z47_frontier_plot_set_plotstatmx_stats(void) {
	strcpy(plotStatMx, "STATS");
}

void z47_frontier_plot_set_plotstatmx_histo(void) {
	strcpy(plotStatMx, "HISTO");
}

void z47_frontier_plot_set_statmx_histo(void) {
	strcpy(statMx, "HISTO");
}

bool_t z47_frontier_plot_has_source_data(void) {
	return (plotStatMx[0] == 'S' && checkMinimumDataPoints(const_2)) ||
	       (plotStatMx[0] == 'D' && drawMxN() >= 2) ||
	       (plotStatMx[0] == 'H' && statMxN() >= 3);
}

void z47_frontier_plot_clear_screen_for_graph_entry(void) {
	if(!GRAPHMODE) {
		clearScreenOld(clrStatusBar, !clrRegisterLines, !clrSoftkeys);
	}
}