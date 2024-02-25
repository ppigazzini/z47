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

/********************************************//**
 * \file constants.c List of constant description
 * see: https://physics.nist.gov/cuu/index.html
 ***********************************************/

#include "constants.h"

#include "constantPointers.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "stack.h"

#include "c47.h"



/********************************************//**
 * \brief Replaces the X content with the selected
 * constant. Enables \b stack \b lift and refreshes the stack
 *
 * \param[in] constant uint16_t Index of the constant to store in X
 * \return void
 ***********************************************/
void fnConstant(const uint16_t constant) {
  liftStack();
  currentSolverStatus &= ~SOLVER_STATUS_READY_TO_EXECUTE;

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  if(constant < NUMBER_OF_CONSTANTS_39) { // 39 digit constants
    realToReal34((real_t *)(constants + constant * TO_BYTES(REAL39_SIZE_IN_BLOCKS)), REGISTER_REAL34_DATA(REGISTER_X));

  }
  else if(constant < NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51) { // 51 digit constants (gamma coefficients)
    realToReal34((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * TO_BYTES(REAL39_SIZE_IN_BLOCKS)
                                      + (constant - NUMBER_OF_CONSTANTS_39) * TO_BYTES(REAL51_SIZE_IN_BLOCKS)), REGISTER_REAL34_DATA(REGISTER_X));
  }
  else if(constant < NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51 + NUMBER_OF_CONSTANTS_1071) { // 1071 digit constant
    realToReal34((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * TO_BYTES(REAL39_SIZE_IN_BLOCKS)
                                      + NUMBER_OF_CONSTANTS_51 * TO_BYTES(REAL51_SIZE_IN_BLOCKS)
                                      + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51) * TO_BYTES(REAL1071_SIZE_IN_BLOCKS)), REGISTER_REAL34_DATA(REGISTER_X));
  }
  else { // 34 digit constants
    real34Copy((real34_t *)(constants + NUMBER_OF_CONSTANTS_39 * TO_BYTES(REAL39_SIZE_IN_BLOCKS)
                                      + NUMBER_OF_CONSTANTS_51 * TO_BYTES(REAL51_SIZE_IN_BLOCKS)
                                      + NUMBER_OF_CONSTANTS_1071 * TO_BYTES(REAL1071_SIZE_IN_BLOCKS)
                                      + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51 - NUMBER_OF_CONSTANTS_1071) * TO_BYTES(REAL34_SIZE_IN_BLOCKS)), REGISTER_REAL34_DATA(REGISTER_X));
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

  setLastintegerBasetoZero();
}



/********************************************//**
 * \brief Replaces the X content with the circumference
 * to diameter ratio pi: 3,1415926. Enables \b stack
 * \b lift and refreshes the stack.
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnPi(uint16_t unusedButMandatoryParameter) {
  liftStack();
  currentSolverStatus &= ~SOLVER_STATUS_READY_TO_EXECUTE;

  convertRealToResultRegister(const_pi, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

  setLastintegerBasetoZero();
}
