library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arbiter_tb is
end entity arbiter_tb;

architecture arch of arbiter_tb is
    -- test signals

    constant clock_period : time := 1 ns;

    signal clock : std_logic;
    signal reset : std_logic;

    signal i_read         : std_logic;
    signal i_write        : std_logic;
    signal i_wait_request : std_logic;

    signal d_read         : std_logic;
    signal d_write        : std_logic;
    signal d_wait_request : std_logic;

    signal mem_read         : std_logic;
    signal mem_write        : std_logic;
    signal mem_wait_request : std_logic;

    signal i_readdata  : std_logic_vector(31 downto 0);
    signal i_writedata : std_logic_vector(31 downto 0);
    signal i_adr       : std_logic_vector(31 downto 0);

    signal d_readdata  : std_logic_vector(31 downto 0);
    signal d_writedata : std_logic_vector(31 downto 0);
    signal d_adr       : std_logic_vector(31 downto 0);

    signal mem_readdata  : std_logic_vector(31 downto 0);
    signal mem_writedata : std_logic_vector(31 downto 0);
    signal mem_adr       : std_logic_vector(31 downto 0);

    component arbiter
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
    end component arbiter;

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
            clock            => clock,
            reset            => reset,
            i_read           => i_read,
            i_write          => i_write,
            i_wait_request   => i_wait_request,
            d_read           => d_read,
            d_write          => d_write,
            d_wait_request   => d_wait_request,
            mem_read         => mem_read,
            mem_write        => mem_write,
            mem_wait_request => mem_wait_request,
            i_readdata       => i_readdata,
            i_writedata      => i_writedata,
            i_adr            => i_adr,
            d_readdata       => d_readdata,
            d_writedata      => d_writedata,
            d_adr            => d_adr,
            mem_readdata     => mem_readdata,
            mem_writedata    => mem_writedata,
            mem_adr          => mem_adr
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
        i_read           <= '0';
        i_write          <= '0';
        d_read           <= '0';
        d_write          <= '0';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '0', error_count);
        assert_equal_bit(d_wait_request, '0', error_count);
        assert_equal_bit(mem_read, '0', error_count);
        assert_equal_bit(mem_write, '0', error_count);

        assert_equal(i_readdata, 32x"0", error_count);
        assert_equal(d_readdata, 32x"0", error_count);
        assert_equal(mem_writedata, 32x"0", error_count);
        assert_equal(mem_adr, 32x"0", error_count);
        -----------------------------------------------------


        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-2: i_read/X/X/X/X";
        i_read           <= '1';
        i_write          <= '0';
        d_read           <= '0';
        d_write          <= '0';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '0', error_count);
        assert_equal_bit(d_wait_request, '1', error_count);
        assert_equal_bit(mem_read, '1', error_count);
        assert_equal_bit(mem_write, '0', error_count);

        assert_equal(i_readdata, 32x"55", error_count);
        assert_equal(d_readdata, 32x"0", error_count);
        assert_equal(mem_writedata, 32x"FF", error_count);
        assert_equal(mem_adr, 32x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-3: i_write/X/X/X/X";
        i_read           <= '0';
        i_write          <= '1';
        d_read           <= '0';
        d_write          <= '0';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '0', error_count);
        assert_equal_bit(d_wait_request, '1', error_count);
        assert_equal_bit(mem_read, '0', error_count);
        assert_equal_bit(mem_write, '1', error_count);

        assert_equal(i_readdata, 32x"55", error_count);
        assert_equal(d_readdata, 32x"0", error_count);
        assert_equal(mem_writedata, 32x"FF", error_count);
        assert_equal(mem_adr, 32x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-4: d_read/X/X/X/X";
        i_read           <= '0';
        i_write          <= '0';
        d_read           <= '1';
        d_write          <= '0';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '1', error_count);
        assert_equal_bit(d_wait_request, '0', error_count);
        assert_equal_bit(mem_read, '1', error_count);
        assert_equal_bit(mem_write, '0', error_count);

        assert_equal(i_readdata, 32x"0", error_count);
        assert_equal(d_readdata, 32x"55", error_count);
        assert_equal(mem_writedata, 32x"AA", error_count);
        assert_equal(mem_adr, 32x"AA", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-5: d_write/X/X/X/X";
        i_read           <= '0';
        i_write          <= '0';
        d_read           <= '0';
        d_write          <= '1';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '1', error_count);
        assert_equal_bit(d_wait_request, '0', error_count);
        assert_equal_bit(mem_read, '0', error_count);
        assert_equal_bit(mem_write, '1', error_count);

        assert_equal(i_readdata, 32x"0", error_count);
        assert_equal(d_readdata, 32x"55", error_count);
        assert_equal(mem_writedata, 32x"AA", error_count);
        assert_equal(mem_adr, 32x"AA", error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-6: d_write/d_read/X/X/X";
        i_read           <= '0';
        i_write          <= '0';
        d_read           <= '1';
        d_write          <= '1';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '1', error_count);
        assert_equal_bit(d_wait_request, '0', error_count);
        assert_equal_bit(mem_read, '1', error_count);
        assert_equal_bit(mem_write, '1', error_count);

        assert_equal(i_readdata, 32x"0", error_count);
        assert_equal(d_readdata, 32x"55", error_count);
        assert_equal(mem_writedata, 32x"AA", error_count);
        assert_equal(mem_adr, 32x"AA", error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-7: i_write/i_read/X/X/X";
        i_read           <= '1';
        i_write          <= '1';
        d_read           <= '0';
        d_write          <= '0';
        mem_wait_request <= '0';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '0', error_count);
        assert_equal_bit(d_wait_request, '1', error_count);
        assert_equal_bit(mem_read, '1', error_count);
        assert_equal_bit(mem_write, '1', error_count);

        assert_equal(i_readdata, 32x"55", error_count);
        assert_equal(d_readdata, 32x"0", error_count);
        assert_equal(mem_writedata, 32x"FF", error_count);
        assert_equal(mem_adr, 32x"FF", error_count);
        -----------------------------------------------------

        -----------------------------------------------------
        -----------------------------------------------------
        report "Test#1-8: mem_wait_request/X/X/X/X";
        i_read           <= '0';
        i_write          <= '0';
        d_read           <= '0';
        d_write          <= '0';
        mem_wait_request <= '1';

        i_writedata  <= 32x"FF";
        i_adr        <= 32x"FF";
        d_writedata  <= 32x"AA";
        d_adr        <= 32x"AA";
        mem_readdata <= 32x"55";

        wait for clock_period;

        assert_equal_bit(i_wait_request, '1', error_count);
        assert_equal_bit(d_wait_request, '1', error_count);
        assert_equal_bit(mem_read, '0', error_count);
        assert_equal_bit(mem_write, '0', error_count);

        assert_equal(i_readdata, 32x"0", error_count);
        assert_equal(d_readdata, 32x"0", error_count);
        assert_equal(mem_writedata, 32x"0", error_count);
        assert_equal(mem_adr, 32x"0", error_count);
        -----------------------------------------------------

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;
end architecture arch;
