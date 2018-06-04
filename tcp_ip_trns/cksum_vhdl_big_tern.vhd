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

entity cksum_528_ter01 is
    generic (
          REGISTER_INPUT_DATA : integer :=1
    );
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_ter01;


--------------
-- Ternary adders
architecture ternary_tree of cksum_528_ter01 is

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 10) of unsigned (17 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 2) of unsigned (19 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  signal sum_L3 : unsigned (20 downto 0); --3x-3x3 = 27. 5 bits
  
  signal sum_L4 : unsigned (21 downto 0);  

  signal sumPrev : unsigned (16 downto 0);
  
  signal sumFinal : unsigned (16 downto 0);
  
  signal pre_cks_reg : unsigned (15 downto 0);
  
begin

    sys_clk <= SysClk_in;  
     
    register_inputs : if (REGISTER_INPUT_DATA = 1) generate
    begin
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
    end generate;

    no_register_inputs : if (REGISTER_INPUT_DATA = 0) generate
    begin
      --Input Registers
      inp_no_reg: process (PktData)
      begin
        for i in 0 to 31 loop --
          PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*16 + 7 downto i*16));
          PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*16 + 15 downto i*16+8));  
        end loop;
      end process;
      pre_cks_REG <= unsigned(pre_cks);
      ChksumFinal <= STD_LOGIC_VECTOR(sumFinal(15 downto 0));
    end generate;


  -- First level of reduction
  L_1: for i in 0 to 9 generate 
        sum_L1(i) <= ("00" & PktData_reg(3*i+2)) + PktData_reg(3*i+1) + PktData_reg(3*i);			  			  
  end generate;
  
  sum_L1(10) <= ("00" & pre_cks_REG) + PktData_reg(31) + PktData_reg(30);

  L_2: for i in 0 to 2 generate             
        sum_L2(i) <= ("00" & sum_L1(3*i+2)) + sum_L1(3*i+1) + sum_L1(3*i);
  end generate;

  L_3: sum_L3 <= ('0' & sum_L2(2)) + sum_L2(1) + sum_L2(0);
  
  L_4: sum_L4 <= ('0' & sum_L3) + sum_L1(10) + sum_L1(9);
  
  sumPrev <=  ('0' & sum_L4(15 downto 0)) + sum_L4(21 downto 16);
  
  sumFinal <=  ('0' & sumPrev(15 downto 0)) + sumPrev(16 downto 16);

 
end ternary_tree;
