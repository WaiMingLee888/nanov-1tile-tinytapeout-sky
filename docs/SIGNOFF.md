# NanoV 1x1 SKY130 signoff

## Bound revision

- Repository: `WaiMingLee888/nanov-1tile-tinytapeout-sky`
- Physical commit: `aea43d652be6ea42b024105291aadba46a345347`
- Immutable tag: `nanov-1tile-ttsky26c-gds-33322018202`
- Official workflow: `33322018202`, successful on attempt 3
- Independent full rerun: `33323135770`, successful on attempt 1
- Tiny Tapeout target: `ttsky26c`, SKY130A, 1x1 tile

The viewer retries did not rebuild the physical design. Attempt 1 produced the
GDS, submission, precheck, and gate-level results. GitHub Pages was then enabled
for Actions deployment; attempt 3 reran only the previously failed viewer job.

## Functional evidence

- Manifest footprint is exactly `1x1`.
- The CPU retains the RV32E base integer register set x0-x15.
- Optional multiplier and UART are excluded from the instantiated one-tile top.
- The 97-word wrapper-level RV32E regression passes through modeled SPI RAM.
- The independent directed core/register/SPI regression passes.
- GCC 12.3 RV32E/ILP32E firmware produces 48 conventional little-endian words
  and passes the wrapper-level simulation.
- SPI memory images use ordinary RISC-V word notation; no firmware-side bit
  reversal is required.

## Official physical evidence

Run `33322018202` completed all 72 LibreLane steps and all four official jobs:

| Requirement | Authoritative result |
| --- | --- |
| Global placement | Passed at 95% target density |
| Detailed placement | Passed |
| Clock-tree synthesis/legalization | Passed with 17 `clkbuf_2` clock buffers |
| Detailed routing | Passed; final TritonRoute DRC errors = 0 |
| Antenna | 0 violating nets, 0 violating pins |
| Magic DRC | 0 errors |
| LVS | 0 errors or unmatched nets/devices/pins |
| Power grid | Connected; 0 violations |
| Extracted setup timing | 0 violations in all 9 corners; worst slack 22.938 ns |
| Extracted hold timing | 0 violations in all 9 corners; worst slack 0.102 ns |
| Tiny Tapeout precheck | Passed |
| Extracted gate-level simulation | Passed |
| GDS viewer deployment | Passed on attempt 3 |

Final physical metrics include a `161 x 111.52 um` die, 16,493.3 um2 instance
area including fill/tap/antenna cells, 1,346 routed signal nets, and 51,523 um
of routed wire. The manufacturability report states Antenna, LVS, and DRC all
passed.

The raw extracted STA metrics report 1,012 max-slew, 10 max-capacitance, and 11
max-fanout limit exceedances at the worst corner. Tiny Tapeout's supplied
checker configuration leaves max-slew and max-capacitance violation-corner
lists empty, so these are reported metrics rather than workflow blockers. This
record does not claim they are zero. Required 12 MHz setup and hold timing are
clean.

## Artifact identity

Downloaded official artifacts are retained locally under
`.artifacts/gds-33322018202/` (ignored by Git because of size).

| Artifact | SHA-256 |
| --- | --- |
| `tt_um_WaiMingLee888_nanov_1tile.gds` | `c8e6f15acb0c01c7546e8ecdf358bc3eeb79ce8621fab1328a99d1413d66a799` |
| `tt_um_WaiMingLee888_nanov_1tile.oas` | `c2e60b41621b05a368bf8353420bdbac796c15af3c6420f9e6c775a68e90cca9` |
| `tt_um_WaiMingLee888_nanov_1tile.nom.spef` | `b32a920bb5a621ce494088990e7b04d3f1197692d489807c01931792e4ad6a82` |
| `tt_um_WaiMingLee888_nanov_1tile.v` | `d0b920d7f061bc443bf406efb076507509bd4532d0c4a5886bb9e693e99cf74a` |

GitHub artifacts `GDS_logs`, `tt_submission`, `gds_render`,
`gatelevel_test_results`, and `precheck_reports` are attached to official run
`33322018202`.

Independent run `33323135770` repeated all four jobs successfully. Its OAS
SHA-256 and post-PNR Verilog SHA-256 exactly match the table above. Its nominal
SPEF differs only in the generated `*DATE` line. Its GDS has the same 3,270,812
byte length and differs in 136 bytes; all differences are the same two
minute/second timestamp fields repeated across 68 GDS structure headers. The
second timestamp-bearing GDS SHA-256 is
`e3446d6705129d897ed8d24d6ec411ae3325c1e0a67ef7ace04aecccc70691e6`.

## Claim boundary

This evidence establishes a routed, signoff-checked, officially prechecked 1x1
Tiny Tapeout submission retaining RV32E capability. It does not establish that
this derivative has been fabricated or tested in silicon.
