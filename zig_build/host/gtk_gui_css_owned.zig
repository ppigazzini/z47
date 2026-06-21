// SPDX-License-Identifier: GPL-3.0-only
//
// Host GTK CSS preprocessing ported from src/c47-gtk/gtkGui.c prepareCssData():
// reads res/c47_pre.css, performs the "/* Replace $X with Y */" token
// substitutions in place, and leaves the result in the `cssData` global that
// setupUI later hands to gtk_css_provider_load_from_data. cssData stays a
// C-defined global (setupUI still reads it).

const CSSFILE: [*:0]const u8 = "res/c47_pre.css";

const SEEK_SET: c_int = 0;
const SEEK_END: c_int = 2;

extern var cssData: [*c]u8;

extern fn fopen(path: [*c]const u8, mode: [*c]const u8) ?*anyopaque;
extern fn fseek(stream: ?*anyopaque, offset: c_long, whence: c_int) c_int;
extern fn ftell(stream: ?*anyopaque) c_long;
extern fn fread(ptr: ?*anyopaque, size: usize, nmemb: usize, stream: ?*anyopaque) usize;
extern fn fclose(stream: ?*anyopaque) c_int;
extern fn malloc(size: usize) ?*anyopaque;
extern fn strstr(haystack: [*c]const u8, needle: [*c]const u8) [*c]u8;
extern fn strReplace(haystack: [*c]u8, needle: [*c]const u8, new_needle: [*c]const u8) void;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
extern fn printf(fmt: [*c]const u8, ...) c_int;
extern fn exit(code: c_int) noreturn;

pub fn prepareCssData() void {
    const css_file = fopen(CSSFILE, "rb") orelse {
        moreInfoOnError("In function prepareCssData:", "error opening file res/c47_pre.css!", null, null);
        exit(1);
    };

    // Get the file length.
    _ = fseek(css_file, 0, SEEK_END);
    const file_lg: usize = @intCast(ftell(css_file));
    _ = fseek(css_file, 0, SEEK_SET);

    cssData = @ptrCast(malloc(2 * file_lg) orelse { // To be sure there is enough space
        moreInfoOnError("In function prepareCssData:", "error allocating 10000 bytes for CSS data", null, null);
        exit(1);
    });

    _ = fread(cssData, 1, file_lg, css_file);
    _ = fclose(css_file);
    cssData[file_lg] = 0;

    var to_replace = strstr(cssData, "/* Replace $");
    while (to_replace != null) {
        var needle: [100]u8 = undefined;
        var new_needle: [100]u8 = undefined;

        to_replace += 11;
        var i: usize = 0;
        while (to_replace[i] != ' ') : (i += 1) {
            needle[i] = to_replace[i];
        }
        needle[i] = 0;

        to_replace[0] = ' ';

        const replace_with = strstr(to_replace, " with ");
        if (replace_with == null) {
            moreInfoOnError("In function prepareCssData:", "Can't find \" with \" after \"/* Replace $\" in CSS file res/c47_pre.css", null, null);
            exit(1);
        }

        replace_with[1] = ' ';
        const rw = replace_with + 6;
        i = 0;
        while (rw[i] != ' ') : (i += 1) {
            new_needle[i] = rw[i];
        }
        new_needle[i] = 0;

        strReplace(to_replace, &needle, &new_needle);

        to_replace = strstr(cssData, "/* Replace $");
    }

    if (strstr(cssData, "$") != null) {
        moreInfoOnError("In function prepareCssData:", "There is still an unreplaced $ in the CSS file!\nPlease check file res/c47_pre.css", null, null);
        _ = printf("%s\n", cssData);
        exit(1);
    }
}
