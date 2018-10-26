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
-- Simplified check sum module.
-- Supposed IP header at begining (0 to lengh*16). Lenght 5 to 11. Length position 3 downto 0 
-- register input and outputs
--
-- Using ternary 32 bits adder tree
-- Avoids final negation using a substractor (needs to have a formal verification!!!!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_IP_header_Tadd01b is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_IP_header_Tadd01b;


--------------
-- Ternary adders
architecture Tern_Add_v1b of cksum_IP_header_Tadd01b is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 14) of unsigned (31 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 4) of unsigned (33 downto 0);
  signal sumData_L1 : chk_sum_L1_type;

  type chk_sum_L2_type is array (0 to 1) of unsigned (35 downto 0);
  signal sumData_L2 : chk_sum_L2_type;

  signal sumData_L3 : unsigned (35 downto 0);
  
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
        for i in 0 to 14 loop --Maximun 60 btes
            if (i < len) then
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*32 + 7 downto i*32));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*32 + 15 downto i*32+8));  
            else  PktData_reg(i)(15 downto 0) <= (others => '0');  
            end if;
            if (i < len) and (i/=2) then --do not capture checksum
                        PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*32 + 31 downto i*32+24));
                        PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*32 + 23 downto i*32+16));
            else  PktData_reg(i)(31 downto 16) <= (others => '0');  
            end if;
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(sumFinal(15 downto 0));
        
      end if;
    end process;


L1_sums: for i in 0 to 4 generate
      sumData_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);
end generate;

sumData_L2(0) <= ("00" & sumData_L1(2)) + sumData_L1(1) + sumData_L1(0);
sumData_L2(1) <= ("00" & sumData_L1(3)) + sumData_L1(4);

sumData_L3 <= sumData_L2(0) + sumData_L2(1);

sumData_L4 <=  ("00" & sumData_L3(15 downto 0)) + sumData_L3(31 downto 16) + sumData_L3(35 downto 32);

sumFinal <=  ("11" & x"FFFF") - ("00" & sumData_L4(15 downto 0)) - (x"0000" & sumData_L4(17 downto 16));

 
end Tern_Add_v1b;
