----------------------------------------------------------------------------------
-- Simplified check C1 adder module.
-- Reduce 512 data plus 16bits
-- 
-- register input and outputs
--
-- Uses binary adders and Näive implementation (No adder Tree)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_528_simple is
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_simple;


--------------
-- simple
architecture simple of cksum_528_simple is

  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  signal sys_clk : STD_LOGIC := '0';  
  
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

  chck_sumProc: Process(PktData_reg, pre_cks_REG)
	variable sum_elems : unsigned (21 downto 0); --Since we are adding 33 numbers, results 6 extra bits
	variable sumIntern : unsigned (16 downto 0);
  begin
    sum_elems := "000000" & pre_cks_REG;
    for i in 0 to 31 loop
	  sum_elems := sum_elems + PktData_reg(i);
	end loop;
	
	sumIntern := ('0' & sum_elems(15 downto 0)) + sum_elems(20 downto 16);
	sumFinal <= ('0' & sumIntern(15 downto 0)) + ('0' & sumIntern(16));
     
  end process;
 
end simple;
