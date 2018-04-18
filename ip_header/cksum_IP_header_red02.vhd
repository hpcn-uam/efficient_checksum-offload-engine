----------------------------------------------------------------------------------
-- Check sum module for IP header.
-- Supposed IP header at begining (0 to lengh*16). Lenght 5 to 11. Length position 3 downto 0 
-- register input and outputs
--
-- Using Reduction adder tree
-- Avoids final negation using a substractor (needs to have a formal verification!!!!)
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_IP_header_red01 is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_IP_header_red01;


--------------
-- Reducer Tree
architecture reducer_tree of cksum_IP_header_red01 is

component reducer_7to3 is port (
  x6, x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;

component reducer_6to3 is port (
  x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;


  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 14) of unsigned (31 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 5) of unsigned (31 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 2) of unsigned (31 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  type chk_sum_L3_type is array (0 to 2) of unsigned (15 downto 0);
  signal sum_L3 : chk_sum_L3_type;
  
  type chk_sum_L4_type is array (0 to 1) of unsigned (15 downto 0);
  signal sum_L4 : chk_sum_L4_type;

  --signal sum_L4 : unsigned (17 downto 0);

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


  -- First level of reduction
  L_1: for i in 0 to 31 generate 
    reduc1: reducer_7to3 port map( x6 => PktData_reg(6)(i), x5 => PktData_reg(5)(i), x4 => PktData_reg(4)(i),
                       x3 => PktData_reg(3)(i), x2 => PktData_reg(2)(i),  x1 => PktData_reg(1)(i), x0 => PktData_reg(0)(i),
                       s2 => sum_L1(2)((i+2) mod 32), s1 => sum_L1(1)((i+1) mod 32), s0 => sum_L1(0)(i) );
                       
    reduc2: reducer_7to3 port map( x6 => PktData_reg(13)(i), x5 => PktData_reg(12)(i), x4 => PktData_reg(11)(i),
                      x3 => PktData_reg(10)(i), x2 => PktData_reg(9)(i),  x1 => PktData_reg(8)(i), x0 => PktData_reg(7)(i),
                      s2 => sum_L1(5)((i+2) mod 32), s1 => sum_L1(4)((i+1) mod 32), s0 => sum_L1(3)(i) );                     
  end generate;

  L_2: for i in 0 to 31 generate 
    reduc: reducer_7to3 port map( x6 => PktData_reg(14)(i), x5 => sum_L1(5)(i), x4 => sum_L1(4)(i),
                       x3 => sum_L1(3)(i), x2 => sum_L1(2)(i),  x1 => sum_L1(1)(i), x0 => sum_L1(0)(i),
                       s2 => sum_L2(2)((i+2) mod 32), s1 => sum_L2(1)((i+1) mod 32), s0 => sum_L2(0)(i) );                       
  end generate;

  L_3: for i in 0 to 15 generate 
    reduc: reducer_6to3 port map( x5 => sum_L2(2)(i), x4 => sum_L2(1)(i), x3 => sum_L2(0)(i),
                                  x2 => sum_L2(2)(i+16),  x1 => sum_L2(1)(i+16), x0 => sum_L2(0)(i+16),
                       s2 => sum_L3(2)((i+2) mod 16), s1 => sum_L3(1)((i+1) mod 16), s0 => sum_L3(0)(i) );                       
  end generate;
  
  L_4: for i in 0 to 15 generate 
      sum_L4(0)(i) <= sum_L3(2)(i) xor sum_L3(1)(i) xor sum_L3(0)(i);
      sum_L4(1)((i+1) mod 16) <= (sum_L3(2)(i) and sum_L3(1)(i)) or  (sum_L3(2)(i) and sum_L3(0)(i)) or (sum_L3(1)(i) and sum_L3(0)(i)) ;
  end generate;

  
sumFinal <=  ("11" & x"FFFF") - ("00" & sum_L4(1)) - ("00" & sum_L4(0));

 
end reducer_tree;
