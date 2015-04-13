#!/usr/bin/env python
"""
Test bench for SPI Master
"""

import random
import cocotb

from cocotb.triggers import Timer, RisingEdge , FallingEdge#, ReadOnly
from cocotb.drivers.avalon import AvalonMaster
from cocotb.result import TestFailure


@cocotb.coroutine
def clock_gen(clk, period):
    """
    Generate clock
    """
    while True:
        clk <= 0
        yield Timer(period)
        clk <= 1
        yield Timer(period)

# ########################################################################### #

@cocotb.coroutine
def init_clock_reset(clk, reset_n):
    """
    Initialize clock and reset dut
    """
    cocotb.fork(clock_gen(clk, 10))

    reset_n = 0
    yield RisingEdge(clk)
    yield FallingEdge(clk)
    reset_n = 1
    yield FallingEdge(clk)

# ########################################################################### #

@cocotb.test()
def run_test(dut):
    """
    run test
    """

    yield init_clock_reset(dut.clk, dut.reset_n)

    # ----------------------------------------------------------------------- #

    avs = AvalonMaster(dut, "avs", dut.clk)

    yield avs.write(1, 0xDEADBEEF)
    spi_data = yield avs.read(1)

    if spi_data != 0xDEADBEEF:
        raise TestFailure("Wrong avalon access")
