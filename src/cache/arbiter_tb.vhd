library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_tb is
end entity arbiter_tb;

architecture arch of arbiter_tb is

    signal clock         : std_logic;
    signal reset         : std_logic;
    signal i_addr        : std_logic_vector(7 downto 0);
    signal i_read        : std_logic;
    signal i_readdata    : std_logic_vector(7 downto 0);
    signal i_write       : std_logic;
    signal i_writedata   : std_logic_vector(7 downto 0);
    signal i_waitrequest : std_logic;
    signal d_addr        : std_logic_vector(7 downto 0);
    signal d_read        : std_logic;
    signal d_readdata    : std_logic_vector(7 downto 0);
    signal d_write       : std_logic;
    signal d_writedata   : std_logic_vector(7 downto 0);
    signal d_waitrequest : std_logic;
    signal m_addr        : std_logic_vector(7 downto 0);
    signal m_read        : std_logic;
    signal m_readdata    : std_logic_vector(7 downto 0);
    signal m_write       : std_logic;
    signal m_writedata   : std_logic_vector(7 downto 0);
    signal m_waitrequest : std_logic;

    component arbiter is
        port(
            clock         : in  std_logic;
            reset         : in  std_logic;
            i_addr        : in  std_logic_vector(7 downto 0);
            i_read        : in  std_logic;
            i_readdata    : out std_logic_vector(7 downto 0);
            i_write       : in  std_logic;
            i_writedata   : in  std_logic_vector(7 downto 0);
            i_waitrequest : out std_logic;
            d_addr        : in  std_logic_vector(7 downto 0);
            d_read        : in  std_logic;
            d_readdata    : out std_logic_vector(7 downto 0);
            d_write       : in  std_logic;
            d_writedata   : in  std_logic_vector(7 downto 0);
            d_waitrequest : out std_logic;
            m_addr        : out std_logic_vector(7 downto 0);
            m_read        : out std_logic;
            m_readdata    : in  std_logic_vector(7 downto 0);
            m_write       : out std_logic;
            m_writedata   : out std_logic_vector(7 downto 0);
            m_waitrequest : in  std_logic
        );
    end component;

    component memory is
        generic(
            ram_size     : integer := 32768;
            mem_delay    : time    := 10 ns;
            clock_period : time    := 1 ns
        );
        port(
            clock       : in  std_logic;
            writedata   : in  std_logic_vector(7 downto 0);
            address     : in  integer range 0 to ram_size - 1;
            memwrite    : in  std_logic;
            memread     : in  std_logic;
            readdata    : out std_logic_vector(7 downto 0);
            waitrequest : out std_logic
        );
    end component;

    constant clock_period : time := 1 ns;

    procedure assert_equal(actual, expected : in std_logic_vector(7 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & to_string(expected) & " but was " & to_string(actual) severity error;
    end assert_equal;

    procedure assert_equal_bit(actual, expected : in std_logic; error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & to_string(expected) & " but was " & to_string(actual) severity error;
    end assert_equal_bit;

begin

    dut : arbiter
        port map(
            clock         => clock,
            reset         => reset,
            i_addr        => i_addr,
            i_read        => i_read,
            i_readdata    => i_readdata,
            i_write       => i_write,
            i_writedata   => i_writedata,
            i_waitrequest => i_waitrequest,
            d_addr        => d_addr,
            d_read        => d_read,
            d_readdata    => d_readdata,
            d_write       => d_write,
            d_writedata   => d_writedata,
            d_waitrequest => d_waitrequest,
            m_addr        => m_addr,
            m_read        => m_read,
            m_readdata    => m_readdata,
            m_write       => m_write,
            m_writedata   => m_writedata,
            m_waitrequest => m_waitrequest
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
        variable error_count : integer := 0;
    begin
        report "Testing memory arbitration";

        reset <= '1';
        wait for clock_period;
        reset <= '0';

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
