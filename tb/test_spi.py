#!/usr/bin/env python
"""
Test bench for SPI Master
"""

from spi_monitor import SpiMonitor

import cocotb

from cocotb.triggers import Timer, RisingEdge , FallingEdge#, ReadOnly
from cocotb.drivers.avalon import AvalonMaster
from cocotb.result import TestFailure

SLAVE_SELECT_ADDR = 0
SPI_DATA_IN_ADDR = 1
SPI_DATA_OUT_ADDR = 2

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

    yield avs.write(SPI_DATA_IN_ADDR, 0xDEADBEEF)
    spi_data = yield avs.read(1)

    assert_equal(spi_data, 0xDEADBEEF, "Wrong avalon access")

# ########################################################################### #

@cocotb.test()
def test_spi(dut):
    """
    Test spi
    """

    yield init_clock_reset(dut.clk, dut.reset_n)

    # ----------------------------------------------------------------------- #

    avs = AvalonMaster(dut, "avs", dut.clk)
    spi_monitor = SpiMonitor(dut)

    yield avs.write(SPI_DATA_OUT_ADDR, 0xDEADBEEF)
    yield avs.write(SLAVE_SELECT_ADDR, 0)

    spi_data_out = yield spi_monitor.wait_for_recv()

    assert_equal(spi_data_out, 0xDEADBEEF, "Wrong spi_data: %X"
                 % spi_data_out)
