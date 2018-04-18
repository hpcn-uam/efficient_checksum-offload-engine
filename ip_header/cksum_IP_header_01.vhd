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

entity cksum_IP_header_01 is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_IP_header_01;

architecture Behavioral of cksum_IP_header_01 is

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
		    if i = 5 then
			  PktData_reg(i)(15 downto 0) <= (others => '0');
			else
            PktData_reg(i)(15 downto 8) <= unsigned(PktData(i*16 + 7 downto i*16));
            PktData_reg(i)(7 downto 0) <= unsigned(PktData(i*16 + 15 downto i*16+8));  
			end if;
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

