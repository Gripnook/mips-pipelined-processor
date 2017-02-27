library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hazard_detector is
    port(
        if_id  : in  std_logic_vector(31 downto 0);
        id_ex  : in  std_logic_vector(31 downto 0);
        ex_mem : in  std_logic_vector(31 downto 0);
        mem_wb : in  std_logic_vector(31 downto 0);
        stall  : out std_logic);
end entity hazard_detector;

architecture arch of hazard_detector is
begin
    stall <= '1';
end architecture arch;
