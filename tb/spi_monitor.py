"""
SPI monitor
"""

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge

from cocotb.monitors import Monitor

class SpiMonitor(Monitor):
    def __init__(self, dut, **kwargs):
        self.dut = dut
        Monitor.__init__(self, **kwargs)

    @cocotb.coroutine
    def _monitor_recv(self):
        """
        Creates an Image object from the output of the DUT
        """

        yield FallingEdge(self.dut.ss_n)

        for _ in range(8):
            yield RisingEdge(self.dut.sclk)

        self._recv("done")
