# RTL simulation evidence

Run started: 2026-08-30T09:42:34-04:00.

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
| `docs/RTL_TEST_LATEST.log` | `19496589d17f542dd0518d013a72e21a6616e19387792dbdfebb7363c2fbde11` |
| `test/results.xml` | `b347ad6b61eb3f1a7ddc597868fe015bfdcf9715d115c2cf0803670dd51ad648` |
| `test/test.mem` | `acec845bf0b9ad02dcbbbdad4eb28471f6d5e455fc2b7f084dbfd54ccebf4e69` |
| `test/sim_build/rtl/sim.vvp` | `79479bc14be7793ba1bc52412b77a59b89647fac095cb409dc8c8e3d78b3cb9a` |
| `test/tb.fst` | `176b1c3681661da59c63bc5e2e5a32b6323fa3a27930339147ea7d986fd8113e` |

This clean rerun uses conventional RV32 little-endian words with no per-byte
bit reversal, includes FST waveform dumping, and constrains `$readmemh` to the
generated 97-word range. It completed without warnings or errors.
