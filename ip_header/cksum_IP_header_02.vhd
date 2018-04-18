----------------------------------------------------------------------------------
-- Simplified check sum module.
-- Supposed IP header at begining (0 to lengh*16). Lenght 5 to 11. Length position 3 downto 0 
-- register input and outputs
--
-- Naive binary version 2. Captures selectively
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_IP_header_02 is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_IP_header_02;


architecture Beh2 of cksum_IP_header_02 is

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
            if (i/=2) then  --do not capture checksum
            PktData_reg(i)(23 downto 16) <= unsigned(PktData(i*32 + 31 downto i*32+24));
            PktData_reg(i)(31 downto 24) <= unsigned(PktData(i*32 + 23 downto i*32+16));
            else  PktData_reg(i)(31 downto 16) <= (others => '0');  
            end if;
        end loop;
        headerLen <= unsigned(PktData(3 downto 0));
        ChksumFinal <= STD_LOGIC_VECTOR(not(sumFinal));
        
      end if;
    end process;


L1_sums: for i in 0 to 6 generate
   process(PktData_reg)
   begin
       if (i*2+1 = headerLen) then
          sumData_L1(i) <= ('0' & PktData_reg(2*i));
       elsif (i*2 < headerLen) then
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



