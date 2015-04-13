#!/usr/bin/env python
"""
Test bench for SPI Master
"""

import cocotb

from cocotb.triggers import Timer, RisingEdge , FallingEdge#, ReadOnly
from cocotb.drivers.avalon import AvalonMaster
from cocotb.result import TestFailure

def assert_equal(actual, expected, error_str):
    """
    assert_equal
    """

    if actual != expected:
        raise TestFailure(error_str)

# ########################################################################### #

@cocotb.coroutine
def clock_gen(clk, period):
    """
    Generate clock
    """
    while True:
        clk.value = 0
        yield Timer(period)
        clk.value = 1
        yield Timer(period)

# ########################################################################### #

@cocotb.coroutine
def init_clock_reset(clk, reset_n):
    """
    Initialize clock and reset dut
    """
    cocotb.fork(clock_gen(clk, 10))

    reset_n.value = 0
    yield RisingEdge(clk)
    yield FallingEdge(clk)
    reset_n.value = 1
    yield FallingEdge(clk)

# ########################################################################### #

@cocotb.test()
def test_avalon(dut):
    """
    Test avalon interface
    """

    yield init_clock_reset(dut.clk, dut.reset_n)

    # ----------------------------------------------------------------------- #

    avs = AvalonMaster(dut, "avs", dut.clk)

    yield avs.write(1, 0xDEADBEEF)
    spi_data = yield avs.read(1)

    assert_equal(spi_data, 0xDEADBEEF, "Wrong avalon access")
