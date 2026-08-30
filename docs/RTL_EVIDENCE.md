# RTL simulation evidence

Run started: 2026-08-30T08:35:30-04:00.

Environment:

- Icarus Verilog 13.0 stable
- Cocotb 2.0.1
- Python 3.10.14
- Top: `tb`, instantiating `tt_um_WaiMingLee888_nanov_1tile`

Result:

- Test: `test.test_rv32e_program`
- Status: PASS
- Simulated time: 331,585.986 ns
- Program words: 97
- Boot signature observed: `0x01`
- Final success signature observed: `0xA5`
- Failure signature `0xEE`: not observed
- XML: one testcase, zero failures, zero errors

Artifact SHA-256 values from the passing run:

| Artifact | SHA-256 |
| --- | --- |
| `docs/RTL_TEST_LATEST.log` | `36829c88fc381d343e63d865e54d14800bfd136db846492f823a9a605616092b` |
| `test/results.xml` | `cb8a8351991ea42f7bd501a21631358652f9e753e61b30e676e198a43a24d947` |
| `test/test.mem` | `fe0ff6d1e23d4296b8454c219ecf72c1a0027a2c8256f1b034b6a5fa3fa93c85` |
| `test/sim_build/rtl/sim.vvp` | `4b8e53c90fd3c491686eecf47919c92b27c5d92d5b962279c159e7751a648b68` |
| `test/tb.fst` | `8238dd1411c6ab7f81d02ce148dbe0e278eb68d63d35d125f01477b7dc0eb2c2` |

This clean rerun includes FST waveform dumping and constrains `$readmemh` to
the generated 97-word range. It completed without warnings or errors.
