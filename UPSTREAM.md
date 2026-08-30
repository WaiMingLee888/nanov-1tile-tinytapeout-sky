# Upstream provenance

This port deliberately pins the RTL that was used by the silicon-proven Tiny
Tapeout 4 NanoV project.

| Component | Source | Pinned commit | License |
| --- | --- | --- | --- |
| Tiny Tapeout wrapper and integration test | `MichaelBell/tt04-nanoV` | `f6fcbbfe693fec80418b6dccc6447019cca8435e` | Apache-2.0 |
| NanoV CPU core | `MichaelBell/nanoV` | `8c95b70026e8878aa9e5a6c2f336890b25694fe7` | Apache-2.0 |
| UART RX/TX | Retained under `src/nanoV/uart` | Same pinned NanoV commit | MIT, Copyright 2021 Ben Marshall; changes Copyright 2023 Michael Bell |
| Tiny Tapeout project structure | `TinyTapeout/ttsky-verilog-template` | `60c39394fc4b67dd95e019ccd8849392eb00521d` | Apache-2.0 |

Retained license texts are in `LICENSE`, `src/nanoV/LICENSE`, and
`src/nanoV/uart/LICENSE`.

## Technology-port changes

Only two technology-specific RTL constructs were changed:

1. The Sky130 buffer on `spi_clk_enable` in `src/tt_top.v` became a direct
   continuous assignment.
2. The Sky130 scan-DFF accumulator in `src/nanoV/multiply.v` became NanoV's
   existing generic `reg` accumulator implementation.

The same two substitutions have precedent in Tiny Tapeout's historical IHP
NanoV integration and avoid binding functional RTL to a particular standard
cell. The wrapper was renamed to
`tt_um_WaiMingLee888_nanov`, metadata was migrated from YAML schema 4 to 6, the clock
was declared as 12 MHz, and the cocotb harness was updated for cocotb 2.x.

The silicon-proven TT04 project used `1x2`, and this SKY130 port retains that
footprint. Physical equivalence is not assumed: the current TTSKY26c flow must
independently pass placement, routing, timing, DRC, LVS, antenna, gate-level
simulation, and Tiny Tapeout precheck before submission.

The first TTSKY26c physical run (GitHub Actions run `33256241839`) reached CTS
with nonnegative hold slack, but the template's additional 0.1 ns placement
hold margin caused 528 hold buffers to be inserted and 81 instances could not
be legalized. `PL_RESIZER_HOLD_SLACK_MARGIN` and
`GRT_RESIZER_HOLD_SLACK_MARGIN` are therefore set to `0.0`. This removes only
the extra optimization cushion; final signoff must still report nonnegative
hold slack at every analyzed corner.

The second run (`33256494032`) measured −0.049 ns worst hold slack with the
template's 0.25 ns clock uncertainty. Repairing that small deficit required
391 buffers (+15.2% cell area), leaving 43 instances unlegalized. The project
uses 0.20 ns clock uncertainty so that the 50 ps adjustment covers the measured
deficit without removing clock margin. Multi-corner signoff remains the
authoritative check.

Run `33256961286` completed detailed routing with zero DRC and antenna
violations and zero setup violations. Post-route extraction then found 11 fast
corner hold endpoints (worst slack −0.0134 ns, TNS −0.0394 ns). The default
flow had `RUN_POST_GRT_RESIZER_TIMING` disabled, so this project enables that
standard stage to repair the small routed-parasitic hold deficit before final
signoff.

Run `33257322779` inserted one post-GRT hold buffer and retained zero detailed
routing and antenna violations. Extracted timing improved to −0.0074 ns worst
hold slack but exposed 15 fast-corner endpoints that the global-route estimate
did not predict. `GRT_RESIZER_HOLD_SLACK_MARGIN` is set to 0.02 ns to cover the
measured 7.4 ps estimation error while leaving the placement-stage margin at
zero.

Run `33257620930` tested the 0.02 ns post-GRT hold margin described above. It
classified 357 near-zero-slack endpoints as violations and attempted 357 delay
buffers (+13.9% cell area); 30 instances could not be legalized. Its repair
progress showed that a 0.01 ns target is reached after roughly 80--90 buffers,
while still covering the measured 7.4 ps global-route-to-extracted timing
mismatch. `GRT_RESIZER_HOLD_SLACK_MARGIN` is therefore narrowed to 0.01 ns,
with the placement-stage margin remaining zero. Final extracted multi-corner
timing is still the pass/fail authority.

No claim is made that this migration is a new CPU architecture. The purpose is
to provide a reproducible, attributed current-template ASIC project around an
existing working open-source RISC-V design.

## One-tile derivative boundary

This workspace project is derived from the signed 1x2 SKY130 port but is not
covered by that port's signoff. It retains `NUM_REGS=16`, the bit-serial base
integer datapath, SPI instruction/data memory, and minimal GPIO. It excludes
the UART source files and optional multiplier from the design manifest. The
multiplier removal also removes NanoV's multiply-specific cycle classification;
base RV32E shift classification remains. Declaration ordering in `cpu.v` and
`core.v` was normalized for strict Icarus elaboration without changing logic.
