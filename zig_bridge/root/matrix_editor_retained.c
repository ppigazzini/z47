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

int16_t z47_frontier_retained_getIRegisterAsInt(bool_t asArrayPointer);
int16_t z47_frontier_retained_getJRegisterAsInt(bool_t asArrayPointer);
void z47_frontier_retained_setIRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
void z47_frontier_retained_setJRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
bool_t z47_frontier_retained_wrapIJ(uint16_t rows, uint16_t cols);
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