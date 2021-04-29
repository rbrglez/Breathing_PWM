library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.CslStdRtlPkg.all;


entity BreathingPWM is
   generic (
      TPD_G : time := 1 ns
   );
   port (
      clk_i : in  sl; --! Input clock
      rst_i : in  sl; --! Input reset
      pwm_o : out sl

   ); --! Output signal
end BreathingPWM;
---------------------------------------------------------------------------------------------------    
architecture rtl of BreathingPWM is

   constant WIDTH_C : positive := 16;

   constant GND : slv(7 downto 0) := (others => '0');
   constant VDD : slv(7 downto 0) := (others => '1');

   type PhaseType is (
         FIRST_PHASE_S,
         SECOND_PHASE_S,
         THIRD_PHASE_S,
         FOURTH_PHASE_S
      );

   type RegType is record
      phase     : PhaseType;
      periodCnt : unsigned(WIDTH_C-1 downto 0);
      cnt       : unsigned(7 downto 0);

      addr : slv(7 downto 0);
      duty : slv(7 downto 0);
   end record RegType;

   --! Initial and reset values for all register elements
   constant REG_INIT_C : RegType := (
         phase     => FIRST_PHASE_S,
         periodCnt => (others => '0'),
         cnt       => (others => '0'),

         addr => (others => '0'),
         duty => (others => '0')
      );

   --! Output of registers
   signal r : RegType;

   --! p_Combinatorial input to registers
   signal rin : RegType;

   signal data : slv(7 downto 0);

---------------------------------------------------------------------------------------------------
begin


   u_SinROM : entity work.sin_data
      port map (
         clka  => clk_i,
         ena   => VDD(0),
         wea   => GND(0),
         addra => r.addr,
         dina  => GND,
         douta => data
      );

   u_PWM : entity work.PwmModule
      generic map (
         TPD_G   => TPD_G,
         WIDTH_G => WIDTH_C
      )
      port map (
         clk_i    => clk_i,
         rst_i    => rst_i,
         en_i     => VDD(0),
         period_i => slv(to_unsigned(10,WIDTH_C)),
         duty_i   => r.duty,
         pwm_o    => pwm_o
      );



   p_Comb : process(rst_i, r) -- p_Combinational process
      variable v : RegType;
   begin

      v := r; --! default assignment

      if (r.periodCnt>=10) then
         v.periodCnt := to_unsigned(0,WIDTH_C);

      else
         v.periodCnt := r.periodCnt + 1;
      end if;

      case r.phase is
         ----------------------------------------------------------------------
         when FIRST_PHASE_S =>

            -- increment counter
            -- positive data
            if (r.periodCnt=to_unsigned(0,WIDTH_C)) then
               v.cnt := r.cnt+1;
            end if;

            v.addr := slv(r.cnt);
            v.duty := slv(to_unsigned(128,8) + unsigned('0' & data(7 downto 1)));

            if (r.cnt = to_unsigned(255,8)) then
               v.cnt   := to_unsigned(255,8);
               v.phase := SECOND_PHASE_S;
            end if;

         ----------------------------------------------------------------------
         when SECOND_PHASE_S =>

            -- decrement counter
            -- positive data
            if (r.periodCnt=to_unsigned(0,WIDTH_C)) then
               v.cnt := r.cnt-1;
            end if;
            v.addr := slv(r.cnt);
            v.duty := slv(to_unsigned(128,8) + unsigned('0' & data(7 downto 1)));

            if (r.cnt = to_unsigned(0,8)) then
               v.cnt   := to_unsigned(0,8);
               v.phase := THIRD_PHASE_S;
            end if;

         ----------------------------------------------------------------------
         when THIRD_PHASE_S =>

            -- increment counter
            -- negative data
            if (r.periodCnt=to_unsigned(0,WIDTH_C)) then
               v.cnt := r.cnt+1;
            end if;

            v.addr := slv(r.cnt);
            v.duty := slv(to_unsigned(128,8) - unsigned('0' & data(7 downto 1)));

            if (r.cnt = to_unsigned(255,8)) then
               v.cnt   := to_unsigned(255,8);
               v.phase := FOURTH_PHASE_S;
            end if;

         ----------------------------------------------------------------------
         when FOURTH_PHASE_S =>

            -- decrement counter
            -- negative data
            if (r.periodCnt=to_unsigned(0,WIDTH_C)) then
               v.cnt := r.cnt-1;
            end if;

            v.addr := slv(r.cnt);
            v.duty := slv(to_unsigned(128,8) - unsigned('0' & data(7 downto 1)));

            if (r.cnt = to_unsigned(0,8)) then
               v.cnt   := to_unsigned(0,8);
               v.phase := FIRST_PHASE_S;
            end if;

         ----------------------------------------------------------------------
         when others =>
            v := REG_INIT_C;
      ----------------------------------------------------------------------
      end case;


      if rst_i = '1' then --! reset condition
         v := REG_INIT_C;
      end if;

      rin <= v; --! drive register inputs

   end process p_Comb;


   --! @brief p_Sequential process
   --! @details Assign rin to r on rising edge of clk to create registers
   --! @param[in]  rin, clk_i
   --! @param[out] r 
   p_Seq : process(clk_i) -- p_Sequential process
   begin
      if rising_edge(clk_i) then
         r <= rin after TPD_G;
      end if;
   end process p_Seq;

end rtl;