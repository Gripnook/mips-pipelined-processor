library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_tb is
end entity arbiter_tb;

architecture arch of arbiter_tb is
    constant clock_period : time := 1 ns;

    signal clock         : std_logic;
    signal reset         : std_logic;
    signal i_addr        : integer := 0;
    signal i_read        : std_logic;
    signal i_readdata    : std_logic_vector(31 downto 0);
    signal i_write       : std_logic;
    signal i_writedata   : std_logic_vector(31 downto 0);
    signal i_waitrequest : std_logic;
    signal d_addr        : integer := 0;
    signal d_read        : std_logic;
    signal d_readdata    : std_logic_vector(31 downto 0);
    signal d_write       : std_logic;
    signal d_writedata   : std_logic_vector(31 downto 0);
    signal d_waitrequest : std_logic;
    signal m_addr        : integer := 0;
    signal m_read        : std_logic;
    signal m_readdata    : std_logic_vector(31 downto 0);
    signal m_write       : std_logic;
    signal m_writedata   : std_logic_vector(31 downto 0);
    signal m_waitrequest : std_logic;

    component arbiter is
        generic(RAM_SIZE : integer := 8192);
        port(clock         : in  std_logic;
             reset         : in  std_logic;
             i_addr        : in  integer range 0 to RAM_SIZE - 1;
             i_read        : in  std_logic;
             i_readdata    : out std_logic_vector(31 downto 0);
             i_write       : in  std_logic;
             i_writedata   : in  std_logic_vector(31 downto 0);
             i_waitrequest : out std_logic;
             d_addr        : in  integer range 0 to RAM_SIZE - 1;
             d_read        : in  std_logic;
             d_readdata    : out std_logic_vector(31 downto 0);
             d_write       : in  std_logic;
             d_writedata   : in  std_logic_vector(31 downto 0);
             d_waitrequest : out std_logic;
             m_addr        : out integer range 0 to RAM_SIZE - 1;
             m_read        : out std_logic;
             m_readdata    : in  std_logic_vector(31 downto 0);
             m_write       : out std_logic;
             m_writedata   : out std_logic_vector(31 downto 0);
             m_waitrequest : in  std_logic);
    end component;

    component memory is
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
    end component;

    procedure assert_equal(actual, expected : in std_logic_vector(31 downto 0); error_count : inout integer) is
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

    mem : memory
        port map(
            clock       => clock,
            writedata   => m_writedata,
            address     => m_addr,
            memwrite    => m_write,
            memread     => m_read,
            readdata    => m_readdata,
            waitrequest => m_waitrequest
        );

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    reset_process : process
    begin
        reset <= '1';
        wait for clock_period;
        reset <= '0';
        wait;
    end process;

    i_cache_process : process
        variable i_error_count : integer := 0;
    begin
        i_read  <= '0';
        i_write <= '0';

        wait until falling_edge(reset);

        i_read <= '1';
        i_addr <= 0;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 1;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 2;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 3;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 4;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 5;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 6;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        i_read <= '1';
        i_addr <= 7;
        wait until rising_edge(i_waitrequest);
        i_read <= '0';
        assert_equal(i_readdata, x"FFFFFFFF", i_error_count);

        wait until falling_edge(clock);

        report "Done. Found " & integer'image(i_error_count) & " instruction access error(s).";

        wait;
    end process;

    d_cache_process : process
        variable d_error_count : integer := 0;
    begin
        d_read  <= '0';
        d_write <= '0';

        wait until falling_edge(reset);

        d_write     <= '1';
        d_writedata <= x"0000000D";
        d_addr      <= 500;
        wait until rising_edge(d_waitrequest);
        d_write <= '0';

        wait until falling_edge(clock);

        d_write     <= '1';
        d_writedata <= x"0000000A";
        d_addr      <= 501;
        wait until rising_edge(d_waitrequest);
        d_write <= '0';

        wait until falling_edge(clock);

        d_write     <= '1';
        d_writedata <= x"00000006";
        d_addr      <= 502;
        wait until rising_edge(d_waitrequest);
        d_write <= '0';

        wait until falling_edge(clock);

        d_write     <= '1';
        d_writedata <= x"00000002";
        d_addr      <= 503;
        wait until rising_edge(d_waitrequest);
        d_write <= '0';

        wait until falling_edge(clock);

        wait for 50 * clock_period;

        d_read <= '1';
        d_addr <= 500;
        wait until rising_edge(d_waitrequest);
        d_read <= '0';
        assert_equal(d_readdata, x"0000000D", d_error_count);

        wait until falling_edge(clock);

        d_read <= '1';
        d_addr <= 501;
        wait until rising_edge(d_waitrequest);
        d_read <= '0';
        assert_equal(d_readdata, x"0000000A", d_error_count);

        wait until falling_edge(clock);

        d_read <= '1';
        d_addr <= 502;
        wait until rising_edge(d_waitrequest);
        d_read <= '0';
        assert_equal(d_readdata, x"00000006", d_error_count);

        wait until falling_edge(clock);

        d_read <= '1';
        d_addr <= 503;
        wait until rising_edge(d_waitrequest);
        d_read <= '0';
        assert_equal(d_readdata, x"00000002", d_error_count);

        wait until falling_edge(clock);

        report "Done. Found " & integer'image(d_error_count) & " data access error(s).";

        wait;
    end process;

end architecture arch;
