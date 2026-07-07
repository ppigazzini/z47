// SPDX-License-Identifier: GPL-3.0-only
//
// translate-c root for the abi struct-layout parity oracle. Pulls in the pinned
// upstream decNumber-family headers so the oracle can compare the C ground-truth
// layout (sizeof / offsetof) against the hand-maintained abi/types.zig mirrors.
// This is the harness that must gate green before abi/types.zig can be generated
// (seam-and-core roadmap): a subtly-wrong layout is a silent-corruption class
// that sim+test do not catch, so it is cross-checked against the C here.
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "defines.h"
#include "decContext.h"
#include "decNumber.h"
#include "decQuad.h"
