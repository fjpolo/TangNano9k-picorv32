module wb_picorv32 (
          input wire        clk,
          input wire        i_resetn,
          input wire        uart_rx,
          output wire       uart_tx,
          // LEDS
          output wire [5:0] o_leds,
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
          // Wishbone
          output reg [31:0]   o_wb_m2s_addr,
          output reg [31:0]   o_wb_m2s_data,
          input  wire [31:0]  i_wb_s2m_data,
          output reg          o_wb_m2s_we,
          output reg [3:0]    o_wb_m2s_sel,
          output reg          o_wb_m2s_stb,
          input  wire         i_wb_s2m_ack,
          output reg          o_wb_m2s_cyc,
          input  wire         i_wb_s2m_stall,
          input  wire         i_wb_s2m_err,
          input  wire [31:0]  i_wb_s2m_err_addr
          );

   parameter [0:0] BARREL_SHIFTER = 0;
   parameter [0:0] ENABLE_MUL = 0;
   parameter [0:0] ENABLE_DIV = 0;
   parameter [0:0] ENABLE_FAST_MUL = 0;
   parameter [0:0] ENABLE_COMPRESSED = 0;
   parameter [0:0] ENABLE_IRQ_QREGS = 0;

   parameter integer          MEMBYTES = 8192;      // This is not easy to change
   parameter [31:0] STACKADDR = (MEMBYTES);         // Grows down.  Software should set it.
   parameter [31:0] PROGADDR_RESET = 32'h0000_0000;
   parameter [31:0] PROGADDR_IRQ = 32'h0000_0000;

   wire                       reset_n; 
   wire [31:0]                mem_addr;
   wire [31:0]                mem_wdata;
   wire [31:0]                mem_rdata;
   wire [3:0]                 mem_wstrb;
   wire                       mem_ready;
   wire                       mem_inst;
   wire                       leds_sel;
   wire                       leds_ready;
   wire [31:0]                leds_data_o;
   wire                       sram_sel;
   wire                       sram_ready;
   wire [31:0]                sram_data_o;
   wire                       cdt_sel;
   wire                       cdt_ready;
   wire [31:0]                cdt_data_o;
   wire                       uart_sel;
   wire [31:0]                uart_data_o;
   wire                       uart_ready;
   wire                       mem_valid;

`ifdef USE_LA
   // Assigns for external logic analyzer connction
   assign clk_out = clk;
   assign b25 = mem_rdata[25];
   assign b24 = mem_rdata[24];
   assign b17 = mem_rdata[17];
   assign b16 = mem_rdata[16];
   assign b09 = mem_rdata[9];
   assign b08 = mem_rdata[8];
   assign b01 = mem_rdata[1];
   assign b00 = mem_rdata[0];
`endif

   // Establish memory map for all slaves:
   //   SRAM 00000000 - 0001ffff
   //   LED  80000000
   //   UART 80000008 - 8000000f
   //   CDT  80000010 - 80000014
   assign sram_sel = mem_valid && (mem_addr < 32'h00002000);
   assign leds_sel = mem_valid && (mem_addr == 32'h80000000);
   assign uart_sel = mem_valid && ((mem_addr & 32'hfffffff8) == 32'h80000008);
   assign cdt_sel =  mem_valid && (mem_addr == 32'h80000010);

   // Core can proceed regardless of *which* slave was targetted and is now ready.
   assign leds_ready = (leds_sel)&&(!i_wb_s2m_stall)&&(i_wb_s2m_ack);
   assign cdt_ready = (cdt_sel)&&(!i_wb_s2m_stall)&&(i_wb_s2m_ack);
   assign mem_ready = mem_valid & (sram_ready | leds_ready | uart_ready | cdt_ready);


   // Select which slave's output data is to be fed to core.
   assign mem_rdata = sram_sel ? sram_data_o    :
                      uart_sel ? uart_data_o    :
                      leds_sel ? wb_mem_rdata   :
                      cdt_sel  ? wb_mem_rdata   : 
                      32'h0;

  reg [5:0] leds;
  always @(posedge clk)
    leds <= ~leds_data_o[5:0]; // Connect to the LEDs off the FPGA

   reset_control reset_controller
     (
      .clk(clk),
      .reset_button_n(i_resetn),
      .reset_n(reset_n)
      );

   uart_wrap uart
     (
      .clk(clk),
      .reset_n(reset_n),
      .uart_tx(uart_tx),
      .uart_rx(uart_rx),
      .uart_sel(uart_sel),
      .addr(mem_addr[3:0]),
      .uart_wstrb(mem_wstrb),
      .uart_di(mem_wdata),
      .uart_do(uart_data_o),
      .uart_ready(uart_ready)
      );

   sram #(.ADDRWIDTH(13)) memory
     (
      .clk(clk),
      .resetn(reset_n),
      .sram_sel(sram_sel),
      .wstrb(mem_wstrb),
      .addr(mem_addr[12:0]),
      .sram_data_i(mem_wdata),
      .sram_ready(sram_ready),
      .sram_data_o(sram_data_o)
      );

   picorv32
     #(
       .STACKADDR(STACKADDR),
       .PROGADDR_RESET(PROGADDR_RESET),
       .PROGADDR_IRQ(PROGADDR_IRQ),
       .BARREL_SHIFTER(BARREL_SHIFTER),
       .COMPRESSED_ISA(ENABLE_COMPRESSED),
       .ENABLE_MUL(ENABLE_MUL),
       .ENABLE_DIV(ENABLE_DIV),
       .ENABLE_FAST_MUL(ENABLE_FAST_MUL),
       .ENABLE_IRQ(1),
       .ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
       ) cpu
       (
        .clk         (clk),
        .resetn      (reset_n),
        .mem_valid   (mem_valid),
        .mem_instr   (mem_inst),
        .mem_ready   (mem_ready),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_wstrb   (mem_wstrb),
        .mem_rdata   (mem_rdata),
        .irq         ('b0)
        );

// Wishbone Master
reg [31:0] wb_mem_rdata;
wire wb_we;
assign wb_we = (mem_wstrb[0] | mem_wstrb[1] | mem_wstrb[2] | mem_wstrb[3]);

wire wb_slave_sel;
assign wb_slave_sel = (leds_sel)||(cdt_sel);

initial	o_wb_m2s_cyc = 1'b0;
initial	o_wb_m2s_stb = 1'b0;
// BUS
always @(posedge clk) begin
   if(~i_resetn) begin
      o_wb_m2s_cyc <= 1'b0;
      o_wb_m2s_stb <= 1'b0;
   end else begin          
      if((wb_slave_sel)&&(!i_wb_s2m_stall)&&(!i_wb_s2m_ack)&&(!o_wb_m2s_cyc)) begin
         o_wb_m2s_cyc <= 1'b1;
         o_wb_m2s_stb <= 1'b1;
      end else if((!i_wb_s2m_stall)&&(!o_wb_m2s_stb)&&(o_wb_m2s_cyc)&&(i_wb_s2m_ack)) begin
         o_wb_m2s_cyc <= 1'b0;
      end
   end
end
// WE
always @(posedge clk)
   if (wb_slave_sel)
      o_wb_m2s_we <= (wb_we);
// ADDRESS 
always @(posedge clk)
   if (wb_slave_sel)
      o_wb_m2s_addr <= mem_addr;
// DATA WRITE
always @(posedge clk) begin
   if(~i_resetn)
      o_wb_m2s_data <= 32'h0;
   else
      if((wb_slave_sel)&&(wb_we))
         o_wb_m2s_data <= mem_wdata;
end
// DATA READ
always @(posedge clk) begin
   if(~i_resetn)
      wb_mem_rdata <= 32'h0;
   else
      // if((!wb_we)&&(o_wb_m2s_cyc)&&(!o_wb_m2s_stb)&&(i_wb_s2m_ack)&&(!i_wb_s2m_stall))
      // if((!o_wb_m2s_we)&&(o_wb_m2s_cyc)&&(!o_wb_m2s_stb)&&(i_wb_s2m_ack)&&(!i_wb_s2m_stall))
      if((o_wb_m2s_cyc)&&(i_wb_s2m_ack))
         wb_mem_rdata <= i_wb_s2m_data;
end

// DEBUG - BEGIN
reg [5:0] dbg_leds;
initial dbg_leds = 6'b00_0000;

// // write to slave
// always @(posedge clk) begin
//   if(o_wb_m2s_stb)
//     dbg_leds[0] <= 1'b1;
//   if(o_wb_m2s_cyc)
//     dbg_leds[1] <= 1'b1;
//   if(i_wb_s2m_stall)
//     dbg_leds[2] <= 1'b1;
//   if(o_wb_m2s_we)
//     dbg_leds[3] <= 1'b1;
//   if((o_wb_m2s_stb)&&(o_wb_m2s_cyc)&&(!i_wb_s2m_stall))
//     dbg_leds[4] <= 1'b1;
//   if(((o_wb_m2s_stb)&&(o_wb_m2s_cyc)&&(!i_wb_s2m_stall))&&(o_wb_m2s_we))
//     dbg_leds[5] <= 1'b1;
// end
// assign o_leds = ~dbg_leds;

// // read from slave
// always @(posedge clk) begin
//   if(o_wb_m2s_stb)
//     dbg_leds[0] <= 1'b1;
//   if(o_wb_m2s_cyc)
//     dbg_leds[1] <= 1'b1;
//   if(i_wb_s2m_stall)
//     dbg_leds[2] <= 1'b1;
//   if(!o_wb_m2s_we)
//     dbg_leds[3] <= 1'b1;
//   if((o_wb_m2s_stb)&&(o_wb_m2s_cyc)&&(!i_wb_s2m_stall))
//     dbg_leds[4] <= 1'b1;
//   if(((o_wb_m2s_stb)&&(o_wb_m2s_cyc)&&(!i_wb_s2m_stall))&&(!o_wb_m2s_we))
//     dbg_leds[5] <= 1'b1;
// end
// assign o_leds = ~dbg_leds;

// // Diverse tests
// assign o_leds = ~mem_wdata[5:0]; 
// assign o_leds = ~o_wb_m2s_data[5:0]; 
// assign o_leds = ~i_wb_s2m_data[5:0]; 
// assign o_leds = ~wb_mem_rdata[5:0]; 
// DEBUG - END

endmodule // top
