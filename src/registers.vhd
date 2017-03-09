library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY registers IS
  port (clock         : IN  std_logic;
        reset         : IN  std_logic;
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

registers(0) <= x"00000000";

reset : process(reset)
begin

  if(reset = '1') then

    For i in 0 to 31 LOOP
        registers(i) <= std_logic_vector(to_unsigned(0, 32));
    END LOOP;

  end if;
end process reset;

write : process(clock)
BEGIN

  if(rising_edge(clock)) then
    if(regWrite = '1') then
      registers(to_integer(unsigned(instruction(20 downto 16)))) <= wb_data;
    end if;
  end if;

END process;

read : process(clock)
BEGIN

  if(falling_edge(clock)) then
    id_rs <= registers(to_integer(unsigned(rs_adr)));
    id_rt <= registers(to_integer(unsigned(rt_adr)));
  end if;

END process;

END registers_arc;
