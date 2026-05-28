// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnEditMatrix z47_frontier_retained_fnEditMatrix
#define fnOldMatrix z47_frontier_retained_fnOldMatrix
#define fnGoToElement z47_frontier_retained_fnGoToElement
#define fnGoToRow z47_frontier_retained_fnGoToRow
#define fnGoToColumn z47_frontier_retained_fnGoToColumn
#define fnSetGrowMode z47_frontier_retained_fnSetGrowMode
#define fnIncDecI z47_frontier_retained_fnIncDecI
#define fnIncDecJ z47_frontier_retained_fnIncDecJ
#define fnInsRow z47_frontier_retained_fnInsRow
#define fnAddRow z47_frontier_retained_fnAddRow
#define fnInsCol z47_frontier_retained_fnInsCol
#define fnAddCol z47_frontier_retained_fnAddCol
#define fnDelRow z47_frontier_retained_fnDelRow
#define fnDelCol z47_frontier_retained_fnDelCol
#define getIRegisterAsInt z47_frontier_retained_getIRegisterAsInt
#define getJRegisterAsInt z47_frontier_retained_getJRegisterAsInt
#define setIRegisterAsInt z47_frontier_retained_setIRegisterAsInt
#define setJRegisterAsInt z47_frontier_retained_setJRegisterAsInt
#define wrapIJ z47_frontier_retained_wrapIJ
#define _fnInsRow z47_frontier_retained__fnInsRow
#define _fnInsCol z47_frontier_retained__fnInsCol
#define mimFinalize z47_frontier_retained_mimFinalize
#define mimRestore z47_frontier_retained_mimRestore
#define mimAddNumber z47_frontier_retained_mimAddNumber
#define mimRunFunction z47_frontier_retained_mimRunFunction
#define showMatrixEditor z47_frontier_retained_showMatrixEditor
#define mimEnter z47_frontier_retained_mimEnter

int16_t z47_frontier_retained_getIRegisterAsInt(bool_t asArrayPointer);
int16_t z47_frontier_retained_getJRegisterAsInt(bool_t asArrayPointer);
void z47_frontier_retained_setIRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
void z47_frontier_retained_setJRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
bool_t z47_frontier_retained_wrapIJ(uint16_t rows, uint16_t cols);
void z47_frontier_retained_showMatrixEditor(void);
void z47_frontier_retained_mimEnter(bool_t commit);
void z47_frontier_retained_mimAddNumber(int16_t item);
void z47_frontier_retained_mimRunFunction(int16_t func, uint16_t param);

#include "../../src/c47/ui/matrixEditor.c"

int16_t z47_frontier_matrix_get_register_as_int(uint16_t regist, bool as_array_pointer) {
	return getRegisterAsInt(as_array_pointer, regist);
}

void z47_frontier_matrix_set_register_as_int(uint16_t regist, bool as_array_pointer, int16_t to_store) {
	setRegisterAsInt(as_array_pointer, to_store, regist);
}

bool z47_frontier_matrix_is_register_matrix_vector(uint16_t regist) {
	return isRegisterMatrixVector(regist);
}

uint16_t z47_frontier_matrix_vector_polar_mode(uint16_t regist) {
	return getVectorRegisterPolarMode(regist);
}

uint16_t z47_frontier_matrix_open_rows(void) {
	return openMatrixMIMPointer.header.matrixRows;
}

uint16_t z47_frontier_matrix_open_cols(void) {
	return openMatrixMIMPointer.header.matrixColumns;
}

void z47_frontier_matrix_commit_open_to_register(void) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, matrixIndex);
	}
	else {
		convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, matrixIndex);
	}
}

void z47_frontier_matrix_calc_mode_normal_gui(void) {
	calcModeNormalGui();
}

void z47_frontier_matrix_hide_cursor(void) {
	hideCursor();
	cursorEnabled = false;
}

void z47_frontier_matrix_reload_open_matrix_from_register(void) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		if(openMatrixMIMPointer.realMatrix.matrixElements) {
			realMatrixFree(&openMatrixMIMPointer.realMatrix);
		}
		convertReal34MatrixRegisterToReal34Matrix(matrixIndex, &openMatrixMIMPointer.realMatrix);
	}
	else {
		if(openMatrixMIMPointer.complexMatrix.matrixElements) {
			complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
		}
		convertComplex34MatrixRegisterToComplex34Matrix(matrixIndex, &openMatrixMIMPointer.complexMatrix);
	}
}

void z47_frontier_matrix_inc_dec_i(uint16_t mode) {
	callByIndexedMatrix((mode == DEC_FLAG) ? decIReal : incIReal, (mode == DEC_FLAG) ? decIComplex : incIComplex);
}

void z47_frontier_matrix_inc_dec_j(uint16_t mode) {
	callByIndexedMatrix((mode == DEC_FLAG) ? decJReal : incJReal, (mode == DEC_FLAG) ? decJComplex : incJComplex);
}

void z47_frontier_matrix_insert_row(bool add) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		insRowRealMatrix(&openMatrixMIMPointer.realMatrix, getIRegisterAsInt(true), add);
	}
	else {
		insRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, getIRegisterAsInt(true), add);
	}
}

void z47_frontier_matrix_insert_col(bool add) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		insColRealMatrix(&openMatrixMIMPointer.realMatrix, getJRegisterAsInt(true), add);
	}
	else {
		insColComplexMatrix(&openMatrixMIMPointer.complexMatrix, getJRegisterAsInt(true), add);
	}
}

void z47_frontier_matrix_delete_row(void) {
	if(openMatrixMIMPointer.header.matrixRows > 1) {
		if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
			delRowRealMatrix(&openMatrixMIMPointer.realMatrix, getIRegisterAsInt(true));
		}
		else {
			delRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, getIRegisterAsInt(true));
		}
	}
}

void z47_frontier_matrix_delete_col(void) {
	if(openMatrixMIMPointer.header.matrixColumns > 1) {
		if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
			delColRealMatrix(&openMatrixMIMPointer.realMatrix, getJRegisterAsInt(true));
		}
		else {
			delColComplexMatrix(&openMatrixMIMPointer.complexMatrix, getJRegisterAsInt(true));
		}
	}
}

void z47_frontier_matrix_finalize_open_matrix_memory(void) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		if(openMatrixMIMPointer.realMatrix.matrixElements) {
			realMatrixFree(&openMatrixMIMPointer.realMatrix);
		}
	}
	else if(getRegisterDataType(matrixIndex) == dtComplex34Matrix) {
		if(openMatrixMIMPointer.complexMatrix.matrixElements) {
			complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
		}
	}
}

bool z47_frontier_matrix_aim_is_empty(void) {
	return aimBuffer[0] == 0;
}

void z47_frontier_matrix_reset_cursor_pos(void) {
	_resetCursorPos();
}

void z47_frontier_matrix_init_aim_exponent(void) {
	aimBuffer[0] = '+';
	aimBuffer[1] = '1';
	aimBuffer[2] = '.';
	aimBuffer[3] = 0;
	nimNumberPart = NP_REAL_FLOAT_PART;
	_resetCursorPos();
}

void z47_frontier_matrix_init_aim_period(void) {
	aimBuffer[0] = '+';
	aimBuffer[1] = '0';
	aimBuffer[2] = 0;
	nimNumberPart = NP_INT_10;
	_resetCursorPos();
}

void z47_frontier_matrix_init_aim_digit(void) {
	aimBuffer[0] = '+';
	aimBuffer[1] = 0;
	nimNumberPart = NP_INT_10;
	_resetCursorPos();
}

bool z47_frontier_matrix_aim_is_single_plus_digit(void) {
	return (aimBuffer[0] == '+') && (aimBuffer[1] != 0) && (aimBuffer[2] == 0);
}

void z47_frontier_matrix_aim_clear_single_plus_digit(void) {
	aimBuffer[1] = 0;
	hideCursor();
	cursorEnabled = false;
}

void z47_frontier_matrix_zero_current_element(void) {
	const int cols = openMatrixMIMPointer.header.matrixColumns;
	const int16_t row = getIRegisterAsInt(true);
	const int16_t col = getJRegisterAsInt(true);

	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		real34SetZero(&openMatrixMIMPointer.realMatrix.matrixElements[row * cols + col]);
	}
	else {
		real34SetZero(VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
		real34SetZero(VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
	}
	setSystemFlag(FLAG_ASLIFT);
}

void z47_frontier_matrix_change_sign_current_element(void) {
	const int cols = openMatrixMIMPointer.header.matrixColumns;
	const int16_t row = getIRegisterAsInt(true);
	const int16_t col = getJRegisterAsInt(true);

	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		real34ChangeSign(&openMatrixMIMPointer.realMatrix.matrixElements[row * cols + col]);
	}
	else {
		real34ChangeSign(VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
		real34ChangeSign(VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
	}
	setSystemFlag(FLAG_ASLIFT);
}

void z47_frontier_matrix_make_j_element(void) {
	const int cols = openMatrixMIMPointer.header.matrixColumns;
	const int16_t row = getIRegisterAsInt(true);
	const int16_t col = getJRegisterAsInt(true);

	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		complex34Matrix_t cxma;
		convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
		realMatrixFree(&openMatrixMIMPointer.realMatrix);
		convertComplex34MatrixToComplex34MatrixRegister(&cxma, matrixIndex);
		if((getSystemFlag(FLAG_POLAR) && !temporaryFlagRect) || temporaryFlagPolar) {
			setRegisterTag(matrixIndex, currentAngularMode | amPolar);
		}
		openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
		openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
		openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;
	}
	else {
		complex34_t *elm = &openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col];
		if((getSystemFlag(FLAG_POLAR) && !temporaryFlagRect) || temporaryFlagPolar) {
			real_t theta;
			realCopy(const39_piOn2, &theta);
			convertAngleFromTo(&theta, amRadian, currentAngularMode, &ctxtReal39);
			real34SetOne(VARIABLE_REAL34_DATA(elm));
			real34Copy(&theta, VARIABLE_IMAG34_DATA(elm));
		}
		else {
			real34SetZero(VARIABLE_REAL34_DATA(elm));
			real34SetOne(VARIABLE_IMAG34_DATA(elm));
		}
	}
}

void z47_frontier_matrix_set_current_to_pi(void) {
	const int cols = openMatrixMIMPointer.header.matrixColumns;
	const int16_t row = getIRegisterAsInt(true);
	const int16_t col = getJRegisterAsInt(true);

	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		realToReal34(const39_pi, &openMatrixMIMPointer.realMatrix.matrixElements[row * cols + col]);
	}
	else {
		realToReal34(const39_pi, VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
		real34SetZero(VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col]));
	}
}

bool z47_frontier_matrix_can_append_pi_literal(void) {
	return nimNumberPart == NP_COMPLEX_INT_PART && aimBuffer[strlen(aimBuffer) - 1] == 'i';
}

void z47_frontier_matrix_append_pi_literal_and_enter(void) {
	strcat(aimBuffer, "3.141592653589793238462643383279503");
	reallyRunFunction(ITM_ENTER, NOPARAM);
}

void z47_frontier_matrix_add_item_to_nim_buffer(int16_t item) {
	addItemToNimBuffer(item);
}

static bool_t z47_frontier_matrix_saved_is_complex;
static real34_t z47_frontier_matrix_saved_re;
static real34_t z47_frontier_matrix_saved_im;

bool z47_frontier_matrix_open_is_complex(void) {
	return getRegisterDataType(matrixIndex) == dtComplex34Matrix;
}

void z47_frontier_matrix_capture_selected_before(void) {
	const int16_t i = getIRegisterAsInt(true);
	const int16_t j = getJRegisterAsInt(true);
	z47_frontier_matrix_saved_is_complex = z47_frontier_matrix_open_is_complex();

	if(z47_frontier_matrix_saved_is_complex) {
		real34Copy(VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]), &z47_frontier_matrix_saved_re);
		real34Copy(VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]), &z47_frontier_matrix_saved_im);
	}
	else {
		real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j], &z47_frontier_matrix_saved_re);
		real34SetZero(&z47_frontier_matrix_saved_im);
	}
}

void z47_frontier_matrix_load_selected_into_register_x(void) {
	const int16_t i = getIRegisterAsInt(true);
	const int16_t j = getJRegisterAsInt(true);
	real34_t re;
	real34_t im;
	const bool_t isComplex = z47_frontier_matrix_open_is_complex();

	if(isComplex) {
		real34Copy(VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]), &re);
		real34Copy(VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]), &im);
		reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
		real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
		real34Copy(&im, REGISTER_IMAG34_DATA(REGISTER_X));
	}
	else {
		real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j], &re);
		reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
		real34Copy(&re, REGISTER_REAL34_DATA(REGISTER_X));
	}
}

void z47_frontier_matrix_run_item_function(int16_t func, uint16_t param) {
	reallyRunFunction(func, param);
}

uint32_t z47_frontier_matrix_register_type(uint16_t reg) {
	return getRegisterDataType(reg);
}

void z47_frontier_matrix_convert_register_x_long_to_real34(void) {
	convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

void z47_frontier_matrix_convert_register_x_short_to_real34(void) {
	convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

bool z47_frontier_matrix_apply_register_x_to_selected(void) {
	const int16_t i = getIRegisterAsInt(true);
	const int16_t j = getJRegisterAsInt(true);
	const bool_t isComplex = z47_frontier_matrix_open_is_complex();

	if(isComplex && getRegisterDataType(REGISTER_X) == dtComplex34) {
		complex34Copy(REGISTER_COMPLEX34_DATA(REGISTER_X), &openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]);
		return false;
	}

	if(isComplex) {
		real34Copy(REGISTER_REAL34_DATA(REGISTER_X), VARIABLE_REAL34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]));
		real34SetZero(                                  VARIABLE_IMAG34_DATA(&openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]));
		return false;
	}

	if(getRegisterDataType(REGISTER_X) == dtComplex34) {
		complex34Matrix_t cxma;
		complex34_t ans;

		complex34Copy(REGISTER_COMPLEX34_DATA(REGISTER_X), &ans);
		convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
		realMatrixFree(&openMatrixMIMPointer.realMatrix);
		convertComplex34MatrixToComplex34MatrixRegister(&cxma, matrixIndex);
		openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
		openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
		openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;

		complex34Copy(&ans, &openMatrixMIMPointer.complexMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]);
		return true;
	}

	real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &openMatrixMIMPointer.realMatrix.matrixElements[i * openMatrixMIMPointer.header.matrixColumns + j]);
	return false;
}

void z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted(void) {
	if(matrixIndex != REGISTER_X) {
		return;
	}

	const int16_t i = getIRegisterAsInt(true);
	const int16_t j = getJRegisterAsInt(true);

	if(z47_frontier_matrix_saved_is_complex) {
		complex34Matrix_t linkedMatrix;
		convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, REGISTER_X);
		linkToComplexMatrixRegister(REGISTER_X, &linkedMatrix);
		real34Copy(&z47_frontier_matrix_saved_re, VARIABLE_REAL34_DATA(&linkedMatrix.matrixElements[i * linkedMatrix.header.matrixColumns + j]));
		real34Copy(&z47_frontier_matrix_saved_im, VARIABLE_IMAG34_DATA(&linkedMatrix.matrixElements[i * linkedMatrix.header.matrixColumns + j]));
	}
	else {
		real34Matrix_t linkedMatrix;
		convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, REGISTER_X);
		linkToRealMatrixRegister(REGISTER_X, &linkedMatrix);
		real34Copy(&z47_frontier_matrix_saved_re, &linkedMatrix.matrixElements[i * linkedMatrix.header.matrixColumns + j]);
	}
}

void z47_frontier_matrix_update_height_cache(void) {
	updateMatrixHeightCache();
}

bool z47_frontier_matrix_softmenu_has_m_edit(void) {
	for(int i = 0; i < SOFTMENU_STACK_SIZE; i++) {
		if(softmenu[softmenuStack[i].softmenuId].menuItem == -MNU_M_EDIT) {
			return true;
		}
	}
	return false;
}

bool z47_frontier_matrix_softmenu_top_is_m_edit(void) {
	return softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_M_EDIT;
}

void z47_frontier_matrix_show_m_edit_softmenu(void) {
	showSoftmenu(-MNU_M_EDIT);
}

uint16_t z47_frontier_matrix_scroll_row_get(void) {
	return scrollRow;
}

void z47_frontier_matrix_scroll_row_set(uint16_t row) {
	scrollRow = row;
}

void z47_frontier_matrix_render_editor_body(bool colVector, int16_t rows, int16_t cols, int16_t matSelRow, int16_t matSelCol) {
	int16_t width = 0;

	if(aimBuffer[0] == 0) {
		clearRegisterLine(NIM_REGISTER_LINE, true, true);
		if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
			showRealMatrix(&openMatrixMIMPointer.realMatrix, 0, toDisplayVectorMatrix, !regXp);
		}
		else {
			showComplexMatrix(&openMatrixMIMPointer.complexMatrix, 0, currentAngularMode, getSystemFlag(FLAG_POLAR), !regXp);
		}
	}
	else {
		clearRegisterLine(NIM_REGISTER_LINE, false, true);
	}

	sprintf(tmpString, "%" PRIi16 ";%" PRIi16 "=" STD_SPACE_4_PER_EM "%s%s%s", (int16_t)(colVector ? matSelCol+1 : matSelRow+1), (int16_t)(colVector ? 1 : matSelCol+1), aimBuffer[0] == 0 ? STD_SPACE_HAIR : "", (aimBuffer[0] == 0 || aimBuffer[0] == '-') ? "" : " ", nimBufferDisplay);
	width = stringWidth(tmpString, &numericFont, true, true) + 1;
	if(aimBuffer[0] == 0) {
		if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
			real34ToDisplayString(&openMatrixMIMPointer.realMatrix.matrixElements[matSelRow*cols+matSelCol], amNone, &tmpString[strlen(tmpString)], &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIGHTIRFRAC);
		}
		else {
			complex34ToDisplayString(&openMatrixMIMPointer.complexMatrix.matrixElements[matSelRow*cols+matSelCol], &tmpString[strlen(tmpString)], &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIMITIRFRAC, currentAngularMode, getSystemFlag(FLAG_POLAR));
		}

		showString(tmpString, &numericFont, 0, Y_POSITION_OF_NIM_LINE, vmNormal, true, false);
	}
	else {
		if(aimBuffer[0] != 0 && aimBuffer[strlen(aimBuffer)-1]=='/') {
			char lastBase[12];
			char *lb = lastBase;
			if(lastDenominator >= 1000) {
				*(lb++) = STD_SUB_0[0];
				*(lb++) = STD_SUB_0[1] + (lastDenominator / 1000);
			}
			if(lastDenominator >= 100) {
				*(lb++) = STD_SUB_0[0];
				*(lb++) = STD_SUB_0[1] + (lastDenominator % 1000 / 100);
			}
			if(lastDenominator >= 10) {
				*(lb++) = STD_SUB_0[0];
				*(lb++) = STD_SUB_0[1] + (lastDenominator % 100 / 10);
			}
			*(lb++) = STD_SUB_0[0];
			*(lb++) = STD_SUB_0[1] + (lastDenominator % 10);
			*(lb++) = 0;
			displayNim(tmpString, lastBase, stringWidth(lastBase, &numericFont, true, true), stringWidth(lastBase, &standardFont, true, true));
		}
		else {
			displayNim(tmpString, "", 0, 0);
		}
	}

	if(temporaryInformation == TI_SHOW_REGISTER && calcMode == CM_MIM) {
		mimShowElement();
		clearRegisterLine(REGISTER_T, true, true);
		refreshRegisterLine(REGISTER_T);
		if(tmpString[SHOWLineSize]) {
			clearRegisterLine(REGISTER_Z, true, true);
			refreshRegisterLine(REGISTER_Z);
		}
	}

	if(lastErrorCode != ERROR_NONE) {
		refreshRegisterLine(errorMessageRegisterLine);
	}
}

void z47_frontier_matrix_mim_enter_apply_aim_buffer(void) {
	const int cols = openMatrixMIMPointer.header.matrixColumns;
	const int16_t row = getIRegisterAsInt(true);
	const int16_t col = getJRegisterAsInt(true);
	bool_t realChanged = false;

	if(aimBuffer[0] == 0) {
		return;
	}

	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		real34_t real34tmp;
		real34_t *real34Ptr = &openMatrixMIMPointer.realMatrix.matrixElements[row * cols + col];

		switch(nimNumberPart) {
			case NP_FRACTION_DENOMINATOR:
			case NP_HP32SII_DENOMINATOR:
				closeNimWithFraction(&real34tmp);
				realChanged = true;
				break;
			case NP_COMPLEX_INT_PART:
			case NP_COMPLEX_FLOAT_PART:
			case NP_COMPLEX_EXPONENT:
			case NP_COMPLEX_FRACTION_DENOMINATOR:
			case NP_COMPLEX_HP32SII_DENOMINATOR: {
				complex34_t *complex34Ptr;
				complex34Matrix_t cxma;
				convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
				realMatrixFree(&openMatrixMIMPointer.realMatrix);
				convertComplex34MatrixToComplex34MatrixRegister(&cxma, matrixIndex);
				openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
				openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
				openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;
				complex34Ptr = &openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col];
				closeNimWithComplex(VARIABLE_REAL34_DATA(complex34Ptr), VARIABLE_IMAG34_DATA(complex34Ptr));
				break;
			}
			default:
				stringToReal34(aimBuffer, &real34tmp);
				realChanged = true;
		}

		if(realChanged) {
			real34Copy(&real34tmp, real34Ptr);
		}
	}
	else {
		complex34_t *complex34Ptr = &openMatrixMIMPointer.complexMatrix.matrixElements[row * cols + col];

		switch(nimNumberPart) {
			case NP_FRACTION_DENOMINATOR:
			case NP_HP32SII_DENOMINATOR:
				closeNimWithFraction(VARIABLE_REAL34_DATA(complex34Ptr));
				real34SetZero(VARIABLE_IMAG34_DATA(complex34Ptr));
				break;
			case NP_COMPLEX_INT_PART:
			case NP_COMPLEX_FLOAT_PART:
			case NP_COMPLEX_EXPONENT:
			case NP_COMPLEX_FRACTION_DENOMINATOR:
			case NP_COMPLEX_HP32SII_DENOMINATOR:
				closeNimWithComplex(VARIABLE_REAL34_DATA(complex34Ptr), VARIABLE_IMAG34_DATA(complex34Ptr));
				break;
			default:
				stringToReal34(aimBuffer, VARIABLE_REAL34_DATA(complex34Ptr));
				real34SetZero(VARIABLE_IMAG34_DATA(complex34Ptr));
		}
	}

	aimBuffer[0] = 0;
	nimBufferDisplay[0] = 0;
	hideCursor();
	cursorEnabled = false;
	setSystemFlag(FLAG_ASLIFT);
}

void z47_frontier_matrix_mim_enter_commit_open_matrix(void) {
	if(getRegisterDataType(matrixIndex) == dtReal34Matrix) {
		convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, matrixIndex);
		setRegisterTag(matrixIndex, openMatrixMIMPointer.header.mtag);
	}
	else {
		convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, matrixIndex);
		setRegisterTag(matrixIndex, openMatrixMIMPointer.header.mtag);
	}
}