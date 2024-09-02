/*****************************************************************
/* Copyright 2024 Grug Huhler.  License SPDX BSD-2-Clause.
/* Copyright 2024 @fjpolo.  License SPDX BSD-2-Clause.
/* 
/* Timer that can be written and read and always counts
/* down, stopping at zero.  The implementation is intentionally
/* overcomplicated.  It meets unnecessary goals:
/****************************************************************/
`default_nettype none

module wb_countdown_timer
(
input wire              i_clk,
input wire              i_reset_n,
// DEBUG LEDS
output wire [5:0]       o_leds,
// Wishbone
input  wire	[31:0] 		i_wb_addr,
input  wire	[31:0] 		i_wb_data,
input  wire	[3:0] 		i_wb_sel,
input  wire		        i_wb_we,
input  wire		        i_wb_cyc,
input  wire		        i_wb_stb,
output wire		        o_wb_ack,
output wire	[31:0] 	    o_wb_data,
output wire 		    o_wb_stall,
output wire 		    o_wb_err
);
reg [31:0]  r_count;
initial r_count = 32'h0;

wire valid;
assign valid = (i_wb_stb)&&(i_wb_cyc)&&(!o_wb_stall);

// Write
always @(posedge i_clk) begin
    if(r_count != 0)
        r_count <= r_count - 1'b1;
    if ((valid)&&(i_wb_we))
        r_count <= i_wb_data;
end

assign o_wb_stall  = 0;
assign o_wb_err = 0;
assign o_wb_ack = i_wb_stb;
assign o_wb_data = r_count;

endmodule