# Compiler-generated NanoV test firmware

This directory builds a freestanding bare-metal RV32E program using the
Buildroot-generated RISC-V GCC toolchain from the KianV work. It does not link
uClibc or attempt to boot Linux.

The firmware writes the `0x01` boot signature, reads the GPIO input, exercises
compiler-generated arithmetic, shifts, branches, SPI-memory stores and loads,
then writes `0xA5` on success or `0xEE` on failure. The simulator supplies GPIO
input `0x5A`.

```sh
make clean
make
make simulate
```

Outputs are placed under `firmware/build/`:

- `nanov_test.elf`: RV32E/ILP32E ELF
- `nanov_test.bin`: flat little-endian program image
- `nanov_test.mem`: conventional 32-bit little-endian SPI-RAM/readmemh image
- `nanov_test.disasm.txt`: disassembly for inspection
- `nanov_test.map`: link map

The checked-in `prebuilt/` directory contains the verified ELF, flat binary,
SPI-RAM `.mem` image, and disassembly from the evidence run recorded in
`docs/FIRMWARE_EVIDENCE.md`. Rebuild from source whenever the firmware or
toolchain changes.

The `.mem` converter does not reverse bits. For example, binary bytes
`37 01 01 00` are written as `00010137`, as expected for an RV32
little-endian image.
