# NanoV integration regression

The cocotb test boots `test.mem` through `sim_spi_ram.v` and verifies the
retained RV32E base-integer datapath, control flow, SPI memory, and GPIO through
the Tiny Tapeout wrapper. UART and the optional multiplier are deliberately not
part of this one-tile design.

From this directory:

```sh
make -B
! grep failure results.xml
```

The local RTL normalizes several inherited declaration-order constructs and is
verified with Icarus 13. Activate the project cocotb environment before running
the test, or use `RUN_RTL_TEST.cmd` from the repository root.

```sh
make clean
make
```

After a successful SKY130 hardening run has supplied `gate_level_netlist.v` and
`PDK_ROOT` points to the SKY130 PDK, run:

```sh
make -B GATES=yes
! grep failure results.xml
```

The Makefile loads the SKY130 HD primitives and functional cell models for the
gate-level run. After changing simulator versions or netlists, remove the old
build with `GATES=yes make clean` before rerunning.

The waveform is written to `tb.fst`.
