# Regenerating the AN0033 screen captures

Every picture in the note is a real capture from the GTK simulator, driven by the same keystrokes the
note prints. Nothing is mocked up or retouched; the only processing is a 3x point-filter upscale so
the pixels stay square in print.

## Build

```
git worktree add ../C47-wt-an0033 <this branch>
cd ../C47-wt-an0033 && make sim
```

`./c47` chdirs to its own folder, so the `.bmp` files land beside the binary.

## Capture

`--reset` starts from factory defaults and ignores `backup.cfg`, which is what makes these
reproducible on any machine. `snap <name>` writes `<name>.bmp`.

| shot | command |
| --- | --- |
| 01-entry | `./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 30"; press @f; press "@k 20"; press F1; press F3; press "@k 28"; press F6; press "@k 30"; press "@k 14"; press F6; press "@k 29"; snap c1entry'` |
| 02-adv | as 01, then `press "@k 32"; press @f; press "@k 19"; snap c2adv` |
| 03-roots | as 02, then `press @g; press F3; snap c3roots` |
| 04-cpx | as 01 with elements 1, -2, 5 (`"@k 28"` F6 `"@k 29"` `"@k 14"` F6 `"@k 24"`), then EXIT, ADV, `@g` F3, `snap c4cpx` |
| 05-error | `./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 28"; press @f; press "@k 20"; press F1; press F3; press "@k 24"; press "@k 32"; press @f; press "@k 19"; press @g; press F3; snap c5error'` |

The sequences in full, one line per shot, ready to paste:

```
./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 30"; press @f; press "@k 20"; press F1; press F3; press "@k 28"; press F6; press "@k 30"; press "@k 14"; press F6; press "@k 29"; snap c1entry'
./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 30"; press @f; press "@k 20"; press F1; press F3; press "@k 28"; press F6; press "@k 30"; press "@k 14"; press F6; press "@k 29"; press "@k 32"; press @f; press "@k 19"; snap c2adv'
./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 30"; press @f; press "@k 20"; press F1; press F3; press "@k 28"; press F6; press "@k 30"; press "@k 14"; press F6; press "@k 29"; press "@k 32"; press @f; press "@k 19"; press @g; press F3; snap c3roots'
./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 30"; press @f; press "@k 20"; press F1; press F3; press "@k 28"; press F6; press "@k 29"; press "@k 14"; press F6; press "@k 24"; press "@k 32"; press @f; press "@k 19"; press @g; press F3; snap c4cpx'
./c47 --reset --exec 'press "@k 28"; press "@k 12"; press "@k 28"; press @f; press "@k 20"; press F1; press F3; press "@k 24"; press "@k 32"; press @f; press "@k 19"; press @g; press F3; snap c5error'
```

## Scale for print

```
magick <name>.bmp -filter point -resize 300% screens/<nn>-<name>.png
```

## Checking a set still reproduces

After the firmware has moved, rerun the recipe and diff against what is committed. Zero differing
pixels is the answer you want.

```
magick c3roots.bmp -filter point -resize 300% /tmp/r.png
compare -metric AE /tmp/r.png screens/03-roots.png null:
```

## The program-step check

SLVP as a program step was verified with a hand-built `.p47` (LBL 'PSLV', SLVP, END; the SLVP step
encodes as the two bytes 135 173 for item 1965) loaded with `readp` and run with `xeq PSLV` on the
vector `[1,-3,2]`, returning `[2,1]`. The same eleven program bytes are printed in the note.

## Physical key numbers

`press "@k NN"` presses physical key NN, numbered row-major from the C47 table in
`src/c47/assign.c`. In alpha entry the same key types the letter in brackets.

```
00 Sigma+ [A]  01 1/x [B]  02 sqrt [C]  03 LOG [D]  04 LN [E]   05 XEQ [F]
06 STO [G]     07 RCL [H]  08 Rdown [I] 09 SIN [J]  10 COS [K]  11 TAN [L]
12 ENTER       13 x<>y [M] 14 +/- [N]   15 EEX [O]  16 backspace
17 up          18 7 [P]    19 8 [Q]     20 9 [R]    21 div [S]
22 down        23 4 [T]    24 5 [U]     25 6 [V]    26 mult [W]
27 f/g shift   28 1 [X]    29 2 [Y]     30 3 [Z]    31 minus
32 EXIT        33 0        34 .         35 R/S      36 plus [space]
```

`press @f` and `press @g` set the pending shift; `press F1`..`F6` press the soft keys.
