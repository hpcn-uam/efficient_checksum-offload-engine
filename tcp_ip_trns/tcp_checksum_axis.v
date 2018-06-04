//==================================================================================================
// -----------------------------------------------------------------------------
// Copyright (c) 2018 All rights reserved
// -----------------------------------------------------------------------------
//  Filename      : tcp_checksum_axis.v
//  Author        : Mario Daniel Ruiz Noguera
//  Company       : HPCN-UAM
//  Email         : mario.ruiz@uam.es
//  Created On    : 2018-05-13 10:48:30
//  Last Modified : 2018-06-02 18:23:07
//
//  Revision      : 1.0
//
//  Description   :
//==================================================================================================

module tcp_checksum_axis #(
  parameter integer VERIFY_KEEP = 1

) (

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
    reg  [ 15:  0]              previous_computation;


    /* Stage 0*/
    
    reg [511:  0]               input_data_i;
    wire                        input_valid;
    integer                     i;

    assign input_valid = S_AXIS_TVALID && S_AXIS_TREADY;

    assign S_AXIS_TREADY = 1'b1/*M_AXIS_TREADY*/;


    /* To assure that only the valid data is taken into account */
    generate
      if (VERIFY_KEEP == 1) begin
        always @(*) begin
            for (i = 0 ; i < 64 ; i=i+1) begin
                if (S_AXIS_TKEEP[i]) begin
                    input_data_i[i*8 +: 8] = S_AXIS_TDATA[i*8 +:8];
                end
                else begin
                    input_data_i[i*8 +: 8] = 8'h0;
                end
            end
        end
      end
      else begin
        always @(*) begin
          input_data_i = S_AXIS_TDATA;
        end
      end
      
    endgenerate


    always @(posedge clk) begin
        if (~rst_n) begin
            previous_computation <= 16'h0;                
        end
        else begin
            if (S_AXIS_TVALID && S_AXIS_TREADY) begin
                if (S_AXIS_TLAST) begin
                    previous_computation <= 16'h0;                        
                end
                else begin
                    previous_computation <= result_computation_i;
                end
            end
        end
    end


    always @(posedge clk) begin
        if (~rst_n) begin
            M_AXIS_TDATA    <= 16'h0;
            M_AXIS_TVALID   <= 1'b0;
        end
        else begin
            M_AXIS_TVALID <= M_AXIS_TVALID & !M_AXIS_TREADY; 
            if (S_AXIS_TVALID && S_AXIS_TREADY && S_AXIS_TLAST) begin
                M_AXIS_TDATA    <= ~result_computation_i;
                M_AXIS_TVALID   <= 1'b1;
            end
        end
    end


    cksum_528_r03 #(
        .REGISTER_INPUT_DATA(0)
    )
    checksum_i ( 
       .SysClk_in   (                    clk),
       .PktData     (           input_data_i),
       .pre_cks     (   previous_computation),
       .ChksumFinal (   result_computation_i)
    );

endmodule