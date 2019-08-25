-- ************************************************
-- BSD 3-Clause License
-- 
-- Copyright (c) 2019, HPCN Group, UAM Spain (hpcn-uam.es)
-- and Systems Group, ETH Zurich (systems.ethz.ch)
-- All rights reserved.
-- 
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of the copyright holder nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- ************************************************/

----------------------------------------------------------------------------------
-- Company: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;


entity chksum_TCP_tb is
--  Port ( );
end chksum_TCP_tb;

architecture Behavioral of chksum_TCP_tb is


  function Add1Comp (In1, In2 : in unsigned (15 downto 0)) return unsigned is
     variable Sum1, Sum0: unsigned(16 downto 0);
   begin
      Sum0 :=  ('0' & unsigned(In1)) + ('0' & unsigned(In2));
      Sum1 :=  ('0' & unsigned(In1)) + ('0' & unsigned(In2)) + 1;
      --Sum_c1 := Sum0(16) ? sum0(15 downto 0) : sum1(15 downto 0); return Sum_c1;
      if (Sum0(16) = '1') then
         return (Sum1(15 downto 0));
      else 
         return (Sum0(15 downto 0));
      end if;
   end Add1Comp;
   
  function calc_c1Add (ip_header : in std_logic_vector (511 downto 0); pre_cks : in STD_LOGIC_VECTOR (15 downto 0)) return unsigned is
      variable Sum_1Com, new_data: unsigned(15 downto 0):= (others => '0');
    begin
       Sum_1Com:= (unsigned(pre_cks));
       for i in 0 to 31 loop --32*16 = 512 bits
                  new_data(15 downto 8) := unsigned(ip_header(i*16 + 7 downto i*16));
                  new_data(7 downto 0) := unsigned(ip_header(i*16 + 15 downto i*16+8));  
                  Sum_1Com := Add1Comp(Sum_1Com, new_data);
       end loop;
       return (Sum_1Com);
    end calc_c1Add;
    
    component cksum_528_r02 is    
        Port ( 
               SysClk_in : in STD_LOGIC;
               PktData : in STD_LOGIC_VECTOR (511 downto 0);
               pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
               ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component cksum_528_bin01 is
         Port ( 
                SysClk_in : in STD_LOGIC;
                PktData : in STD_LOGIC_VECTOR (511 downto 0);
                pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
                ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
     end component;
     
    component cksum_528_ter01 is
          Port ( 
                 SysClk_in : in STD_LOGIC;
                 PktData : in STD_LOGIC_VECTOR (511 downto 0);
                 pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
                 ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
      end component;
      
      component cksum_528_simple is
            Port ( 
                   SysClk_in : in STD_LOGIC;
                   PktData : in STD_LOGIC_VECTOR (511 downto 0);
                   pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
                   ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component cksum_528_bin32 is
          Port ( 
                 SysClk_in : in STD_LOGIC;
                 PktData : in STD_LOGIC_VECTOR (511 downto 0);
                 pre_cks : in STD_LOGIC_VECTOR (15 downto 0);
                 ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
   end component;
  
   signal clk : std_logic := '0';
   constant clk_period : time := 10 ns;
   signal ChksumHW, ChksumHW2, ChksumGold : STD_LOGIC_VECTOR (15 downto 0);
   signal PktData : STD_LOGIC_VECTOR (511 downto 0);
   --signal ip_header : STD_LOGIC_VECTOR (479 downto 0) :=(others => '1');   
   --signal ip_header : STD_LOGIC_VECTOR (511 downto 0); -- := x"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567";
   signal pre_cks : STD_LOGIC_VECTOR (15 downto 0) := x"89AB";
   constant MAX_TEST: integer := 200;
   constant zeros : STD_LOGIC_VECTOR (511-479-1 downto 0):=(others => '0');
   signal endsim : boolean:= false;
   
 BEGIN
 
     uut1: cksum_528_r02 PORT MAP (SysClk_in => clk,
     --uut1: cksum_528_ter01 PORT MAP (SysClk_in => clk, 
                              PktData => PktData,
                              pre_cks => pre_cks, 
                              ChksumFinal => ChksumHW);    
                               
       --uut2: cksum_528_simple PORT MAP (SysClk_in => clk, 
       --uut2: cksum_528_bin01 PORT MAP (SysClk_in => clk, 
       uut2: cksum_528_bin32 PORT MAP (SysClk_in => clk,  
                            PktData => PktData,
                            pre_cks => pre_cks, 
                            ChksumFinal => ChksumHW2);                                                   
 
    -- Clock process definitions( clock with 50% duty cycle is generated here.
    clk_process : process
    begin
         clk <= '0';
         wait for clk_period/2; 
         clk <= '1';
         wait for clk_period/2; 
         if(endsim = true) then wait; end if; 
    end process;


process
   variable seed1, seed2: positive;               -- seed values for random generator
   variable rand: real;   -- random real-number value in range 0 to 1.0  
   variable range_of_rand : real := 1000.0;    -- the range of random values created will be 0 to +1000.
   variable rand_num : integer := 1111; 
begin

wait for clk_period/4; 
uniform(seed1, seed2, rand);

for i in 1 to MAX_TEST loop
        wait for clk_period;
        for k in 0 to 31 loop
            uniform(seed1, seed2, rand);   -- generate random number
--          rand_num := integer(rand*(2**16-1));  -- rescale to 0..1000, convert integer part 
            rand_num := 65535;
            PktData (k*16+15 downto k*16) <= std_logic_vector(to_unsigned(rand_num, 16));
        end loop;
        uniform(seed1, seed2, rand);   -- generate random number
        rand_num := integer(rand*(2**16-1));  -- rescale to 0..1000, convert integer part 
        pre_cks <= std_logic_vector(to_unsigned(rand_num, 16));          
        wait for clk_period;
        ChksumGold <= std_logic_vector(calc_c1Add (PktData, pre_cks));
        wait for clk_period;
        assert ChksumHW = ChksumGold report "No equal values." severity warning;
        --assert ChksumHW = ChksumGold report "No equal values." severity failure;

end loop;

endsim <= true;
report "No ERRORS detected." severity note;
wait;

end process;


end Behavioral;



--------------------------
--------------------------
--  configuration c2 of chksum_tb is
--     for Behavioral
--        for uut:cksum_vhdl use entity work.cksum_vhdl(Behavioral);
--        end for;
--     end for;
--  end configuration c2;
  

  