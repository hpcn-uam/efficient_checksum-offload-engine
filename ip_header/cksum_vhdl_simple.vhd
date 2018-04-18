----------------------------------------------------------------------------------
-- Simplified check sum module.
-- register input and outputs
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cksum_vhdl_simp is
    Generic (Pipe_mode : string := "3_stage");
    Port ( 
           SysClk_in : in STD_LOGIC;
           reset : in STD_LOGIC_VECTOR (7 downto 0);
           PktData0 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData1 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData2 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData3 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData4 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData5 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData6 : in STD_LOGIC_VECTOR (15 downto 0);
           PktData7 : in STD_LOGIC_VECTOR (15 downto 0);
           ChksumFinal : out STD_LOGIC_VECTOR (15 downto 0));
end cksum_vhdl_simp;

architecture Behavioral of cksum_vhdl_simp is

    component clk_gen port (
      clk_out1          : out    std_logic;
      reset             : in     std_logic;
      locked            : out    std_logic;
      clk_in1           : in     std_logic
     );
    end component;

-- This function performs a 1's-complement addition on 2 16-bit inputs.
-- 1's complement addition requires adding the carry-out bit back into the sum.
-- To increase performance two additions in parallel (with CIN=0, and CIN=1).
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
   

  signal sys_clk : STD_LOGIC := '0';  
  
  signal PktData0_reg : unsigned (15 downto 0) := (others => '0');
  signal PktData1_reg : unsigned (15 downto 0) := (others => '0');  
  signal PktData2_reg : unsigned (15 downto 0) := (others => '0');
  signal PktData3_reg : unsigned (15 downto 0) := (others => '0');  
  signal PktData4_reg : unsigned (15 downto 0) := (others => '0');
  signal PktData5_reg : unsigned (15 downto 0) := (others => '0');  
  signal PktData6_reg : unsigned (15 downto 0) := (others => '0');
  signal PktData7_reg : unsigned (15 downto 0) := (others => '0');  
  
  signal ChksumPartial : unsigned (18 downto 0) := (others => '0'); 
  signal Chksum0123_Partial : unsigned (17 downto 0) := (others => '0'); 
  signal Chksum4567_Partial : unsigned (17 downto 0) := (others => '0');
  signal Chksum01_Partial : unsigned (16 downto 0) := (others => '0'); 
  signal Chksum23_Partial : unsigned (16 downto 0) := (others => '0'); 
  signal Chksum45_Partial : unsigned (16 downto 0) := (others => '0'); 
  signal Chksum67_Partial : unsigned (16 downto 0) := (others => '0'); 
   
begin

    sys_clk <= SysClk_in;  
     
    --Input Registers
    inp_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then
        PktData0_reg  <= unsigned (PktData0);
        PktData1_reg  <= unsigned (PktData1);
        PktData2_reg  <= unsigned (PktData2);
        PktData3_reg  <= unsigned (PktData3);
        PktData4_reg  <= unsigned (PktData4);
        PktData5_reg  <= unsigned (PktData5);
        PktData6_reg  <= unsigned (PktData6);
        PktData7_reg  <= unsigned (PktData7);
      end if;
    end process;

gen_3: if Pipe_mode = "3_stage" generate    
    inter_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then
           --ChksumPartial <=   Chksum7 + Chksum6 +... + Chksum0; add 8 time 16 bits numbers
           Chksum01_Partial <= ('0' & PktData1_reg) + PktData0_reg;
           Chksum23_Partial <= ('0' & PktData3_reg) + PktData1_reg;
           Chksum45_Partial <= ('0' & PktData5_reg) + PktData2_reg;
           Chksum67_Partial <= ('0' & PktData7_reg) + PktData3_reg;
           
           Chksum0123_Partial <=  ('0' & Chksum01_Partial) + Chksum23_Partial;
           Chksum4567_Partial <=  ('0' & Chksum45_Partial) + Chksum67_Partial;
           
           ChksumPartial <=  ('0' & Chksum0123_Partial) + Chksum4567_Partial;
      end if;
    end process;
end generate gen_3;

gen_2: if Pipe_mode = "2_stage" generate    
    inter_reg: process (sys_clk)
    begin
      if (sys_clk'event and sys_clk='1') then
           --ChksumPartial <=   Chksum7 + Chksum6 +... + Chksum0; add 8 time 16 bits numbers
           Chksum01_Partial <= ('0' & PktData1_reg) + PktData0_reg;
           Chksum23_Partial <= ('0' & PktData3_reg) + PktData1_reg;
           Chksum45_Partial <= ('0' & PktData5_reg) + PktData2_reg;
           Chksum67_Partial <= ('0' & PktData7_reg) + PktData3_reg;
      end if;
      
      Chksum0123_Partial <=  ('0' & Chksum01_Partial) + Chksum23_Partial;
      Chksum4567_Partial <=  ('0' & Chksum45_Partial) + Chksum67_Partial;
      
      ChksumPartial <=  ('0' & Chksum0123_Partial) + Chksum4567_Partial;
    end process;
end generate gen_2;

gen_1: if Pipe_mode = "no_stage" generate    
           --ChksumPartial <=   Chksum7 + Chksum6 +... + Chksum0; add 8 time 16 bits numbers
           ChksumPartial <= ("000" & PktData1_reg) + PktData0_reg + PktData3_reg + PktData1_reg 
                                   + PktData5_reg) + PktData2_reg + PktData7_reg + PktData3_reg;
         
            
end generate gen_1;

--add the carries to get the 16-bit 1s complement sum   
    final_add: process (sys_clk)
      variable ChksumPart_upper : unsigned (15 downto 0) := (others => '0'); 
    begin
        if (sys_clk'event and sys_clk='1') then        
            ChksumPart_upper := '0' & x"000" & ChksumPartial(18 downto 16);
            ChksumFinal <= std_logic_vector (not(Add1Comp(ChksumPartial(15 downto 0), ChksumPart_upper)));
        end if;
    end process;

end Behavioral;


