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
-- Using ternary 64 bits adder tree
-- Avoids final negation using a substractor (needs to have a formal verification!!!!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_vhdl4 is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_vhdl4;


--------------
-- Ternary adders. 64 bit additions
architecture Tern_Add_v2 of cksum_vhdl4 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 7) of unsigned (63 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 2) of unsigned (65 downto 0);
  signal sumData_L1 : chk_sum_L1_type;

  signal sumData_L2 : unsigned (67 downto 0);
  
  signal sumData_L3 : unsigned (33 downto 0);
  
  signal sumData_L4 : unsigned (17 downto 0);
  signal sumFinal : unsigned (15 downto 0);
  
  signal headerLen : unsigned (3 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    variable Len : unsigned (3 downto 0);
    begin
      Len := unsigned(PktData(3 downto 0));  
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 6 loop --Maximun 60 bytes 7*8 = 56
            if (i*2 < len) then
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*64 + 7 downto i*64));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*64 + 15 downto i*64+8)); 
            else  PktData_reg(i)(15 downto 0) <= (others => '0'); 
            end if;     
            if (i*2 < len) and (i /= 1) then         
            PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*64 + 31 downto i*64+24));
            PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*64 + 23 downto i*64+16));
            else  PktData_reg(i)(31 downto 16) <= (others => '0'); 
            end if; 
            if (i*2+1 < len) then
            PktData_reg(i)(32+15 downto 32+8) <= unsigned(PktData(32+i*64 + 7 downto 32+i*64));
            PktData_reg(i)(32+7 downto 32+0) <= unsigned(PktData(32+i*64 + 15 downto 32+i*64+8));  
            PktData_reg(i)(32+23 downto 32+16) <= unsigned(PktData(32+i*64 + 31 downto 32+i*64+24));
            PktData_reg(i)(32+31 downto 32+24) <= unsigned(PktData(32+i*64 + 23 downto 32+i*64+16));    
            else  PktData_reg(i)(63 downto 32) <= (others => '0'); 
            end if;             
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        if (len = 15) then
        PktData_reg(7)(15 downto 8) <= unsigned(PktData(7*64 + 7 downto 7*64));
        PktData_reg(7)(7 downto 0) <= unsigned(PktData(7*64 + 15 downto 7*64+8));  
        PktData_reg(7)(23 downto 16) <= unsigned(PktData(7*64 + 31 downto 7*64+24));
        PktData_reg(7)(31 downto 24) <= unsigned(PktData(7*64 + 23 downto 7*64+16));
        else PktData_reg(7)(31 downto 0) <= (others => '0'); 
        end if;
        PktData_reg(7)(63 downto 32) <= (others => '0');        
      end if;
        
    end process;



L1_sums: for i in 0 to 1 generate
      sumData_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);
end generate;
sumData_L1(2) <= ("00" & PktData_reg(7)) + PktData_reg(6);

sumData_L2 <= ("00" & sumData_L1(0)) + sumData_L1(1) + sumData_L1(2);

sumData_L3 <= ("00" & sumData_L2(31 downto 0)) + sumData_L2(63 downto 32) + sumData_L2(67 downto 64);

sumData_L4 <=  ("00" & sumData_L3(15 downto 0)) + sumData_L3(31 downto 16) + sumData_L3(33 downto 32);

sumFinal <=  (sumData_L4(15 downto 0)) + (sumData_L4(17 downto 16));

end Tern_Add_v2;
