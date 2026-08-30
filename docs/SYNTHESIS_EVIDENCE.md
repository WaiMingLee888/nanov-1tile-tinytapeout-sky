# Generic synthesis evidence

Yosys 0.45+106 synthesized both source trees with the same generic `synth`
flow and hierarchy checking. The standard SPI instruction-word correction is
a static bit permutation. Parameterizing the core's register interface leaves
the signed-compatible internal path at 1,725 cells.

| Source | Generic cells | Wire bits |
| --- | ---: | ---: |
| Signed NanoV 1x2 baseline | 2,087 | 3,759 |
| NanoV 1x1 derivative | 1,725 | 3,328 |
| Reduction | 362 (17.3%) | 431 (11.5%) |

The comparison confirms that removing the optional multiplier and UART reduces
the synthesized design while retaining the 16-register RV32E base datapath.
Generic cells do not predict routability or signoff utilization. The official
Tiny Tapeout SKY130 flow remains the authority for the 1x1 fit decision.

Artifact SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| `docs/SYNTH_GENERIC.log` | `e3f25032db7a89627e9ec7e44f02a143f00cbf8fc2f9318348785a368b922910` |
| `docs/SYNTH_GENERIC.json` | `349783bc956c5a8349f7cbc7853822d7274228d10d26362c38e2fd34d7fd0115` |
| `docs/SYNTH_BASELINE_1X2.log` | `24620af79f9c1912d5379f54a2c8734b1457b5975c7a2c1092e4e56822a58eb1` |
