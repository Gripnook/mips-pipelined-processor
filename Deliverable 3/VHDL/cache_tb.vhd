library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is
    component cache is
        generic(
            ram_size : INTEGER := 32768
        );
        port(
            clock         : in  std_logic;
            reset         : in  std_logic;

            -- Avalon interface --
            s_addr        : in  std_logic_vector(31 downto 0);
            s_read        : in  std_logic;
            s_readdata    : out std_logic_vector(31 downto 0);
            s_write       : in  std_logic;
            s_writedata   : in  std_logic_vector(31 downto 0);
            s_waitrequest : out std_logic;
            m_addr        : out integer range 0 to ram_size - 1;
            m_read        : out std_logic;
            m_readdata    : in  std_logic_vector(7 downto 0);
            m_write       : out std_logic;
            m_writedata   : out std_logic_vector(7 downto 0);
            m_waitrequest : in  std_logic
        );
    end component;

    component memory is
        GENERIC(
            ram_size     : INTEGER := 32768;
            mem_delay    : time    := 10 ns;
            clock_period : time    := 1 ns
        );
        PORT(
            clock       : IN  STD_LOGIC;
            writedata   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            address     : IN  INTEGER RANGE 0 TO ram_size - 1;
            memwrite    : IN  STD_LOGIC;
            memread     : IN  STD_LOGIC;
            readdata    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            waitrequest : OUT STD_LOGIC
        );
    end component;

    -- test signals
    signal clock          : std_logic := '0';
    signal reset          : std_logic := '0';
    constant clock_period : time      := 1 ns;

    signal s_addr        : std_logic_vector(31 downto 0);
    signal s_read        : std_logic;
    signal s_readdata    : std_logic_vector(31 downto 0);
    signal s_write       : std_logic;
    signal s_writedata   : std_logic_vector(31 downto 0);
    signal s_waitrequest : std_logic;

    signal m_addr        : integer range 0 to 2147483647;
    signal m_read        : std_logic;
    signal m_readdata    : std_logic_vector(7 downto 0);
    signal m_write       : std_logic;
    signal m_writedata   : std_logic_vector(7 downto 0);
    signal m_waitrequest : std_logic;

    function to_address(tag, block_index, block_offset : integer) return std_logic_vector is
        variable addr : std_logic_vector(31 downto 0);
    begin
        addr(31 downto 15) := (others => '0');
        addr(14 downto 9) := std_logic_vector(to_unsigned(tag, 6));
        addr(8 downto 4) := std_logic_vector(to_unsigned(block_index, 5));
        addr(3 downto 2) := std_logic_vector(to_unsigned(block_offset, 2));
        addr(1 downto 0) := (others => '0');
        return addr;
    end to_address;

    procedure assert_equal(actual, expected : in std_logic_vector(31 downto 0)) is
    begin
        ASSERT (actual = expected) REPORT "The data should be " & integer'image(to_integer(signed(expected))) & " but was " & integer'image(to_integer(signed(actual))) SEVERITY ERROR;
    end assert_equal;

begin

    --dut => Device Under Test
    dut : cache
        port map(
            clock         => clock,
            reset         => reset,
            s_addr        => s_addr,
            s_read        => s_read,
            s_readdata    => s_readdata,
            s_write       => s_write,
            s_writedata   => s_writedata,
            s_waitrequest => s_waitrequest,
            m_addr        => m_addr,
            m_read        => m_read,
            m_readdata    => m_readdata,
            m_write       => m_write,
            m_writedata   => m_writedata,
            m_waitrequest => m_waitrequest
        );

    MEM : memory
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

    test_process : process
    begin

        s_write <= '0';
        s_read <= '0';

        reset <= '1';
        wait for clock_period;
        reset <= '0';
        wait for clock_period;

        -----------------------------------------------------
        ---------------------Test#1: Write-------------------
        --This test performs the first write operation

        s_addr <= to_address(1, 1, 0);
        s_writedata <= x"FFFFFFFF";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#2: Read--------------------
        --This test confirms that Test#1 was successful and checks
        --the ability to read from an address

        s_addr <= to_address(1, 1, 0);
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        s_read <= '0';

        assert_equal(s_readdata, x"FFFFFFFF");

        -----------------------------------------------------
        ---------------------Test#3: Write-------------------
        --This test attempts to overwrite the data stored from Test#1
        --with different data. This checks that writeback works

        s_addr <= to_address(1, 1, 0);
        s_writedata <= x"00000057";
        s_write <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#4: Read--------------------
        --This test ensures that the data written in Test#1 was successfully
        --overwritten with the data from Test#3

        s_addr <= to_address(1, 1, 0);
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        s_read <= '0';

        assert_equal(s_readdata, x"00000057");

        -----------------------------------------------------
        ---------------------Test#5: Write-------------------
        --This test fills up the remaining 3 word blocks
        --in the line ensuring that we can write to full 16B lines

        s_write <= '1';

        s_addr <= to_address(1, 1, 1);
        s_writedata <= x"00000058";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr <= to_address(1, 1, 2);
        s_writedata <= x"00000059";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr <= to_address(1, 1, 3);
        s_writedata <= x"0000005A";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        
        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#6: Read--------------------
        --This test confirms that Test#5 was successful and
        --ensures that we can address individual words

        s_read <= '1';

        s_addr <= to_address(1, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"00000058");

        s_addr <= to_address(1, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"00000059");

        s_addr <= to_address(1, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        
        assert_equal(s_readdata, x"0000005A");

        s_read <= '0';

        wait;

    end process;

end behavior;
