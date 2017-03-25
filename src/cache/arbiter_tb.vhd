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
        -------------- Memory arbitration ---------------
        report "Testing memory arbitration";

        reset <= '1';
        wait for clock_period;
        reset <= '0';

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-1: X/X/X/X/X";
        i_read        <= '0';
        i_write       <= '0';
        d_read        <= '0';
        d_write       <= '0';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '0', error_count);
        assert_equal_bit(d_waitrequest, '0', error_count);
        assert_equal_bit(m_read, '0', error_count);
        assert_equal_bit(m_write, '0', error_count);

        assert_equal(i_readdata, 8x"0", error_count);
        assert_equal(d_readdata, 8x"0", error_count);
        assert_equal(m_writedata, 8x"0", error_count);
        assert_equal(m_addr, 8x"0", error_count);
        -----------------------------------------------------


        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-2: i_read/X/X/X/X";
        i_read        <= '1';
        i_write       <= '0';
        d_read        <= '0';
        d_write       <= '0';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '0', error_count);
        assert_equal_bit(d_waitrequest, '1', error_count);
        assert_equal_bit(m_read, '1', error_count);
        assert_equal_bit(m_write, '0', error_count);

        assert_equal(i_readdata, 8x"55", error_count);
        assert_equal(d_readdata, 8x"0", error_count);
        assert_equal(m_writedata, 8x"FF", error_count);
        assert_equal(m_addr, 8x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-3: i_write/X/X/X/X";
        i_read        <= '0';
        i_write       <= '1';
        d_read        <= '0';
        d_write       <= '0';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '0', error_count);
        assert_equal_bit(d_waitrequest, '1', error_count);
        assert_equal_bit(m_read, '0', error_count);
        assert_equal_bit(m_write, '1', error_count);

        assert_equal(i_readdata, 8x"55", error_count);
        assert_equal(d_readdata, 8x"0", error_count);
        assert_equal(m_writedata, 8x"FF", error_count);
        assert_equal(m_addr, 8x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-4: d_read/X/X/X/X";
        i_read        <= '0';
        i_write       <= '0';
        d_read        <= '1';
        d_write       <= '0';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '1', error_count);
        assert_equal_bit(d_waitrequest, '0', error_count);
        assert_equal_bit(m_read, '1', error_count);
        assert_equal_bit(m_write, '0', error_count);

        assert_equal(i_readdata, 8x"0", error_count);
        assert_equal(d_readdata, 8x"55", error_count);
        assert_equal(m_writedata, 8x"AA", error_count);
        assert_equal(m_addr, 8x"AA", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-5: d_write/X/X/X/X";
        i_read        <= '0';
        i_write       <= '0';
        d_read        <= '0';
        d_write       <= '1';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '1', error_count);
        assert_equal_bit(d_waitrequest, '0', error_count);
        assert_equal_bit(m_read, '0', error_count);
        assert_equal_bit(m_write, '1', error_count);

        assert_equal(i_readdata, 8x"0", error_count);
        assert_equal(d_readdata, 8x"55", error_count);
        assert_equal(m_writedata, 8x"AA", error_count);
        assert_equal(m_addr, 8x"AA", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-6: d_write/d_read/X/X/X";
        i_read        <= '0';
        i_write       <= '0';
        d_read        <= '1';
        d_write       <= '1';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '1', error_count);
        assert_equal_bit(d_waitrequest, '0', error_count);
        assert_equal_bit(m_read, '1', error_count);
        assert_equal_bit(m_write, '1', error_count);

        assert_equal(i_readdata, 8x"0", error_count);
        assert_equal(d_readdata, 8x"55", error_count);
        assert_equal(m_writedata, 8x"AA", error_count);
        assert_equal(m_addr, 8x"AA", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-7: i_write/i_read/X/X/X";
        i_read        <= '1';
        i_write       <= '1';
        d_read        <= '0';
        d_write       <= '0';
        m_waitrequest <= '0';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '0', error_count);
        assert_equal_bit(d_waitrequest, '1', error_count);
        assert_equal_bit(m_read, '1', error_count);
        assert_equal_bit(m_write, '1', error_count);

        assert_equal(i_readdata, 8x"55", error_count);
        assert_equal(d_readdata, 8x"0", error_count);
        assert_equal(m_writedata, 8x"FF", error_count);
        assert_equal(m_addr, 8x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-8: m_waitrequest/X/X/X/X";
        i_read        <= '0';
        i_write       <= '0';
        d_read        <= '0';
        d_write       <= '0';
        m_waitrequest <= '1';

        i_writedata <= 8x"FF";
        i_addr      <= 8x"FF";
        d_writedata <= 8x"AA";
        d_addr      <= 8x"AA";
        m_readdata  <= 8x"55";

        wait for clock_period;

        assert_equal_bit(i_waitrequest, '1', error_count);
        assert_equal_bit(d_waitrequest, '1', error_count);
        assert_equal_bit(m_read, '0', error_count);
        assert_equal_bit(m_write, '0', error_count);

        assert_equal(i_readdata, 8x"0", error_count);
        assert_equal(d_readdata, 8x"0", error_count);
        assert_equal(m_writedata, 8x"0", error_count);
        assert_equal(m_addr, 8x"0", error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end architecture arch;
