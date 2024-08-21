`default_nettype none

module wb_interconnect(
    input wire          i_clk,
    input wire          i_resetn,
    // LEDS
    input wire  [5:0]   o_leds,
    // Wishbone
    input  wire	[31:0] 	i_wb_addr,
    input  wire	[31:0] 	i_wb_data,
    input  wire	[3:0]  	i_wb_sel,
    input  wire			i_wb_we,
    input  wire			i_wb_cyc,
    input  wire			i_wb_stb,
    output wire			o_wb_ack,
    output wire	[31:0] 	o_wb_data,
    output wire 		o_wb_stall,
    output wire         o_wb_err,
    output wire [31:0]  o_wb_err_address
);
// `include "wb_slaves.vh"
parameter WB_SLAVE_ADD_SRAM             = 32'h0000_0000;     //   SRAM 00000000 - 0001ffff
parameter WB_SLAVE_ADDR_LED             = 32'h8000_0000;     //   LED  80000000
parameter WB_SLAVE_ADDR_UART            = 32'h8000_0008;     //   UART 80000008 - 8000000f
parameter WB_SLAVE_ADDR_CDT             = 32'h8000_0010;     //   CDT  80000010 - 80000014

// DEBUG
reg [5:0] dbg_leds;
initial dbg_leds = 6'b11_1111;
always @(posedge i_clk) begin
    if(i_wb_stb)
        dbg_leds[0] <= 1'b0;
    if(i_wb_cyc)
        dbg_leds[1] <= 1'b0;
    if(i_wb_we)
        dbg_leds[2] <= 1'b0;
    if(i_wb_addr == WB_SLAVE_ADDR_LED)
        dbg_leds[3] <= 1'b0;
    if(o_wb_ack)
        dbg_leds[4] <= 1'b0;
end
// assign o_leds = dbg_leds;
// DEBUG
// assign o_leds[0] = 1'b0;


// WB LEDs
wire            wb_m2s_sel_leds;
wire  [31:0]    wb_s2m_data_leds;
wire            wb_s2m_ack_leds;
wire            wb_s2m_err_leds;
wire            wb_s2m_stall_leds;
wb_tang_leds wb_soc_leds(
.i_clk(i_clk),
.i_reset_n(i_resetn),
// LEDS
.o_leds(o_leds),
// Wishbone
.i_wb_addr(i_wb_addr),
.i_wb_data(i_wb_data),
.i_wb_stb((i_wb_stb)&&(wb_m2s_sel_leds)),
.i_wb_cyc(i_wb_cyc),
.o_wb_data(wb_s2m_data_leds),
.o_wb_ack(wb_s2m_ack_leds),
.i_wb_sel(i_wb_sel),
.i_wb_we(i_wb_we),
.o_wb_stall(o_wb_stall),
.o_wb_err(wb_s2m_err_leds)
);
// SEL
wire wb_none_sel;
assign wb_m2s_sel_leds  = (i_wb_addr == WB_SLAVE_ADDR_LED);
assign wb_none_sel      = (!wb_m2s_sel_leds);

// ERROR
reg wb_err;
reg bus_err_address;
always @(posedge i_clk)
	wb_err <= (i_wb_stb)&&(wb_none_sel);
always @(posedge i_clk)
	if (o_wb_err)
		bus_err_address <= i_wb_addr;
assign o_wb_err = wb_s2m_err_leds;
assign o_wb_err_address = bus_err_address;

// STALL
// assign	o_wb_stall = ((wb_m2s_sel_leds)&&(wb_s2m_stall_leds));
// assign o_leds[0] = ~o_wb_stall;

// ACK
reg wb_ack;
always @(posedge i_clk)
	wb_ack <= (wb_s2m_ack_leds);
assign o_wb_ack = wb_ack;

// Return data
reg [31:0] wb_data;
always @(posedge i_clk)
	if (wb_s2m_ack_leds)
		wb_data <= wb_s2m_data_leds;
	else
		wb_data <= 32'h0;
assign o_wb_data = wb_data;

endmodule