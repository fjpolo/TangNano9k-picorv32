/*
 * Simple 8-bit wide GPIO module
 *
 * First byte is the GPIO I/O reg
 * Second is the direction register
 *
 * Set direction bit to '1' to output corresponding data bit.
 *
 * Register mapping:
 *
 * adr 0: gpio data 7:0
 * adr 1: gpio dir 7:0
 */

module wb_gpio(
	input wire			        i_clk,
	input wire			        i_reset_n,
  	// Wishbone
	input wire			        wb_adr_i,
	input wire		  [7:0] 	wb_dat_i,
	input wire			      	wb_we_i,
	input wire			      	wb_cyc_i,
	input wire			      	wb_stb_i,
	input wire		  [2:0]		wb_cti_i,
	input wire		  [1:0]	 	wb_bte_i,
	output reg	      [7:0]	  	wb_dat_o,
	output wire		            wb_ack_o,
	output wire     	        wb_err_o,
	output wire     	        wb_rty_o,
  	// GPIO
	input wire        [7:0]	  	gpio_i,
	output reg	      [7:0]	  	gpio_o,
	output reg	      [7:0]	  	gpio_dir_o
);

// GPIO dir register
always @(posedge i_clk)
	if (~i_reset_n)
		gpio_dir_o <= 0; // All set to in at reset
	else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
		if (wb_adr_i == 1)
			gpio_dir_o[7:0] <= wb_dat_i;
	end

// GPIO data out register
always @(posedge i_clk)
	if (~i_reset_n)
		gpio_o <= 0;
	else if (wb_cyc_i & wb_stb_i & wb_we_i) begin
		if (wb_adr_i == 0)
			gpio_o[7:0] <= wb_dat_i;
	end

// Register the gpio in signal
always @(posedge i_clk) begin
	// Data registers
	if (wb_adr_i == 0)
		wb_dat_o[7:0] <= gpio_i[7:0];
	// Direction registers
	if (wb_adr_i == 1)
		wb_dat_o[7:0] <= gpio_dir_o[7:0];
     end

// ACK generation
// always @(posedge i_clk)
// 	if (~i_reset_n)
// 		wb_ack_o <= 0;
// 	else if (wb_ack_o)
// 		wb_ack_o <= 0;
// 	else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
// 		wb_ack_o <= 1;

assign wb_ack_o = wb_stb_i;
assign wb_err_o = 0;
assign wb_rty_o = 0;

/*********************************/
/* Formal Verification
/*********************************/
`ifdef	FORMAL

	`ifdef	WB_GPIO_STANDALONE
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

	// Reset
	always @(posedge i_clk)
		if ((f_past_valid)&&(~$past(i_reset_n)))
			assert(gpio_dir_o == 0);
	always @(posedge i_clk)
		if ((f_past_valid)&&(~$past(i_reset_n)))
			assert(gpio_o == 0);

	//
	// Contract
	//
	always @(posedge i_clk)
		if ((f_past_valid)&&($past(i_reset_n)))
			if (($past(wb_cyc_i))&&($past(wb_stb_i))&&($past(wb_we_i))) begin
				// Direction registers
				if($past(wb_adr_i) == 1)
					assert(gpio_dir_o[7:0] == $past(wb_dat_i));
				// Data registers
				else if($past(wb_adr_i) == 0)
					assert(gpio_o[7:0] == $past(wb_dat_i));
			end
	always @(posedge i_clk) begin
		if ((f_past_valid)&&($past(i_reset_n))) begin
			// Data registers
			if ($past(wb_adr_i) == 0)
				assert(wb_dat_o[7:0] == $past(gpio_i[7:0]));
			// Direction registers
			if ($past(wb_adr_i) == 1)
				assert(wb_dat_o[7:0] == $past(gpio_dir_o[7:0]));
		end
	end
		
	// 
	// Cover
	//

`endif // FORMAL VERIFICATION

endmodule