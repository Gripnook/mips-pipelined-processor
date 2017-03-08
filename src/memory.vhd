-- Simplified memory model simulating cache hits on the falling edge.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    generic(
        ram_size     : integer := 32768
    );
    port(
        clock       : in  std_logic;
        writedata   : in  std_logic_vector(31 downto 0) := (others => '0');
        address     : in  integer range 0 to ram_size - 1;
        memwrite    : in  std_logic := '0';
        memread     : in  std_logic;
        readdata    : out std_logic_vector(31 downto 0);
        waitrequest : out std_logic
    );
end memory;

architecture rtl of memory is
    type mem_type is array (ram_size - 1 downto 0) of std_logic_vector(31 downto 0);
    signal ram_block : mem_type;
begin
    mem_process : process(clock)
    begin
        if (falling_edge(clock)) then
            if (memread = '1') then
                waitrequest <= '1';
                readdata <= ram_block(address);
                waitrequest <= '0';
            elsif (memwrite = '1') then
                waitrequest <= '1';
                ram_block(address) <= writedata;
                waitrequest <= '0';
            end if;
        end if;
    end process;
end rtl;