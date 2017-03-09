library ieee;
use ieee.std_logic_1164.all;

entity processor_tb is
end processor_tb;

architecture arch of processor_tb is

    component processor is
        port(clock : in std_logic;
             reset : in std_logic);
    end component;

    constant clock_period : time := 1 ns;

    signal clock : std_logic;
    signal reset : std_logic;

begin

    dut : processor
    port map(clock => clock,
             reset => reset);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process;

    test_process : process
    begin
        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';
        wait;
    end process;

end architecture;
