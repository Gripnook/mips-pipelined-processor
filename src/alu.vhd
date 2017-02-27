library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port(
        a          : in  std_logic_vector(31 downto 0);
        b          : in  std_logic_vector(31 downto 0);
        opcode     : in  std_logic_vector(5 downto 0);
        shamt      : in  std_logic_vector(4 downto 0);
        funct      : in  std_logic_vector(5 downto 0);
        alu_output : out std_logic_vector(63 downto 0));
end entity alu;

architecture arch of alu is
begin
    alu_output <= 64x"FEFEFEFEFEFEFEFE";
end architecture arch;
