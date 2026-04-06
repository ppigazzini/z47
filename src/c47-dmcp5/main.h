/*

  Copyright (c) 2018 SwissMicros GmbH

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in
     the documentation and/or other materials provided with the
     distribution.

  3. Neither the name of the copyright holder nor the names of its
     contributors may be used to endorse or promote products derived
     from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.


  The SDK and related material is released as “NOMAS”  (NOt MAnufacturer Supported).

  1. Info is released to assist customers using, exploring and extending the product
  2. Do NOT contact the manufacturer with questions, seeking support, etc. regarding
     NOMAS material as no support is implied or committed-to by the Manufacturer
  3. The Manufacturer may reply and/or update materials if and when needed solely at
     their discretion

*/

// This file is included by dep/DMCP_SDK/dmcp/sys/pgm_syscalls.c
// It is used to set values in a struct that is read by the DMCP
// The file name must be main.h for this to be included

#if !defined(__PGM_MAIN_H__)
#define __PGM_MAIN_H__

#include "defines.h"
#include "version.h"

#if(CALCMODEL == USER_C47) // C47
  #define PROGRAM_NAME    "C47"
  #define PROGRAM_VERSION VERSION_SHORT
  #if(HARDWARE_MODEL == HWM_DM32)
    #define PROGRAM_KEYMAP_ID 0x32334d44
  #endif
#endif // CALCMODEL == USER_C47

#if(CALCMODEL == USER_R47) // R47
  #define PROGRAM_NAME    "R47"
  #define PROGRAM_VERSION VERSION_SHORT
  #define PROGRAM_KEYMAP_ID 0x00373452   // R47 keymap file
#endif // CALCMODEL == USER_R47

#endif // __PGM_MAIN_H__
