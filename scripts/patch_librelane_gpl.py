#!/usr/bin/env python3
"""Enable exact-density placement in a LibreLane installation."""

from pathlib import Path

import librelane


script = Path(librelane.__file__).parent / "scripts/openroad/gpl.tcl"
text = script.read_text(encoding="utf-8")
marker = "set arg_list [list]\n"
flag = "lappend arg_list -disable_pin_density_adjust\n"

if flag not in text:
    if text.count(marker) != 1:
        raise SystemExit(f"unexpected LibreLane GPL script: {script}")
    script.write_text(text.replace(marker, marker + flag), encoding="utf-8")

print(f"exact-density placement enabled in {script}")
