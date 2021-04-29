
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CslStdRtlPkg.all;



entity BreathingPWMTb is
end BreathingPWMTb;

architecture Behavioral of BreathingPWMTb is

   constant TPD_C : time := 1ns;
   constant T_C   : time := 10 ns;

   signal clk_i : sl := '0';
   signal rst_i : sl := '1';


   signal pwm_o : sl;

begin

   DUT : entity work.BreathingPWM
      generic map (
         TPD_G => TPD_C
      )
      port map (
         clk_i => clk_i,
         rst_i => rst_i,
         pwm_o => pwm_o
      );

   p_ClkGen : process
   begin
      clk_i <= '0';
      wait for T_C/2;
      clk_i <= '1';
      wait for T_C/2;
   end process;


   p_Sim : process
   begin

      wait for 10*T_C;
      wait for TPD_C;

      rst_i <= '0';

      wait;

   end process;

end Behavioral;
