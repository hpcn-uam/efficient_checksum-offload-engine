----------------------------------------------------------------------------------
-- Simplified check sum module.
-- Reduce 512 data plus 16bits
-- Supposed IP header at begining. 
-- register input and outputs
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_528_r01 is
    Port ( 
           SysClk_in : in STD_LOGIC;
           PktData : in STD_LOGIC_VECTOR (511 downto 0);
		   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_528_r01;


--------------
-- Ternary adders
architecture reducer_tree of cksum_528_r01 is

component reducer_7to3 is port (
  x6, x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;

component reducer_6to3 is port (
  x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;


  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 14) of unsigned (15 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 5) of unsigned (15 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  type chk_sum_L3_type is array (0 to 2) of unsigned (15 downto 0);
  signal sum_L3 : chk_sum_L3_type;
  
--  type chk_sum_L4_type is array (0 to 1) of unsigned (15 downto 0);
--  signal sum_L4 : chk_sum_L4_type;

  signal sum_L4 : unsigned (17 downto 0);

  signal sumFinal : unsigned (17 downto 0);
  
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
    reduc1: reducer_7to3 port map( x6 => PktData_reg(6)(i), x5 => PktData_reg(5)(i), x4 => PktData_reg(4)(i),
                       x3 => PktData_reg(3)(i), x2 => PktData_reg(2)(i),  x1 => PktData_reg(1)(i), x0 => PktData_reg(0)(i),
                       s2 => sum_L1(2)((i+2) mod 16), s1 => sum_L1(1)((i+1) mod 16), s0 => sum_L1(0)(i) );
                       
    reduc2: reducer_7to3 port map( x6 => PktData_reg(13)(i), x5 => PktData_reg(12)(i), x4 => PktData_reg(11)(i),
                      x3 => PktData_reg(10)(i), x2 => PktData_reg(9)(i),  x1 => PktData_reg(8)(i), x0 => PktData_reg(7)(i),
                      s2 => sum_L1(5)((i+2) mod 16), s1 => sum_L1(4)((i+1) mod 16), s0 => sum_L1(3)(i) );   

    reduc3: reducer_7to3 port map( x6 => PktData_reg(20)(i), x5 => PktData_reg(19)(i), x4 => PktData_reg(18)(i),
                       x3 => PktData_reg(17)(i), x2 => PktData_reg(16)(i),  x1 => PktData_reg(15)(i), x0 => PktData_reg(14)(i),
                       s2 => sum_L1(8)((i+2) mod 16), s1 => sum_L1(7)((i+1) mod 16), s0 => sum_L1(6)(i) );
                       
    reduc4: reducer_6to3 port map( x5 => PktData_reg(26)(i), x4 => PktData_reg(25)(i), x3 => PktData_reg(24)(i),
                          x2 => PktData_reg(23)(i),  x1 => PktData_reg(22)(i), x0 => PktData_reg(21)(i),
                          s2 => sum_L1(11)((i+2) mod 16), s1 => sum_L1(10)((i+1) mod 16), s0 => sum_L1(9)(i) ); 
                                                      
    reduc5: reducer_6to3 port map( x5 => pre_cks_REG(i), x4 => PktData_reg(31)(i), x3 => PktData_reg(30)(i),
                          x2 => PktData_reg(29)(i),  x1 => PktData_reg(28)(i), x0 => PktData_reg(27)(i),
                          s2 => sum_L1(14)((i+2) mod 16), s1 => sum_L1(13)((i+1) mod 16), s0 => sum_L1(12)(i) ); 	
					  			  
  end generate;

  L_2: for i in 0 to 15 generate 
    reduc1: reducer_7to3 port map( x6 => sum_L1(6)(i), x5 => sum_L1(5)(i), x4 => sum_L1(4)(i),
                       x3 => sum_L1(3)(i), x2 => sum_L1(2)(i),  x1 => sum_L1(1)(i), x0 => sum_L1(0)(i),
                       s2 => sum_L2(2)((i+2) mod 16), s1 => sum_L2(1)((i+1) mod 16), s0 => sum_L2(0)(i) );     
                         
    reduc2: reducer_7to3 port map( x6 => sum_L1(13)(i), x5 => sum_L1(12)(i), x4 => sum_L1(11)(i),
                    x3 => sum_L1(10)(i), x2 => sum_L1(9)(i),  x1 => sum_L1(8)(i), x0 => sum_L1(7)(i),
                    s2 => sum_L2(5)((i+2) mod 16), s1 => sum_L2(4)((i+1) mod 16), s0 => sum_L2(3)(i) );                   
  end generate;

  L_3: for i in 0 to 15 generate 
    reduc1: reducer_7to3 port map( x6 => sum_L1(14)(i), x5 => sum_L2(5)(i), x4 => sum_L2(4)(i),
                       x3 => sum_L2(3)(i), x2 => sum_L2(2)(i),  x1 => sum_L2(1)(i), x0 => sum_L2(0)(i),
                       s2 => sum_L3(2)((i+2) mod 16), s1 => sum_L3(1)((i+1) mod 16), s0 => sum_L3(0)(i) );                       
  end generate;
  
--  L_4: for i in 0 to 15 generate 
--      sum_L4(0)(i) <= sum_L3(2)(i) xor sum_L3(1)(i) xor sum_L3(0)(i);
--      sum_L4(1)((i+1) mod 16) <= (sum_L3(2)(i) and sum_L3(1)(i)) or  (sum_L3(2)(i) and sum_L3(0)(i)) or (sum_L3(1)(i) and sum_L3(0)(i)) ;
--  end generate;

   sum_L4 <= ("00" & sum_L3(2)) + sum_L3(1) + sum_L3(0);
   
--sumFinal <=  ("11" & x"FFFF") - ("00" & sum_L4(1)) - ("00" & sum_L4(0));
   sumFinal <=  ("00" & sum_L4(15 downto 0)) + sum_L4(17 downto 16);

 
end reducer_tree;


--------------
-- Ternary adders
architecture reducer_tree2 of cksum_528_r01 is

component reducer_7to3 is port (
  x6, x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;

component reducer_6to3 is port (
  x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic);
end component;

  signal sys_clk : STD_LOGIC := '0';  
  
  type op_chk_sum_type is array (0 to 31) of unsigned (15 downto 0);
  signal PktData_reg : op_chk_sum_type; 
  
  type chk_sum_L1_type is array (0 to 14) of unsigned (15 downto 0);
  signal sum_L1 : chk_sum_L1_type;
  
  type chk_sum_L2_type is array (0 to 5) of unsigned (15 downto 0);
  signal sum_L2 : chk_sum_L2_type;
  
  type chk_sum_L3_type is array (0 to 2) of unsigned (15 downto 0);
  signal sum_L3 : chk_sum_L3_type;
  
  type chk_sum_L4_type is array (0 to 2) of unsigned (17 downto 0);
  signal sum_L4 : chk_sum_L4_type;

  --signal sum_L4 : unsigned (17 downto 0);

  signal sumFinal : unsigned (17 downto 0);
  
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
    reduc1: reducer_7to3 port map( x6 => PktData_reg(6)(i), x5 => PktData_reg(5)(i), x4 => PktData_reg(4)(i),
                       x3 => PktData_reg(3)(i), x2 => PktData_reg(2)(i),  x1 => PktData_reg(1)(i), x0 => PktData_reg(0)(i),
                       s2 => sum_L1(2)((i+2) mod 16), s1 => sum_L1(1)((i+1) mod 16), s0 => sum_L1(0)(i) );
                       
    reduc2: reducer_7to3 port map( x6 => PktData_reg(13)(i), x5 => PktData_reg(12)(i), x4 => PktData_reg(11)(i),
                      x3 => PktData_reg(10)(i), x2 => PktData_reg(9)(i),  x1 => PktData_reg(8)(i), x0 => PktData_reg(7)(i),
                      s2 => sum_L1(5)((i+2) mod 16), s1 => sum_L1(4)((i+1) mod 16), s0 => sum_L1(3)(i) );   

    reduc3: reducer_7to3 port map( x6 => PktData_reg(20)(i), x5 => PktData_reg(19)(i), x4 => PktData_reg(18)(i),
                       x3 => PktData_reg(17)(i), x2 => PktData_reg(16)(i),  x1 => PktData_reg(15)(i), x0 => PktData_reg(14)(i),
                       s2 => sum_L1(8)((i+2) mod 16), s1 => sum_L1(7)((i+1) mod 16), s0 => sum_L1(6)(i) );
                       
    reduc4: reducer_6to3 port map( x5 => PktData_reg(26)(i), x4 => PktData_reg(25)(i), x3 => PktData_reg(24)(i),
                          x2 => PktData_reg(23)(i),  x1 => PktData_reg(22)(i), x0 => PktData_reg(21)(i),
                          s2 => sum_L1(11)((i+2) mod 16), s1 => sum_L1(10)((i+1) mod 16), s0 => sum_L1(9)(i) ); 
                                                      
    reduc5: reducer_6to3 port map( x5 => pre_cks_REG(i), x4 => PktData_reg(31)(i), x3 => PktData_reg(30)(i),
                          x2 => PktData_reg(29)(i),  x1 => PktData_reg(28)(i), x0 => PktData_reg(27)(i),
                          s2 => sum_L1(14)((i+2) mod 16), s1 => sum_L1(13)((i+1) mod 16), s0 => sum_L1(12)(i) ); 	
					  			  
  end generate;

  L_2: for i in 0 to 15 generate 
    reduc1: reducer_7to3 port map( x6 => sum_L1(6)(i), x5 => sum_L1(5)(i), x4 => sum_L1(4)(i),
                       x3 => sum_L1(3)(i), x2 => sum_L1(2)(i),  x1 => sum_L1(1)(i), x0 => sum_L1(0)(i),
                       s2 => sum_L2(2)((i+2) mod 16), s1 => sum_L2(1)((i+1) mod 16), s0 => sum_L2(0)(i) );     
                         
    reduc2: reducer_7to3 port map( x6 => sum_L1(13)(i), x5 => sum_L1(12)(i), x4 => sum_L1(11)(i),
                    x3 => sum_L1(10)(i), x2 => sum_L1(9)(i),  x1 => sum_L1(8)(i), x0 => sum_L1(7)(i),
                    s2 => sum_L2(5)((i+2) mod 16), s1 => sum_L2(4)((i+1) mod 16), s0 => sum_L2(3)(i) );                   
  end generate;

  L_3: for i in 0 to 15 generate 
    reduc1: reducer_7to3 port map( x6 => sum_L1(14)(i), x5 => sum_L2(5)(i), x4 => sum_L2(4)(i),
                       x3 => sum_L2(3)(i), x2 => sum_L2(2)(i),  x1 => sum_L2(1)(i), x0 => sum_L2(0)(i),
                       s2 => sum_L3(2)((i+2) mod 16), s1 => sum_L3(1)((i+1) mod 16), s0 => sum_L3(0)(i) );                       
  end generate;
  

  sum_L4(0) <= ("00" & sum_L3(2)) + sum_L3(1) + sum_L3(0);  
  sum_L4(1) <= ("00" & sum_L3(2)) + sum_L3(1) + sum_L3(0) + 1;  
  sum_L4(2) <= ("00" & sum_L3(2)) + sum_L3(1) + sum_L3(0) + 2;

    
   with (sum_L4(0)(17 downto 16)) select 
   sumFinal <= sum_L4(0) when "00",
               sum_L4(1) when "01",
               sum_L4(1) when others;
               
end reducer_tree2;
