--------------------------------------------------------------
-- Reduce 7 input, outputs the addition in 3 bits
-- It's a carry-save like adder.
--------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity reducer_7to3_i is port (
  x6, x5,x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic
);
end reducer_7to3_i ;

architecture rtl of reducer_7to3_i is
  type memrom is array (0 to 127) of STD_LOGIC;
  signal sum_0: memrom := x"6996_9669_9669_6996_9669_6996_6996_9669";
  signal sum_1: memrom := x"177E_7EE8_7EE8_E881_7EE8_E881_E881_8117";  
  signal sum_2: memrom := x"0001_0117_0117_177F_0117_177F_177F_7FFF";
  signal x: std_logic_vector (6 downto 0);

begin
  
  x <= x6 & x5 & x4 & x3 & x2 & x1 & x0;
  s2 <= sum_2(conv_integer(x));  
  s1 <= sum_1(conv_integer(x));  
  s0 <= sum_0(conv_integer(x));

end rtl;

