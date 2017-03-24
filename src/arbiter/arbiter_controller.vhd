library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_controller is
    port(
        clk              : in  std_logic;
        rst              : in  std_logic;
        -- I$
        i_read           : in  std_logic;
        i_write          : in  std_logic;
        i_wait_request   : out std_logic;

        -- D$
        d_read           : in  std_logic;
        d_write          : in  std_logic;
        d_wait_request   : out std_logic;

        -- Memory
        mem_read         : out std_logic;
        mem_write        : out std_logic;
        mem_wait_request : in  std_logic);
end entity arbiter_controller;

architecture arch of arbiter_controller is
    type state_type is (state0, state1, state2);
begin
    process(clk, rst) is
        variable state : state_type := state0;
    begin
        if rst = '1' then
            state := state0;
        elsif rising_edge(clk) then
            case state is
                when state0 =>
                    state := state1;
                when state1 =>
                    state := state2;
                when state2 =>
                    state := state0;
            end case;
        end if;
    end process;
end architecture arch;
