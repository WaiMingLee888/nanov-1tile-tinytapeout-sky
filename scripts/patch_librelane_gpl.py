#!/usr/bin/env python3
"""Apply the measured one-tile placement and clock-tree settings."""

from pathlib import Path

import librelane


scripts = Path(librelane.__file__).parent / "scripts/openroad"


def insert_flags(name: str, flags: tuple[str, ...]) -> Path:
    script = scripts / name
    text = script.read_text(encoding="utf-8")
    marker = "set arg_list [list]\n"
    additions = "".join(f"lappend arg_list {flag}\n" for flag in flags)

    if additions not in text:
        if text.count(marker) != 1:
            raise SystemExit(f"unexpected LibreLane script: {script}")
        script.write_text(text.replace(marker, marker + additions), encoding="utf-8")
    return script


gpl = insert_flags("gpl.tcl", ("-disable_pin_density_adjust",))
cts = insert_flags("cts.tcl", ("-dont_use_dummy_load", "-no_insertion_delay"))
print(f"exact-density placement enabled in {gpl}")
print(f"compact clock-tree options enabled in {cts}")
