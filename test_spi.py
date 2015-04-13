#!/usr/bin/env python
"""
test_spi
"""

import cocotb

from cocotb.triggers import Timer, RisingEdge , FallingEdge#, ReadOnly
#from cocotb.drivers.avalon import AvalonMaster
from cocotb.result import TestFailure

#class EndianSwapperTB(object):

#    def __init__(self, dut, debug=False):

#        self.csr = AvalonMaster(dut, "csr", dut.clk)

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

@cocotb.test()
def run_test(dut):
    """
    run test
    """

    cocotb.fork(clock_gen(dut.clk, 10))

    dut.reset_n = 0
    yield RisingEdge(dut.clk)
    yield FallingEdge(dut.clk)
    dut.reset_n = 1
    yield FallingEdge(dut.clk)

    raise TestFailure("Patata")
