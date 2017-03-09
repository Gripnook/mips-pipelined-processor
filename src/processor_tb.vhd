library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.textio.all;
library modelsim_lib;
use modelsim_lib.util.all;

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

    type instruction_mem_type is array (0 to 1023) of std_logic_vector(31 downto 0);
    

    signal pc : std_logic_vector(31 downto 0);

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
        file program : text;
        file register_file : text;
        file memory : text;

        variable program_line : line;
        variable instruction : std_logic_vector(31 downto 0);

        variable instruction_cache : instruction_mem_type;

    begin
        init_signal_spy("/dut/instruction_cache/ram_block", "/instruction_cache");
        init_signal_spy("/dut/pc", "/pc");

        file_open(program, "program.txt", read_mode);

        for i in 0 to 1023 loop
            instruction_cache(i) := x"000F0000";
        end loop;
        << signal .processor_tb.dut.instruction_cache.ram_block : instruction_mem_type >> <= instruction_cache;

        report to_string(pc);

        reset <= '1';
        wait until rising_edge(clock);
        reset <= '0';

        wait until to_integer(unsigned(pc)) = 4092;
        pc <= x"FFFFFFFF";
        reset <= '1';

        wait;

    end process;

end architecture;
