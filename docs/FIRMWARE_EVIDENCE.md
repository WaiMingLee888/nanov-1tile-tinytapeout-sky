# Compiler-generated firmware evidence

Run started: 2026-08-30T09:42:17-04:00.

The KianV Buildroot-generated GCC 12.3.0 cross-compiler built the freestanding
NanoV test with `-march=rv32e -mabi=ilp32e`. The ELF header independently
reports `ELF32`, machine `RISC-V`, entry point `0x0`, and flags `RVE,
soft-float ABI`.

The 192-byte binary was converted directly into 48 conventional little-endian
SPI-memory words. No NanoV-specific bit reversal is required: binary bytes
`37 01 01 00` become the ordinary readmemh word `00010137`. Icarus 13.0 and
Cocotb 2.0.1 then executed the compiler-generated image on the one-tile RTL.
The program observed GPIO input
`0x5A`, exercised arithmetic, shifts, branches, external-memory stores and
loads, and reached output signature `0xA5` after 195,584.90 ns. Result: one test
passed, zero failed.

Artifact SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| `docs/FIRMWARE_TEST_LATEST.log` | `785677425465b6e3e9843e7adb88a0308e395e92daeb687e76427fd6e2e2f9c6` |
| `firmware/prebuilt/nanov_test.elf` | `3cf51c4e230df71174d1cc360dfc3a87ff9749798c1415dad64389ddf546b60c` |
| `firmware/prebuilt/nanov_test.bin` | `2eebcc66eaf46e311417c462ec16ee285f483a888952112278a3f0da02a2a892` |
| `firmware/prebuilt/nanov_test.mem` | `80cbee4bf5b21924e09f02407a0834210218e2617f8d73958f2438db82d1ea29` |
| `firmware/prebuilt/nanov_test.disasm.txt` | `be60abedba830efca7040c9dba9926b1941d2531934a779c62b87c073d424ef1` |
| `docs/artifacts/FIRMWARE_results.xml` | `93ad82789c47b1649ff914840a3fa82dbcc7045f75a6bda40cef58ee5774a74b` |
