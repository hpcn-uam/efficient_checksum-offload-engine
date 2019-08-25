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
-- Naive binary version
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_IP_header is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_IP_header;

architecture Behavioral of cksum_IP_header is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 29) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  type chk_sum_L1_type is array (0 to 14) of unsigned (16 downto 0);
  signal sumData_L1 : chk_sum_L1_type;
  type chk_sum_L2_type is array (0 to 7) of unsigned (17 downto 0);
  signal sumData_L2 : chk_sum_L2_type;
  type chk_sum_L3_type is array (0 to 3) of unsigned (18 downto 0);
  signal sumData_L3 : chk_sum_L3_type;
  type chk_sum_L4_type is array (0 to 1) of unsigned (19 downto 0);
  signal sumData_L4 : chk_sum_L4_type;
  
  signal sumData_L5 : unsigned (20 downto 0);
  signal sumData_L6 : unsigned (16 downto 0);
  signal sumFinal   : unsigned (15 downto 0);
  
  signal headerLen : unsigned (3 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 29 loop --Maximun 60 bytes
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*16 + 7 downto i*16));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*16 + 15 downto i*16+8));  
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        
      end if;
    end process;


L1_sums: for i in 0 to 14 generate
   process(PktData_reg)
   begin
   if (i < headerLen) then
      sumData_L1(i) <= ('0' & PktData_reg(2*i)) + PktData_reg(2*i+1);
   else
      sumData_L1(i) <= (others => '0');   
   end if;   
   end process;
end generate;

L2_sums: for i in 0 to 6 generate
   sumData_L2(i) <= ('0' & sumData_L1(2*i)) + sumData_L1(2*i+1);
end generate;
sumData_L2(7) <= ('0' & sumData_L1(14));

L3_sums: for i in 0 to 3 generate
   sumData_L3(i) <= ('0' & sumData_L2(2*i)) + sumData_L2(2*i+1);
end generate;

L4_sums: for i in 0 to 1 generate
   sumData_L4(i) <= ('0' & sumData_L3(2*i)) + sumData_L3(2*i+1);
end generate;

sumData_L5 <= ('0' & sumData_L4(0)) + sumData_L4(1);

sumData_L6 <=  ('0' & sumData_L5(15 downto 0)) + sumData_L5(20 downto 16);

sumFinal <=  (sumData_L6(15 downto 0)) + ('0' & sumData_L6(16));

end Behavioral;

--------------
--
architecture Beh2 of cksum_vhdl is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 14) of unsigned (31 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 7) of unsigned (32 downto 0);
  signal sumData_L1 : chk_sum_L1_type;

  type chk_sum_L2_type is array (0 to 3) of unsigned (33 downto 0);
  signal sumData_L2 : chk_sum_L2_type;

  type chk_sum_L3_type is array (0 to 1) of unsigned (34 downto 0);
  signal sumData_L3 : chk_sum_L3_type;
    

  signal sumData_L4 : unsigned (35 downto 0);
  
  signal sumData_L5 : unsigned (17 downto 0);
  signal sumFinal : unsigned (15 downto 0);
  
  signal headerLen : unsigned (3 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 14 loop --Maximun 60 btes
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*32 + 7 downto i*32));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*32 + 15 downto i*32+8));  
            PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*32 + 31 downto i*32+24));
            PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*32 + 23 downto i*32+16));  
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        
      end if;
    end process;


L1_sums: for i in 0 to 6 generate
   process(PktData_reg)
   begin
   if (i < headerLen/2) then
      sumData_L1(i) <= ('0' & PktData_reg(2*i+1)) + PktData_reg(2*i);
   else
      sumData_L1(i) <= (others => '0');   
   end if;   
   end process;
end generate;

   process(PktData_reg)
   begin
   if (headerLen = 15) then
      sumData_L1(7) <= ('0' & PktData_reg(14));
   else
      sumData_L1(7) <= (others => '0');   
   end if;   
   end process;

L2_sums: for i in 0 to 3 generate
   sumData_L2(i) <= ('0' & sumData_L1(2*i)) + sumData_L1(2*i+1);
end generate;


L3_sums: for i in 0 to 1 generate
   sumData_L3(i) <= ('0' & sumData_L2(2*i)) + sumData_L2(2*i+1);
end generate;


sumData_L4 <= ('0' & sumData_L3(0)) + sumData_L3(1);

sumData_L5 <=  ("00" & sumData_L4(15 downto 0)) + sumData_L4(31 downto 16) + sumData_L4(35 downto 32);

sumFinal <=  (sumData_L5(15 downto 0)) + (sumData_L5(17 downto 16));

end Beh2;










--------------
-- Ternary adders
architecture Tern_Add_v1 of cksum_vhdl is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 14) of unsigned (31 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 4) of unsigned (33 downto 0);
  signal sumData_L1 : chk_sum_L1_type;

  type chk_sum_L2_type is array (0 to 1) of unsigned (35 downto 0);
  signal sumData_L2 : chk_sum_L2_type;

  signal sumData_L3 : unsigned (35 downto 0);
  
  signal sumData_L4 : unsigned (17 downto 0);
  signal sumFinal : unsigned (15 downto 0);
  
  signal headerLen : unsigned (3 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 14 loop --Maximun 60 btes
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*32 + 7 downto i*32));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*32 + 15 downto i*32+8));  
            PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*32 + 31 downto i*32+24));
            PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*32 + 23 downto i*32+16));  
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        
      end if;
    end process;


L1_sums: for i in 0 to 4 generate
--   process(PktData_reg)
--   begin
--   if (i < headerLen/2) then
      sumData_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);
--   else
--      sumData_L1(i) <= (others => '0');   
--   end if;   
--   end process;
end generate;

sumData_L2(0) <= ("00" & sumData_L1(2)) + sumData_L1(1) + sumData_L1(0);
sumData_L2(1) <= ("00" & sumData_L1(3)) + sumData_L1(4);

sumData_L3 <= sumData_L2(0) + sumData_L2(1);

sumData_L4 <=  ("00" & sumData_L3(15 downto 0)) + sumData_L3(31 downto 16) + sumData_L3(35 downto 32);

sumFinal <=  (sumData_L4(15 downto 0)) + (sumData_L4(17 downto 16));

end Tern_Add_v1;

--------------
-- Ternary adders. 64 bit additions
architecture Tern_Add_v2 of cksum_vhdl is

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
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 6 loop --Maximun 60 bytes 7*8 = 56
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*64 + 7 downto i*64));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*64 + 15 downto i*64+8));  
            PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*64 + 31 downto i*64+24));
            PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*64 + 23 downto i*64+16));
            
            PktData_reg(i)(32+15 downto 32+8) <= unsigned(PktData(32+i*64 + 7 downto 32+i*64));
            PktData_reg(i)(32+7 downto 32+0) <= unsigned(PktData(32+i*64 + 15 downto 32+i*64+8));  
            PktData_reg(i)(32+23 downto 32+16) <= unsigned(PktData(32+i*64 + 31 downto 32+i*64+24));
            PktData_reg(i)(32+31 downto 32+24) <= unsigned(PktData(32+i*64 + 23 downto 32+i*64+16));    
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        
      end if;
    PktData_reg(7)(15 downto 8) <= unsigned(PktData(7*64 + 7 downto 7*64));
    PktData_reg(7)(7 downto 0) <= unsigned(PktData(7*64 + 15 downto 7*64+8));  
    PktData_reg(7)(23 downto 16) <= unsigned(PktData(7*64 + 31 downto 7*64+24));
    PktData_reg(7)(31 downto 24) <= unsigned(PktData(7*64 + 23 downto 7*64+16));
    PktData_reg(7)(63 downto 32) <= (others => '0');
    
    end process;



L1_sums: for i in 0 to 1 generate
      sumData_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);
end generate;
sumData_L1(2) <= ("00" & PktData_reg(7));

sumData_L2 <= ("00" & sumData_L1(0)) + sumData_L1(1) + sumData_L1(2);

sumData_L3 <= ("00" & sumData_L2(31 downto 0)) + sumData_L2(63 downto 32) + sumData_L2(67 downto 64);

sumData_L4 <=  ("00" & sumData_L3(15 downto 0)) + sumData_L3(31 downto 16) + sumData_L3(33 downto 32);

sumFinal <=  (sumData_L4(15 downto 0)) + (sumData_L4(17 downto 16));

end Tern_Add_v2;
