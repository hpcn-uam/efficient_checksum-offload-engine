----------------------------------------------------------------------------------
-- Simplified check C1 adder module.
-- Reduce 512 data plus 16bits
-- 
-- register input and outputs
--
-- Uses binary adders. 32 bits width
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_528_bin32 is
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_bin32;


--------------
-- binary adders
architecture binary_tree of cksum_528_bin32 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 15) of unsigned (31 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 7) of unsigned (32 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 3) of unsigned (33 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  type chk_sum_L3_type is array (0 to 1) of unsigned (34 downto 0);
  signal sum_L3 : chk_sum_L3_type;
  
  signal sum_L4 : unsigned (35 downto 0);
 
  signal sum_L6 : unsigned (17 downto 0);

  signal sumFinal : unsigned (16 downto 0);
    
  signal sumPrev : unsigned (16 downto 0);
    
  signal pre_cks_reg : unsigned (15 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then 
        for i in 0 to 15 loop --
			PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*32 + 7 downto i*32));
			PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*32 + 15 downto i*32+8));  	
			PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*32 + 31 downto i*32+24));
			PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*32 + 23 downto i*32+16));
        end loop;
		pre_cks_REG <= unsigned(pre_cks);
        ChksumFinal <= STD_LOGIC_VECTOR(sumFinal(15 downto 0));
        
      end if;
    end process;


  -- First level of reduction
  L_1: for i in 0 to 7 generate 
        sum_L1(i) <= ('0' & PktData_reg(2*i+1)) + ('0' & PktData_reg(2*i));			  			  
  end generate;

  L_2: for i in 0 to 3 generate 
		sum_L2(i) <= ('0' & sum_L1(2*i+1)) + ('0' & sum_L1(2*i));                
  end generate;

  L_3: for i in 0 to 1 generate 
		sum_L3(i) <= ('0' & sum_L2(2*i+1)) + ('0' & sum_L2(2*i));                
  end generate;
  
  sum_L4 <= ('0' & sum_L3(1)) + ('0' & sum_L3(0));
  
  sum_L6 <= ( ("00" & sum_L4(15 downto 0)) + pre_cks_REG ) + (sum_L4(31 downto 16) + sum_L4(35 downto 32));
  
  --sumFinal <=  ('0' & sum_L5(15 downto 0)) + sum_L5(18 downto 16);
  
  sumPrev <=  ('0' & sum_L6(15 downto 0)) + sum_L6(17 downto 16);
  
  sumFinal <=  ('0' & sumPrev(15 downto 0)) + sumPrev(16 downto 16);
 

 
end binary_tree;
