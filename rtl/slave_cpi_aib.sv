// DISTRIBUTION STATEMENT A. Approved for public release.
//
// The views, opinions and/or findings expressed are those of the author and
// should not be interpreted as representing the official views or policies of
// the Department of Defense or the U.S. Government.
//
// Copyright 2019 © Lockheed Martin Corporation
//----------------------------------------------------------------------------------------
//
// New Wave Design and Verification
// Copyright (C) 2018 New Wave Design and Verification, LLC 
// 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an 
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// 
// See the License for the specific language governing permissions and limitations under the License.
//
//                                                              
// File name   : slave_cpi_aib
// Author      : New Wave Design and Verification
//
// Description :
// This block combines the CPI slave bridge with the AIB slave-configured PHY
//
//
// Revision History: 
// Date        Description
// 2018 Oct 11 Initial release.
//
//----------------------------------------------------------------------------------------

module slave_cpi_aib              #(parameter DWIDTH = 80,          // AIB interface width must be 40
                                    parameter DISABLE_SDR = 0,      // Don't operate in 40 bit mode when DWIDTH = 80 & ddr_en = 0
                                    parameter ADDR_DID_WIDTH = 2,   // Width of address field used for DID. Max is 8.
                                    parameter CFG_ADDR_WIDTH = 8,   // Width of address field used for config space. Min is 0. Max is 31
                                    parameter CFG_ADDR = 255,       // Value that indicates config space address region
                                    parameter AR_AWIDTH = 34,       // Read addr width,min is 8,max is 34 + ADDR_DID_WIDTH
                                    parameter AR_IDWIDTH = 8,       // Read addr ID width maximum is 8
                                    parameter AR_USRWIDTH = 8,      // Read addr user width maximum is 8
                                    parameter AW_AWIDTH = 34,       // Write addr width,min is 8,max is 34 + ADDR_DID_WIDTH
                                    parameter AW_IDWIDTH = 8,       // Write addr ID width maximum is 8
                                    parameter AW_USRWIDTH = 8,      // Write addr user width maximum is 8
                                    parameter W_DWIDTH = 128,       // Write data width must be 32, 64 or 128
                                    parameter W_USRWIDTH = 8,       // Write data user width maximum is 8
                                    parameter R_IDWIDTH = 8,        // Read data ID width maximum is 8
                                    parameter R_DWIDTH = 128,       // Read data width must be 32, 64 or 128
                                    parameter R_USRWIDTH = 5,       // Read data user width maximum is 5
                                    parameter B_IDWIDTH = 8,        // Write response ID width maximum is 8
                                    parameter B_USRWIDTH = 5,       // Write response user width maximum is 5
                                    parameter NUM_AXI_BURSTS = 2,   // Num AXI bursts in transmit FIFO. Max is 16
                                    parameter NUM_CPI_FLITS = 128,  // Num CPI flits in receive FIFO. Min is 128. Max is 256.
                                    parameter MAX_XFR_SIZE = 256,   // Maximum AXI data transfer is 256 bytes.
                                    parameter SIZEFIT = 0,          // Write data size is always equal to W_DWIDTH
                                    parameter CR_RTN_THRESH = 32,   // Credit return threshold
                                    parameter AXI_BURST_WAIT = 1,   // Start after all AXI burst transfers received
                                    parameter CPI_BURST_WAIT = 0,   // Start after all CPI flits received
                                    parameter NDAT = 32'd80,        // Number of Sync Data uBumps in chan
                                    parameter NBMP = NDAT + 32'd10, // Total number of bumps                                    
                                    parameter HNBMP = NBMP/32'd2,   // Half the # of uBumps in chan
                                    parameter FBMP  = NBMP - 32'd2, // # of functional/logical uBumps (wo spares)
                                    parameter DLYW = 32'd10         // Manual mode DLL adjust bit width
                                    )  // Number of uBumps in chan
(

   // Clocks and resets
   input clk,                                  // CPI bridge clock

   input rx_rd_rstb,                           // CPI rx rd reset
   input tx_wr_rstb,                           // CPI tx wr reset
   // AXI Slave Interface Rx Path
   output [AR_AWIDTH-1:0]     axi_s_araddr,    // AXI Slave Read Address channel address
   output [AR_IDWIDTH-1:0]    axi_s_arid,      // AXI Slave Read Address channel ID
   output [7:0]               axi_s_arlen,     // AXI Slave Read Address channel burst length
   output [2:0]               axi_s_arsize,    // AXI Slave Read Address channel burst size
   output [1:0]               axi_s_arburst,   // AXI Slave Read Address channel burst type
   output [AR_USRWIDTH-1:0]   axi_s_aruser,    // AXI Slave Read Address channel user
   output                     axi_s_arlock,    // AXI Slave Read Address channel lock
   output [3:0]               axi_s_arqos,     // AXI Slave Read Address channel QoS
   output [3:0]               axi_s_arregion,  // AXI Slave Read Address channel region
   output [2:0]               axi_s_arprot,    // AXI Slave Read Address channel prot
   output                     axi_s_arvalid,   // AXI Slave Read Address channel valid
   input                      axi_s_arready,   // AXI Slave Read Address channel ready


   output [AW_AWIDTH-1:0]     axi_s_awaddr,    // AXI Slave Write Address channel address
   output [AW_IDWIDTH-1:0]    axi_s_awid,      // AXI Slave Write Address channel ID
   output [7:0]               axi_s_awlen,     // AXI Slave Write Address channel burst length
   output [2:0]               axi_s_awsize,    // AXI Slave Write Address channel burst size
   output [1:0]               axi_s_awburst,   // AXI Slave Write Address channel burst type
   output [AW_USRWIDTH-1:0]   axi_s_awuser,    // AXI Slave Write Address channel user
   output                     axi_s_awlock,    // AXI Slave Write Address channel lock
   output [3:0]               axi_s_awqos,     // AXI Slave Write Address channel QoS
   output [3:0]               axi_s_awregion,  // AXI Slave Write Address channel region
   output [2:0]               axi_s_awprot,    // AXI Slave Write Address channel prot
   output                     axi_s_awvalid,   // AXI Slave Write Address channel valid
   input                      axi_s_awready,   // AXI Slave Write Address channel ready

   output [W_DWIDTH-1:0]      axi_s_wdata,     // AXI Slave Write Data channel data
   output [(W_DWIDTH/8)-1:0]  axi_s_wstrb,     // AXI Slave Write Data channel strobe
   output                     axi_s_wlast,     // AXI Slave Write Data channel last
   output [W_USRWIDTH-1:0]    axi_s_wuser,     // AXI Slave Write Data channel user
   output                     axi_s_wvalid,    // AXI Slave Write Data channel valid
   input                      axi_s_wready,    // AXI Slave Write Data channel ready

   // AXI Slave Interface Tx Path
   input [R_IDWIDTH-1:0]     axi_s_rid,        // AXI Slave Read Response channel ID
   input [R_DWIDTH-1:0]      axi_s_rdata,      // AXI Slave Read Response channel data
   input                     axi_s_rlast,      // AXI Slave Read Response channel last
   input [1:0]               axi_s_rresp,      // AXI Slave Read Response channel response
   input [R_USRWIDTH-1:0]    axi_s_ruser,      // AXI Slave Read Response channel user
   input                     axi_s_rvalid,     // AXI Slave Read Response channel valid
   output                    axi_s_rready,     // AXI Slave Read Response channel ready



   input [B_IDWIDTH-1:0]     axi_s_bid,        // AXI Slave Write Response channel ID
   input [1:0]               axi_s_bresp,      // AXI Slave Write Response channel response
   input [B_USRWIDTH-1:0]    axi_s_buser,      // AXI Slave Write Response channel user
   input                     axi_s_bvalid,     // AXI Slave Write Response channel valid
   output                    axi_s_bready,     // AXI Slave Write Response channel ready

   
   input [63:0]              cr_init_delay,      // Number of clock cycles to delay credit init

   // AIB Slave Interfaces
   inout [NBMP-1:0]          ubump,            // IO chan uBumps
   inout [1:0]               ubump_aux,        // AUX chan uBumps
   
   input                     tx_clk,
   output                    rx_clk,           // Output: generated from sys_clk_m through bumps
      
   // AIB CONF_DONE
   input                     conf_done,
   output                    config_done,
  
   input                     device_detect_ovrd,
   
   input                     por_ovrd,
                                
   // APB Slave Interface
   //
   input                     pclk,             // Clock.
   input                     presetn,          // Reset.
   input  [11:0]             paddr,            // Address.
   input                     pwrite,           // Direction.
   input                     psel,             // Select.
   input                     penable,          // Enable.
   input  [31:0]             pwdata,           // Write Data.
   output [31:0]             prdata, 
   output                    pready,

   // JTAG Interface
   //
   input                     tdi,              // test data in     (JTAG)
   input                     tck,              // test clock       (JTAG)
   input                     tms,              // test mode select (JTAG)
   output                    tdo,              // test data out    (JTAG)

   input                     trstn_or_por_rstn,
   output wire               aib_rstn,              // test data out    (JTAG)

   output                    rx_error,           // Receive parity error
   output [DWIDTH-1:0]       rx_error_data,      // Receive parity error data
   output                    tx_rlen_error,      // Transmit read response length error
   output [2:0]              tx_rlen_error_sz,   // Transmit read response length error AXI size
   output [7:0]              tx_rlen_error_len,  // Transmit read response length error AXI length
   
   input                     dig_test_sel,
   output [7:0]              dig_test_bus      // Output DFT: Debug signals from AIB IO 
 );
   parameter ARFIFO_DEPTH = 4;    // Depth of Read address channel FIFO. Max is 16. (4)
   parameter AWFIFO_DEPTH = 4;    // Depth of Write address channel FIFO. Max is 16. (4)
   parameter WFIFO_DEPTH = 2;     // Depth of Write data channel header FIFO. Max is 16. (2)
   
   reg [79:0]                 slave_tx_data_in; 
   wire [DWIDTH-1:0]        i_slave_tx_data_in; 
   reg [DWIDTH-1:0]           slave_rx_data_out;
   wire [79:0]              i_slave_rx_data_out;
   
   wire                       dwidth_80 ;
   wire                  ddr_en ;
   wire                  fs_rstn ;
   wire                  ns_rstn ;
   
 assign aib_rstn = fs_rstn && ns_rstn ;
   //AXI-CPI Slave Bridge 
   axi_cpi_sb #(.DWIDTH(DWIDTH), .DISABLE_SDR(DISABLE_SDR), .ADDR_DID_WIDTH(ADDR_DID_WIDTH), .CFG_ADDR_WIDTH(CFG_ADDR_WIDTH),
                .CFG_ADDR(CFG_ADDR), .AR_AWIDTH(AR_AWIDTH),
                .AR_IDWIDTH(AR_IDWIDTH), .AR_USRWIDTH(AR_USRWIDTH), .AW_AWIDTH(AW_AWIDTH),
                .AW_IDWIDTH(AW_IDWIDTH), .AW_USRWIDTH(AW_USRWIDTH), .W_DWIDTH(W_DWIDTH),
                .W_USRWIDTH(W_USRWIDTH), .R_IDWIDTH(R_IDWIDTH), .R_DWIDTH(R_DWIDTH),
                .R_USRWIDTH(R_USRWIDTH), .B_IDWIDTH(B_IDWIDTH), .B_USRWIDTH(B_USRWIDTH),
                .NUM_AXI_BURSTS(NUM_AXI_BURSTS), .NUM_CPI_FLITS(NUM_CPI_FLITS),
                .ARFIFO_DEPTH(ARFIFO_DEPTH), .AWFIFO_DEPTH(AWFIFO_DEPTH),
                .WFIFO_DEPTH(WFIFO_DEPTH), .MAX_XFR_SIZE(MAX_XFR_SIZE), .SIZEFIT(SIZEFIT),
                .CR_RTN_THRESH(CR_RTN_THRESH), .AXI_BURST_WAIT(AXI_BURST_WAIT),
                .CPI_BURST_WAIT(CPI_BURST_WAIT)
                ) axi_slave
     (.clk           (clk),
      .rx_rd_rstb    (rx_rd_rstb),  // Reset is active low
      .tx_wr_rstb    (tx_wr_rstb),


      .axi_s_araddr  (axi_s_araddr  ),
      .axi_s_arid    (axi_s_arid    ),
      .axi_s_arlen   (axi_s_arlen   ),
      .axi_s_arsize  (axi_s_arsize  ),
      .axi_s_arburst (axi_s_arburst ),
      .axi_s_aruser  (axi_s_aruser  ),
      .axi_s_arlock  (axi_s_arlock  ),
      .axi_s_arqos   (axi_s_arqos   ),
      .axi_s_arregion(axi_s_arregion),
      .axi_s_arprot  (axi_s_arprot  ),
      .axi_s_arvalid (axi_s_arvalid ),
      .axi_s_arready (axi_s_arready ), 
                      
      .axi_s_awaddr  (axi_s_awaddr  ),
      .axi_s_awid    (axi_s_awid    ),
      .axi_s_awlen   (axi_s_awlen   ),
      .axi_s_awsize  (axi_s_awsize  ),
      .axi_s_awburst (axi_s_awburst ),
      .axi_s_awuser  (axi_s_awuser  ),
      .axi_s_awlock  (axi_s_awlock  ),
      .axi_s_awqos   (axi_s_awqos   ),
      .axi_s_awregion(axi_s_awregion),
      .axi_s_awprot  (axi_s_awprot  ),
      .axi_s_awvalid (axi_s_awvalid ),
      .axi_s_awready (axi_s_awready ),
                      
      .axi_s_wdata   (axi_s_wdata   ),
      .axi_s_wstrb   (axi_s_wstrb   ),
      .axi_s_wlast   (axi_s_wlast   ),
      .axi_s_wuser   (axi_s_wuser   ),
      .axi_s_wvalid  (axi_s_wvalid  ),
      .axi_s_wready  (axi_s_wready  ),
                      
      .axi_s_rid     (axi_s_rid     ),
      .axi_s_rdata   (axi_s_rdata   ),
      .axi_s_rlast   (axi_s_rlast   ),
      .axi_s_rresp   (axi_s_rresp   ),
      .axi_s_ruser   (axi_s_ruser   ),
      .axi_s_rvalid  (axi_s_rvalid  ),
      .axi_s_rready  (axi_s_rready  ),
                      
      .axi_s_bid     (axi_s_bid     ),
      .axi_s_bresp   (axi_s_bresp   ),
      .axi_s_buser   (5'h0          ),
      .axi_s_bvalid  (axi_s_bvalid  ),
      .axi_s_bready  (axi_s_bready  ),
      
      .ddr_en        (ddr_en        ),
      
      .cr_init_delay (cr_init_delay ),

      .rx_error          (rx_error          ),         
      .rx_error_data     (rx_error_data     ),    
      .tx_rlen_error     (tx_rlen_error     ),    
      .tx_rlen_error_sz  (tx_rlen_error_sz  ), 
      .tx_rlen_error_len (tx_rlen_error_len ),
      
      .tx_data_out   (i_slave_tx_data_in),
      .rx_data_in    (slave_rx_data_out)
      );
      
      assign dwidth_80 = DWIDTH == 80 ;

      // slave_tx_data_in assignment      
      always @* 
         casez ({dwidth_80, ddr_en})
            
            2'b01 : slave_tx_data_in =   {40'b0,i_slave_tx_data_in[39:0]} ;          // DWIDTH = 40, DDR
            
            2'b00 : slave_tx_data_in =   {1'b0, i_slave_tx_data_in[39],              // DWIDTH = 40, SDR
                                          1'b0, i_slave_tx_data_in[38], 
                                          1'b0, i_slave_tx_data_in[37], 
                                          1'b0, i_slave_tx_data_in[36], 
                                          1'b0, i_slave_tx_data_in[35], 
                                          1'b0, i_slave_tx_data_in[34], 
                                          1'b0, i_slave_tx_data_in[33], 
                                          1'b0, i_slave_tx_data_in[32], 
                                          1'b0, i_slave_tx_data_in[31], 
                                          1'b0, i_slave_tx_data_in[30], 
                                          1'b0, i_slave_tx_data_in[29], 
                                          1'b0, i_slave_tx_data_in[28], 
                                          1'b0, i_slave_tx_data_in[27], 
                                          1'b0, i_slave_tx_data_in[26], 
                                          1'b0, i_slave_tx_data_in[25], 
                                          1'b0, i_slave_tx_data_in[24], 
                                          1'b0, i_slave_tx_data_in[23], 
                                          1'b0, i_slave_tx_data_in[22], 
                                          1'b0, i_slave_tx_data_in[21], 
                                          1'b0, i_slave_tx_data_in[20], 
                                          1'b0, i_slave_tx_data_in[19], 
                                          1'b0, i_slave_tx_data_in[18], 
                                          1'b0, i_slave_tx_data_in[17], 
                                          1'b0, i_slave_tx_data_in[16], 
                                          1'b0, i_slave_tx_data_in[15], 
                                          1'b0, i_slave_tx_data_in[14], 
                                          1'b0, i_slave_tx_data_in[13], 
                                          1'b0, i_slave_tx_data_in[12], 
                                          1'b0, i_slave_tx_data_in[11], 
                                          1'b0, i_slave_tx_data_in[10], 
                                          1'b0, i_slave_tx_data_in[9], 
                                          1'b0, i_slave_tx_data_in[8], 
                                          1'b0, i_slave_tx_data_in[7], 
                                          1'b0, i_slave_tx_data_in[6], 
                                          1'b0, i_slave_tx_data_in[5], 
                                          1'b0, i_slave_tx_data_in[4], 
                                          1'b0, i_slave_tx_data_in[3], 
                                          1'b0, i_slave_tx_data_in[2], 
                                          1'b0, i_slave_tx_data_in[1], 
                                          1'b0, i_slave_tx_data_in[0]} ;                                          
                                          
            2'b1? : slave_tx_data_in =          i_slave_tx_data_in[79:0] ;           // DWIDTH = 40/80, DDR



         endcase    
         
      // slave_rx_data_out assignment      
      always @* 
         casez ({dwidth_80, ddr_en})
         
            2'b01 : slave_rx_data_out =          i_slave_rx_data_out[39:0] ;         // DWIDTH = 40, DDR
            
            2'b00 : slave_rx_data_out =         {i_slave_rx_data_out[78],            // DWIDTH = 40, SDR 
                                                 i_slave_rx_data_out[76], 
                                                 i_slave_rx_data_out[74], 
                                                 i_slave_rx_data_out[72], 
                                                 i_slave_rx_data_out[70], 
                                                 i_slave_rx_data_out[68], 
                                                 i_slave_rx_data_out[66], 
                                                 i_slave_rx_data_out[64], 
                                                 i_slave_rx_data_out[62], 
                                                 i_slave_rx_data_out[60], 
                                                 i_slave_rx_data_out[58], 
                                                 i_slave_rx_data_out[56], 
                                                 i_slave_rx_data_out[54], 
                                                 i_slave_rx_data_out[52], 
                                                 i_slave_rx_data_out[50], 
                                                 i_slave_rx_data_out[48], 
                                                 i_slave_rx_data_out[46], 
                                                 i_slave_rx_data_out[44], 
                                                 i_slave_rx_data_out[42], 
                                                 i_slave_rx_data_out[40], 
                                                 i_slave_rx_data_out[38], 
                                                 i_slave_rx_data_out[36], 
                                                 i_slave_rx_data_out[34], 
                                                 i_slave_rx_data_out[32], 
                                                 i_slave_rx_data_out[30], 
                                                 i_slave_rx_data_out[28], 
                                                 i_slave_rx_data_out[26], 
                                                 i_slave_rx_data_out[24], 
                                                 i_slave_rx_data_out[22], 
                                                 i_slave_rx_data_out[20], 
                                                 i_slave_rx_data_out[18], 
                                                 i_slave_rx_data_out[16], 
                                                 i_slave_rx_data_out[14], 
                                                 i_slave_rx_data_out[12], 
                                                 i_slave_rx_data_out[10], 
                                                 i_slave_rx_data_out[8], 
                                                 i_slave_rx_data_out[6], 
                                                 i_slave_rx_data_out[4], 
                                                 i_slave_rx_data_out[2], 
                                                 i_slave_rx_data_out[0]} ;    
                                                 
            2'b1? : slave_rx_data_out =          i_slave_rx_data_out[79:0] ;           // DWIDTH = 80, DDR
         endcase            
                                                   
   tlrb_aib_phy_ext u_slave_aib_channel
      (
      .ubump                           (ubump),
      
      .ubump_aux                       (ubump_aux),
      .tx_data                         (slave_tx_data_in),
      .rx_data                         (i_slave_rx_data_out),
      
      .tx_clk                          (tx_clk),
      .rx_clk                          (rx_clk),    // Output
      
      .conf_done                       (conf_done),
      .config_done                     (config_done),
      .device_detect_ovrd              (device_detect_ovrd),
      .dig_test_sel                    (dig_test_sel),
      .dig_test_bus                    (dig_test_bus),
     
      .paddr                           (paddr),
      .pclk                            (pclk),
      .penable                         (penable),
      .por_ovrd                        (por_ovrd),
      .presetn                         (presetn),
      .psel                            (psel),
      .pwdata                          (pwdata),
      .pwrite                          (pwrite),
      .prdata                          (prdata),
      .pready                          (pready),
      
      .ms_nsl                          (1'b 0),       // Slave mode
      
      .tck                             (tck),              // Input  JTAG scan enable
      .tdi                             (tdi),              // Input  JTAG data register clock
      .tms                             (tms),              // Input  JTAG reset (active low)
      .tdo                             (tdo),              // Input  JTAG reset enable
      .trstn_or_por_rstn               (trstn_or_por_rstn),// Input  JTAG clock select

      .r_apb_iddr_enable               (ddr_en),
      .r_apb_ns_adap_rstn              (),
      .r_apb_ns_rstn                   (ns_rstn),
      .r_apb_fs_adap_rstn              (),
      .r_apb_fs_rstn                   (fs_rstn)
      );

endmodule // slave_cpi_aib
