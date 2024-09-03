/* Copyright 2024 Grug Huhler.  License SPDX BSD-2-Clause. */
/* 
Top level module of simple SoC based on picorv32

It includes:
     * the picorv32 core
     * An 8192 byte SRAM which is initialzed within the Verilog.
     * A module to read/write LEDs on the Gowin Tang Nano 9K
     * A wrapped version of the UART from picorv32's picosoc.
     * A 32-bit count down timer.
  
Built and tested with the Gowin Eductional tool set on Tang Nano 9K.

The picorv32 core has a very simple memory interface.
See https://github.com/YosysHQ/picorv32

In this SoC, slave (target) device has signals:

   * SLAVE_sel - this is asserted when mem_valid == 1 and mem_addr targets the slave.
     It "tells" the slave that it is active.  It must accept a write for provide data
     for a read.
   * SLAVE_ready - this is asserted by the slave when it is done with the transaction.
     Core signal mem_ready is the OR of all of the SLAVE_ready signals.
   * Core mem_addr, mem_wdata, and mem_wstrb can be passed to all slaves directly.
     The latter is a byte lane enable for writes.
   * Each slave drives SLAVE_data_o.  The core's mem_rdata is formed by selecting the
     correct SLAVE_data_o based on SLAVE_sel.
*/

// Define this for logic analyer connections and enable picorv32_la.cst.
//`define USE_LA

module top (
            input wire        clk,
            input wire        reset_button_n,
            input wire        uart_rx,
            output wire       uart_tx,
`ifdef USE_LA
            output wire       clk_out,
            output wire       mem_instr, 
            output wire       mem_valid,
            output wire       mem_ready,
            output wire       b25,
            output wire       b24,
            output wire       b17,
            output wire       b16,
            output wire       b09,
            output wire       b08,
            output wire       b01,
            output wire       b00,
            output wire [3:0] mem_wstrb,
`endif
            // LEDs
            output wire [5:0] leds,
            // GPIO0
            inout wire  [7:0] gpio0
            );
// // DEBUG
// assign leds = ~wb_m2s_data[5:0];


// 
// Wishbone Bus
// 
wire  [31:0]  wb_m2s_addr;
wire  [31:0]  wb_m2s_data;
wire  [3:0]   wb_m2s_sel;
wire          wb_m2s_we;
wire          wb_m2s_cyc;
wire          wb_m2s_stb;
wire  [31:0]  wb_s2m_data;
wire          wb_s2m_ack;
wire          wb_s2m_stall;
wire          wb_s2m_err;
wire  [31:0]  wb_s2m_err_addr;

// Wishbone interconnect
wb_interconnect wb_inter(
  .i_clk(clk),
  .i_resetn(reset_n),
  // LEDS
  .o_leds(leds),
  // GPIO0
  .io_gpio0(),
  // Wishbone
  .i_wb_addr(wb_m2s_addr),
  .i_wb_data(wb_m2s_data),
  .i_wb_sel(wb_s2m_stb),
  .i_wb_we(wb_m2s_we),
  .i_wb_cyc(wb_m2s_cyc),
  .i_wb_stb(wb_m2s_stb),
  .o_wb_ack(wb_s2m_ack),
  .o_wb_data(wb_s2m_data),
  .o_wb_stall(wb_s2m_stall),
  .o_wb_err(wb_s2m_err),
  .o_wb_err_address(wb_s2m_err_addr)
);

wb_picorv32 uut(
          .clk(clk),
          .i_resetn(reset_button_n),
          .uart_rx(uart_rx),
          .uart_tx(uart_tx),
          // LEDs
          .o_leds(leds),
`ifdef USE_LA
          .clk_out(clk_out),
          .mem_instr,(mem_instr) 
          .mem_valid(mem_valid),
          .mem_ready(mem_ready),
          .b25(b25),
          .b24(b24),
          .b17(b17),
          .b16(b16),
          .b09(b09),
          .b08(b08),
          .b01(b01),
          .b00(b00),
          .mem_wstrb(mem_wstrb),
`endif
          // Wishbone
          .o_wb_m2s_addr(wb_m2s_addr),
          .o_wb_m2s_data(wb_m2s_data),
          .i_wb_s2m_data(wb_s2m_data),
          .o_wb_m2s_we(wb_m2s_we),
          .o_wb_m2s_sel(wb_m2s_sel),
          .o_wb_m2s_stb(wb_m2s_stb),
          .i_wb_s2m_ack(wb_s2m_ack),
          .o_wb_m2s_cyc(wb_m2s_cyc),
          .i_wb_s2m_stall(wb_s2m_stall),
          .i_wb_s2m_err(wb_s2m_err),
          .i_wb_s2m_err_addr(wb_s2m_err_addr)
          );           

endmodule // top
