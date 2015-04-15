module spi_master
#(
  parameter                              NUMBER_SLAVES = 1,
  parameter                              CPOL          = 0
)
(
  // Clk & Reset
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
localparam SPI_DATA_IN_ADDR  = 1;
localparam SPI_DATA_OUT_ADDR = 2;

localparam SPI_CLK_DIV = 2;

localparam IDLE           = 0;
localparam START_TRANSFER = 1;
localparam DATA           = 2;
localparam END_TRANSFER   = 3;

/* ========================================================================= */
/* signal declarations                                                       */
/* ========================================================================= */

reg [31:0] slave_select;
reg [31:0] spi_data_out;
reg [31:0] spi_data_in;
reg [$clog2(32)-1:0] spi_data_out_count;
reg [$clog2(32)-1:0] spi_data_in_count;

reg is_spi_transfer_active;
reg spi_transfer_start;
reg spi_clk_active;

reg [$clog2(SPI_CLK_DIV)-1:0] spi_clk_div_count;

reg [$clog2(END_TRANSFER)-1:0] spi_state;

/* ========================================================================= */
/* function declarations                                                     */
/* ========================================================================= */

task launch_data;
  begin
    mosi               <= spi_data_out[spi_data_out_count];
    spi_data_out_count <= spi_data_out_count + 1;
  end
endtask

task latch_data;
  begin
    spi_data_in[spi_data_in_count] <= miso;
    spi_data_in_count              <= spi_data_in_count + 1;
  end
endtask

/* ========================================================================= */
/* Timing constraints for intermediate signals                               */
/* ========================================================================= */

/* ######################################################################### */

/* SPI FSM */
always @(posedge clk or negedge reset_n)
begin
  if (!reset_n) begin
    ss_n               <= 'b1;
    spi_clk_active     <= 1'b0;
    spi_data_out_count <= 'b0;
    spi_data_in_count  <= 'b0;
    spi_state          <= IDLE;
  end
  else begin

    case (spi_state)

      IDLE: begin
        if (spi_transfer_start) begin
          spi_state <= START_TRANSFER;

          ss_n[slave_select] <= 1'b0;
        end
      end

      /*---------------------------------------------------------------------*/

      START_TRANSFER: begin
        spi_state <= DATA;

        spi_clk_active <= 1'b1;
      end

      /*---------------------------------------------------------------------*/

      DATA: begin

        // Launch or latch data
        if (spi_clk_div_count == (SPI_CLK_DIV-1)) begin
          if (sclk) begin // Falling edge
            launch_data();
          end

          else begin // Rising edge
            latch_data();
          end
        end

        if (spi_data_out_count == (32-1)) begin
          spi_state <= END_TRANSFER;

          spi_clk_active <= 1'b0;
        end
      end

      /*---------------------------------------------------------------------*/

      END_TRANSFER: begin
        spi_state <= IDLE;

        ss_n[slave_select] <= 1'b1;
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
      if (spi_clk_div_count < (SPI_CLK_DIV-1)) begin
        spi_clk_div_count <= spi_clk_div_count + 1;
      end
      else begin
        spi_clk_div_count <= 'b0;
        sclk              <= ~sclk;
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
    spi_data_out <= 'b0;
    spi_data_in  <= 'b0;
  end
  else begin
    spi_transfer_start <= 1'b0;

    // Read
    if (avs_read) begin
      case (avs_address)
        SLAVE_SELECT_ADDR : avs_readdata <= slave_select;
        SPI_DATA_OUT_ADDR : avs_readdata <= spi_data_out;
        SPI_DATA_IN_ADDR  : avs_readdata <= spi_data_in;
      endcase
    end

    // Write
    else if (avs_write) begin
      case (avs_address)
        SLAVE_SELECT_ADDR : begin
          spi_transfer_start <= 1'b1;
          slave_select       <= avs_writedata;
        end
        SPI_DATA_OUT_ADDR : spi_data_out <= avs_writedata;
        SPI_DATA_IN_ADDR  : spi_data_in  <= avs_writedata;
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
