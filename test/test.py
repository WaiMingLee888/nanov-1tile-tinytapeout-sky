"""Self-checking integration regression for the one-tile NanoV derivative."""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_rv32e_program(nv):
    clock = Clock(nv.clk, 83334, unit="ps")
    cocotb.start_soon(clock.start())

    nv.ui_in.value = 0x5A
    nv.rstn.value = 0
    await ClockCycles(nv.clk, 10)
    assert int(nv.uio_oe_debug.value) == 0x00
    assert int(nv.uo_out.value) == 0x00

    nv.rstn.value = 1
    await ClockCycles(nv.clk, 2)
    assert int(nv.uio_oe_debug.value) == 0x87

    observed = set()
    for _ in range(4000):
        await ClockCycles(nv.clk, 32)
        value = int(nv.uo_out.value)
        observed.add(value)
        if value == 0xEE:
            raise AssertionError("RV32E self-test reached failure signature 0xEE")
        if value == 0xA5:
            break
    else:
        raise AssertionError(
            f"RV32E self-test timed out; observed GPIO values: {sorted(observed)}"
        )

    assert 0x01 in observed
    assert int(nv.uo_out.value) == 0xA5
