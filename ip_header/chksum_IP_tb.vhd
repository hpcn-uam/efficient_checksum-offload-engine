----------------------------------------------------------------------------------
-- Company: 
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity chksum_IP_tb is
--  Port ( );
end chksum_IP_tb;

architecture Behavioral of chksum_IP_tb is

  function Add1Comp (In1, In2 : in unsigned (15 downto 0)) return unsigned is
     variable Sum1, Sum0: unsigned(16 downto 0);
     --variable Sum_c1: unsigned (15 downto 0);
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
   
   
  function calc_chsum (ip_header : in std_logic_vector (479 downto 0)) return unsigned is
      variable Sum_1Com, new_data: unsigned(15 downto 0):= (others => '0');
      --variable Sum_c1: unsigned (15 downto 0);
      variable len: integer:=0;
    begin
       len := to_integer(unsigned(ip_header(3 downto 0)));
       for i in 0 to 2*len-1 loop
              if i /= 5 then --ignores IPChecksum
                  new_data(15 downto 8) := unsigned(ip_header(i*16 + 7 downto i*16));
                  new_data(7 downto 0) := unsigned(ip_header(i*16 + 15 downto i*16+8));  
                  Sum_1Com := Add1Comp(Sum_1Com, new_data);
              end if;
       end loop;
       return (not(Sum_1Com));
    end calc_chsum;
    
    component cksum_vhdl_r03 is
        Port ( 
               SysClk_in : in STD_LOGIC;
               PktData : in STD_LOGIC_VECTOR (511 downto 0);
               ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component cksum_vhdl2 is
        Port ( 
               SysClk_in : in STD_LOGIC;
               PktData : in STD_LOGIC_VECTOR (511 downto 0);
               ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
   signal clk : std_logic := '0';
   constant clk_period : time := 10 ns;
   signal ChksumHW, ChksumHW_2, ChksumGold : STD_LOGIC_VECTOR (15 downto 0);
   signal PktData : STD_LOGIC_VECTOR (511 downto 0);
   --signal ip_header : STD_LOGIC_VECTOR (479 downto 0) :=(others => '1');   
   signal ip_header : STD_LOGIC_VECTOR (479 downto 0) := x"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF01234567";
   constant MAX_TEST: integer := 10;
   constant zeros : STD_LOGIC_VECTOR (511-479-1 downto 0):=(others => '0');
   
   
 BEGIN
 
    uut: cksum_vhdl_r03 PORT MAP (SysClk_in => clk, 
                              PktData => PktData, 
                              ChksumFinal => ChksumHW);    
                               
    uut2: cksum_vhdl2 PORT MAP (SysClk_in => clk, 
                              PktData => PktData, 
                              ChksumFinal => ChksumHW_2);                               
    PktData <= zeros & ip_header;                          
 
    -- Clock process definitions( clock with 50% duty cycle is generated here.
    clk_process : process
    begin
         clk <= '0';
         wait for clk_period/2; 
         clk <= '1';
         wait for clk_period/2;  
    end process;


process
--variable ChksumGold: STD_LOGIC_VECTOR (15 downto 0);
begin

wait for clk_period/4; 

for i in 1 to MAX_TEST loop
    for j in 5 to 15 loop    
        wait for clk_period;
        ip_header (3 downto 0) <= std_logic_vector(to_unsigned(j, 4));
        wait for clk_period;
        ChksumGold <= std_logic_vector(calc_chsum (ip_header));
        wait for clk_period;
        assert ChksumHW = ChksumGold report "No equal values." severity warning;
    end loop; 
    ip_header (31 downto 24) <=  std_logic_vector(unsigned(ip_header (31 downto 24)) + 7);
       
end loop;

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
  

  