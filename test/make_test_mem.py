#!/usr/bin/env python3
"""Generate the self-checking NanoV one-tile RV32E regression image."""

from __future__ import annotations

import argparse
from pathlib import Path


def r_type(funct7: int, rs2: int, rs1: int, funct3: int, rd: int) -> int:
    return ((funct7 << 25) | (rs2 << 20) | (rs1 << 15) |
            (funct3 << 12) | (rd << 7) | 0x33)


def i_type(imm: int, rs1: int, funct3: int, rd: int, opcode: int = 0x13) -> int:
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def s_type(imm: int, rs2: int, rs1: int, funct3: int) -> int:
    value = imm & 0xFFF
    return (((value >> 5) << 25) | (rs2 << 20) | (rs1 << 15) |
            (funct3 << 12) | ((value & 0x1F) << 7) | 0x23)


def b_type(offset: int, rs2: int, rs1: int, funct3: int) -> int:
    value = offset & 0x1FFF
    return ((((value >> 12) & 1) << 31) | (((value >> 5) & 0x3F) << 25) |
            (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
            (((value >> 1) & 0xF) << 8) | (((value >> 11) & 1) << 7) | 0x63)


def j_type(offset: int, rd: int) -> int:
    value = offset & 0x1FFFFF
    return ((((value >> 20) & 1) << 31) | (((value >> 1) & 0x3FF) << 21) |
            (((value >> 11) & 1) << 20) | (((value >> 12) & 0xFF) << 12) |
            (rd << 7) | 0x6F)


class Program:
    def __init__(self) -> None:
        self.words: list[int] = []
        self.labels: dict[str, int] = {}
        self.fixups: list[tuple[str, int, tuple[int, ...], str]] = []

    @property
    def pc(self) -> int:
        return 4 * len(self.words)

    def emit(self, word: int) -> None:
        self.words.append(word & 0xFFFFFFFF)

    def label(self, name: str) -> None:
        if name in self.labels:
            raise ValueError(f"duplicate label: {name}")
        self.labels[name] = self.pc

    def li(self, rd: int, value: int) -> None:
        value &= 0xFFFFFFFF
        signed = value if value < 0x80000000 else value - 0x100000000
        if -2048 <= signed <= 2047:
            self.emit(i_type(signed, 0, 0, rd))
            return
        upper = (value + 0x800) >> 12
        lower = value - ((upper & 0xFFFFF) << 12)
        if lower >= 0x80000000:
            lower -= 0x100000000
        self.emit(((upper & 0xFFFFF) << 12) | (rd << 7) | 0x37)
        self.emit(i_type(lower, rd, 0, rd))

    def li_label(self, rd: int, label: str) -> None:
        index = len(self.words)
        self.emit(0)
        self.emit(0)
        self.fixups.append(("li", index, (rd,), label))

    def branch(self, funct3: int, rs1: int, rs2: int, label: str) -> None:
        index = len(self.words)
        self.emit(0)
        self.fixups.append(("branch", index, (funct3, rs1, rs2), label))

    def jal(self, rd: int, label: str) -> None:
        index = len(self.words)
        self.emit(0)
        self.fixups.append(("jal", index, (rd,), label))

    def resolve(self) -> list[int]:
        for kind, index, args, label in self.fixups:
            target = self.labels[label]
            pc = 4 * index
            if kind == "branch":
                funct3, rs1, rs2 = args
                self.words[index] = b_type(target - pc, rs2, rs1, funct3)
            elif kind == "jal":
                (rd,) = args
                self.words[index] = j_type(target - pc, rd)
            elif kind == "li":
                (rd,) = args
                upper = (target + 0x800) >> 12
                lower = target - ((upper & 0xFFFFF) << 12)
                self.words[index] = ((upper & 0xFFFFF) << 12) | (rd << 7) | 0x37
                self.words[index + 1] = i_type(lower, rd, 0, rd)
            else:
                raise AssertionError(kind)
        return self.words


def build_program() -> list[int]:
    p = Program()

    # Boot marker through the hardwired x4 = 0x10000000 MMIO base.
    p.li(5, 0x01)
    p.emit(s_type(0, 5, 4, 2))

    # Register-register arithmetic and logic.
    p.li(5, 5); p.li(6, 7)
    p.emit(r_type(0x00, 6, 5, 0, 7)); p.li(8, 12); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x20, 5, 6, 0, 7)); p.li(8, 2); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x00, 6, 5, 4, 7)); p.li(8, 2); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x00, 6, 5, 6, 7)); p.li(8, 7); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x00, 6, 5, 7, 7)); p.li(8, 5); p.branch(1, 7, 8, "fail")

    # Shifts and signed/unsigned comparisons.
    p.li(5, 1); p.li(6, 5)
    p.emit(r_type(0x00, 6, 5, 1, 7)); p.li(8, 32); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x00, 6, 7, 5, 7)); p.branch(1, 7, 5, "fail")
    p.li(5, -32); p.li(6, 3)
    p.emit(r_type(0x20, 6, 5, 5, 7)); p.li(8, -4); p.branch(1, 7, 8, "fail")
    p.li(5, -1); p.li(6, 1)
    p.emit(r_type(0x00, 6, 5, 2, 7)); p.li(8, 1); p.branch(1, 7, 8, "fail")
    p.emit(r_type(0x00, 6, 5, 3, 7)); p.branch(1, 7, 0, "fail")

    # Immediate ALU forms.
    p.li(5, 0x55)
    p.emit(i_type(0x0F, 5, 4, 6)); p.li(7, 0x5A); p.branch(1, 6, 7, "fail")
    p.emit(i_type(0x20, 5, 6, 6)); p.li(7, 0x75); p.branch(1, 6, 7, "fail")
    p.emit(i_type(0x0F, 5, 7, 6)); p.li(7, 5); p.branch(1, 6, 7, "fail")
    p.li(5, 1)
    p.emit(i_type(4, 5, 1, 6)); p.li(7, 16); p.branch(1, 6, 7, "fail")
    p.emit(i_type(2, 6, 5, 6)); p.li(7, 4); p.branch(1, 6, 7, "fail")
    p.li(5, -16)
    p.emit(i_type((0x20 << 5) | 2, 5, 5, 6)); p.li(7, -4); p.branch(1, 6, 7, "fail")

    # SPI-backed data memory via hardwired x3 = 0x00001000.
    p.li(5, 0x12345678)
    p.emit(s_type(0, 5, 3, 2))
    p.emit(i_type(0, 3, 2, 6, 0x03))
    p.branch(1, 5, 6, "fail")

    # Combinational GPIO input path.
    p.emit(i_type(4, 4, 2, 6, 0x03))
    p.li(7, 0x5A)
    p.branch(1, 6, 7, "fail")

    # All six branch predicates.
    p.li(5, -1); p.li(6, 1)
    for funct3, rs1, rs2, label in (
        (0, 6, 6, "beq_ok"), (1, 5, 6, "bne_ok"),
        (4, 5, 6, "blt_ok"), (5, 6, 5, "bge_ok"),
        (6, 6, 5, "bltu_ok"), (7, 5, 6, "bgeu_ok"),
    ):
        p.branch(funct3, rs1, rs2, label)
        p.jal(0, "fail")
        p.label(label)

    # JAL and JALR link semantics.
    jal_pc = p.pc
    p.jal(5, "jal_target")
    p.jal(0, "fail")
    p.label("jal_target")
    p.li(6, jal_pc + 4)
    p.branch(1, 5, 6, "fail")
    p.li_label(6, "jalr_target")
    jalr_pc = p.pc
    p.emit(i_type(0, 6, 0, 5, 0x67))
    p.jal(0, "fail")
    p.label("jalr_target")
    p.li(6, jalr_pc + 4)
    p.branch(1, 5, 6, "fail")

    p.li(5, 0xA5)
    p.emit(s_type(0, 5, 4, 2))
    p.label("done")
    p.jal(0, "done")

    p.label("fail")
    p.li(5, 0xEE)
    p.emit(s_type(0, 5, 4, 2))
    p.label("fail_loop")
    p.jal(0, "fail_loop")
    return p.resolve()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path, nargs="?", default=Path("test.mem"))
    args = parser.parse_args()
    words = build_program()
    args.output.write_text("".join(f"{word:08x}\n" for word in words), encoding="ascii")
    print(f"wrote {len(words)} RV32E test words to {args.output}")


if __name__ == "__main__":
    main()
