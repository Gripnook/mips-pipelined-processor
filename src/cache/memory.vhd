--Adapted from Example 12-15 of Quartus Design and Synthesis handbook
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    generic(RAM_SIZE     : integer := 8192;
            MEM_DELAY    : time    := 10 ns;
            CLOCK_PERIOD : time    := 1 ns);
    port(clock       : in  std_logic;
         writedata   : in  std_logic_vector(31 downto 0);
         address     : in  integer range 0 to RAM_SIZE - 1;
         memwrite    : in  std_logic;
         memread     : in  std_logic;
         readdata    : out std_logic_vector(31 downto 0);
         waitrequest : out std_logic);
end memory;

architecture rtl of memory is
    type ram is array (0 to RAM_SIZE - 1) of std_logic_vector(31 downto 0);
    signal ram_block         : ram;
    signal read_address_reg  : integer range 0 to RAM_SIZE - 1;
    signal write_waitreq_reg : std_logic := '1';
    signal read_waitreq_reg  : std_logic := '1';
begin
    --This is the main section of the SRAM model
    mem_process : process(clock)
    begin
        if (rising_edge(clock)) then
            if (memwrite = '1') then
                ram_block(address) <= writedata;
            end if;
            read_address_reg <= address;
        end if;
    end process;
    readdata <= ram_block(read_address_reg);

    --The waitrequest signal is used to vary response time in simulation
    --Read and write should never happen at the same time.
    waitreq_w_proc : process(memwrite)
    begin
        if (rising_edge(memwrite)) then
            write_waitreq_reg <= '0' after MEM_DELAY, '1' after MEM_DELAY + CLOCK_PERIOD;
        end if;
    end process;

    waitreq_r_proc : process(memread)
    begin
        if (rising_edge(memread)) then
            read_waitreq_reg <= '0' after MEM_DELAY, '1' after MEM_DELAY + CLOCK_PERIOD;
        end if;
    end process;

    -- Synchronize the waitrequest signal to the falling edge of the clock
    waitreq_proc : process(clock)
    begin
        if (falling_edge(clock)) then
            waitrequest <= write_waitreq_reg and read_waitreq_reg;
        end if;
    end process;
end rtl;
