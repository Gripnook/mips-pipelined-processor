library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
    port(clock      : in  std_logic;
         reset      : in  std_logic;
         rs_addr    : in  std_logic_vector(4 downto 0);
         rt_addr    : in  std_logic_vector(4 downto 0);
         write_en   : in  std_logic;
         write_addr : in  std_logic_vector(4 downto 0);
         writedata  : in  std_logic_vector(31 downto 0);
         rs         : out std_logic_vector(31 downto 0);
         rt         : out std_logic_vector(31 downto 0));
end registers;

architecture arch of registers is
    type reg_type is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_type;

begin
    registers(0) <= (others => '0');    -- $0 is hard wired to 0

    process(clock, reset)
    begin
        if (reset = '1') then
            for i in 0 to 31 loop
                registers(i) <= (others => '0');
            end loop;
        elsif (rising_edge(clock)) then
            if (write_en = '1' and write_addr /= "00000") then
                registers(to_integer(unsigned(write_addr))) <= writedata;
            end if;
        elsif (falling_edge(clock)) then
            rs <= registers(to_integer(unsigned(rs_addr)));
            rt <= registers(to_integer(unsigned(rt_addr)));
        end if;
    end process;

end arch;
