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
// File name   : master_cpi_aib
// Author      : New Wave Design and Verification
//
// Description :
// This block combines the CPI master bridge with the AIB master-configured PHY
//
//
// Revision History: 
// Date        Description
// 2018 Oct 11 Initial release.
//
//----------------------------------------------------------------------------------------

module master_cpi_aib              #(parameter DWIDTH = 80,         // AIB interface width must be 40
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
                                    parameter W_DWIDTH = 128,        // Write data width must be 32, 64 or 128
                                    parameter W_USRWIDTH = 8,       // Write data user width maximum is 8
                                    parameter R_IDWIDTH = 8,        // Read data ID width maximum is 8
                                    parameter R_DWIDTH = 128,        // Read data width must be 32, 64 or 128
                                    parameter R_USRWIDTH = 5,       // Read data user width maximum is 5
                                    parameter B_IDWIDTH = 8,        // Write response ID width maximum is 8
                                    parameter B_USRWIDTH = 5,       // Write response user width maximum is 5
                                    parameter NUM_AXI_BURSTS = 2,   // Num AXI bursts in transmit FIFO. Max is 16
                                    parameter NUM_CPI_FLITS = 128,  // Num CPI flits in receive FIFO. Min is 128. Max is 256.
                                    parameter BFIFO_DEPTH = 4,      // Depth of Write response channel FIFO. Max is 16.
                                    parameter RFIFO_DEPTH = 2,      // Depth of Read data channel header FIFO. Max is 16.
                                    parameter MAX_XFR_SIZE = 256,   // Maximum AXI data transfer is 256 bytes.
                                    parameter SIZEFIT = 0,          // Write data size is always equal to W_DWIDTH
                                    parameter CR_RTN_THRESH = 32,   // Credit return threshold
                                    parameter AXI_BURST_WAIT = 0,   // Start after all AXI burst transfers received
                                    parameter CPI_BURST_WAIT = 0,   // Start after all CPI flits received
                                    parameter NDAT = 32'd80,        // Number of Sync Data uBumps in chan
                                    parameter NBMP = NDAT + 32'd10, // Total number of bumps                                    
                                    parameter HNBMP = NBMP/32'd2,   // Half the # of uBumps in chan
                                    parameter FBMP  = NBMP - 32'd2, // # of functional/logical uBumps (wo spares)
                                    parameter DLYW = 32'd10         // Manual mode DLL adjust bit width
                                    )  // Number of uBumps in chan
(
   input clk,                                  // CPI bridge clock
   input rx_rd_rstb,                           // CPI rx rd reset
   input tx_wr_rstb,                           // CPI tx wr reset

   // AXI Master Interface Tx Path
   input [AR_AWIDTH-1:0]     axi_m_araddr,    // AXI Master Read Address channel address
   input [AR_IDWIDTH-1:0]    axi_m_arid,      // AXI Master Read Address channel ID
   input [7:0]               axi_m_arlen,     // AXI Master Read Address channel burst length
   input [2:0]               axi_m_arsize,    // AXI Master Read Address channel burst size
   input [1:0]               axi_m_arburst,   // AXI Master Read Address channel burst type
   input [AR_USRWIDTH-1:0]   axi_m_aruser,    // AXI Master Read Address channel user
   input                     axi_m_arlock,    // AXI Master Read Address channel lock
   input [3:0]               axi_m_arqos,     // AXI Master Read Address channel QoS
   input [3:0]               axi_m_arregion,  // AXI Master Read Address channel region
   input [2:0]               axi_m_arprot,    // AXI Master Read Address channel prot
   input                     axi_m_arvalid,   // AXI Master Read Address channel valid
   output                    axi_m_arready,   // AXI Master Read Address channel ready

   input [AW_AWIDTH-1:0]     axi_m_awaddr,    // AXI Master Write Address channel address
   input [AW_IDWIDTH-1:0]    axi_m_awid,      // AXI Master Write Address channel ID
   input [7:0]               axi_m_awlen,     // AXI Master Write Address channel burst length
   input [2:0]               axi_m_awsize,    // AXI Master Write Address channel burst size
   input [1:0]               axi_m_awburst,   // AXI Master Write Address channel burst type
   input [AW_USRWIDTH-1:0]   axi_m_awuser,    // AXI Master Write Address channel user
   input                     axi_m_awlock,    // AXI Master Write Address channel lock
   input [3:0]               axi_m_awqos,     // AXI Master Write Address channel QoS
   input [3:0]               axi_m_awregion,  // AXI Master Write Address channel region
   input [2:0]               axi_m_awprot,    // AXI Master Write Address channel prot
   input                     axi_m_awvalid,   // AXI Master Write Address channel valid
   output                    axi_m_awready,   // AXI Master Write Address channel ready

   input [W_DWIDTH-1:0]      axi_m_wdata,     // AXI Master Write Data channel data
   input [(W_DWIDTH/8)-1:0]  axi_m_wstrb,     // AXI Master Write Data channel strobe
   input                     axi_m_wlast,     // AXI Master Write Data channel last
   input [W_USRWIDTH-1:0]    axi_m_wuser,     // AXI Master Write Data channel user
   input                     axi_m_wvalid,    // AXI Master Write Data channel valid
   output                    axi_m_wready,    // AXI Master Write Data channel ready

   
   input [7:0]               cpi_source_id,   // CPI Source component ID for this bridge

   // AXI Master Interface Rx Path
   output [R_IDWIDTH-1:0]    axi_m_rid,       // AXI Master Read Response channel ID
   output [R_DWIDTH-1:0]     axi_m_rdata,     // AXI Master Read Response channel data
   output                    axi_m_rlast,     // AXI Master Read Response channel last
   output [1:0]              axi_m_rresp,     // AXI Master Read Response channel response
   output [R_USRWIDTH-1:0]   axi_m_ruser,     // AXI Master Read Response channel user
   output                    axi_m_rvalid,    // AXI Master Read Response channel valid
   input                     axi_m_rready,    // AXI Master Read Response channel ready

   output [B_IDWIDTH-1:0]    axi_m_bid,       // AXI Master Write Response channel ID
   output [1:0]              axi_m_bresp,     // AXI Master Write Response channel response
   output [B_USRWIDTH-1:0]   axi_m_buser,     // AXI Master Write Response channel user
   output                    axi_m_bvalid,    // AXI Master Write Response channel valid
   input                     axi_m_bready,    // AXI Master Write Response channel ready
   
   input [63:0]              cr_init_delay,      // Number of clock cycles to delay credit init
   
   // AIB Master Interfaces
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
   output                    tx_rlen_error,      // Transmit read length error
   output [2:0]              tx_rlen_error_sz,   // Transmit read length error AXI size
   output [7:0]              tx_rlen_error_len,  // Transmit read length error AXI length
   output                    tx_wlen_error,      // Transmit write length error
   output [2:0]              tx_wlen_error_sz,   // Transmit write length error AXI size
   output [7:0]              tx_wlen_error_len,   // Transmit write length error AXI length
   
   input                     dig_test_sel,
   output [7:0]              dig_test_bus      // Output DFT: Debug signals from AIB IO 
 );
    
   reg [79:0]            master_tx_data_in;    // AIB interface is fixed at 80 bits
   wire [DWIDTH-1:0]   i_master_tx_data_in;  
   reg  [DWIDTH-1:0]     master_rx_data_out;
   wire [79:0]         i_master_rx_data_out;   // AIB interface is fixed at 80 bits
      
   wire                  dwidth_80 ;
   wire                  ddr_en ;
   wire                  fs_rstn ;
   wire                  ns_rstn ;
   
 assign aib_rstn = fs_rstn && ns_rstn ;
 
   //AXI-CPI Master Bridge 
   axi_cpi_mb #(.DWIDTH(DWIDTH), .DISABLE_SDR(DISABLE_SDR), .ADDR_DID_WIDTH(ADDR_DID_WIDTH), .CFG_ADDR_WIDTH(CFG_ADDR_WIDTH),
                .CFG_ADDR(CFG_ADDR), .AR_AWIDTH(AR_AWIDTH),
                .AR_IDWIDTH(AR_IDWIDTH), .AR_USRWIDTH(AR_USRWIDTH), .AW_AWIDTH(AW_AWIDTH),
                .AW_IDWIDTH(AW_IDWIDTH), .AW_USRWIDTH(AW_USRWIDTH), .W_DWIDTH(W_DWIDTH),
                .W_USRWIDTH(W_USRWIDTH), .R_IDWIDTH(R_IDWIDTH), .R_DWIDTH(R_DWIDTH),
                .R_USRWIDTH(R_USRWIDTH), .B_IDWIDTH(B_IDWIDTH), .B_USRWIDTH(B_USRWIDTH),
                .NUM_AXI_BURSTS(NUM_AXI_BURSTS), .NUM_CPI_FLITS(NUM_CPI_FLITS), .BFIFO_DEPTH(BFIFO_DEPTH),
                .RFIFO_DEPTH(RFIFO_DEPTH), .MAX_XFR_SIZE(MAX_XFR_SIZE), .SIZEFIT(SIZEFIT),
                .CR_RTN_THRESH(CR_RTN_THRESH), .AXI_BURST_WAIT(AXI_BURST_WAIT),
                .CPI_BURST_WAIT(CPI_BURST_WAIT)
        ) axi_master
     (.clk           (clk),
      .rx_rd_rstb    (rx_rd_rstb),  // Reset is active low
      .tx_wr_rstb    (tx_wr_rstb),

      .cpi_source_id (cpi_source_id),
      
      .axi_m_araddr  (axi_m_araddr),
      .axi_m_arid    (axi_m_arid),
      .axi_m_arlen   (axi_m_arlen),
      .axi_m_arsize  (axi_m_arsize),
      .axi_m_arburst (axi_m_arburst), // incr
      .axi_m_aruser  (axi_m_aruser),
      .axi_m_arlock  (axi_m_arlock),
      .axi_m_arqos   (axi_m_arqos), // no QoS scheme
      .axi_m_arregion(axi_m_arregion),
      .axi_m_arprot  (axi_m_arprot),
      .axi_m_arvalid (axi_m_arvalid),
      .axi_m_arready (axi_m_arready),

      .axi_m_awaddr  (axi_m_awaddr),
      .axi_m_awid    (axi_m_awid),
      .axi_m_awlen   (axi_m_awlen),
      .axi_m_awsize  (axi_m_awsize),
      .axi_m_awburst (axi_m_awburst), // incr
      .axi_m_awuser  (axi_m_awuser),
      .axi_m_awlock  (axi_m_awlock),
      .axi_m_awqos   (axi_m_awqos), // no QoS scheme
      .axi_m_awregion(axi_m_awregion),
      .axi_m_awprot  (axi_m_awprot),
      .axi_m_awvalid (axi_m_awvalid),
      .axi_m_awready (axi_m_awready),
      
      .axi_m_wdata   (axi_m_wdata),
      .axi_m_wstrb   (axi_m_wstrb),
      .axi_m_wlast   (axi_m_wlast),
      .axi_m_wuser   (axi_m_wuser),
      .axi_m_wvalid  (axi_m_wvalid),
      .axi_m_wready  (axi_m_wready),
           
      .axi_m_rid     (axi_m_rid),
      .axi_m_rdata   (axi_m_rdata),
      .axi_m_rlast   (axi_m_rlast),
      .axi_m_rresp   (axi_m_rresp),
      .axi_m_ruser   (),           //USER field not used
      .axi_m_rvalid  (axi_m_rvalid),
      .axi_m_rready  (axi_m_rready),
           
      .axi_m_bid     (axi_m_bid),
      .axi_m_bresp   (axi_m_bresp),
      .axi_m_buser   (),           //USER field not used
      .axi_m_bvalid  (axi_m_bvalid),
      .axi_m_bready  (axi_m_bready),
           
      .ddr_en        (ddr_en      ),
      
      .cr_init_delay (cr_init_delay ),

      .rx_error          (rx_error          ),         
      .rx_error_data     (rx_error_data     ),    
      .tx_rlen_error     (tx_rlen_error     ),    
      .tx_rlen_error_sz  (tx_rlen_error_sz  ), 
      .tx_rlen_error_len (tx_rlen_error_len ),
      .tx_wlen_error     (tx_wlen_error     ),    
      .tx_wlen_error_sz  (tx_wlen_error_sz  ), 
      .tx_wlen_error_len (tx_wlen_error_len ),
      
      .tx_data_out   (i_master_tx_data_in),
      .rx_data_in    (master_rx_data_out) 
      
      );
      
      assign dwidth_80 = DWIDTH == 80 ;

      // master_tx_data_in assignment      

      always @* 
         casez ({dwidth_80, ddr_en})
            
            2'b01 : master_tx_data_in =  {40'b0,i_master_tx_data_in[39:0]} ;          // DWIDTH = 40, DDR
            
            2'b00 : master_tx_data_in =  {1'b0, i_master_tx_data_in[39],              // DWIDTH = 40, SDR 
                                          1'b0, i_master_tx_data_in[38], 
                                          1'b0, i_master_tx_data_in[37], 
                                          1'b0, i_master_tx_data_in[36], 
                                          1'b0, i_master_tx_data_in[35], 
                                          1'b0, i_master_tx_data_in[34], 
                                          1'b0, i_master_tx_data_in[33], 
                                          1'b0, i_master_tx_data_in[32], 
                                          1'b0, i_master_tx_data_in[31], 
                                          1'b0, i_master_tx_data_in[30], 
                                          1'b0, i_master_tx_data_in[29], 
                                          1'b0, i_master_tx_data_in[28], 
                                          1'b0, i_master_tx_data_in[27], 
                                          1'b0, i_master_tx_data_in[26], 
                                          1'b0, i_master_tx_data_in[25], 
                                          1'b0, i_master_tx_data_in[24], 
                                          1'b0, i_master_tx_data_in[23], 
                                          1'b0, i_master_tx_data_in[22], 
                                          1'b0, i_master_tx_data_in[21], 
                                          1'b0, i_master_tx_data_in[20], 
                                          1'b0, i_master_tx_data_in[19], 
                                          1'b0, i_master_tx_data_in[18], 
                                          1'b0, i_master_tx_data_in[17], 
                                          1'b0, i_master_tx_data_in[16], 
                                          1'b0, i_master_tx_data_in[15], 
                                          1'b0, i_master_tx_data_in[14], 
                                          1'b0, i_master_tx_data_in[13], 
                                          1'b0, i_master_tx_data_in[12], 
                                          1'b0, i_master_tx_data_in[11], 
                                          1'b0, i_master_tx_data_in[10], 
                                          1'b0, i_master_tx_data_in[9], 
                                          1'b0, i_master_tx_data_in[8], 
                                          1'b0, i_master_tx_data_in[7], 
                                          1'b0, i_master_tx_data_in[6], 
                                          1'b0, i_master_tx_data_in[5], 
                                          1'b0, i_master_tx_data_in[4], 
                                          1'b0, i_master_tx_data_in[3], 
                                          1'b0, i_master_tx_data_in[2], 
                                          1'b0, i_master_tx_data_in[1], 
                                          1'b0, i_master_tx_data_in[0]} ;                                          
                                          
            2'b1? : master_tx_data_in =         i_master_tx_data_in[79:0] ;           // DWIDTH = 80, SDR/DDR
         endcase            
      
      // master_rx_data_out assignment      

      always @* 
         casez ({dwidth_80, ddr_en})
         
            2'b01 : master_rx_data_out =         i_master_rx_data_out[39:0] ;         // DWIDTH = 40, DDR
            
            2'b00 : master_rx_data_out =        {i_master_rx_data_out[78],            // DWIDTH = 40, SDR 
                                                 i_master_rx_data_out[76], 
                                                 i_master_rx_data_out[74], 
                                                 i_master_rx_data_out[72], 
                                                 i_master_rx_data_out[70], 
                                                 i_master_rx_data_out[68], 
                                                 i_master_rx_data_out[66], 
                                                 i_master_rx_data_out[64], 
                                                 i_master_rx_data_out[62], 
                                                 i_master_rx_data_out[60], 
                                                 i_master_rx_data_out[58], 
                                                 i_master_rx_data_out[56], 
                                                 i_master_rx_data_out[54], 
                                                 i_master_rx_data_out[52], 
                                                 i_master_rx_data_out[50], 
                                                 i_master_rx_data_out[48], 
                                                 i_master_rx_data_out[46], 
                                                 i_master_rx_data_out[44], 
                                                 i_master_rx_data_out[42], 
                                                 i_master_rx_data_out[40], 
                                                 i_master_rx_data_out[38], 
                                                 i_master_rx_data_out[36], 
                                                 i_master_rx_data_out[34], 
                                                 i_master_rx_data_out[32], 
                                                 i_master_rx_data_out[30], 
                                                 i_master_rx_data_out[28], 
                                                 i_master_rx_data_out[26], 
                                                 i_master_rx_data_out[24], 
                                                 i_master_rx_data_out[22], 
                                                 i_master_rx_data_out[20], 
                                                 i_master_rx_data_out[18], 
                                                 i_master_rx_data_out[16], 
                                                 i_master_rx_data_out[14], 
                                                 i_master_rx_data_out[12], 
                                                 i_master_rx_data_out[10], 
                                                 i_master_rx_data_out[8], 
                                                 i_master_rx_data_out[6], 
                                                 i_master_rx_data_out[4], 
                                                 i_master_rx_data_out[2], 
                                                 i_master_rx_data_out[0]} ;    
                                                 
            2'b1? : master_rx_data_out =         i_master_rx_data_out[79:0] ;           // DWIDTH = 80, SDR/DDR
         endcase            
      
   // AIB Master Channel - Adapter + AIB I/O Block (see Fig 3-11)
   tlrb_aib_phy_ext u_master_aib_channel
      (
      .ubump                           (ubump),
      
      .ubump_aux                       (ubump_aux),
      .tx_data                         (master_tx_data_in),
      .rx_data                         (i_master_rx_data_out),
      
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
      
      .ms_nsl                          (1'b 1),            // Master mode
      
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

endmodule // master_cpi_aib
