# RTL simulation evidence

Run started: 2026-08-30T09:04:59-04:00.

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
| `docs/RTL_TEST_LATEST.log` | `7e86c6d03874f9a9f696fde3a946d057a571607d7ab7bb3e18a8e99c1d02e7e9` |
| `test/results.xml` | `217bbe2ae15e5a20faf6c35c8d0262fff8959d65bf7b8fe3f0e034a43870abe2` |
| `test/test.mem` | `acec845bf0b9ad02dcbbbdad4eb28471f6d5e455fc2b7f084dbfd54ccebf4e69` |
| `test/sim_build/rtl/sim.vvp` | `b549930bcc37c502576c29d89afb558253c451916601842325d68917bd10038a` |
| `test/tb.fst` | `f969629be3d92438748bb7d574981a8bb969eff2ede33d7100cd77187d091bce` |

This clean rerun uses conventional RV32 little-endian words with no per-byte
bit reversal, includes FST waveform dumping, and constrains `$readmemh` to the
generated 97-word range. It completed without warnings or errors.
