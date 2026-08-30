#!/usr/bin/env python3
"""Verify non-negotiable one-tile NanoV architecture constraints."""

from __future__ import annotations

import importlib.util
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def require(pattern: str, text: str, description: str) -> None:
    if re.search(pattern, text, flags=re.MULTILINE) is None:
        raise AssertionError(f"missing {description}: /{pattern}/")


def load_test_words() -> list[int]:
    path = ROOT / "test" / "make_test_mem.py"
    spec = importlib.util.spec_from_file_location("make_test_mem", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.build_program()


def check_register_fields(words: list[int]) -> None:
    rd_opcodes = {0x03, 0x13, 0x17, 0x33, 0x37, 0x67, 0x6F}
    rs1_opcodes = {0x03, 0x13, 0x23, 0x33, 0x63, 0x67}
    rs2_opcodes = {0x23, 0x33, 0x63}
    seen_opcodes: set[int] = set()

    for index, word in enumerate(words):
        opcode = word & 0x7F
        seen_opcodes.add(opcode)
        fields = []
        if opcode in rd_opcodes:
            fields.append(("rd", (word >> 7) & 0x1F))
        if opcode in rs1_opcodes:
            fields.append(("rs1", (word >> 15) & 0x1F))
        if opcode in rs2_opcodes:
            fields.append(("rs2", (word >> 20) & 0x1F))
        for name, register in fields:
            if register > 15:
                raise AssertionError(
                    f"word {index} uses {name}=x{register}, outside RV32E x0-x15"
                )
        if opcode == 0x33 and ((word >> 25) & 0x7F) == 0x01:
            raise AssertionError(f"word {index} uses the removed M extension")

    required = {0x03, 0x13, 0x23, 0x33, 0x63, 0x67, 0x6F}
    missing = required - seen_opcodes
    if missing:
        raise AssertionError(f"regression misses required opcode groups: {sorted(missing)}")


def main() -> None:
    info = (ROOT / "info.yaml").read_text(encoding="utf-8")
    config = (ROOT / "src" / "config.json").read_text(encoding="utf-8")
    top = (ROOT / "src" / "tt_top.v").read_text(encoding="utf-8")
    core = (ROOT / "src" / "nanoV" / "core.v").read_text(encoding="utf-8")
    cpu = (ROOT / "src" / "nanoV" / "cpu_external.v").read_text(encoding="utf-8")
    makefile = (ROOT / "test" / "Makefile").read_text(encoding="utf-8")

    require(r'^\s*tiles:\s*"1x1"\s*$', info, "1x1 footprint")
    require(
        r'^\s*top_module:\s*"tt_um_WaiMingLee888_nanov_1tile"\s*$',
        info,
        "one-tile top-module metadata",
    )
    require(r'module\s+tt_um_WaiMingLee888_nanov_1tile\s*\(', top, "one-tile RTL top")
    require(r'nanoV_cpu_external\s+nano\s*\(', top, "external-register CPU")
    require(r'parameter\s+NUM_REGS\s*=\s*16', core, "16-register core default")
    require(r'\.NUM_REGS\s*\(\s*16\s*\)', cpu, "16-register RV32E core instance")
    require(r'rd\s*!=\s*0\s*&&\s*rd\s*!=\s*3\s*&&\s*rd\s*!=\s*4', cpu,
            "writable external RV32E register namespace")
    require(r'wire\s+is_mul\s*=\s*1\'b0\s*;', core, "disabled optional multiplier")
    require(r'"PL_TARGET_DENSITY_PCT"\s*:\s*95', config, "measured 95% placement target")
    require(r'"PL_ROUTABILITY_DRIVEN"\s*:\s*false', config,
            "disabled routability-driven placement")
    workflow = (ROOT / ".github" / "workflows" / "gds.yaml").read_text(
        encoding="utf-8"
    )
    require(r'lappend arg_list -disable_pin_density_adjust', workflow,
            "exact-density OpenROAD placement flag")
    require(r'"RUN_LINTER"\s*:\s*1', config, "enabled RTL linter")
    require(r'"RUN_CTS"\s*:\s*1', config, "enabled clock-tree synthesis")

    source_manifest = info + "\n" + makefile
    for forbidden in ("multiply.v", "uart_tx.v", "uart_rx.v"):
        if forbidden in source_manifest:
            raise AssertionError(f"removed block remains in design source list: {forbidden}")

    words = load_test_words()
    check_register_fields(words)
    print(
        "one-tile contract passed: footprint=1x1, NUM_REGS=16, "
        f"base regression words={len(words)}, optional multiplier/UART excluded"
    )


if __name__ == "__main__":
    main()
