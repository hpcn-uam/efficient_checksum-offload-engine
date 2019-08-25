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
-- Simplified check sum module.
-- Supposed IP header at begining (0 to lengh*16). Lenght 5 to 11. Length position 3 downto 0 
-- register input and outputs
--
-- Using ternary 16 bits adder tree
-- Avoids final negation using a substractor (needs to have a formal verification!!!!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_vhdl5 is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_vhdl5;


--------------
-- Ternary adders
architecture Tern_Add_v1b of cksum_vhdl5 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 29) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 9) of unsigned (17 downto 0);
  signal sumData_L1 : chk_sum_L1_type;

  type chk_sum_L2_type is array (0 to 3) of unsigned (19 downto 0);
  signal sumData_L2 : chk_sum_L2_type;

  signal sumData_L3 : unsigned (21 downto 0);
  
  signal sumData_L4 : unsigned (17 downto 0);
  signal sumFinal : unsigned (17 downto 0);
  
  signal headerLen : unsigned (3 downto 0);
  
begin

    sys_clk <= SysClk_in;  
    
	    --Input Registers
    inp_reg: process (sys_clk)
    variable Len : unsigned (3 downto 0);
	begin
      if (sys_clk'event and sys_clk='1') then 
        Len := unsigned(PktData(3 downto 0));            
        for i in 0 to 29 loop --Maximun 60 bytes
            if (i < len*2) and (i/=5) then --do not capture checksum
			PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*16 + 7 downto i*16));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*16 + 15 downto i*16+8));  
			else  PktData_reg(i)(15 downto 0) <= (others => '0');  
            end if;
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(sumFinal(15 downto 0));
      end if;
    end process;

L1_sums: for i in 0 to 9 generate
      sumData_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);
end generate;

L2_sums: for i in 0 to 2 generate
      sumData_L2(i) <= ("00" & sumData_L1(3*i+2)) + sumData_L1(3*i+1) + sumData_L1(3*i);
end generate;
sumData_L2(3) <= ("00" & sumData_L1(9)); --Not used

sumData_L3 <= ("00" & sumData_L2(0)) + sumData_L2(1) + sumData_L2(2);

sumData_L4 <=  ("00" & sumData_L3(15 downto 0)) + sumData_L3(21 downto 16) + sumData_L1(9);
--Review posibble overflow.
--L1(9) < 10_1111xxx; 

sumFinal <=  ("11" & x"FFFF") - ("00" & sumData_L4(15 downto 0)) - (x"0000" & sumData_L4(17 downto 16));

 
end Tern_Add_v1b;
