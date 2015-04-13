module spi_master
#(
  parameter                              NUMBER_SLAVES = 1
)
(
  input                                  clk,
  input                                  reset_n,

  // SPI Interface
  output reg                             sclk,
  output reg                             mosi,
  input                                  miso,
  output reg [NUMBER_SLAVES-1:0]         ss_n,

  // Avalon Slave interface
  input      [ 1:0]                      avs_address,
  input                                  avs_read,
  output reg [31:0]                      avs_readdata,
  input                                  avs_write,
  input      [31:0]                      avs_writedata
);

/* ========================================================================= */
/* type definitions                                                          */
/* ========================================================================= */

/* ========================================================================= */
/* constants                                                                 */
/* ========================================================================= */

/* ========================================================================= */
/* signal declarations                                                       */
/* ========================================================================= */

reg [31:0] slave_select;
reg [31:0] spi_data;

/* ========================================================================= */
/* function declarations                                                     */
/* ========================================================================= */

/* ========================================================================= */
/* Timing constraints for intermediate signals                               */
/* ========================================================================= */

/* ######################################################################### */

//always @(*)
//    stream_out_valid = (stream_in_valid & ~stream_out_endofpacket) | flush_pipe;

/*===========================================================================*/

/* Avalon interface process */
always @(posedge clk or negedge reset_n)
begin
  if (!reset_n) begin
    slave_select <= 'b0;
    spi_data     <= 'b0;
    avs_readdata <= 'b0;
  end
  else begin
    // Read
    if (avs_read) begin
      case (avs_address)
        0:    avs_readdata <= slave_select;
        1:    avs_readdata <= spi_data;
      endcase
    end
    // Write
    else if (avs_write) begin
      case (avs_address)
        0:    slave_select <= avs_writedata;
        1:    spi_data     <= avs_writedata;
      endcase
    end
  end
end

/*===========================================================================*/

`ifdef COCOTB_SIM
  initial begin
    $dumpfile ("waveform.vcd");
    $dumpvars (0, spi_master);
    #1;
  end
`endif

endmodule
