// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK key-translation cluster ported from src/c47-gtk/gtkGui.c
// (_getGdkKeyItem / _getDeadKeyItem / _keyCodeFromGdkKey). It maps raw GDK key
// codes -- including dead-key composition -- to C47 item codes for the desktop
// keyboard-shortcut path. The lookup tables gdkKeyMap[] / deadKeysMap[] stay as
// C-defined `const` data in gtkGui.c and are reached here as extern arrays.

// --- item codes (probed from items.h) ---
const ITM_0: i16 = 540;
const ITM_A: i16 = 550;
const ITM_ALPHA: i16 = 602;
const ITM_ASTERISK: i16 = 816;
const ITM_B: i16 = 551;
const ITM_BETA: i16 = 603;
const ITM_C: i16 = 552;
const ITM_CHI: i16 = 625;
const ITM_COLON: i16 = 822;
const ITM_CR: i16 = 1172;
const ITM_CROSS: i16 = 855;
const ITM_D: i16 = 553;
const ITM_DELTA: i16 = 605;
const ITM_DOT: i16 = 849;
const ITM_E: i16 = 554;
const ITM_EPSILON: i16 = 606;
const ITM_ETA: i16 = 608;
const ITM_F: i16 = 555;
const ITM_G: i16 = 556;
const ITM_GAMMA: i16 = 604;
const ITM_H: i16 = 557;
const ITM_I: i16 = 558;
const ITM_IOTA: i16 = 610;
const ITM_J: i16 = 559;
const ITM_K: i16 = 560;
const ITM_KAPPA: i16 = 612;
const ITM_L: i16 = 561;
const ITM_LAMBDA: i16 = 613;
const ITM_M: i16 = 562;
const ITM_MU: i16 = 614;
const ITM_N: i16 = 563;
const ITM_NQUOTE: i16 = 2146;
const ITM_NU: i16 = 615;
const ITM_O: i16 = 564;
const ITM_OMEGA: i16 = 627;
const ITM_OMICRON: i16 = 617;
const ITM_P: i16 = 565;
const ITM_PHI: i16 = 624;
const ITM_PI: i16 = 618;
const ITM_PROD_SIGN: i16 = 9999;
const ITM_PSI: i16 = 626;
const ITM_Q: i16 = 566;
const ITM_QOPPA: i16 = 1809;
const ITM_R: i16 = 567;
const ITM_RHO: i16 = 619;
const ITM_S: i16 = 568;
const ITM_SIGMA: i16 = 620;
const ITM_SPACE: i16 = 806;
const ITM_SUB_0: i16 = 1080;
const ITM_T: i16 = 569;
const ITM_TAU: i16 = 621;
const ITM_THETA: i16 = 609;
const ITM_U: i16 = 570;
const ITM_UPSILON: i16 = 622;
const ITM_V: i16 = 571;
const ITM_W: i16 = 572;
const ITM_X: i16 = 573;
const ITM_XI: i16 = 616;
const ITM_Y: i16 = 574;
const ITM_Z: i16 = 575;
const ITM_ZETA: i16 = 607;
const ITM_a: i16 = 576;
const ITM_alpha: i16 = 628;
const ITM_b: i16 = 577;
const ITM_beta: i16 = 629;
const ITM_c: i16 = 578;
const ITM_chi: i16 = 651;
const ITM_d: i16 = 579;
const ITM_delta: i16 = 631;
const ITM_e: i16 = 580;
const ITM_epsilon: i16 = 632;
const ITM_eta: i16 = 634;
const ITM_f: i16 = 581;
const ITM_g: i16 = 582;
const ITM_gamma: i16 = 630;
const ITM_h: i16 = 583;
const ITM_i: i16 = 584;
const ITM_iota: i16 = 636;
const ITM_j: i16 = 585;
const ITM_k: i16 = 586;
const ITM_kappa: i16 = 638;
const ITM_l: i16 = 587;
const ITM_lambda: i16 = 639;
const ITM_m: i16 = 588;
const ITM_mu: i16 = 640;
const ITM_n: i16 = 589;
const ITM_nu: i16 = 641;
const ITM_o: i16 = 590;
const ITM_omega: i16 = 653;
const ITM_omicron: i16 = 643;
const ITM_p: i16 = 591;
const ITM_phi: i16 = 650;
const ITM_pi: i16 = 644;
const ITM_psi: i16 = 652;
const ITM_q: i16 = 592;
const ITM_qoppa: i16 = 1845;
const ITM_r: i16 = 593;
const ITM_rho: i16 = 645;
const ITM_s: i16 = 594;
const ITM_sigma: i16 = 646;
const ITM_t: i16 = 595;
const ITM_tau: i16 = 647;
const ITM_theta: i16 = 635;
const ITM_u: i16 = 596;
const ITM_upsilon: i16 = 648;
const ITM_v: i16 = 597;
const ITM_w: i16 = 598;
const ITM_x: i16 = 599;
const ITM_xi: i16 = 642;
const ITM_y: i16 = 600;
const ITM_z: i16 = 601;
const ITM_zeta: i16 = 633;

// --- GDK key syms (probed from gtk/gtk.h) ---
const GDK_KEY_0: u32 = 48;
const GDK_KEY_9: u32 = 57;
const GDK_KEY_A: u32 = 65;
const GDK_KEY_Begin: u32 = 65368;
const GDK_KEY_F1: u32 = 65470;
const GDK_KEY_F12: u32 = 65481;
const GDK_KEY_F14: u32 = 65483;
const GDK_KEY_Home: u32 = 65360;
const GDK_KEY_Hyper_R: u32 = 65518;
const GDK_KEY_KP_0: u32 = 65456;
const GDK_KEY_KP_9: u32 = 65465;
const GDK_KEY_KP_Divide: u32 = 65455;
const GDK_KEY_KP_Multiply: u32 = 65450;
const GDK_KEY_Shift_L: u32 = 65505;
const GDK_KEY_Tab: u32 = 65289;
const GDK_KEY_Z: u32 = 90;
const GDK_KEY_a: u32 = 97;
const GDK_KEY_at: u32 = 64;
const GDK_KEY_colon: u32 = 58;
const GDK_KEY_dead_abovedot: u32 = 65110;
const GDK_KEY_dead_abovering: u32 = 65112;
const GDK_KEY_dead_acute: u32 = 65105;
const GDK_KEY_dead_breve: u32 = 65109;
const GDK_KEY_dead_cedilla: u32 = 65115;
const GDK_KEY_dead_circumflex: u32 = 65106;
const GDK_KEY_dead_diaeresis: u32 = 65111;
const GDK_KEY_dead_grave: u32 = 65104;
const GDK_KEY_dead_macron: u32 = 65108;
const GDK_KEY_dead_ogonek: u32 = 65116;
const GDK_KEY_dead_stroke: u32 = 65123;
const GDK_KEY_dead_tilde: u32 = 65107;
const GDK_KEY_ninesubscript: u32 = 16785545;
const GDK_KEY_slash: u32 = 47;
const GDK_KEY_space: u32 = 32;
const GDK_KEY_z: u32 = 122;
const GDK_KEY_zerosubscript: u32 = 16785536;

const FLAG_MULTx: i32 = 32795;

const gdkKeyMap_t = extern struct {
    item: i16,
    gdkKey: u32,
};

const deadKeysMap_t = extern struct {
    item: i16,
    item_macron: i16,
    item_acute: i16,
    item_breve: i16,
    item_grave: i16,
    item_diaresis: i16,
    item_tilde: i16,
    item_circ: i16,
    item_caron: i16,
    item_ogonek: i16,
    item_ring: i16,
    item_cedilla: i16,
    item_stroke: i16,
    item_dot: i16,
};

// gdkKeyMap[] / deadKeysMap[] data (ported from gtkGui.c; values resolved
// from the C ITM_/GDK_KEY_ symbols at probe time). Terminated by a {0} sentinel.
const gdkKeyMap = [_]gdkKeyMap_t{
    .{ .item = 664, .gdkKey = 960 },
    .{ .item = 665, .gdkKey = 193 },
    .{ .item = 666, .gdkKey = 451 },
    .{ .item = 667, .gdkKey = 192 },
    .{ .item = 668, .gdkKey = 196 },
    .{ .item = 669, .gdkKey = 195 },
    .{ .item = 670, .gdkKey = 194 },
    .{ .item = 671, .gdkKey = 197 },
    .{ .item = 672, .gdkKey = 198 },
    .{ .item = 673, .gdkKey = 417 },
    .{ .item = 674, .gdkKey = 454 },
    .{ .item = 675, .gdkKey = 456 },
    .{ .item = 676, .gdkKey = 199 },
    .{ .item = 677, .gdkKey = 464 },
    .{ .item = 678, .gdkKey = 463 },
    .{ .item = 679, .gdkKey = 938 },
    .{ .item = 680, .gdkKey = 201 },
    .{ .item = 682, .gdkKey = 200 },
    .{ .item = 683, .gdkKey = 203 },
    .{ .item = 684, .gdkKey = 202 },
    .{ .item = 685, .gdkKey = 458 },
    .{ .item = 686, .gdkKey = 683 },
    .{ .item = 687, .gdkKey = 975 },
    .{ .item = 688, .gdkKey = 205 },
    .{ .item = 689, .gdkKey = 16777516 },
    .{ .item = 690, .gdkKey = 204 },
    .{ .item = 691, .gdkKey = 207 },
    .{ .item = 692, .gdkKey = 206 },
    .{ .item = 693, .gdkKey = 967 },
    .{ .item = 696, .gdkKey = 419 },
    .{ .item = 697, .gdkKey = 453 },
    .{ .item = 699, .gdkKey = 465 },
    .{ .item = 700, .gdkKey = 466 },
    .{ .item = 701, .gdkKey = 209 },
    .{ .item = 702, .gdkKey = 978 },
    .{ .item = 703, .gdkKey = 211 },
    .{ .item = 705, .gdkKey = 210 },
    .{ .item = 706, .gdkKey = 214 },
    .{ .item = 707, .gdkKey = 213 },
    .{ .item = 708, .gdkKey = 212 },
    .{ .item = 710, .gdkKey = 5052 },
    .{ .item = 711, .gdkKey = 223 },
    .{ .item = 712, .gdkKey = 422 },
    .{ .item = 713, .gdkKey = 425 },
    .{ .item = 714, .gdkKey = 426 },
    .{ .item = 715, .gdkKey = 427 },
    .{ .item = 716, .gdkKey = 478 },
    .{ .item = 717, .gdkKey = 990 },
    .{ .item = 718, .gdkKey = 218 },
    .{ .item = 719, .gdkKey = 733 },
    .{ .item = 720, .gdkKey = 217 },
    .{ .item = 721, .gdkKey = 220 },
    .{ .item = 722, .gdkKey = 989 },
    .{ .item = 723, .gdkKey = 219 },
    .{ .item = 724, .gdkKey = 473 },
    .{ .item = 725, .gdkKey = 16777588 },
    .{ .item = 726, .gdkKey = 16777590 },
    .{ .item = 727, .gdkKey = 221 },
    .{ .item = 728, .gdkKey = 5054 },
    .{ .item = 729, .gdkKey = 428 },
    .{ .item = 730, .gdkKey = 430 },
    .{ .item = 731, .gdkKey = 431 },
    .{ .item = 732, .gdkKey = 992 },
    .{ .item = 733, .gdkKey = 225 },
    .{ .item = 734, .gdkKey = 483 },
    .{ .item = 735, .gdkKey = 224 },
    .{ .item = 736, .gdkKey = 228 },
    .{ .item = 737, .gdkKey = 227 },
    .{ .item = 738, .gdkKey = 226 },
    .{ .item = 739, .gdkKey = 229 },
    .{ .item = 740, .gdkKey = 230 },
    .{ .item = 741, .gdkKey = 433 },
    .{ .item = 742, .gdkKey = 486 },
    .{ .item = 743, .gdkKey = 488 },
    .{ .item = 744, .gdkKey = 231 },
    .{ .item = 745, .gdkKey = 496 },
    .{ .item = 747, .gdkKey = 954 },
    .{ .item = 748, .gdkKey = 233 },
    .{ .item = 750, .gdkKey = 232 },
    .{ .item = 751, .gdkKey = 235 },
    .{ .item = 752, .gdkKey = 234 },
    .{ .item = 753, .gdkKey = 490 },
    .{ .item = 754, .gdkKey = 699 },
    .{ .item = 755, .gdkKey = 689 },
    .{ .item = 756, .gdkKey = 1007 },
    .{ .item = 757, .gdkKey = 237 },
    .{ .item = 758, .gdkKey = 16777517 },
    .{ .item = 759, .gdkKey = 236 },
    .{ .item = 760, .gdkKey = 239 },
    .{ .item = 761, .gdkKey = 238 },
    .{ .item = 762, .gdkKey = 999 },
    .{ .item = 764, .gdkKey = 697 },
    .{ .item = 765, .gdkKey = 435 },
    .{ .item = 766, .gdkKey = 485 },
    .{ .item = 768, .gdkKey = 497 },
    .{ .item = 769, .gdkKey = 498 },
    .{ .item = 770, .gdkKey = 241 },
    .{ .item = 771, .gdkKey = 1010 },
    .{ .item = 772, .gdkKey = 243 },
    .{ .item = 774, .gdkKey = 242 },
    .{ .item = 775, .gdkKey = 246 },
    .{ .item = 776, .gdkKey = 245 },
    .{ .item = 777, .gdkKey = 244 },
    .{ .item = 779, .gdkKey = 5053 },
    .{ .item = 780, .gdkKey = 504 },
    .{ .item = 781, .gdkKey = 480 },
    .{ .item = 783, .gdkKey = 438 },
    .{ .item = 784, .gdkKey = 441 },
    .{ .item = 785, .gdkKey = 442 },
    .{ .item = 787, .gdkKey = 510 },
    .{ .item = 788, .gdkKey = 1022 },
    .{ .item = 789, .gdkKey = 250 },
    .{ .item = 790, .gdkKey = 765 },
    .{ .item = 791, .gdkKey = 249 },
    .{ .item = 792, .gdkKey = 252 },
    .{ .item = 793, .gdkKey = 1021 },
    .{ .item = 794, .gdkKey = 251 },
    .{ .item = 795, .gdkKey = 505 },
    .{ .item = 796, .gdkKey = 16777589 },
    .{ .item = 800, .gdkKey = 16777591 },
    .{ .item = 801, .gdkKey = 253 },
    .{ .item = 802, .gdkKey = 255 },
    .{ .item = 803, .gdkKey = 444 },
    .{ .item = 804, .gdkKey = 446 },
    .{ .item = 805, .gdkKey = 447 },
    .{ .item = 829, .gdkKey = 91 },
    .{ .item = 830, .gdkKey = 92 },
    .{ .item = 831, .gdkKey = 93 },
    .{ .item = 832, .gdkKey = 94 },
    .{ .item = 833, .gdkKey = 95 },
    .{ .item = 834, .gdkKey = 123 },
    .{ .item = 835, .gdkKey = 124 },
    .{ .item = 836, .gdkKey = 125 },
    .{ .item = 837, .gdkKey = 126 },
    .{ .item = 838, .gdkKey = 161 },
    .{ .item = 839, .gdkKey = 162 },
    .{ .item = 840, .gdkKey = 163 },
    .{ .item = 841, .gdkKey = 165 },
    .{ .item = 842, .gdkKey = 167 },
    .{ .item = 844, .gdkKey = 171 },
    .{ .item = 845, .gdkKey = 172 },
    .{ .item = 846, .gdkKey = 176 },
    .{ .item = 847, .gdkKey = 177 },
    .{ .item = 848, .gdkKey = 181 },
    .{ .item = 850, .gdkKey = 187 },
    .{ .item = 851, .gdkKey = 189 },
    .{ .item = 852, .gdkKey = 188 },
    .{ .item = 851, .gdkKey = 189 },
    .{ .item = 853, .gdkKey = 191 },
    .{ .item = 854, .gdkKey = 208 },
    .{ .item = 855, .gdkKey = 215 },
    .{ .item = 856, .gdkKey = 240 },
    .{ .item = 858, .gdkKey = 972 },
    .{ .item = 859, .gdkKey = 1004 },
    .{ .item = 860, .gdkKey = 460 },
    .{ .item = 861, .gdkKey = 492 },
    .{ .item = 862, .gdkKey = 448 },
    .{ .item = 863, .gdkKey = 472 },
    .{ .item = 864, .gdkKey = 985 },
    .{ .item = 865, .gdkKey = 1017 },
    .{ .item = 868, .gdkKey = 2721 },
    .{ .item = 869, .gdkKey = 2723 },
    .{ .item = 870, .gdkKey = 2724 },
    .{ .item = 872, .gdkKey = 2725 },
    .{ .item = 873, .gdkKey = 2726 },
    .{ .item = 874, .gdkKey = 2728 },
    .{ .item = 875, .gdkKey = 2768 },
    .{ .item = 876, .gdkKey = 2769 },
    .{ .item = 877, .gdkKey = 2813 },
    .{ .item = 879, .gdkKey = 2770 },
    .{ .item = 880, .gdkKey = 2771 },
    .{ .item = 881, .gdkKey = 2814 },
    .{ .item = 883, .gdkKey = 2734 },
    .{ .item = 885, .gdkKey = 8364 },
    .{ .item = 892, .gdkKey = 2299 },
    .{ .item = 893, .gdkKey = 2300 },
    .{ .item = 894, .gdkKey = 2301 },
    .{ .item = 895, .gdkKey = 2302 },
    .{ .item = 905, .gdkKey = 2287 },
    .{ .item = 908, .gdkKey = 16785925 },
    .{ .item = 910, .gdkKey = 2245 },
    .{ .item = 911, .gdkKey = 16785928 },
    .{ .item = 912, .gdkKey = 16785929 },
    .{ .item = 913, .gdkKey = 16785931 },
    .{ .item = 917, .gdkKey = 177 },
    .{ .item = 918, .gdkKey = 3018 },
    .{ .item = 919, .gdkKey = 2790 },
    .{ .item = 920, .gdkKey = 16785946 },
    .{ .item = 921, .gdkKey = 16785947 },
    .{ .item = 924, .gdkKey = 2242 },
    .{ .item = 932, .gdkKey = 2270 },
    .{ .item = 933, .gdkKey = 2271 },
    .{ .item = 934, .gdkKey = 2268 },
    .{ .item = 935, .gdkKey = 2269 },
    .{ .item = 936, .gdkKey = 2239 },
    .{ .item = 937, .gdkKey = 16785964 },
    .{ .item = 941, .gdkKey = 2803 },
    .{ .item = 942, .gdkKey = 2249 },
    .{ .item = 943, .gdkKey = 2248 },
    .{ .item = 947, .gdkKey = 2237 },
    .{ .item = 948, .gdkKey = 2255 },
    .{ .item = 949, .gdkKey = 2236 },
    .{ .item = 950, .gdkKey = 2238 },
    .{ .item = 954, .gdkKey = 3010 },
    .{ .item = 1008, .gdkKey = 16785520 },
    .{ .item = 1009, .gdkKey = 185 },
    .{ .item = 1010, .gdkKey = 178 },
    .{ .item = 1011, .gdkKey = 179 },
    .{ .item = 1012, .gdkKey = 16785524 },
    .{ .item = 1013, .gdkKey = 16785525 },
    .{ .item = 1014, .gdkKey = 16785526 },
    .{ .item = 1015, .gdkKey = 16785527 },
    .{ .item = 1016, .gdkKey = 16785528 },
    .{ .item = 1017, .gdkKey = 16785529 },
    .{ .item = 0, .gdkKey = 0 },
};
const deadKeysMap = [_]deadKeysMap_t{
    .{ .item = 550, .item_macron = 664, .item_acute = 665, .item_breve = 666, .item_grave = 667, .item_diaresis = 668, .item_tilde = 669, .item_circ = 670, .item_caron = 550, .item_ogonek = 673, .item_ring = 671, .item_cedilla = 550, .item_stroke = 550, .item_dot = 550 },
    .{ .item = 552, .item_macron = 552, .item_acute = 674, .item_breve = 552, .item_grave = 552, .item_diaresis = 552, .item_tilde = 552, .item_circ = 552, .item_caron = 675, .item_ogonek = 552, .item_ring = 552, .item_cedilla = 676, .item_stroke = 552, .item_dot = 552 },
    .{ .item = 553, .item_macron = 553, .item_acute = 553, .item_breve = 553, .item_grave = 553, .item_diaresis = 553, .item_tilde = 553, .item_circ = 553, .item_caron = 678, .item_ogonek = 553, .item_ring = 553, .item_cedilla = 553, .item_stroke = 677, .item_dot = 553 },
    .{ .item = 554, .item_macron = 679, .item_acute = 680, .item_breve = 681, .item_grave = 682, .item_diaresis = 683, .item_tilde = 554, .item_circ = 684, .item_caron = 860, .item_ogonek = 685, .item_ring = 554, .item_cedilla = 554, .item_stroke = 554, .item_dot = 858 },
    .{ .item = 556, .item_macron = 556, .item_acute = 556, .item_breve = 686, .item_grave = 556, .item_diaresis = 556, .item_tilde = 556, .item_circ = 556, .item_caron = 556, .item_ogonek = 556, .item_ring = 556, .item_cedilla = 556, .item_stroke = 556, .item_dot = 556 },
    .{ .item = 558, .item_macron = 687, .item_acute = 688, .item_breve = 689, .item_grave = 690, .item_diaresis = 691, .item_tilde = 558, .item_circ = 692, .item_caron = 558, .item_ogonek = 693, .item_ring = 558, .item_cedilla = 558, .item_stroke = 558, .item_dot = 694 },
    .{ .item = 561, .item_macron = 561, .item_acute = 697, .item_breve = 561, .item_grave = 561, .item_diaresis = 561, .item_tilde = 561, .item_circ = 561, .item_caron = 561, .item_ogonek = 561, .item_ring = 561, .item_cedilla = 561, .item_stroke = 696, .item_dot = 561 },
    .{ .item = 563, .item_macron = 563, .item_acute = 699, .item_breve = 563, .item_grave = 563, .item_diaresis = 563, .item_tilde = 701, .item_circ = 563, .item_caron = 700, .item_ogonek = 563, .item_ring = 563, .item_cedilla = 563, .item_stroke = 563, .item_dot = 563 },
    .{ .item = 564, .item_macron = 702, .item_acute = 703, .item_breve = 704, .item_grave = 705, .item_diaresis = 706, .item_tilde = 707, .item_circ = 708, .item_caron = 564, .item_ogonek = 564, .item_ring = 564, .item_cedilla = 564, .item_stroke = 709, .item_dot = 564 },
    .{ .item = 567, .item_macron = 567, .item_acute = 862, .item_breve = 567, .item_grave = 567, .item_diaresis = 567, .item_tilde = 567, .item_circ = 567, .item_caron = 863, .item_ogonek = 567, .item_ring = 567, .item_cedilla = 567, .item_stroke = 567, .item_dot = 567 },
    .{ .item = 568, .item_macron = 568, .item_acute = 712, .item_breve = 568, .item_grave = 568, .item_diaresis = 568, .item_tilde = 568, .item_circ = 568, .item_caron = 713, .item_ogonek = 568, .item_ring = 568, .item_cedilla = 714, .item_stroke = 568, .item_dot = 568 },
    .{ .item = 569, .item_macron = 569, .item_acute = 569, .item_breve = 569, .item_grave = 569, .item_diaresis = 569, .item_tilde = 569, .item_circ = 569, .item_caron = 715, .item_ogonek = 569, .item_ring = 569, .item_cedilla = 716, .item_stroke = 569, .item_dot = 569 },
    .{ .item = 570, .item_macron = 717, .item_acute = 718, .item_breve = 719, .item_grave = 720, .item_diaresis = 721, .item_tilde = 722, .item_circ = 723, .item_caron = 570, .item_ogonek = 864, .item_ring = 724, .item_cedilla = 570, .item_stroke = 570, .item_dot = 570 },
    .{ .item = 572, .item_macron = 572, .item_acute = 572, .item_breve = 572, .item_grave = 572, .item_diaresis = 572, .item_tilde = 572, .item_circ = 725, .item_caron = 572, .item_ogonek = 572, .item_ring = 572, .item_cedilla = 572, .item_stroke = 572, .item_dot = 572 },
    .{ .item = 574, .item_macron = 574, .item_acute = 727, .item_breve = 574, .item_grave = 574, .item_diaresis = 728, .item_tilde = 574, .item_circ = 726, .item_caron = 574, .item_ogonek = 574, .item_ring = 574, .item_cedilla = 574, .item_stroke = 574, .item_dot = 574 },
    .{ .item = 575, .item_macron = 575, .item_acute = 729, .item_breve = 575, .item_grave = 575, .item_diaresis = 575, .item_tilde = 575, .item_circ = 575, .item_caron = 730, .item_ogonek = 575, .item_ring = 575, .item_cedilla = 575, .item_stroke = 575, .item_dot = 731 },
    .{ .item = 576, .item_macron = 732, .item_acute = 733, .item_breve = 734, .item_grave = 735, .item_diaresis = 736, .item_tilde = 737, .item_circ = 738, .item_caron = 576, .item_ogonek = 741, .item_ring = 739, .item_cedilla = 576, .item_stroke = 576, .item_dot = 576 },
    .{ .item = 578, .item_macron = 578, .item_acute = 742, .item_breve = 578, .item_grave = 578, .item_diaresis = 578, .item_tilde = 578, .item_circ = 578, .item_caron = 743, .item_ogonek = 578, .item_ring = 578, .item_cedilla = 744, .item_stroke = 578, .item_dot = 578 },
    .{ .item = 579, .item_macron = 579, .item_acute = 579, .item_breve = 579, .item_grave = 579, .item_diaresis = 579, .item_tilde = 579, .item_circ = 579, .item_caron = 579, .item_ogonek = 579, .item_ring = 579, .item_cedilla = 579, .item_stroke = 745, .item_dot = 579 },
    .{ .item = 580, .item_macron = 747, .item_acute = 748, .item_breve = 749, .item_grave = 750, .item_diaresis = 751, .item_tilde = 580, .item_circ = 752, .item_caron = 861, .item_ogonek = 753, .item_ring = 580, .item_cedilla = 580, .item_stroke = 580, .item_dot = 859 },
    .{ .item = 582, .item_macron = 582, .item_acute = 582, .item_breve = 754, .item_grave = 582, .item_diaresis = 582, .item_tilde = 582, .item_circ = 582, .item_caron = 582, .item_ogonek = 582, .item_ring = 582, .item_cedilla = 582, .item_stroke = 582, .item_dot = 582 },
    .{ .item = 583, .item_macron = 583, .item_acute = 583, .item_breve = 583, .item_grave = 583, .item_diaresis = 583, .item_tilde = 583, .item_circ = 583, .item_caron = 583, .item_ogonek = 583, .item_ring = 583, .item_cedilla = 583, .item_stroke = 755, .item_dot = 583 },
    .{ .item = 584, .item_macron = 756, .item_acute = 757, .item_breve = 758, .item_grave = 759, .item_diaresis = 760, .item_tilde = 584, .item_circ = 761, .item_caron = 584, .item_ogonek = 762, .item_ring = 584, .item_cedilla = 584, .item_stroke = 584, .item_dot = 763 },
    .{ .item = 587, .item_macron = 587, .item_acute = 766, .item_breve = 587, .item_grave = 587, .item_diaresis = 587, .item_tilde = 587, .item_circ = 587, .item_caron = 587, .item_ogonek = 587, .item_ring = 587, .item_cedilla = 587, .item_stroke = 765, .item_dot = 587 },
    .{ .item = 589, .item_macron = 589, .item_acute = 768, .item_breve = 589, .item_grave = 589, .item_diaresis = 589, .item_tilde = 770, .item_circ = 589, .item_caron = 769, .item_ogonek = 589, .item_ring = 589, .item_cedilla = 589, .item_stroke = 589, .item_dot = 589 },
    .{ .item = 590, .item_macron = 771, .item_acute = 772, .item_breve = 773, .item_grave = 774, .item_diaresis = 775, .item_tilde = 776, .item_circ = 777, .item_caron = 590, .item_ogonek = 590, .item_ring = 590, .item_cedilla = 590, .item_stroke = 778, .item_dot = 590 },
    .{ .item = 593, .item_macron = 593, .item_acute = 781, .item_breve = 593, .item_grave = 593, .item_diaresis = 593, .item_tilde = 593, .item_circ = 593, .item_caron = 780, .item_ogonek = 593, .item_ring = 593, .item_cedilla = 593, .item_stroke = 593, .item_dot = 593 },
    .{ .item = 594, .item_macron = 594, .item_acute = 783, .item_breve = 594, .item_grave = 594, .item_diaresis = 594, .item_tilde = 594, .item_circ = 594, .item_caron = 784, .item_ogonek = 594, .item_ring = 594, .item_cedilla = 785, .item_stroke = 594, .item_dot = 594 },
    .{ .item = 595, .item_macron = 595, .item_acute = 595, .item_breve = 595, .item_grave = 595, .item_diaresis = 595, .item_tilde = 595, .item_circ = 595, .item_caron = 595, .item_ogonek = 595, .item_ring = 595, .item_cedilla = 787, .item_stroke = 595, .item_dot = 595 },
    .{ .item = 596, .item_macron = 788, .item_acute = 789, .item_breve = 790, .item_grave = 791, .item_diaresis = 792, .item_tilde = 793, .item_circ = 794, .item_caron = 596, .item_ogonek = 865, .item_ring = 795, .item_cedilla = 596, .item_stroke = 596, .item_dot = 596 },
    .{ .item = 598, .item_macron = 598, .item_acute = 598, .item_breve = 598, .item_grave = 598, .item_diaresis = 598, .item_tilde = 598, .item_circ = 796, .item_caron = 598, .item_ogonek = 598, .item_ring = 598, .item_cedilla = 598, .item_stroke = 598, .item_dot = 598 },
    .{ .item = 599, .item_macron = 599, .item_acute = 599, .item_breve = 599, .item_grave = 599, .item_diaresis = 599, .item_tilde = 599, .item_circ = 798, .item_caron = 599, .item_ogonek = 599, .item_ring = 599, .item_cedilla = 599, .item_stroke = 599, .item_dot = 599 },
    .{ .item = 600, .item_macron = 600, .item_acute = 801, .item_breve = 600, .item_grave = 600, .item_diaresis = 802, .item_tilde = 600, .item_circ = 800, .item_caron = 600, .item_ogonek = 600, .item_ring = 600, .item_cedilla = 600, .item_stroke = 600, .item_dot = 600 },
    .{ .item = 601, .item_macron = 601, .item_acute = 803, .item_breve = 601, .item_grave = 601, .item_diaresis = 601, .item_tilde = 601, .item_circ = 601, .item_caron = 804, .item_ogonek = 601, .item_ring = 601, .item_cedilla = 601, .item_stroke = 601, .item_dot = 805 },
    .{ .item = 806, .item_macron = 806, .item_acute = 806, .item_breve = 806, .item_grave = 806, .item_diaresis = 806, .item_tilde = 837, .item_circ = 832, .item_caron = 806, .item_ogonek = 806, .item_ring = 918, .item_cedilla = 806, .item_stroke = 806, .item_dot = 849 },
    .{ .item = 0, .item_macron = 0, .item_acute = 0, .item_breve = 0, .item_grave = 0, .item_diaresis = 0, .item_tilde = 0, .item_circ = 0, .item_caron = 0, .item_ogonek = 0, .item_ring = 0, .item_cedilla = 0, .item_stroke = 0, .item_dot = 0 },
};

extern var deadKey: u32;
extern var testDeadKeys: bool;

extern fn getSystemFlag(sf: i32) bool;
extern fn showHideAlphaMode() void;
extern fn refreshLcd(unused_data: ?*anyopaque) c_int;

fn getGdkKeyItem(gdkKey: u32) i16 {
    if ((GDK_KEY_Shift_L <= gdkKey and gdkKey <= GDK_KEY_Hyper_R) or
        (GDK_KEY_Home <= gdkKey and gdkKey <= GDK_KEY_Begin) or
        (GDK_KEY_F1 <= gdkKey and gdkKey <= GDK_KEY_F14) or
        (GDK_KEY_zerosubscript < gdkKey))
    {
        return 0;
    } else if (GDK_KEY_0 <= gdkKey and gdkKey <= GDK_KEY_9) {
        return ITM_0 + @as(i16, @intCast(gdkKey - GDK_KEY_0));
    } else if (GDK_KEY_A <= gdkKey and gdkKey <= GDK_KEY_Z) {
        return ITM_A + @as(i16, @intCast(gdkKey - GDK_KEY_A));
    } else if (GDK_KEY_a <= gdkKey and gdkKey <= GDK_KEY_z) {
        return ITM_a + @as(i16, @intCast(gdkKey - GDK_KEY_a));
    } else if (GDK_KEY_KP_0 <= gdkKey and gdkKey <= GDK_KEY_KP_9) {
        return ITM_0 + @as(i16, @intCast(gdkKey - GDK_KEY_KP_0));
    } else if (GDK_KEY_KP_Multiply <= gdkKey and gdkKey <= GDK_KEY_KP_Divide) {
        return ITM_ASTERISK + @as(i16, @intCast(gdkKey - GDK_KEY_KP_Multiply));
    } else if (GDK_KEY_space <= gdkKey and gdkKey <= GDK_KEY_slash) {
        return ITM_SPACE + @as(i16, @intCast(gdkKey - GDK_KEY_space));
    } else if (GDK_KEY_colon <= gdkKey and gdkKey <= GDK_KEY_at) {
        return ITM_COLON + @as(i16, @intCast(gdkKey - GDK_KEY_colon));
    } else if (GDK_KEY_zerosubscript <= gdkKey and gdkKey <= GDK_KEY_ninesubscript) {
        return ITM_SUB_0 + @as(i16, @intCast(gdkKey - GDK_KEY_zerosubscript));
    } else {
        var i: usize = 0;
        while (gdkKeyMap[i].item != 0) {
            if (gdkKeyMap[i].gdkKey == gdkKey) {
                break;
            }
            i += 1;
        }
        return gdkKeyMap[i].item;
    }
}

fn getDeadKeyItem(item: i16) i16 {
    if (deadKey == GDK_KEY_F12) {
        switch (item) {
            ITM_A => return ITM_ALPHA,
            ITM_B => return ITM_BETA,
            ITM_C => return ITM_GAMMA,
            ITM_D => return ITM_DELTA,
            ITM_E => return ITM_EPSILON,
            ITM_F => return ITM_PHI,
            ITM_G => return ITM_GAMMA,
            ITM_H => return ITM_CHI,
            ITM_I => return ITM_IOTA,
            ITM_J => return ITM_ETA,
            ITM_K => return ITM_KAPPA,
            ITM_L => return ITM_LAMBDA,
            ITM_M => return ITM_MU,
            ITM_N => return ITM_NU,
            ITM_O => return ITM_OMEGA,
            ITM_P => return ITM_PI,
            ITM_Q => return ITM_OMICRON,
            ITM_R => return ITM_RHO,
            ITM_S => return ITM_SIGMA,
            ITM_T => return ITM_TAU,
            ITM_U => return ITM_THETA,
            ITM_V => return ITM_QOPPA,
            ITM_W => return ITM_PSI,
            ITM_X => return ITM_XI,
            ITM_Y => return ITM_UPSILON,
            ITM_Z => return ITM_ZETA,
            ITM_a => return ITM_alpha,
            ITM_b => return ITM_beta,
            ITM_c => return ITM_gamma,
            ITM_d => return ITM_delta,
            ITM_e => return ITM_epsilon,
            ITM_f => return ITM_phi,
            ITM_g => return ITM_gamma,
            ITM_h => return ITM_chi,
            ITM_i => return ITM_iota,
            ITM_j => return ITM_eta,
            ITM_k => return ITM_kappa,
            ITM_l => return ITM_lambda,
            ITM_m => return ITM_mu,
            ITM_n => return ITM_nu,
            ITM_o => return ITM_omega,
            ITM_p => return ITM_pi,
            ITM_q => return ITM_omicron,
            ITM_r => return ITM_rho,
            ITM_s => return ITM_sigma,
            ITM_t => return ITM_tau,
            ITM_u => return ITM_theta,
            ITM_v => return ITM_qoppa,
            ITM_w => return ITM_psi,
            ITM_x => return ITM_xi,
            ITM_y => return ITM_upsilon,
            ITM_z => return ITM_zeta,
            else => {},
        }
    } else {
        var i: usize = 0;
        while (deadKeysMap[i].item != 0) : (i += 1) {
            if (deadKeysMap[i].item == item) {
                switch (deadKey) {
                    GDK_KEY_dead_macron => return deadKeysMap[i].item_macron,
                    GDK_KEY_dead_acute => return deadKeysMap[i].item_acute,
                    GDK_KEY_dead_breve => return deadKeysMap[i].item_breve,
                    GDK_KEY_dead_grave => return deadKeysMap[i].item_grave,
                    GDK_KEY_dead_diaeresis => return deadKeysMap[i].item_diaresis,
                    GDK_KEY_dead_tilde => return deadKeysMap[i].item_tilde,
                    GDK_KEY_dead_circumflex => return deadKeysMap[i].item_circ,
                    GDK_KEY_dead_ogonek => return deadKeysMap[i].item_ogonek,
                    GDK_KEY_dead_abovering => return deadKeysMap[i].item_ring,
                    GDK_KEY_dead_cedilla => return deadKeysMap[i].item_cedilla,
                    GDK_KEY_dead_stroke => return deadKeysMap[i].item_stroke,
                    GDK_KEY_dead_abovedot => return deadKeysMap[i].item_dot,
                    else => {},
                }
            }
        }
    }
    return item;
}

pub fn keyCodeFromGdkKey(gdk_k: u32) i16 {
    var gdkKey = gdk_k;

    if (testDeadKeys) {
        gdkKey = switch (gdkKey) {
            '^' => GDK_KEY_dead_circumflex,
            '`' => GDK_KEY_dead_grave,
            '\'' => GDK_KEY_dead_acute,
            '~' => GDK_KEY_dead_tilde,
            '/' => GDK_KEY_dead_stroke,
            else => gdkKey,
        };
    }

    const is_dead_key = switch (gdkKey) {
        GDK_KEY_F12,
        GDK_KEY_dead_macron,
        GDK_KEY_dead_acute,
        GDK_KEY_dead_breve,
        GDK_KEY_dead_grave,
        GDK_KEY_dead_diaeresis,
        GDK_KEY_dead_tilde,
        GDK_KEY_dead_circumflex,
        GDK_KEY_dead_ogonek,
        GDK_KEY_dead_abovering,
        GDK_KEY_dead_cedilla,
        GDK_KEY_dead_stroke,
        GDK_KEY_dead_abovedot,
        => true,
        else => false,
    };

    if (is_dead_key) {
        if (deadKey != 0 and deadKey == gdkKey and testDeadKeys) {
            deadKey = 0;
            gdkKey = switch (gdkKey) {
                GDK_KEY_dead_circumflex => '^',
                GDK_KEY_dead_grave => '`',
                GDK_KEY_dead_acute => '\'',
                GDK_KEY_dead_tilde => '~',
                GDK_KEY_dead_stroke => '/',
                else => gdkKey,
            };
            showHideAlphaMode();
            _ = refreshLcd(null);
            // falls through to the normal translation (cancelledDeadkey)
        } else {
            deadKey = gdkKey;
            showHideAlphaMode();
            _ = refreshLcd(null);
            return -1;
        }
    }

    var item: i16 = switch (gdkKey) {
        GDK_KEY_Tab => ITM_CR,
        '`' => ITM_NQUOTE,
        '*' => ITM_PROD_SIGN,
        else => getGdkKeyItem(gdkKey),
    };

    if (item == ITM_PROD_SIGN) {
        item = if (getSystemFlag(FLAG_MULTx)) ITM_CROSS else ITM_DOT;
    }

    if (item != 0) {
        if (deadKey != 0) {
            item = getDeadKeyItem(item);
            deadKey = 0;
        }
    }

    return item;
}
