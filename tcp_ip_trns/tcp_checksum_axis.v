//==================================================================================================
// -----------------------------------------------------------------------------
// Copyright (c) 2018 All rights reserved
// -----------------------------------------------------------------------------
//  Filename      : tcp_checksum_axis.v
//  Author        : Mario Daniel Ruiz Noguera
//  Company       : HPCN-UAM
//  Email         : mario.ruiz@uam.es
//  Created On    : 2018-05-13 10:48:30
//  Last Modified : 2018-07-05 16:30:35
//
//  Revision      : 1.0
//
//  Description   :
//==================================================================================================

module tcp_checksum_axis (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS:M_AXIS, ASSOCIATED_RESET rst_n" *)
  input  wire                           clk            ,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                           rst_n          ,

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)  
  input wire [    511 : 0]              S_AXIS_TDATA,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
  input wire [     63 : 0]              S_AXIS_TKEEP,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)    
  input wire                            S_AXIS_TVALID,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)    
  input wire                            S_AXIS_TLAST,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)      
  output wire                           S_AXIS_TREADY,

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
  output reg [     15 : 0]              M_AXIS_TDATA,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)  
  output reg                            M_AXIS_TVALID,
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)  
  input wire                            M_AXIS_TREADY

);


    wire [ 15:  0]              result_computation_i;
    reg  [ 15:  0]              previous_computation = 16'h0;


    /* Stage 0*/
    
    reg [511:  0]               data_r;
    reg                         valid_r;
    reg                         ready_r;
    reg                         last_r;
    integer                     i;

    /* If the channel is busy clear s_ready*/
    assign S_AXIS_TREADY = !M_AXIS_TVALID | M_AXIS_TREADY;

    /* Register data in and verify keep signal to ensure that only the valid data is taken into account */
    always @(posedge clk) begin
      for (i = 0 ; i < 64 ; i=i+1) begin
        if (S_AXIS_TKEEP[i]) begin
          data_r[i*8 +: 8] <= S_AXIS_TDATA[i*8 +:8];
        end
        else begin
          data_r[i*8 +: 8] <= 8'h0;
        end
      end
      valid_r   <= S_AXIS_TVALID;
      ready_r   <= S_AXIS_TREADY;
      last_r    <= S_AXIS_TLAST;
    end

    /* Register the output of the checksum computation, that it is the current checksum
       and clear it when the packet finishes*/
    always @(posedge clk) begin
      if (valid_r && ready_r) begin
        if (last_r) begin
          previous_computation <= 16'h0;                        
        end
        else begin
          previous_computation <= result_computation_i;
        end
      end
    end

    /* Write the checksum when a last is received, also keep valid set until the data is consumed*/
    always @(posedge clk) begin
      if (~rst_n) begin
        M_AXIS_TDATA    <= 16'h0;
        M_AXIS_TVALID   <= 1'b0;
      end
      else begin
        M_AXIS_TVALID <= M_AXIS_TVALID & !M_AXIS_TREADY; 
        if (valid_r && ready_r && last_r) begin
          M_AXIS_TDATA    <= ~result_computation_i;
          M_AXIS_TVALID   <= 1'b1;
        end
      end
    end


    cksum_528_r03 #(
      .REGISTER_INPUT_DATA(               0)
    )
    checksum_i ( 
      .SysClk_in   (                    clk),
      .PktData     (                 data_r),
      .pre_cks     (   previous_computation),
      .ChksumFinal (   result_computation_i)
    );

endmodule