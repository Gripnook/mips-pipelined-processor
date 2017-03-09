-- Simplified memory model simulating a cache
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity memory is
    generic(ram_size : integer := 8192);
    port(clock       : in  std_logic;
         writedata   : in  std_logic_vector(31 downto 0) := (others => '0');
         address     : in  integer range 0 to ram_size - 1;
         memwrite    : in  std_logic := '0';
         memread     : in  std_logic;
         readdata    : out std_logic_vector(31 downto 0);
         waitrequest : out std_logic);
end memory;

architecture rtl of memory is
    type mem_type is array (0 to ram_size - 1) of std_logic_vector(31 downto 0);
    signal ram_block : mem_type;

    type state_type is (ready, stalled);
    signal state : state_type := ready;

    constant miss_enable : std_logic := '0'; -- Set this constant to enable random cache misses
    constant miss_rate : real := 0.1;
    constant miss_penalty : integer := 10;

    signal miss_countdown : integer := 0;

begin

    mem_process : process(clock)
        -- generates deterministic pseudo-random miss sequence for benchmark simulation
        variable seed1 : positive := 1024;
        variable seed2 : positive := 8192;
        variable rand : real := 1.0;
    begin
        if (falling_edge(clock)) then
            if (state = ready) then
                waitrequest <= '0';
                if (miss_enable = '1') then
                    uniform(seed1, seed2, rand);
                end if;
                if (rand < miss_rate) then
                    state <= stalled;
                    miss_countdown <= miss_penalty - 1;
                    waitrequest <= '1';
                elsif (memread = '1') then
                    readdata <= ram_block(address);
                elsif (memwrite = '1') then
                    ram_block(address) <= writedata;
                end if;
            else
                if (miss_countdown = 0) then
                    state <= ready;
                    waitrequest <= '0';
                    if (memread = '1') then
                        readdata <= ram_block(address);
                    elsif (memwrite = '1') then
                        ram_block(address) <= writedata;
                    end if;
                else
                    miss_countdown <= miss_countdown - 1;
                end if;
            end if;
        end if;
    end process;
end rtl;
