
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CslStdRtlPkg.all;

entity PwmModule is
   generic(
      TPD_G   : time     := 1ns;
      WIDTH_G : positive := 8
   );
   port(
      clk_i    : in  sl;
      rst_i    : in  sl;
      en_i     : in  sl;
      period_i : in  slv(WIDTH_G-1 downto 0);
      duty_i   : in  slv(7 downto 0);
      pwm_o    : out sl
   );
end PwmModule;

architecture rtl of PwmModule is
   --! Record containing all register elements
   type RegType is record
      dutyCnt   : unsigned(7 downto 0);
      periodCnt : unsigned(WIDTH_G-1 downto 0);
      pwm       : sl;
      duty      : unsigned(7 downto 0);
      period    : unsigned(WIDTH_G-1 downto 0);
   end record RegType;

   --! Initial and reset values for all register elements
   constant REG_INIT_C : RegType := (
         dutyCnt   => (others => '0'),
         periodCnt => (others => '0'),
         pwm       => '0',
         duty      => (others => '0'),
         period    => (others => '0')
      );

   --! Output of registers
   signal r : RegType;

   --! p_Combinatorial input to registers
   signal rin : RegType;

begin

   p_Comb : process(rst_i, r, duty_i,period_i) -- p_Combinational process
      variable v : RegType;
   begin

      v := r; --! default assignment

      if (en_i='1') then
         -- register duty and period value from the input
         v.duty   := unsigned(duty_i);
         v.period := unsigned(period_i);

      end if;

      -- period counter
      -- when it resets to 0 we have another period
      if (r.periodCnt>=r.period-1) then
         -- reset counter
         v.periodCnt := to_unsigned(0,WIDTH_G);
      else
         v.periodCnt := r.periodCnt + 1;
      end if;

      if (r.periodCnt*to_unsigned(256,9)>= r.period*r.duty) then
         v.pwm := '0';
      else
         v.pwm := '1';
      end if;

      if rst_i = '1' then --! reset condition
         v := REG_INIT_C;
      end if;

      rin <= v; --! drive register inputs

      --! drive outputs
      pwm_o <= r.pwm;

   end process p_Comb;

   p_Seq : process(clk_i) -- p_Sequential process
   begin
      if rising_edge(clk_i) then
         r <= rin after TPD_G;
      end if;
   end process p_Seq;

end rtl;
