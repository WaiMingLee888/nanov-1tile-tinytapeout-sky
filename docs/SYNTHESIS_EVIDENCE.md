# Generic synthesis evidence

Yosys 0.45+106 synthesized both source trees with the same generic `synth`
flow and hierarchy checking. The standard SPI instruction-word correction is
a static bit permutation and left the derivative at exactly 1,728 cells.

| Source | Generic cells | Wire bits |
| --- | ---: | ---: |
| Signed NanoV 1x2 baseline | 2,087 | 3,759 |
| NanoV 1x1 derivative | 1,728 | 3,272 |
| Reduction | 359 (17.2%) | 487 (13.0%) |

The comparison confirms that removing the optional multiplier and UART reduces
the synthesized design while retaining the 16-register RV32E base datapath.
Generic cells do not predict routability or signoff utilization. The official
Tiny Tapeout SKY130 flow remains the authority for the 1x1 fit decision.

Artifact SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| `docs/SYNTH_GENERIC.log` | `ff49cc2ada6f814b00c2ca7c361f81b6b14fe16878d6ee71259208984ee60cd5` |
| `docs/SYNTH_GENERIC.json` | `a774a2dc800c70db6bcf175c37c6f27e9a94100b088f3f94e085a0f6c436cbc0` |
| `docs/SYNTH_BASELINE_1X2.log` | `24620af79f9c1912d5379f54a2c8734b1457b5975c7a2c1092e4e56822a58eb1` |
