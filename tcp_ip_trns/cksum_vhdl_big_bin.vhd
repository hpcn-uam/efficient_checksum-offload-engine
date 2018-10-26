-- ************************************************
-- Copyright (c) 2018, HPCN Group, UAM Spain (hpcn-uam.es)
-- and Systems Group, ETH Zurich (systems.ethz.ch)
-- All rights reserved.
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
-- EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>
-- ************************************************/

----------------------------------------------------------------------------------
-- Simplified check C1 adder module.
-- Reduce 512 data plus 16bits
-- 
-- register input and outputs
--
-- Uses binary adders
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_528_bin01 is
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_bin01;


--------------
-- binary adders
architecture binary_tree of cksum_528_bin01 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 15) of unsigned (16 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 7) of unsigned (17 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  type chk_sum_L3_type is array (0 to 3) of unsigned (18 downto 0);
  signal sum_L3 : chk_sum_L3_type;
  
  type chk_sum_L4_type is array (0 to 1) of unsigned (19 downto 0);
  signal sum_L4 : chk_sum_L4_type;

  signal sum_L5 : unsigned (20 downto 0);

  signal sum_L6 : unsigned (21 downto 0);

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
  L_1: for i in 0 to 15 generate 
        sum_L1(i) <= ('0' & PktData_reg(2*i+1)) + ('0' & PktData_reg(2*i));			  			  
  end generate;

  L_2: for i in 0 to 7 generate 
		sum_L2(i) <= ('0' & sum_L1(2*i+1)) + ('0' & sum_L1(2*i));                
  end generate;

  L_3: for i in 0 to 3 generate 
		sum_L3(i) <= ('0' & sum_L2(2*i+1)) + ('0' & sum_L2(2*i));                
  end generate;
  
  L_4: for i in 0 to 1 generate 
		sum_L4(i) <= ('0' & sum_L3(2*i+1)) + ('0' & sum_L3(2*i));                
  end generate;
  
  sum_L5 <= ('0' & sum_L4(1)) + sum_L4(0);
  
  sum_L6 <= ('0' & sum_L5) + pre_cks_REG;
   
  sumPrev <=  ('0' & sum_L6(15 downto 0)) + sum_L6(21 downto 16);
  
  sumFinal <=  ('0' & sumPrev(15 downto 0)) + sumPrev(16 downto 16);
 
end binary_tree;
