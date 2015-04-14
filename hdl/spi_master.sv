module spi_master
#(
  parameter                              NUMBER_SLAVES = 1,
  parameter                              CPOL          = 0
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

localparam SLAVE_SELECT_ADDR = 0;
localparam SPI_DATA_ADDR     = 1;

localparam SPI_CLK_DIV = 2;

localparam IDLE           = 0;
localparam SLAVE_SELECT_1 = 1;
localparam DATA           = 2;
localparam SLAVE_SELECT_2 = 3;

/* ========================================================================= */
/* signal declarations                                                       */
/* ========================================================================= */

reg [31:0] slave_select;
reg [31:0] spi_data;
reg is_spi_transfer_active;
reg spi_transfer_start;
reg spi_clk_active;
reg spi_clk_div_count;

reg [$clog2(SLAVE_SELECT_2)-1:0] spi_state;

/* ========================================================================= */
/* function declarations                                                     */
/* ========================================================================= */

/* ========================================================================= */
/* Timing constraints for intermediate signals                               */
/* ========================================================================= */

/* ######################################################################### */

/* SPI FSM */
always @(posedge clk or negedge reset_n)
begin
  if (!reset_n) begin
    ss_n      <= 'b1;
    spi_state <= IDLE;
  end
  else begin

    case (spi_state)

      IDLE: begin
        if (spi_transfer_start) begin
          ss_n[slave_select] <= 1'b0;

          spi_state <= SLAVE_SELECT_1;
        end
      end

      /*---------------------------------------------------------------------*/

      SLAVE_SELECT_1: begin
        spi_clk_active <= 1'b1;

        spi_state <= DATA;
      end

      /*---------------------------------------------------------------------*/

      DATA: begin
      end

      /*---------------------------------------------------------------------*/

      default: begin
      end
    endcase
  end
end

/*===========================================================================*/

/* SPI serial clock */
always @(posedge clk or negedge reset_n)
begin
  if (!reset_n) begin
    sclk              <= CPOL;
    spi_clk_div_count <= 'b0;
  end
  else begin
    if (spi_clk_active) begin
      if (spi_clk_div_count == (SPI_CLK_DIV-1)) begin
        spi_clk_div_count <= 'b0;
        sclk              <= ~sclk;
      end
      else begin
        spi_clk_div_count <= spi_clk_div_count + 1;
      end
    end
  end
end

/*===========================================================================*/

/* Avalon interface process */
always @(posedge clk or negedge reset_n)
begin
  if (!reset_n) begin
    slave_select <= 'b0;
    spi_data     <= 'b0;
  end
  else begin
    spi_transfer_start <= 1'b0;

    // Read
    if (avs_read) begin
      case (avs_address)
        SLAVE_SELECT_ADDR : avs_readdata <= slave_select;
        SPI_DATA_ADDR     : avs_readdata <= spi_data;
      endcase
    end

    // Write
    else if (avs_write) begin
      case (avs_address)
        SLAVE_SELECT_ADDR : begin
          spi_transfer_start <= 1'b1;
          slave_select       <= avs_writedata;
        end
        SPI_DATA_ADDR     : spi_data     <= avs_writedata;
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
