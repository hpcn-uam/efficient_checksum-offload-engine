--------------------------------------------------------------
-- Reduce 6 input, outputs the addition in 3 bits
-- It's a carry-save like adder.
--------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity reducer_6to3_i is port (
  x5, x4, x3, x2, x1, x0: in std_logic;
  s2, s1, s0: out std_logic
);
end reducer_6to3_i ;

architecture rtl of reducer_6to3_i is
  type memrom is array (0 to 63) of STD_LOGIC;
  signal sum_0: memrom := x"6996_9669_9669_6996";
  signal sum_1: memrom := x"177E_7EE8_7EE8_E881";  
  signal sum_2: memrom := x"0001_0117_0117_177F"; 
  
  signal x: std_logic_vector (5 downto 0);

begin
  
  x  <= x5 & x4 & x3 & x2 & x1 & x0;
  s2 <= sum_2(conv_integer(x));  
  s1 <= sum_1(conv_integer(x));  
  s0 <= sum_0(conv_integer(x));

end rtl;


