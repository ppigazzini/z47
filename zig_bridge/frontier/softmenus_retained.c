// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnDynamicMenu z47_frontier_retained_fnDynamicMenu
#include "../../src/c47/softmenus.c"

int16_t z47_frontier_dynamic_menu_softmenu_id(void) {
	return softmenuStack[0].softmenuId;
}

int16_t z47_frontier_dynamic_menu_item(void) {
	return dynamicMenuItem;
}