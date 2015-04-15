"""
SPI monitor
"""

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge

from cocotb.monitors import Monitor

class SpiMonitor(Monitor):
    """
    Spi Monitor class
    """

    def __init__(self, dut, **kwargs):
        self.dut = dut
        Monitor.__init__(self, **kwargs)

    @cocotb.coroutine
    def _monitor_recv(self):
        """
        Creates an Image object from the output of the DUT
        """

        spi_data_out = 0

        yield FallingEdge(self.dut.ss_n)

        yield FallingEdge(self.dut.sclk)

        for i in range(32):
            yield RisingEdge(self.dut.sclk)
            spi_data_out += (self.dut.mosi.value << i)


        self._recv(spi_data_out)
