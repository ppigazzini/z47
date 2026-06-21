// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK key-translation cluster ported from src/c47-gtk/gtkGui.c
// (_getGdkKeyItem / _getDeadKeyItem / _keyCodeFromGdkKey). It maps raw GDK key
// codes -- including dead-key composition -- to C47 item codes for the desktop
// keyboard-shortcut path. The lookup tables gdkKeyMap[] / deadKeysMap[] stay as
// C-defined `const` data in gtkGui.c and are reached here as extern arrays.

// --- item codes (probed from items.h via __DEV/gen_consts.c) ---
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

// gdkKeyMap[] and deadKeysMap[] remain defined as C data in gtkGui.c.
const gdkKeyMap = @extern([*]const gdkKeyMap_t, .{ .name = "gdkKeyMap" });
const deadKeysMap = @extern([*]const deadKeysMap_t, .{ .name = "deadKeysMap" });

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
