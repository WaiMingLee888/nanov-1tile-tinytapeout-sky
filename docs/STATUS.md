# Verification status

This 1x1 NanoV RV32E derivative passed the official Tiny Tapeout SKY130
hardening workflow at physical commit
`aea43d652be6ea42b024105291aadba46a345347`. Run `33322018202` completed GDS,
gate-level simulation, precheck, and viewer successfully. This is a
GDS-verified derivative; it has not yet been fabricated, so no
silicon-proven claim is made for the 1x1 implementation.

## Current evidence

- The manifest declares `1x1`, retains RV32E x0-x15, and excludes the optional
  multiplier and UART.
- Writable x1, x2, and x5-x15 words live in reserved SPI RAM locations;
  hardwired x0, x3, and x4 retain signed NanoV semantics. Two rotating source
  rings are reused in place for destination writeback, avoiding a third ring.
- Program/data images and SPI transactions use conventional little-endian byte
  ordering. No firmware-side bit reversal is required. The wrapper exposes a
  conventional non-inverted mode-0 SCK and samples MISO directly on its rising
  edge; the former falling-edge sample register has been removed.
- The full Tiny Tapeout wrapper passes the 97-word self-checking RV32E
  regression through modeled SPI RAM and GPIO. It covers ALU, shifts,
  comparisons, branches, JAL/JALR, byte/half/word loads and stores, and reaches
  `0xA5` without the `0xEE` failure signature.
- A separate fetched-code directed regression validates dependent operations,
  taken/not-taken branches, jumps and links, SLL/SRL/SRA, SLT/SLTU/SLTI,
  signed/unsigned LB/LH, SB/SH/SW, reserved-register persistence, and GPIO.
- GCC 12.3 builds 48 conventional RV32E/ILP32E words from C. That firmware
  passes on the same external-register top, including general-register-based
  GPIO addressing and SPI scratch-memory checks.
- Mapping the complete wrapper with the retained official SKY130 liberty file
  produces 1,318 standard cells, 197 `dfxtp_2` cells, and 14,652.8032 um^2
  total cell area. Sequential area is 4,190.2688 um^2. Evidence is in
  `ONE_TILE_SKY130_MAP.log` (SHA-256
  `b9e7ade029630c47eaa6b985acc2af743d836f4c7790a0bb77c809587c947b3c`).
- The earlier internal-register GDS trial `33312477537` failed at 21,577.910
  um^2 movable area and 135.548% utilization. The current mapped candidate is
  materially smaller. Trial `33317487603` then reached global placement but
  routability-driven pin-density inflation raised movable area to 16,948.879
  um^2 (106.469%). The next bounded trial disables that inflation and uses a
  95% placement target. That retry showed that the initial placer still adds
  the same 1,999.541 um^2 pin-density adjustment even with routability-driven
  placement disabled. Trial `33318273256` confirmed that skipping initial
  placement also leaves the adjustment active. Trial `33318697303` showed the
  first workflow injection was overwritten by the action's Python setup, and
  trial `33318909097` confirmed a startup guard still targeted the wrong
  runtime context. Trial `33319109423` exposed why: TinyTapeout hardening runs
  inside LibreLane's official 3.0.5 container. The flow now derives a container
  from that exact image with only OpenROAD's documented
  `-disable_pin_density_adjust` switch added. Routing and DRC remain mandatory.

- Trial `33319317296` confirmed the container patch: pin-density adjustment
  was 0, raw movable utilization was 93.909%, and global placement completed.
  Post-GPL repair then failed detailed legalization on 126 reported instance
  placements. This led to a bounded trial of LibreLane's `AREA 1` recovery
  strategy, which had looked smaller in a local mapping context.
- Trial `33319510770` showed `AREA 1` was worse in the official flow:
  15,016.902 um^2 and 122 failed placements. The flow is restored to `AREA 0`.
  The post-GPL repair failure is caused by 10 input buffers followed by 142
  repair buffers for 27 slew and 45 fanout violations. The next bounded trial
  defers that repair until after ordinary detailed placement; CTS, subsequent
  timing repair, routing, and signoff remain enabled.
- Trial `33320278688` reduced the official movable area to 14,560.214 um^2
  (91.464% raw utilization), and both global and detailed placement passed.
  OpenROAD then crashed in CTS because the direct inverted SCK output appeared
  as an inverter clock sink with no downstream instance. The wrapper now uses
  mode-0 non-inverted SCK and no falling-edge MISO register, eliminating that
  invalid CTS topology while preserving the SPI protocol in RTL regression.
- Trial `33320934344` proved the mode-0 wrapper clears the OpenROAD crash and
  completes clock-tree construction. Generic CTS defaults inserted 56 clock
  buffers occupying 1,151.10 um^2, which could not legalize. An exact local
  replay of that run's step-33 database now passes CTS legalization with a
  genuine 17-buffer `clkbuf_2` tree occupying 85.08 um^2. The replay uses a
  30-sink fanout/cluster constraint and OpenROAD's documented no-dummy-load and
  no-insertion-delay modes; routing, extracted setup/hold timing, and physical
  signoff checks remain enabled to validate the smaller tree.

- Official run `33322018202` completed the full 72-step LibreLane flow. The
  final design occupies the Tiny Tapeout 1x1 die (`161 x 111.52 um`), routes
  1,346 signal nets with zero final TritonRoute DRC errors, and has zero
  antenna, Magic DRC, LVS, power-grid, critical-disconnected-pin, setup, and
  hold violations. The worst extracted setup slack is 22.938 ns and the worst
  extracted hold slack is 0.102 ns across all nine reported corners.
- The official gate-level simulation and Tiny Tapeout precheck both passed.
  GitHub Pages is configured for Actions deployment and the official viewer
  job passed on run attempt 3.
- Independent full rerun `33323135770` passed GDS, gate-level simulation,
  precheck, and viewer on its first attempt. Its OAS layout and post-PNR
  netlist are bit-identical to run `33322018202`; its nominal SPEF differs only
  in the generated `*DATE` line. The GDS files have equal length and differ in
  only 136 timestamp-field bytes (68 repeated minute/second pairs).
- The final GDS SHA-256 is
  `c8e6f15acb0c01c7546e8ecdf358bc3eeb79ce8621fab1328a99d1413d66a799`;
  the final OAS SHA-256 is
  `c2e60b41621b05a368bf8353420bdbac796c15af3c6420f9e6c775a68e90cca9`.
- Raw extracted metrics also report 1,012 max-slew, 10 max-capacitance, and 11
  max-fanout limit exceedances at the worst corner. The standard Tiny Tapeout
  checker configuration does not make those categories fatal for this macro;
  they are recorded here rather than being misrepresented as zero. Setup and
  hold timing are clean at the required 12 MHz clock.

## Signoff result

1. Official 1x1 placement, CTS, routing, extraction, and multi-corner
   setup/hold timing: passed.
2. DRC, LVS, antenna, Tiny Tapeout precheck, and extracted gate-level test:
   passed.
3. Physical source and artifacts: bound to commit
   `aea43d652be6ea42b024105291aadba46a345347` and tag
   `nanov-1tile-ttsky26c-gds-33322018202`.

See `SIGNOFF.md` for the requirement-by-requirement audit and artifact hashes.
