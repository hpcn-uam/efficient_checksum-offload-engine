-- ************************************************
-- Copyright (c) 2018, HPCN Group, UAM Spain (hpcn-uam.es)
-- and Systems Group, ETH Zurich (systems.ethz.ch)
-- All rights reserved.
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- any later version.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
-- EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>
-- ************************************************/

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

