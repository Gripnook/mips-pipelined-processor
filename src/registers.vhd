library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

ENTITY registers IS
  port (clock         : IN  std_logic;
        regWrite      : IN  std_logic;
        rs_adr        : IN  std_logic_vector(4 downto 0);
        rt_adr        : IN  std_logic_vector(4 downto 0);
        instruction   : IN  std_logic_vector(31 downto 0);
        wb_data       : IN  std_logic_vector(31 downto 0);
        id_rs         : OUT std_logic_vector(31 downto 0);
        id_rt         : OUT std_logic_vector(31 downto 0)
        );
end registers;

ARCHITECTURE registers_arc OF registers IS

  TYPE REG IS ARRAY (31 downto 0) OF std_logic_vector(31 downto 0);

  signal registers : REG;

BEGIN

registers(0) <= x"0000";

write : process(clock)
BEGIN

  if(rising_edge(clock)) then
    if(regWrite = '1') then
      registers(to_integer(to_unsigned(instruction(20 downto 16)))) <= wb_data;
    end if;
  end if;

END process;

read : process(clock)
BEGIN

  if(falling_edge(clock)) then
    id_rs <= registers(to_integer(to_unsigned(rs_adr,5)));
    id_rt <= registers(to_integer(to_unsigned(rt_adr,5)));
  end if;

END process;

END registers_arc;
