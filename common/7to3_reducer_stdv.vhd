--------------------------------------------------------------
-- Reduce 6 input, outputs the addition in 3 bits
-- It's a carry-save like adder.
--------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity reducer_7to3_std_v is port (
  x: in std_logic_vector (6 downto 0);
  s: out std_logic_vector (2 downto 0)
);
end reducer_7to3_std_v ;

architecture rtl of reducer_7to3_std_v is
  type memrom is array (0 to 127) of STD_LOGIC;
  signal sum_0: memrom := x"6996_9669_9669_6996_9669_6996_6996_9669";
  signal sum_1: memrom := x"177E_7EE8_7EE8_E881_7EE8_E881_E881_8117";  
  signal sum_2: memrom := x"0001_0117_0117_177F_0117_177F_177F_7FFF";
  
begin

  s(2) <= sum_2(conv_integer(x));  
  s(1) <= sum_1(conv_integer(x));  
  s(0) <= sum_0(conv_integer(x));

end rtl;

