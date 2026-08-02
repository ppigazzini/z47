# Regenerating the AN0023 screen captures

Every picture in the note is a real capture from the GTK simulator, driven by the same keystrokes the
note prints. Nothing is mocked up or retouched; the only processing is a 3x point-filter upscale so
the pixels stay square in print.

## Build

```
git worktree add ../C47-wt-an23 master
cd ../C47-wt-an23 && make sim
```

`./c47` chdirs to its own folder, so the `.bmp` files land beside the binary. `press` needs the GTK
front end, so these are `./c47` and not `./t47`.

## Two settings first

Every capture starts from `--reset`, which is factory defaults and ignores `backup.cfg`, and then
makes the two settings the note asks the reader to make:

| setting | keys | why |
| --- | --- | --- |
| `FIX 5` | `press @f; press "@k 15"; press F1; press "@k 24"` | the note quotes 5 decimals throughout |
| `RAD` | `press @f; press "@k 14"; press F2` | `E(φ,m)`, `F(φ,m)` and `Z(φ,m)` read the angular mode |

`RAD` is only set where the note's own example is in radians. Shots 01, 02, 06 and 07 stay in the
factory degree mode, because nothing in them reads an angle.

## Reaching the Ellipt menu

```
press @g; press "@k 20"      # g X.FN
press "@k 17"                # up, to page 2 of 3
press @g; press F1           # g Ellipt, first key on the blue row
```

The up arrow, not the down arrow. `X.FN` has three pages and the paging wraps, so `↓` from page 1
lands on page 3. This was the first thing the captures caught.

## Capture

`snap <name>` writes `<name>.bmp` and `<name>.REGS.TSV.T47.TSV`, the stack as text, which is how the
numerical results below were checked to full precision rather than to what the screen shows.

Writing `$ELL` for the three lines above and `$FIX5` and `$RAD` for the two settings:

| shot | command |
| --- | --- |
| 01-ellipt | `./c47 --reset --exec "$ELL; snap s01ellipt"` |
| 02-em | `./c47 --reset --exec "$FIX5; press \"@k 34\"; press \"@k 20\"; press \"@k 25\"; $ELL; press F5; snap s02em"` |
| 03-ephim | `./c47 --reset --exec "$FIX5; $RAD; press \"@k 34\"; press \"@k 20\"; press \"@k 25\"; press ENTER; press \"@k 34\"; press \"@k 29\"; $ELL; press @f; press F5; snap s03ephim"` |
| 04-elle, 05-solve | `./c47 --reset --script elle.t47` |
| 06-snk | `./c47 --reset --exec "$FIX5; press \"@k 34\"; press \"@k 24\"; press ENTER; press \"@k 34\"; press \"@k 19\"; $ELL; press F1; snap s06snk"` |
| 07-snm | `./c47 --reset --exec "$FIX5; press \"@k 34\"; press \"@k 24\"; press @f; press \"@k 02\"; press \"@k 34\"; press \"@k 19\"; $ELL; press F1; snap s07snm"` |

## Scale for print

```
magick s01ellipt.bmp -filter point -resize 300% screens/01-ellipt.png
```

## Alpha entry inverts the case

`press <single ASCII>` in alpha entry types the opposite case, so the label `EllE` is
`press e; press L; press L; press e`. The physical-key form, `press "@k 04"` for the `E` key, types
the calculator's own default case for the prompt it is in. `elle.t47` uses the ASCII form because
this label is mixed case.

## What the captures corrected

The point of replaying the keystrokes is that three of them were wrong, and none of the three would
have produced an error message:

1. **The paging key.** The note said `↓` to reach page 2 of `X.FN`. Paging wraps, so `↓` goes to
   page 3 and the following `g` soft key presses nothing.
2. **The second and third `MVAR`.** Repeating `P.FN1`, `P.FN2`, `MVAR` for each variable is wrong:
   after the first one the menu is already on `P.FN2`, so the repeat lands on `RTN` and then enters a
   stray alpha literal. `EllE` came out as ten steps with `RTN` at 0003.
3. **The angular mode.** `E(φ,m)`, `F(φ,m)` and `Z(φ,m)` read the angular mode, and the note's worked
   examples are in radians while the factory setting is degrees. In degrees the solver returns
   `11.458 99` instead of `0.200 00`: the same angle in the other unit, and no error at all.

## Numerical results, checked

Every figure the note quotes was reproduced. Read to full precision from the `.REGS.TSV` export:

| example | note | simulator |
| --- | --- | --- |
| `E(m)`, m=.96 | 1.05050 | 1.050 50 |
| `E(φ,m)`, m=.96 φ=.2 rad | .19872 | 0.198 72 |
| solve `EllE`, m=.96 u=.19872 | 0.20000 | 0.199 997 076 533 ... |
| `Π(n,m)`, n=.4 m=.6 | 2.59092 | 2.590 921 156 555 ... |
| `Z(φ,m)`, m=.5 φ=2 rad | -0.11777 | -0.117 772 359 233 ... |
| `sn(u,m)`, m=.5 u=.8 | .69093 | 0.690 934 850 866 ... |
| `sn(u,m)`, m=.25 u=.8 | .70421 | 0.704 212 141 547 ... |
| `sn(u,m)`, m=.36 u=1.3 | .93416 | 0.934 159 410 259 ... |
| `F(φ,m)`, m=.16 φ=36 deg | .63459 | 0.634 591 290 106 ... |
| `E(φ,m)`, m=.16 φ=36 deg | .62215 | 0.622 153 935 928 ... |
| `F(φ,m)`, m=.49 φ=.1 rad | .10008 | 0.100 081 683 231 ... |
| `a,b→m`, a=5 b=1 | .96 | 0.96 |
| `k→m`, k=.5 | .25 | 0.25 |

The only correction to a printed figure was `1.0505`, which the note gave to four decimals while
telling the reader to set `FIX 5`. The display shows `1.050 50`.

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

`press @f` and `press @g` set the pending shift; `press F1`..`press F6` press the soft keys.
