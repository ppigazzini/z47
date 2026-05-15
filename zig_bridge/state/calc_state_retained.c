// SPDX-License-Identifier: GPL-3.0-only

#define doSave z47_calc_state_retained_doSave
#define doLoad z47_calc_state_retained_doLoad
#define fnSave z47_calc_state_retained_fnSave
#define fnLoad z47_calc_state_retained_fnLoad
#define fnSaveAuto z47_calc_state_retained_fnSaveAuto
#define fnLoadAuto z47_calc_state_retained_fnLoadAuto
#define saveCalc z47_calc_state_retained_saveCalc
#define restoreCalc z47_calc_state_retained_restoreCalc

#include "../../src/c47/saveRestoreCalcState.c"

#undef doSave
#undef doLoad
#undef fnSave
#undef fnLoad
#undef fnSaveAuto
#undef fnLoadAuto
#undef saveCalc
#undef restoreCalc

#if !defined(DMCP_BUILD)

void z47_calc_state_reset_load_context(void) {
	savedCalcModel = 0;
	loadedVersion = 0;
}

void z47_calc_state_set_saved_calc_model(uint16_t saved_calc_model) {
	savedCalcModel = saved_calc_model;
}

uint16_t z47_calc_state_get_saved_calc_model(void) {
	return savedCalcModel;
}

void z47_calc_state_set_loaded_version(uint32_t version) {
	loadedVersion = version;
}

uint32_t z47_calc_state_get_loaded_version(void) {
	return loadedVersion;
}

uint32_t z47_calc_state_get_version_allowed(void) {
	return VersionAllowed;
}

uint32_t z47_calc_state_get_config_file_version(void) {
	return configFileVersion;
}

bool_t z47_calc_state_restore_one_section(uint16_t loadMode, uint16_t s, uint16_t n, uint16_t d, bool_t allowUserKeys) {
	return restoreOneSection(loadMode, s, n, d, allowUserKeys);
}

void z47_calc_state_save_sections(void) {
	char tmpString[3000];
	calcRegister_t regist;
	uint32_t i;
	char yy1[35], yy2[35];

	hourGlassIconEnabled = true;
	showHideHourGlass();

	sprintf(tmpString, "SAVE_FILE_REVISION\n%" PRIu8 "\n", (uint8_t)0);
	save(tmpString, strlen(tmpString));
	#if CALCMODEL == USER_R47
		sprintf(tmpString, "R47_save_file_00\n%" PRIu32 "\n", (uint32_t)configFileVersion);
	#else
		sprintf(tmpString, "C47_save_file_00\n%" PRIu32 "\n", (uint32_t)configFileVersion);
	#endif
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "GLOBAL_REGISTERS\n%" PRIu16 "\n", (uint16_t)(LAST_GLOBAL_REGISTER + 1));
	save(tmpString, strlen(tmpString));
	for(regist = FIRST_GLOBAL_REGISTER; regist <= LAST_GLOBAL_REGISTER; regist++) {
		registerToSaveString(regist);
		sprintf(tmpString, "R%03" PRId16 "\n%s\n%s\n", regist, aimBuffer1, tmpRegisterString);
		save(tmpString, strlen(tmpString));
		saveMatrixElements(regist);
	}

	strcpy(tmpString, "GLOBAL_FLAGS\n");
	save(tmpString, strlen(tmpString));
	sprintf(tmpString, "%" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 " %" PRIu16 "\n",
											 globalFlags[0],
																	 globalFlags[1],
																							 globalFlags[2],
																													 globalFlags[3],
																																			 globalFlags[4],
																																									 globalFlags[5],
																																															 globalFlags[6],
																																																					 globalFlags[7]);
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "LOCAL_REGISTERS\n%" PRIu8 "\n", currentNumberOfLocalRegisters);
	save(tmpString, strlen(tmpString));
	for(i = 0; i < currentNumberOfLocalRegisters; i++) {
		registerToSaveString(FIRST_LOCAL_REGISTER + i);
		sprintf(tmpString, "R.%02" PRIu32 "\n%s\n%s\n", i, aimBuffer1, tmpRegisterString);
		save(tmpString, strlen(tmpString));
		saveMatrixElements(FIRST_LOCAL_REGISTER + i);
	}

	if(currentLocalRegisters) {
		sprintf(tmpString, "LOCAL_FLAGS\n%" PRIu32 "\n", *currentLocalFlags);
		save(tmpString, strlen(tmpString));
	}

	sprintf(tmpString, "NAMED_VARIABLES\n%" PRIu16 "\n", numberOfNamedVariables);
	save(tmpString, strlen(tmpString));
	for(i = 0; i < numberOfNamedVariables; i++) {
		registerToSaveString(FIRST_NAMED_VARIABLE + i);
		stringToUtf8((char *)allNamedVariables[i].variableName + 1, (uint8_t *)tmpString);
		sprintf(tmpString + strlen(tmpString), "\n%s\n%s\n", aimBuffer1, tmpRegisterString);
		save(tmpString, strlen(tmpString));
		saveMatrixElements(FIRST_NAMED_VARIABLE + i);
	}

	sprintf(tmpString, "STATISTICAL_SUMS\n%" PRIu16 "\n", (uint16_t)(statisticalSumsPointer ? NUMBER_OF_STATISTICAL_SUMS : 0));
	save(tmpString, strlen(tmpString));
	for(i = 0; i < (statisticalSumsPointer ? NUMBER_OF_STATISTICAL_SUMS : 0); i++) {
		realToString(statisticalSumsPointer + i, tmpRegisterString);
		sprintf(tmpString, "%s\n", tmpRegisterString);
		save(tmpString, strlen(tmpString));
	}

	UI64toString(systemFlags0, yy1);
	sprintf(tmpString, "SYSTEM_FLAGS\n%s\n", yy1);
	save(tmpString, strlen(tmpString));
	UI64toString(systemFlags1, yy1);
	sprintf(tmpString, "SYSTEM_FLAGS1\n%s\n", yy1);
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "KEYBOARD_ASSIGNMENTS\n37\n");
	save(tmpString, strlen(tmpString));
	for(i = 0; i < 37; i++) {
		sprintf(tmpString, "%" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 " %" PRId16 "\n",
												 kbd_usr[i].keyId,
																		 kbd_usr[i].primary,
																								 kbd_usr[i].fShifted,
																														 kbd_usr[i].gShifted,
																																				 kbd_usr[i].keyLblAim,
																																										 kbd_usr[i].primaryAim,
																																																 kbd_usr[i].fShiftedAim,
																																																						 kbd_usr[i].gShiftedAim,
																																																												 kbd_usr[i].primaryTam);
		save(tmpString, strlen(tmpString));
	}
	if(loadedVersion < 10000023) {
		setLongPressFg(calcModel, -MNU_HOME);
	}

	sprintf(tmpString, "KEYBOARD_ARGUMENTS\n");
	save(tmpString, strlen(tmpString));

	uint32_t num = 0;
	for(i = 0; i < 37 * 6; ++i) {
		if(*(getNthString((uint8_t *)userKeyLabel, i)) != 0) {
			++num;
		}
	}
	sprintf(tmpString, "%" PRIu32 "\n", num);
	save(tmpString, strlen(tmpString));

	for(i = 0; i < 37 * 6; ++i) {
		if(*(getNthString((uint8_t *)userKeyLabel, i)) != 0) {
			sprintf(tmpString, "%" PRIu32 " ", i);
			stringToUtf8((char *)getNthString((uint8_t *)userKeyLabel, i), (uint8_t *)tmpString + strlen(tmpString));
			strcat(tmpString, "\n");
			save(tmpString, strlen(tmpString));
		}
	}

	sprintf(tmpString, "MYMENU\n18\n");
	save(tmpString, strlen(tmpString));
	for(i = 0; i < 18; i++) {
		sprintf(tmpString, "%" PRId16, userMenuItems[i].item);
		if(userMenuItems[i].argumentName[0] != 0) {
			strcat(tmpString, " ");
			stringToUtf8(userMenuItems[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
		}
		strcat(tmpString, "\n");
		save(tmpString, strlen(tmpString));
	}

	sprintf(tmpString, "MYALPHA\n18\n");
	save(tmpString, strlen(tmpString));
	for(i = 0; i < 18; i++) {
		sprintf(tmpString, "%" PRId16, userAlphaItems[i].item);
		if(userAlphaItems[i].argumentName[0] != 0) {
			strcat(tmpString, " ");
			stringToUtf8(userAlphaItems[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
		}
		strcat(tmpString, "\n");
		save(tmpString, strlen(tmpString));
	}

	sprintf(tmpString, "USER_MENUS\n");
	save(tmpString, strlen(tmpString));
	sprintf(tmpString, "%" PRIu16 "\n", numberOfUserMenus);
	save(tmpString, strlen(tmpString));
	for(uint32_t j = 0; j < numberOfUserMenus; ++j) {
		stringToUtf8(userMenus[j].menuName, (uint8_t *)tmpString);
		strcat(tmpString, "\n18\n");
		save(tmpString, strlen(tmpString));
		for(i = 0; i < 18; i++) {
			sprintf(tmpString, "%" PRId16, userMenus[j].menuItem[i].item);
			if(userMenus[j].menuItem[i].argumentName[0] != 0) {
				strcat(tmpString, " ");
				stringToUtf8(userMenus[j].menuItem[i].argumentName, (uint8_t *)tmpString + strlen(tmpString));
			}
			strcat(tmpString, "\n");
			save(tmpString, strlen(tmpString));
		}
	}

	uint16_t currentSizeInBlocks = RAM_SIZE_IN_BLOCKS - TO_C47MEMPTR(beginOfProgramMemory);
	sprintf(tmpString, "PROGRAMS\n%" PRIu16 "\n", currentSizeInBlocks);
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_C47MEMPTR(currentStep), (uint32_t)((void *)currentStep - TO_PCMEMPTR(TO_C47MEMPTR(currentStep))));
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "%" PRIu32 "\n%" PRIu32 "\n", (uint32_t)TO_C47MEMPTR(firstFreeProgramByte), (uint32_t)((void *)firstFreeProgramByte - TO_PCMEMPTR(TO_C47MEMPTR(firstFreeProgramByte))));
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "%" PRIu16 "\n", freeProgramBytes);
	save(tmpString, strlen(tmpString));

	for(i = 0; i < currentSizeInBlocks; i++) {
		sprintf(tmpString, "%" PRIu32 "\n", *(((uint32_t *)(beginOfProgramMemory)) + i));
		save(tmpString, strlen(tmpString));
	}

	sprintf(tmpString, "EQUATIONS\n%" PRIu16 "\n", numberOfFormulae);
	save(tmpString, strlen(tmpString));

	for(i = 0; i < numberOfFormulae; i++) {
		stringToUtf8(TO_PCMEMPTR(allFormulae[i].pointerToFormulaData), (uint8_t *)tmpString);
		strcat(tmpString, "\n");
		save(tmpString, strlen(tmpString));
	}

	sprintf(tmpString, "OTHER_CONFIGURATION_STUFF\n00\n");
	save(tmpString, strlen(tmpString));
	save(tmpString, strlen(tmpString));

	sprintf(tmpString, "firstGregorianDay\n%" PRIu32 "\n", firstGregorianDay);                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "denMax\n%" PRIu32 "\n", denMax);                                         save(tmpString, strlen(tmpString));
	sprintf(tmpString, "lastDenominator\n%" PRIu32 "\n", lastDenominator);                      save(tmpString, strlen(tmpString));
	sprintf(tmpString, "displayFormat\n%" PRIu8 "\n", displayFormat);                            save(tmpString, strlen(tmpString));
	sprintf(tmpString, "displayFormatDigits\n%" PRIu8 "\n", displayFormatDigits);                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "timeDisplayFormatDigits\n%" PRIu8 "\n", timeDisplayFormatDigits);        save(tmpString, strlen(tmpString));
	sprintf(tmpString, "shortIntegerWordSize\n%" PRIu8 "\n", shortIntegerWordSize);              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "shortIntegerMode\n%" PRIu8 "\n", shortIntegerMode);                      save(tmpString, strlen(tmpString));
	sprintf(tmpString, "significantDigits\n%" PRIu8 "\n", significantDigits);                    save(tmpString, strlen(tmpString));
	sprintf(tmpString, "fractionDigits\n%" PRIu8 "\n", fractionDigits);                          save(tmpString, strlen(tmpString));
	sprintf(tmpString, "currentAngularMode\n%" PRIu8 "\n", (uint8_t)currentAngularMode);         save(tmpString, strlen(tmpString));
	sprintf(tmpString, "gapItemLeft\n%" PRIu16 "\n", gapItemLeft);                                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "gapItemRight\n%" PRIu16 "\n", gapItemRight);                              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "gapItemRadix\n%" PRIu16 "\n", gapItemRadix);                              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "lastCenturyHighUsed\n%" PRIu16 "\n", lastCenturyHighUsed);                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "grpGroupingLeft\n%" PRIu8 "\n", grpGroupingLeft);                          save(tmpString, strlen(tmpString));
	sprintf(tmpString, "grpGroupingGr1LeftOverflow\n%" PRIu8 "\n", grpGroupingGr1LeftOverflow);  save(tmpString, strlen(tmpString));
	sprintf(tmpString, "grpGroupingGr1Left\n%" PRIu8 "\n", grpGroupingGr1Left);                   save(tmpString, strlen(tmpString));
	sprintf(tmpString, "grpGroupingRight\n%" PRIu8 "\n", grpGroupingRight);                        save(tmpString, strlen(tmpString));
	sprintf(tmpString, "roundingMode\n%" PRIu8 "\n", roundingMode);                                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "displayStack\n%" PRIu8 "\n", displayStack);                                save(tmpString, strlen(tmpString));
	UI64toString(pcg32_global.state, yy1);
	UI64toString(pcg32_global.inc, yy2);
	sprintf(tmpString, "rngState\n%s %s\n", yy1, yy2);                                              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "exponentLimit\n%" PRId16 "\n", exponentLimit);                             save(tmpString, strlen(tmpString));
	sprintf(tmpString, "exponentHideLimit\n%" PRId16 "\n", exponentHideLimit);                     save(tmpString, strlen(tmpString));
	sprintf(tmpString, "bestF\n%" PRIu16 "\n", lrSelection);                                       save(tmpString, strlen(tmpString));
	sprintf(tmpString, "dispBase\n%" PRIu8 "\n", (uint8_t)dispBase);                               save(tmpString, strlen(tmpString));
	sprintf(tmpString, "calcModel\n%" PRId16 "\n", calcModel);                                     save(tmpString, strlen(tmpString));
	sprintf(tmpString, "Norm_Key_00.func\n%" PRId16 "\n", Norm_Key_00.func);                       save(tmpString, strlen(tmpString));
	sprintf(tmpString, "Norm_Key_00.funcParam\n%s\n", (Norm_Key_00.funcParam[0] == 0) ? "NoNormKeyParamDef" : Norm_Key_00.funcParam); save(tmpString, strlen(tmpString));
	sprintf(tmpString, "Norm_Key_00.used\n%" PRIu8 "\n", (uint8_t)Norm_Key_00.used);               save(tmpString, strlen(tmpString));
	sprintf(tmpString, "Input_Default\n%" PRIu8 "\n", Input_Default);                              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "displayStackSHOIDISP\n%" PRIu8 "\n", displayStackSHOIDISP);                save(tmpString, strlen(tmpString));
	sprintf(tmpString, "bcdDisplaySign\n%" PRIu8 "\n", bcdDisplaySign);                            save(tmpString, strlen(tmpString));
	sprintf(tmpString, "DRG_Cycling\n%" PRIu8 "\n", DRG_Cycling);                                   save(tmpString, strlen(tmpString));
	sprintf(tmpString, "DM_Cycling\n%" PRIu8 "\n", DM_Cycling);                                     save(tmpString, strlen(tmpString));
	sprintf(tmpString, "LongPressM\n%" PRIu8 "\n", (uint8_t)LongPressM);                            save(tmpString, strlen(tmpString));
	sprintf(tmpString, "LongPressF\n%" PRIu8 "\n", (uint8_t)LongPressF);                            save(tmpString, strlen(tmpString));
	sprintf(tmpString, "lastIntegerBase\n%" PRIu8 "\n", (uint8_t)lastIntegerBase);                  save(tmpString, strlen(tmpString));
	sprintf(tmpString, "amortP1\n%" PRIu16 "\n", amortP1);                                          save(tmpString, strlen(tmpString));
	sprintf(tmpString, "amortP2\n%" PRIu16 "\n", amortP2);                                          save(tmpString, strlen(tmpString));
	sprintf(tmpString, "lrChosen\n%" PRIu16 "\n", lrChosen);                                        save(tmpString, strlen(tmpString));
	sprintf(tmpString, "graph_dx\n%f\n", graph_dx);                                                   save(tmpString, strlen(tmpString));
	sprintf(tmpString, "graph_dy\n%f\n", graph_dy);                                                   save(tmpString, strlen(tmpString));
	sprintf(tmpString, "roundedTicks\n%" PRIu8 "\n", (uint8_t)roundedTicks);                        save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_INTG\n%" PRIu8 "\n", (uint8_t)PLOT_INTG);                               save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_DIFF\n%" PRIu8 "\n", (uint8_t)PLOT_DIFF);                               save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_RMS\n%" PRIu8 "\n", (uint8_t)PLOT_RMS);                                 save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_SHADE\n%" PRIu8 "\n", (uint8_t)PLOT_SHADE);                             save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_AXIS\n%" PRIu8 "\n", (uint8_t)PLOT_AXIS);                               save(tmpString, strlen(tmpString));
	sprintf(tmpString, "PLOT_ZMY\n%" PRIu8 "\n", PLOT_ZMY);                                          save(tmpString, strlen(tmpString));
	sprintf(tmpString, "firstDayOfWeek\n%" PRIu8 "\n", firstDayOfWeek);                              save(tmpString, strlen(tmpString));
	sprintf(tmpString, "firstWeekOfYearDay\n%" PRIu8 "\n", firstWeekOfYearDay);                      save(tmpString, strlen(tmpString));
	sprintf(tmpString, "printerOn\n%" PRIu8 "\n", printerState.print_on);                            save(tmpString, strlen(tmpString));
	sprintf(tmpString, "printerModel\n%" PRIu8 "\n", printerState.printer_model);                    save(tmpString, strlen(tmpString));
	sprintf(tmpString, "printerLineDelay\n%" PRIu16 "\n", printerState.delay);                       save(tmpString, strlen(tmpString));
	sprintf(tmpString, "END_OTHER_PARAM\n");                                                            save(tmpString, strlen(tmpString));

	hourGlassIconEnabled = false;
}

#endif