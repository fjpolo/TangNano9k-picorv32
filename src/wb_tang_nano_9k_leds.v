/* Copyright 2024 Grug Huhler.  License SPDX BSD-2-Clause. */

// tang_leds is a toy peripheral that allows software on the
// core to write to a register that controls the LEDs on the
// Tang Nano 9K board.  It can also read this register,
`default_nettype none

module wb_tang_leds
  (
    input wire            i_clk,
    input wire            i_reset_n,
    output wire [5:0]     o_leds,
    // Wishbone
    input  wire	[31:0] 		i_wb_addr,
    input  wire	[31:0] 		i_wb_data,
    input  wire	[3:0] 		i_wb_sel,
    input  wire				    i_wb_we,
    input  wire				    i_wb_cyc,
    input  wire				    i_wb_stb,
    output wire				    o_wb_ack,
    output wire	[31:0] 	  o_wb_data,
    output wire 			    o_wb_stall,
    output wire 			    o_wb_err
   );
reg [5:0]  leds_internal;
initial leds_internal = 6'b11_1111;

wire valid;
assign valid = (i_wb_stb)&&(i_wb_cyc)&&(!o_wb_stall);

// Write
always @(posedge i_clk)
  if ((valid)&&(i_wb_we))
    leds_internal <= i_wb_data[5:0];

assign o_wb_stall  = 0;
assign o_wb_err = 0;
assign o_wb_ack = i_wb_stb;
assign o_wb_data = {26'b00000000000000000000000000, leds_internal};

assign o_leds = ~leds_internal;


/*********************************/
/* Formal Verification
/*********************************/
`ifdef	FORMAL

	`ifdef	WB_LEDS_STANDALONE
	`define	ASSUME	assume
	`else
	`define	ASSUME	assert
	`endif

	// Global clock
	// (* gclk *) wire f_gbl_clk;
		
	// f_past_valid
	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge i_clk)
		f_past_valid <= 1'b1;

	// BMC and induction
  always @(*) begin
    assert(o_leds     == ~leds_internal);
    assert(o_wb_stall == 0);
    assert(o_wb_data  == wb_data);
    assert(o_wb_ack   == wb_ack);
  end
	
	//
	// Contract
	//
  always @(posedge i_clk)
    if((f_past_valid)&&($past(f_past_valid))&&($past(i_reset_n)))
      if (($past(i_wb_stb))&&($past(i_wb_we))&&($past(i_wb_cyc))&&(!$past(o_wb_stall)))
        assert(leds_internal == $past(i_wb_data[5:0]));
	always @(posedge i_clk) begin
    if((f_past_valid)&&($past(f_past_valid))&&($past(i_reset_n)))
		  if ($past(valid)&&(!$past(i_wb_we))) begin
			  assert(wb_data == {26'b00000000000000000000000000, $past(leds_internal)});
        assert(wb_ack == 1'b1);
      end
  end

	// 
	// Cover
	//
  always @(posedge i_clk)
    if((f_past_valid)&&($past(f_past_valid))&&(~$past(i_reset_n))&&($past(i_wb_stb)))
      cover(o_wb_ack);

`endif // FORMAL

endmodule // leds
