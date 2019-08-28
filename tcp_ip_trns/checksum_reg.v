/************************************************
BSD 3-Clause License

Copyright (c) 2019, HPCN Group, UAM Spain (hpcn-uam.es)
and Systems Group, ETH Zurich (systems.ethz.ch)
All rights reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

************************************************/


`timescale 1ns / 1ps

module checksum_reg (

  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF, ASSOCIATED_RESET rst_n" *)
  input  wire                           clk            ,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_n RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire                           rst_n          ,

  input wire [    511 : 0]              data,

  output reg [     16 : 0]              result

);


    reg  [ 15:  0]              resultWord0_r = 16'h0;
    reg  [ 15:  0]              resultWord1_r = 16'h0;
    reg  [ 15:  0]              resultWord2_r = 16'h0;
    wire [ 15:  0]              resultWord0_w;
    wire [ 15:  0]              resultWord1_w;
    wire [ 15:  0]              resultWord2_w;
    
    wire [ 15:  0]              result_computation_w;

    reg  [511:  0]              data_r;

    always @(posedge clk) begin
      data_r <= data;
    end

    /* Register the output of the checksum computation, that it is the current checksum
       and clear it when the packet finishes*/
    always @(posedge clk) begin
      resultWord0_r <= resultWord0_w;
      resultWord1_r <= resultWord1_w;
      resultWord2_r <= resultWord2_w;
    end

    /* Write the checksum when a last is received, also keep valid set until the data is consumed*/
    always @(posedge clk) begin
      result    <= result_computation_w;
    end


    checksumRed35to3  checksum_i ( 
      .currentData (              data_r),
      .prevWord0   (       resultWord0_r),
      .prevWord1   (       resultWord1_r),
      .prevWord2   (       resultWord2_r),

      .ResWord0    (       resultWord0_w),
      .ResWord1    (       resultWord1_w),
      .ResWord2    (       resultWord2_w),
      
      .result      (result_computation_w)
    );

endmodule