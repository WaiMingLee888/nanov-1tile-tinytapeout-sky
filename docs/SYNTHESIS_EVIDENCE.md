# Generic synthesis evidence

Yosys 0.45+106 synthesized both source trees with the same generic `synth`
flow and hierarchy checking.

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
| `docs/SYNTH_GENERIC.log` | `04fea0bc25701008f3dc7a31e9288dc091c4179dbcf940c4c2e458502c3f0850` |
| `docs/SYNTH_GENERIC.json` | `0e42a3ed7eb3265340426722b5050aceca806a666bf55a15d4d64062563cbb5e` |
| `docs/SYNTH_BASELINE_1X2.log` | `24620af79f9c1912d5379f54a2c8734b1457b5975c7a2c1092e4e56822a58eb1` |
