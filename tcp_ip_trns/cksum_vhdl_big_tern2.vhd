-- ************************************************
-- BSD 3-Clause License
-- 
-- Copyright (c) 2019, HPCN Group, UAM Spain (hpcn-uam.es)
-- and Systems Group, ETH Zurich (systems.ethz.ch)
-- All rights reserved.
-- 
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of the copyright holder nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- ************************************************/

----------------------------------------------------------------------------------
-- Simplified check C1 adder module.
-- Reduce 512 data plus 16bits
-- 
-- register input and outputs
--
-- Uses ternary adders
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_528_ter02 is
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_ter02;


--------------
-- Ternary adders
architecture ternary_tree of cksum_528_ter02 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 10) of unsigned (17 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 2) of unsigned (19 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  signal sum_L3 : unsigned (21 downto 0);  --3x3x3 = 27 elem. Add one more 4 regularity
  
  signal sum_L4 : unsigned (21 downto 0);  

  signal sumPrev : unsigned (16 downto 0);
  
  signal sumFinal : unsigned (16 downto 0);
  
  signal pre_cks_reg : unsigned (15 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 31 loop --
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*16 + 7 downto i*16));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*16 + 15 downto i*16+8));  
        end loop;
		pre_cks_REG <= unsigned(pre_cks);
        ChksumFinal <= STD_LOGIC_VECTOR(sumFinal(15 downto 0));
      end if;
    end process;


  -- First level of reduction
  L_1: for i in 0 to 9 generate 
        sum_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);			  			  
  end generate;
  
  sum_L1(10) <= ("00" & pre_cks_REG) + PktData_reg(31) + PktData_reg(30);

  L_2: for i in 0 to 2 generate             
        sum_L2(i) <= ("00" & sum_L1(3*i+2)) + sum_L1(3*i+1) + sum_L1(3*i);
  end generate;



  L_3: sum_L3 <= ("00" & sum_L2(2)) + sum_L2(1) + sum_L2(0);
  
  L_4: sum_L4 <= (sum_L3) + sum_L1(10) + sum_L1(9);
  
--  sum_L2(3) <= ("00" & sum_L1(10)) + sum_L1(9);
  
--  L_3: sum_L3 <= ('0' & sum_L2(2)) + sum_L2(1) + sum_L2(0);
  
--  L_4: sum_L4 <= ('0' & sum_L3) + sum_L2(3);
  
  sumPrev <=  ('0' & sum_L4(15 downto 0)) + sum_L4(21 downto 16);
  
  sumFinal <=  ('0' & sumPrev(15 downto 0)) + sumPrev(16 downto 16);

 
end ternary_tree;
