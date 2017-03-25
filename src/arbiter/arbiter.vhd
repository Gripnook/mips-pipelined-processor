library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter is
    port(
        -- Controller
        clock            : in  std_logic;
        reset            : in  std_logic;

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
        mem_wait_request : in  std_logic;

        -- Datapath
        -- I$
        i_readdata       : out std_logic_vector(31 downto 0);
        i_writedata      : in  std_logic_vector(31 downto 0);
        i_adr            : in  std_logic_vector(31 downto 0);

        -- D$
        d_readdata       : out std_logic_vector(31 downto 0);
        d_writedata      : in  std_logic_vector(31 downto 0);
        d_adr            : in  std_logic_vector(31 downto 0);

        -- Memory
        mem_readdata     : in  std_logic_vector(31 downto 0);
        mem_writedata    : out std_logic_vector(31 downto 0);
        mem_adr          : out std_logic_vector(31 downto 0));
end entity arbiter;

architecture arch of arbiter is
begin
    controller : process(clock, reset) is
    begin
        if reset = '1' then
            i_wait_request <= '0';
            d_wait_request <= '0';
            mem_read       <= '0';
            mem_write      <= '0';
        elsif rising_edge(clock) then
            if mem_wait_request = '1' then
                i_wait_request <= '1';
                d_wait_request <= '1';
                mem_read       <= '0';
                mem_write      <= '0';
            elsif d_read = '1' or d_write = '1' then
                i_wait_request <= '1';
                d_wait_request <= mem_wait_request;
                mem_read       <= d_read;
                mem_write      <= d_write;
            elsif i_read = '1' or i_write = '1' then
                i_wait_request <= mem_wait_request;
                d_wait_request <= '1';
                mem_read       <= i_read;
                mem_write      <= i_write;
            end if;
        end if;
    end process;

    datapath : process(d_read, d_write, i_read, i_write) is
    begin
        i_readdata    <= 32x"0";
        d_readdata    <= 32x"0";
        mem_writedata <= 32x"0";
        mem_adr       <= 32x"0";
        if d_read = '1' or d_write = '1' then
            d_readdata    <= mem_readdata;
            mem_writedata <= d_writedata;
            mem_adr       <= d_adr;
        elsif i_read = '1' or i_write = '1' then
            i_readdata    <= mem_readdata;
            mem_writedata <= i_writedata;
            mem_adr       <= i_adr;
        end if;
    end process;
end architecture arch;
