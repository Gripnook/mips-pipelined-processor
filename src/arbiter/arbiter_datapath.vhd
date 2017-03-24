library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_datapath is
    port(
        clk           : in  std_logic;
        rst           : in  std_logic;
        -- I$
        i_readdata    : out std_logic_vector(31 downto 0);
        i_writedata   : in  std_logic_vector(31 downto 0);
        i_adr         : in  std_logic_vector(31 downto 0);

        -- D$
        d_readdata    : out std_logic_vector(31 downto 0);
        d_writedata   : in  std_logic_vector(31 downto 0);
        d_adr         : in  std_logic_vector(31 downto 0);

        -- Memory
        mem_readdata  : in  std_logic_vector(31 downto 0);
        mem_writedata : out std_logic_vector(31 downto 0);
        mem_adr       : out std_logic_vector(31 downto 0));
end entity arbiter_datapath;

architecture arch of arbiter_datapath is
begin
end architecture arch;
