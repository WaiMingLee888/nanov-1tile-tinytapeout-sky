#!/usr/bin/env python3
"""Convert a little-endian RV32 binary to one 32-bit word per readmemh line."""

from pathlib import Path
import argparse


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("mem", type=Path)
    args = parser.parse_args()

    data = args.binary.read_bytes()
    data += bytes((-len(data)) % 4)
    words = [
        int.from_bytes(data[i : i + 4], "little")
        for i in range(0, len(data), 4)
    ]
    args.mem.write_text("".join(f"{word:08x}\n" for word in words), encoding="ascii")
    print(f"wrote {len(words)} compiler-generated RV32E words to {args.mem}")


if __name__ == "__main__":
    main()
