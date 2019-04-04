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
// File name   : axim_cpi_aib_aib_cpi_axis
// Author      : New Wave Design and Verification
//
// Description :
// This block connects a CPI/AIB master to a CPI/AIB slave for simulation purposes.  The block behaves
//   as an AXI pass-through.
//
//
// Revision History: 
// Date        Description
// 2018 Oct 11 Initial release.
//
//----------------------------------------------------------------------------------------

`timescale 1ps / 1ps
`define AXI_PROT_DATA 3'h4


module axim_cpi_aib_aib_cpi_axis  #(parameter ADDR_DID_WIDTH = 2,  // Width of address field used for DID. Max is 8.
                                    parameter DISABLE_SDR = 0,     // Don't operate in 40 bit mode when DWIDTH = 80 & ddr_en = 0
                                    parameter CFG_ADDR_WIDTH = 8,  // Width of address field used for config space. Min is 0. Max is 31
                                    parameter CFG_ADDR = 255,      // Value that indicates config space address region
                                    parameter AR_AWIDTH = 34,      // Read addr width,min is 8,max is 34 + ADDR_DID_WIDTH
                                    parameter AR_IDWIDTH = 8,      // Read addr ID width maximum is 8
                                    parameter AR_USRWIDTH = 8,     // Read addr user width maximum is 8
                                    parameter AW_AWIDTH = 34,      // Write addr width,min is 8,max is 34 + ADDR_DID_WIDTH
                                    parameter AW_IDWIDTH = 8,      // Write addr ID width maximum is 8
                                    parameter AW_USRWIDTH = 8,     // Write addr user width maximum is 8
                                    parameter AX_DWIDTH = 64,      // Read and wite data width must be 32, 64 or 128. 32 only if DWIDTH is 40.
                                    parameter W_DWIDTH = 64,       // Write data width must be 32, 64 or 128
                                    parameter W_USRWIDTH = 8,      // Write data user width maximum is 8
                                    parameter R_IDWIDTH = 8,       // Read data ID width maximum is 8
                                    parameter R_DWIDTH = 64,       // Read data width must be 32, 64 or 128
                                    parameter R_USRWIDTH = 5,      // Read data user width maximum is 5
                                    parameter B_IDWIDTH = 8,       // Write response ID width maximum is 8
                                    parameter B_USRWIDTH = 5,      // Write response user width maximum is 5
                                    parameter NUM_AXI_BURSTS = 2,  // Num AXI bursts in transmit FIFO. Max is 16
                                    parameter NUM_CPI_FLITS = 128, // Num CPI flits in receive FIFO. Min is 128. Max is 255.
                                    parameter BFIFO_DEPTH = 4,     // Depth of Write response channel FIFO. Max is 16.
                                    parameter RFIFO_DEPTH = 2,     // Depth of Read data channel header FIFO. Max is 16.
                                    parameter MAX_XFR_SIZE = 256,  // Maximum AXI data transfer is 256 bytes.
                                    parameter SIZEFIT = 0,         // Write data size is always equal to W_DWIDTH
                                    parameter CR_RTN_THRESH = 32,  // Credit return threshold
                                    parameter AXI_BURST_WAIT = 0,  // Start after all AXI burst transfers received
                                    parameter CPI_BURST_WAIT = 0
)
(

  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME AXI_M, ASSOCIATED_RESET aib_reset, FREQ_HZ 100000000" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk_m CLK" *) 
   input sys_clk_m,                           // clock for master
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME AXI_S, ASSOCIATED_RESET aib_reset, FREQ_HZ 100000000" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 sys_clk_s CLK" *) 
   input sys_clk_s,                           // clock for slave -- not connected
                                              //   clock option 1, CHIPS AIB Architecture Specification sect. 8.5
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aib_reset, POLARITY ACTIVE_LOW" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aib_reset RST" *)  
   input aib_reset,                           // AIB RX read reset bar
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME bridge_reset, POLARITY ACTIVE_LOW" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 bridge_reset RST" *)  
   input bridge_reset,                        // AIB RX read reset bar

   // AXI Master Interface Tx Path
   input [AR_AWIDTH-1:0]     axi_m_araddr,    // AXI Master Read Address channel address
   input [AR_IDWIDTH-1:0]    axi_m_arid,      // AXI Master Read Address channel ID
   input [7:0]               axi_m_arlen,     // AXI Master Read Address channel burst length
   input [2:0]               axi_m_arsize,    // AXI Master Read Address channel burst size
   input [1:0]               axi_m_arburst,   // AXI Master Read Address channel burst type
//   input [AR_USRWIDTH-1:0]   axi_m_aruser,    // AXI Master Read Address channel user
//   input                     axi_m_arlock,    // AXI Master Read Address channel lock
//   input [3:0]               axi_m_arqos,     // AXI Master Read Address channel QoS
//   input [3:0]               axi_m_arregion,  // AXI Master Read Address channel region
//   input [2:0]               axi_m_arprot,    // AXI Master Read Address channel prot
   input                     axi_m_arvalid,   // AXI Master Read Address channel valid
   output                    axi_m_arready,   // AXI Master Read Address channel ready

   input [AW_AWIDTH-1:0]     axi_m_awaddr,    // AXI Master Write Address channel address
   input [AW_IDWIDTH-1:0]    axi_m_awid,      // AXI Master Write Address channel ID
   input [7:0]               axi_m_awlen,     // AXI Master Write Address channel burst length
   input [2:0]               axi_m_awsize,    // AXI Master Write Address channel burst size
   input [1:0]               axi_m_awburst,   // AXI Master Write Address channel burst type
 //  input [AW_USRWIDTH-1:0]   axi_m_awuser,    // AXI Master Write Address channel user
 //  input                     axi_m_awlock,    // AXI Master Write Address channel lock
 //  input [3:0]               axi_m_awqos,     // AXI Master Write Address channel QoS
 //  input [3:0]               axi_m_awregion,  // AXI Master Write Address channel region
 //  input [2:0]               axi_m_awprot,    // AXI Master Write Address channel prot
   input                     axi_m_awvalid,   // AXI Master Write Address channel valid
   output                    axi_m_awready,   // AXI Master Write Address channel ready

   input [W_DWIDTH-1:0]      axi_m_wdata,     // AXI Master Write Data channel data
   input [(W_DWIDTH/8)-1:0]  axi_m_wstrb,     // AXI Master Write Data channel strobe
   input                     axi_m_wlast,     // AXI Master Write Data channel last
//   input [W_USRWIDTH-1:0]    axi_m_wuser,     // AXI Master Write Data channel user
   input                     axi_m_wvalid,    // AXI Master Write Data channel valid
   output                    axi_m_wready,    // AXI Master Write Data channel ready

   // AXI Master Interface Rx Path
   output [R_IDWIDTH-1:0]    axi_m_rid,       // AXI Master Read Response channel ID
   output [R_DWIDTH-1:0]     axi_m_rdata,     // AXI Master Read Response channel data
   output                    axi_m_rlast,     // AXI Master Read Response channel last
   output [1:0]              axi_m_rresp,     // AXI Master Read Response channel response
   output wire [R_USRWIDTH-1:0]   axi_m_ruser,     // AXI Master Read Response channel user
   output                    axi_m_rvalid,    // AXI Master Read Response channel valid
   input                     axi_m_rready,    // AXI Master Read Response channel ready

   output [B_IDWIDTH-1:0]    axi_m_bid,       // AXI Master Write Response channel ID
   output [1:0]              axi_m_bresp,     // AXI Master Write Response channel response
//   output wire [B_USRWIDTH-1:0]   axi_m_buser,     // AXI Master Write Response channel user
   output                    axi_m_bvalid,    // AXI Master Write Response channel valid
   input                     axi_m_bready,    // AXI Master Write Response channel ready

   // AXI Slave Interface Rx Path
   output [AR_AWIDTH-1:0]     axi_s_araddr,    // AXI Slave Read Address channel address
   output [AR_IDWIDTH-1:0]    axi_s_arid,      // AXI Slave Read Address channel ID
   output [7:0]               axi_s_arlen,     // AXI Slave Read Address channel burst length
   output [2:0]               axi_s_arsize,    // AXI Slave Read Address channel burst size
   output [1:0]               axi_s_arburst,   // AXI Slave Read Address channel burst type
//   wire [AR_USRWIDTH-1:0]   axi_s_aruser,    // AXI Slave Read Address channel user
//   wire                     axi_s_arlock,    // AXI Slave Read Address channel lock
//   wire [3:0]               axi_s_arqos,     // AXI Slave Read Address channel QoS
//   wire [3:0]               axi_s_arregion,  // AXI Slave Read Address channel region
//   wire [2:0]               axi_s_arprot,    // AXI Slave Read Address channel prot
   output                     axi_s_arvalid,   // AXI Slave Read Address channel valid
   input                      axi_s_arready,   // AXI Slave Read Address channel ready

   output [AW_AWIDTH-1:0]     axi_s_awaddr,    // AXI Slave Write Address channel address
   output [AW_IDWIDTH-1:0]    axi_s_awid,      // AXI Slave Write Address channel ID
   output [7:0]               axi_s_awlen,     // AXI Slave Write Address channel burst length
   output [2:0]               axi_s_awsize,    // AXI Slave Write Address channel burst size
   output [1:0]               axi_s_awburst,   // AXI Slave Write Address channel burst type
 //  wire [AW_USRWIDTH-1:0]   axi_s_awuser,    // AXI Slave Write Address channel user
 //  wire                     axi_s_awlock,    // AXI Slave Write Address channel lock
 //  wire [3:0]               axi_s_awqos,     // AXI Slave Write Address channel QoS
 //  wire [3:0]               axi_s_awregion,  // AXI Slave Write Address channel region
 //  wire [2:0]               axi_s_awprot,    // AXI Slave Write Address channel prot
   output                     axi_s_awvalid,   // AXI Slave Write Address channel valid
   input                      axi_s_awready,   // AXI Slave Write Address channel ready

   output [W_DWIDTH-1:0]      axi_s_wdata,     // AXI Slave Write Data channel data
   output [(W_DWIDTH/8)-1:0]  axi_s_wstrb,     // AXI Slave Write Data channel strobe
   output                     axi_s_wlast,     // AXI Slave Write Data channel last
//   output [W_USRWIDTH-1:0]    axi_s_wuser,     // AXI Slave Write Data channel user
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
//   input [B_USRWIDTH-1:0]    axi_s_buser,      // AXI Slave Write Response channel user
   input                     axi_s_bvalid,     // AXI Slave Write Response channel valid
   output                    axi_s_bready,     // AXI Slave Write Response channel ready
   
// APB Slave Interface -- For master CPI/AIB
   //
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME APB_M, ASSOCIATED_RESET aib_reset, FREQ_HZ 100000000" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pclk_m CLK" *) 
   input                     pclk_m,             // Clock.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PADDR" *)
   input  [11:0]             paddr_m,            // Address.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PWRITE" *)
   input                     pwrite_m,           // Direction.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PSEL" *)
   input                     psel_m,             // Select.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PENABLE" *)
   input                     penable_m,          // Enable.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PWDATA" *)
   input  [31:0]             pwdata_m,           // Write Data.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PRDATA" *)
   output [31:0]             prdata_m, 
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_M PREADY" *)
   output                    pready_m,
   
// APB Slave Interface -- For slave CPI/AIB
   //
  (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME APB_S, ASSOCIATED_RESET aib_reset, FREQ_HZ 100000000" *)
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pclk_s CLK" *) 
   input                     pclk_s,             // Clock.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PADDR" *)
   input  [11:0]             paddr_s,            // Address.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PWRITE" *)
   input                     pwrite_s,           // Direction.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PSEL" *)
   input                     psel_s,             // Select.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PENABLE" *)
   input                     penable_s,          // Enable.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PWDATA" *)
   input  [31:0]             pwdata_s,           // Write Data.
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PRDATA" *)
   output [31:0]             prdata_s, 
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 APB_S PREADY" *)
   output                    pready_s

);

// 0 = SDR path through AIB I/O. 1 = DDR path through AIB I/O
   `ifdef DDR_1
      parameter DDR = 1;
   `else
      parameter DDR = 0;
   `endif
// 0 = DWIDTH = 40. 1 = DWIDTH = 80.
   `ifdef DWIDTH_80
      parameter DWIDTH = 80;
   `else
      parameter DWIDTH = 40;
   `endif
   parameter ARFIFO_DEPTH = 4;    // Depth of Read address channel FIFO. Max is 16. (4)
   parameter AWFIFO_DEPTH = 4;    // Depth of Write address channel FIFO. Max is 16. (4)
   parameter WFIFO_DEPTH = 2;     // Depth of Write data channel header FIFO. Max is 16. (2)
   
   // Do not change the localparams   
   localparam NDAT = 32'd80;         // Number of Sync Data uBumps in chan
   localparam NBMP = NDAT + 32'd10;  // Number of uBumps in chan
   localparam HNBMP = NBMP/32'd2;    // Half the # of uBumps in chan
   localparam FBMP  = NBMP - 32'd2;  // # of functional/logical uBumps (wo spares)
   localparam DLYW = 32'd10;         // Manual mode DLL adjust bit width
   
   wire [NBMP-1:0]   ubump_master;
   wire [NBMP-1:0]   ubump_slave;
   
   wire [1:0] ubump_aux;
   wire sys_clk_s_gen;
   wire s_aib_rstn;
   wire m_aib_rstn;
   
   reg m1_next, m2_next, s1_next, s2_next ;
   
   integer f1, f2, f3, f4, mw_time, sw_time, mr_time, sr_time ; 
   
   wire conf_done;
   wire config_done_m;
   wire config_done_s;
  
  `ifndef EXT_DRV_JTAG
     wire m_tdi = 1'b 0 ;
     wire m_tck = 1'b 1 ;
     wire m_tms = 1'b 0 ;
     wire m_trstn = 1'b 1 ;
    
     wire s_tdi = 1'b 0 ;
     wire s_tck = 1'b 1 ;
     wire s_tms = 1'b 0 ;
     wire s_trstn = 1'b 1 ;
  `else
     wire m_tdi ;
     wire m_tck ;
     wire m_tms ;
     wire m_trstn ;
    
     wire s_tdi ;
     wire s_tck ;
     wire s_tms ;
     wire s_trstn ;
     
     wire m_tdi_in   ;
     wire m_tck_in   ;
     wire m_tms_in   ;
     wire m_trstn_in ;
     wire m_tdo_out  ;
    
     wire s_tdi_in   ;
     wire s_tck_in   ;
     wire s_tms_in   ;
     wire s_trstn_in ;
     wire s_tdo_out  ;
  `endif
   wire m_por_trstn ;
   wire s_por_trstn ;
   
   wire m_tdo ;
   wire s_tdo ;
     
 assign conf_done = config_done_m && config_done_s;

// These files capture latency information for master writes, slave writes, slave reads and master reads.
initial begin
   f1 = $fopen ("mwrite.txt", "w") ;
   f2 = $fopen ("swrite.txt", "w") ;
   f3 = $fopen ("sread.txt", "w") ;
   f4 = $fopen ("mread.txt", "w") ;     
end

always @(negedge bridge_reset, negedge sys_clk_m )

// These processes capture latency numbers for master writes, slave writes, slave reads and master reads.
begin
  if (!bridge_reset) begin
      m1_next =1 ;
      m2_next =1 ;
      s1_next =1 ;
      s2_next =1 ;    
  end
  else begin  
 
      if (axi_m_wready && axi_m_wvalid && axi_m_wlast && !m1_next) begin
         m1_next = 1 ;
      end
      else if (axi_m_wready && axi_m_wvalid && m1_next) begin // Capture 1st in frame
         m1_next = axi_m_wlast ;
         mw_time = $time;
         $fwrite (f1, "Write last data from master driver: %h, %t, %d\n", axi_m_wdata, $time, mw_time);  
      end
      
      if (axi_s_wready && axi_s_wvalid && axi_s_wlast && !s1_next) begin
         s1_next = 1 ;
      end
      else if (axi_s_wready && axi_s_wvalid && s1_next) begin // Capture 1st in frame
         s1_next = axi_s_wlast ;
         sw_time = $time ;
         $fwrite (f2, "Write last data to slave receiver: %h, %t, %d\n", axi_s_wdata, $time, sw_time);  
      end
      
      if (axi_s_rready && axi_s_rvalid && axi_s_rlast && !s2_next) begin
         s2_next = 1 ;
      end
      else if (axi_s_rready && axi_s_rvalid && s2_next) begin // Capture 1st in frame
         s2_next = axi_s_rlast ;
         sr_time = $time ;
         $fwrite (f3, "Read last data from slave driver: %h, %t, %d\n", axi_s_rdata, $time, sr_time);  
      end
      
      if (axi_m_rready && axi_m_rvalid && axi_m_rlast && !m2_next) begin
         m2_next = 1 ;
      end
      else if (axi_m_rready && axi_m_rvalid && m2_next) begin // Capture 1st in frame
         m2_next = axi_m_rlast ;
         mr_time = $time ;
         $fwrite (f4, "Read last data to master receiver: %h, %t, %d\n", axi_m_rdata, $time, mr_time);  
      end
  end
end      
  `ifdef EXT_DRV_JTAG
     assign m_tdi         =  m_tdi_in  ;
     assign m_tck         =  m_tck_in  ;
     assign m_tms         =  m_tms_in  ;
     assign m_trstn       =  m_trstn_in;
     assign m_tdo_out     =  m_tdo;
     
     assign s_tdi         =  s_tdi_in  ;
     assign s_tck         =  s_tck_in  ;
     assign s_tms         =  s_tms_in  ;
     assign s_trstn       =  s_trstn_in;
     assign s_tdo_out     =  s_tdo;
  `endif

   assign m_por_trstn = aib_reset & m_trstn;
   assign s_por_trstn = aib_reset & s_trstn;

   //AXI-CPI Master Bridge 
   master_cpi_aib #(.DWIDTH(DWIDTH), .DISABLE_SDR(DISABLE_SDR), .ADDR_DID_WIDTH(ADDR_DID_WIDTH), 
                .CFG_ADDR_WIDTH(CFG_ADDR_WIDTH), .CFG_ADDR(CFG_ADDR), .AR_AWIDTH(AR_AWIDTH),
                .AR_IDWIDTH(AR_IDWIDTH), .AR_USRWIDTH(AR_USRWIDTH), .AW_AWIDTH(AW_AWIDTH),
                .AW_IDWIDTH(AW_IDWIDTH), .AW_USRWIDTH(AW_USRWIDTH), .W_DWIDTH(W_DWIDTH),
                .W_USRWIDTH(W_USRWIDTH), .R_IDWIDTH(R_IDWIDTH), .R_DWIDTH(R_DWIDTH),
                .R_USRWIDTH(R_USRWIDTH), .B_IDWIDTH(B_IDWIDTH), .B_USRWIDTH(B_USRWIDTH),
                .NUM_AXI_BURSTS(NUM_AXI_BURSTS), .NUM_CPI_FLITS(NUM_CPI_FLITS), .BFIFO_DEPTH(BFIFO_DEPTH),
                .RFIFO_DEPTH(RFIFO_DEPTH), .MAX_XFR_SIZE(MAX_XFR_SIZE), .SIZEFIT(SIZEFIT),
                .CR_RTN_THRESH(CR_RTN_THRESH), .AXI_BURST_WAIT(AXI_BURST_WAIT),
                .CPI_BURST_WAIT(CPI_BURST_WAIT)
        ) i_master_cpi_aib
     (.clk               (sys_clk_m),
      .rx_rd_rstb        (m_aib_rstn),  // Reset is active low
      .tx_wr_rstb        (m_aib_rstn),
                         
      .cpi_source_id     (8'h5a),
                         
      .axi_m_araddr      (axi_m_araddr),
      .axi_m_arid        (axi_m_arid),
      .axi_m_arlen       (axi_m_arlen),
      .axi_m_arsize      (axi_m_arsize),
      .axi_m_arburst     (axi_m_arburst), // incr
      .axi_m_aruser      (8'b0),
      .axi_m_arlock      (1'b0),
      .axi_m_arqos       (4'b0),         // no QoS scheme
      .axi_m_arregion    (4'b0),
      .axi_m_arprot      (`AXI_PROT_DATA),
      .axi_m_arvalid     (axi_m_arvalid),
      .axi_m_arready     (axi_m_arready),
                         
      .axi_m_awaddr      (axi_m_awaddr),
      .axi_m_awid        (axi_m_awid),
      .axi_m_awlen       (axi_m_awlen),
      .axi_m_awsize      (axi_m_awsize),
      .axi_m_awburst     (axi_m_awburst), // incr
      .axi_m_awuser      (8'b0),
      .axi_m_awlock      (1'b0),
      .axi_m_awqos       (4'b0),          // no QoS scheme
      .axi_m_awregion    (4'b0),
      .axi_m_awprot      (`AXI_PROT_DATA),
      .axi_m_awvalid     (axi_m_awvalid),
      .axi_m_awready     (axi_m_awready),
                         
      .axi_m_wdata       (axi_m_wdata),
      .axi_m_wstrb       (axi_m_wstrb),
      .axi_m_wlast       (axi_m_wlast),
      .axi_m_wuser       (8'b0),
      .axi_m_wvalid      (axi_m_wvalid),
      .axi_m_wready      (axi_m_wready),
                         
      .axi_m_rid         (axi_m_rid),
      .axi_m_rdata       (axi_m_rdata),
      .axi_m_rlast       (axi_m_rlast),
      .axi_m_rresp       (axi_m_rresp),
      .axi_m_ruser       (),              //USER field not used
      .axi_m_rvalid      (axi_m_rvalid),
      .axi_m_rready      (axi_m_rready),
                         
      .axi_m_bid         (axi_m_bid),
      .axi_m_bresp       (axi_m_bresp),
      .axi_m_buser       (),              //USER field not used
      .axi_m_bvalid      (axi_m_bvalid),
      .axi_m_bready      (axi_m_bready),
                               
      .cr_init_delay     (64'h0       ),
      
      .rx_error          ( ),             // Error logging outputs     
      .rx_error_data     ( ),    
      .tx_rlen_error     ( ),    
      .tx_rlen_error_sz  ( ), 
      .tx_rlen_error_len ( ),
      .tx_wlen_error     ( ),    
      .tx_wlen_error_sz  ( ), 
      .tx_wlen_error_len ( ),
      
      // AIB             
      .ubump             (ubump_master),
                         
      .ubump_aux         (ubump_aux),
                         
      .tx_clk            (sys_clk_m),
      .rx_clk            (),
                         
   // AIB CONF_DONE
      .conf_done          (conf_done),     // Active hi input
      .config_done        (config_done_m), // Active hi output
   
      .device_detect_ovrd (1'b 0),
   
      .por_ovrd           (1'b 1),
                                
   // APB Slave Interface
   //
      .pclk               (pclk_m),
      .presetn            (aib_reset),
      .paddr              (paddr_m),
      .pwrite             (pwrite_m),
      .psel               (psel_m),
      .penable            (penable_m),
      .pwdata             (pwdata_m),
      .prdata             (prdata_m),
      .pready             (pready_m),

   // JTAG Interface
   //
      .tdi                (m_tdi),      // test data in     (JTAG)
      .tck                (m_tck),      // test clock       (JTAG)
      .tms                (m_tms),      // test mode select (JTAG)
      .tdo                (m_tdo),      // test data out    (JTAG)

      .trstn_or_por_rstn  (m_por_trstn),
      .aib_rstn           (m_aib_rstn),
   
      .dig_test_sel      (1'b0),
      .dig_test_bus      ()
     );
// Data assignments, master to slave      
assign ubump_slave[89] = ubump_master[50];
assign ubump_slave[88] = ubump_master[51];
assign ubump_slave[87] = ubump_master[52];
assign ubump_slave[86] = ubump_master[53];
assign ubump_slave[85] = ubump_master[54];
assign ubump_slave[84] = ubump_master[55];
assign ubump_slave[83] = ubump_master[56];
assign ubump_slave[82] = ubump_master[57];
assign ubump_slave[81] = ubump_master[58];
assign ubump_slave[80] = ubump_master[59];
assign ubump_slave[79] = ubump_master[60];
assign ubump_slave[78] = ubump_master[61];
assign ubump_slave[77] = ubump_master[62];
assign ubump_slave[76] = ubump_master[63];
assign ubump_slave[75] = ubump_master[64];
assign ubump_slave[74] = ubump_master[65];
assign ubump_slave[73] = ubump_master[66];
assign ubump_slave[72] = ubump_master[67];
assign ubump_slave[71] = ubump_master[68];
assign ubump_slave[70] = ubump_master[69];
assign ubump_slave[49] = ubump_master[0 ];
assign ubump_slave[48] = ubump_master[1 ];
assign ubump_slave[47] = ubump_master[2 ];
assign ubump_slave[46] = ubump_master[3 ];
assign ubump_slave[45] = ubump_master[4 ];
assign ubump_slave[44] = ubump_master[5 ];
assign ubump_slave[43] = ubump_master[6 ];
assign ubump_slave[42] = ubump_master[7 ];
assign ubump_slave[41] = ubump_master[8 ];
assign ubump_slave[40] = ubump_master[9 ];
assign ubump_slave[37] = ubump_master[12];
assign ubump_slave[36] = ubump_master[13];
assign ubump_slave[35] = ubump_master[14];
assign ubump_slave[34] = ubump_master[15];
assign ubump_slave[33] = ubump_master[16];
assign ubump_slave[32] = ubump_master[17];
assign ubump_slave[31] = ubump_master[18];
assign ubump_slave[30] = ubump_master[19];
assign ubump_slave[29] = ubump_master[20];
assign ubump_slave[28] = ubump_master[21];

// Data assignments, slave to master      
assign ubump_master[89] = ubump_slave[50];
assign ubump_master[88] = ubump_slave[51];
assign ubump_master[87] = ubump_slave[52];
assign ubump_master[86] = ubump_slave[53];
assign ubump_master[85] = ubump_slave[54];
assign ubump_master[84] = ubump_slave[55];
assign ubump_master[83] = ubump_slave[56];
assign ubump_master[82] = ubump_slave[57];
assign ubump_master[81] = ubump_slave[58];
assign ubump_master[80] = ubump_slave[59];
assign ubump_master[79] = ubump_slave[60];
assign ubump_master[78] = ubump_slave[61];
assign ubump_master[77] = ubump_slave[62];
assign ubump_master[76] = ubump_slave[63];
assign ubump_master[75] = ubump_slave[64];
assign ubump_master[74] = ubump_slave[65];
assign ubump_master[73] = ubump_slave[66];
assign ubump_master[72] = ubump_slave[67];
assign ubump_master[71] = ubump_slave[68];
assign ubump_master[70] = ubump_slave[69];
assign ubump_master[49] = ubump_slave[0 ];
assign ubump_master[48] = ubump_slave[1 ];
assign ubump_master[47] = ubump_slave[2 ];
assign ubump_master[46] = ubump_slave[3 ];
assign ubump_master[45] = ubump_slave[4 ];
assign ubump_master[44] = ubump_slave[5 ];
assign ubump_master[43] = ubump_slave[6 ];
assign ubump_master[42] = ubump_slave[7 ];
assign ubump_master[41] = ubump_slave[8 ];
assign ubump_master[40] = ubump_slave[9 ];
assign ubump_master[37] = ubump_slave[12];
assign ubump_master[36] = ubump_slave[13];
assign ubump_master[35] = ubump_slave[14];
assign ubump_master[34] = ubump_slave[15];
assign ubump_master[33] = ubump_slave[16];
assign ubump_master[32] = ubump_slave[17];
assign ubump_master[31] = ubump_slave[18];
assign ubump_master[30] = ubump_slave[19];
assign ubump_master[29] = ubump_slave[20];
assign ubump_master[28] = ubump_slave[21];

// Resets
assign ubump_slave[27] = ubump_master[22];
assign ubump_slave[26] = ubump_master[23];

assign ubump_master[27] = ubump_slave[22];
assign ubump_master[26] = ubump_slave[23];

// Clocks
assign ubump_slave[39] = ubump_master[10];
assign ubump_slave[38] = ubump_master[11];

assign ubump_master[39] = ubump_slave[10];
assign ubump_master[38] = ubump_slave[11];

// Spares
//assign ubump_slave[24]  = ubump_master[25];
//assign ubump_slave[25]  = ubump_master[24];

//assign ubump_master[24]  = ubump_slave[25];
//assign ubump_master[25]  = ubump_slave[24];

assign ubump_slave[24]  = 1'bz;
assign ubump_slave[25]  = 1'bz;

assign ubump_master[24]  =1'bz;
assign ubump_master[25]  =1'bz;

   //AXI-CPI Slave Bridge 
   slave_cpi_aib #(.DWIDTH(DWIDTH), .DISABLE_SDR(DISABLE_SDR), .ADDR_DID_WIDTH(ADDR_DID_WIDTH),
                .CFG_ADDR_WIDTH(CFG_ADDR_WIDTH), .CFG_ADDR(CFG_ADDR), .AR_AWIDTH(AR_AWIDTH),
                .AR_IDWIDTH(AR_IDWIDTH), .AR_USRWIDTH(AR_USRWIDTH), .AW_AWIDTH(AW_AWIDTH),
                .AW_IDWIDTH(AW_IDWIDTH), .AW_USRWIDTH(AW_USRWIDTH), .W_DWIDTH(W_DWIDTH),
                .W_USRWIDTH(W_USRWIDTH), .R_IDWIDTH(R_IDWIDTH), .R_DWIDTH(R_DWIDTH),
                .R_USRWIDTH(R_USRWIDTH), .B_IDWIDTH(B_IDWIDTH), .B_USRWIDTH(B_USRWIDTH),
                .NUM_AXI_BURSTS(NUM_AXI_BURSTS), .NUM_CPI_FLITS(NUM_CPI_FLITS),
                .MAX_XFR_SIZE(MAX_XFR_SIZE), .SIZEFIT(SIZEFIT),
                .CR_RTN_THRESH(CR_RTN_THRESH), .AXI_BURST_WAIT(AXI_BURST_WAIT),
                .CPI_BURST_WAIT(CPI_BURST_WAIT)
                ) i_slave_cpi_aib
     (.clk                (sys_clk_s_gen), // Clock is wrapped back from slave AIB
      .rx_rd_rstb         (s_aib_rstn),    // Reset is active low
      .tx_wr_rstb         (s_aib_rstn),
                          
      .axi_s_araddr       (axi_s_araddr  ),
      .axi_s_arid         (axi_s_arid    ),
      .axi_s_arlen        (axi_s_arlen   ),
      .axi_s_arsize       (axi_s_arsize  ),
      .axi_s_arburst      (axi_s_arburst ),
      .axi_s_aruser       (   ),
      .axi_s_arlock       (   ),
      .axi_s_arqos        (    ),
      .axi_s_arregion     ( ),
      .axi_s_arprot       (   ),
      .axi_s_arvalid      (axi_s_arvalid ),
      .axi_s_arready      (axi_s_arready ), 
                           
      .axi_s_awaddr       (axi_s_awaddr  ),
      .axi_s_awid         (axi_s_awid    ),
      .axi_s_awlen        (axi_s_awlen   ),
      .axi_s_awsize       (axi_s_awsize  ),
      .axi_s_awburst      (axi_s_awburst ),
      .axi_s_awuser       (   ),
      .axi_s_awlock       (   ),
      .axi_s_awqos        (    ),
      .axi_s_awregion     ( ),
      .axi_s_awprot       (   ),
      .axi_s_awvalid      (axi_s_awvalid ),
      .axi_s_awready      (axi_s_awready ),
                           
      .axi_s_wdata        (axi_s_wdata   ),
      .axi_s_wstrb        (axi_s_wstrb   ),
      .axi_s_wlast        (axi_s_wlast   ),
      .axi_s_wuser        (    ),
      .axi_s_wvalid       (axi_s_wvalid  ),
      .axi_s_wready       (axi_s_wready  ),
                           
      .axi_s_rid          (axi_s_rid     ),
      .axi_s_rdata        (axi_s_rdata   ),
      .axi_s_rlast        (axi_s_rlast   ),
      .axi_s_rresp        (axi_s_rresp   ),
      .axi_s_ruser        (axi_s_ruser   ),
      .axi_s_rvalid       (axi_s_rvalid  ),
      .axi_s_rready       (axi_s_rready  ),
                           
      .axi_s_bid          (axi_s_bid     ),
      .axi_s_bresp        (axi_s_bresp   ),
      .axi_s_buser        (5'h0          ),
      .axi_s_bvalid       (axi_s_bvalid  ),
      .axi_s_bready       (axi_s_bready  ),
                          
      .cr_init_delay      (64'h0         ),
      
      .rx_error          ( ),                  // Error logging outputs   
      .rx_error_data     ( ),    
      .tx_rlen_error     ( ),    
      .tx_rlen_error_sz  ( ), 
      .tx_rlen_error_len ( ),
      // AIB                  
      .ubump              ({ubump_slave[89:26], ubump_master[24], ubump_master[25], ubump_slave[23:0]}),
                          
      .ubump_aux          (ubump_aux),

       .tx_clk             (sys_clk_s_gen),
       .rx_clk             (sys_clk_s_gen),    // Output: generated from sys_clk_m through bumps
                          
   // AIB CONF_DONE
      .conf_done          (conf_done),         // Active hi input
      .config_done        (config_done_s),     // Active hi output
   
      .device_detect_ovrd (1'b 0),
   
      .por_ovrd           (1'b 1),
                                
   // APB Slave Interface
   //
      .pclk               (pclk_s),
      .presetn            (aib_reset),
      .paddr              (paddr_s),
      .pwrite             (pwrite_s),
      .psel               (psel_s),
      .penable            (penable_s),
      .pwdata             (pwdata_s),
      .prdata             (prdata_s),
      .pready             (pready_s),

   // JTAG Interface
   //
      .tdi                (s_tdi),      // test data in     (JTAG)
      .tck                (s_tck),      // test clock       (JTAG)
      .tms                (s_tms),      // test mode select (JTAG)
      .tdo                (s_tdo),      // test data out    (JTAG)

      .trstn_or_por_rstn  (s_por_trstn),
      .aib_rstn           (s_aib_rstn),
   
      .dig_test_sel      (1'b0),
      .dig_test_bus      ()
      );
        
endmodule // axim_cpi_aib_aib_cpi_axis
