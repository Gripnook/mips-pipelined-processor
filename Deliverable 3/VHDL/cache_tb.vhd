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

    signal s_addr        : std_logic_vector(31 downto 0) := (others => '0');
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
        addr(14 downto 9)  := std_logic_vector(to_unsigned(tag, 6));
        addr(8 downto 4)   := std_logic_vector(to_unsigned(block_index, 5));
        addr(3 downto 2)   := std_logic_vector(to_unsigned(block_offset, 2));
        addr(1 downto 0)   := (others => '0');
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
        s_read  <= '0';

        reset <= '1';
        wait for clock_period;
        reset <= '0';
        wait for clock_period;

        -----------------------------------------------------
        ---------------------Test#1: Write-------------------
        --This test performs the first write operation

        s_addr      <= to_address(1, 1, 0);
        s_writedata <= x"FFFFFFFF";
        s_write     <= '1';
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
        --with different data. This checks that we can overwrite data

        s_addr      <= to_address(1, 1, 0);
        s_writedata <= x"00000057";
        s_write     <= '1';
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

        s_addr      <= to_address(1, 1, 1);
        s_writedata <= x"00000058";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(1, 1, 2);
        s_writedata <= x"00000059";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(1, 1, 3);
        s_writedata <= x"0000005A";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#6: Read--------------------
        --This test confirms that Test#5 was successful and
        --ensures that we can address individual words

        s_read <= '1';

        s_addr <= to_address(1, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"00000057");

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

        -----------------------------------------------------
        ---------------------Test#7: Write-------------------
        --This test overwrites the data written in Tests#3,5
        --with data with a different tag. The whole block must
        --be then written to memory

        s_write <= '1';

        s_addr      <= to_address(2, 1, 0);
        s_writedata <= x"0000002C";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(2, 1, 1);
        s_writedata <= x"0000002D";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(2, 1, 2);
        s_writedata <= x"0000002E";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(2, 1, 3);
        s_writedata <= x"0000002F";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#8: Read--------------------
        --This test confirms that Test#7 sucessfully wrote the
        --data from 5 to memory and was retreived

        s_read <= '1';

        s_addr <= to_address(1, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"00000057");

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

        -----------------------------------------------------
        ---------------------Test#9: Read--------------------
        --This test confirms that we can still access the data
        --we wrote in Test#7 which has a different tag

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"0000002C");

        s_addr <= to_address(2, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"0000002D");

        s_addr <= to_address(2, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"0000002E");

        s_addr <= to_address(2, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"0000002F");

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#10: Write-------------------
        --This test writes data to a line in cache that should
        --have valid bit but not dirty bit since the data was
        --retreived from memory in Test#7, hence clean

        s_write <= '1';

        s_addr      <= to_address(3, 1, 0);
        s_writedata <= x"000003B1";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(3, 1, 1);
        s_writedata <= x"000003B2";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(3, 1, 2);
        s_writedata <= x"000003B3";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(3, 1, 3);
        s_writedata <= x"000003B4";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#11: Read--------------------
        --This test confirms that the write in Test#10 did
        --indeed overwrite the data in the block and that
        --it doesn't redundantly write back to memory

        s_read <= '1';

        s_addr <= to_address(3, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B1");

        s_addr <= to_address(3, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B2");

        s_addr <= to_address(3, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B3");

        s_addr <= to_address(3, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B4");

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#12: Read--------------------
        --This test reads the data written in Test#7, putting
        --non-dirty data in the cache

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B1");

        s_addr <= to_address(2, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B2");

        s_addr <= to_address(2, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B3");

        s_addr <= to_address(2, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B4");

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#13: Write-------------------
        --This test overwrites one of the words in the block retreived
        --in Test#12 thus making it dirty and should be written to
        --memory on the next cache index write

        s_write <= '1';

        s_addr      <= to_address(2, 1, 0);
        s_writedata <= x"000003B0";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#14: Write-------------------
        --This test writes data to the same index as Test#13,
        --which should move that data to memory and then replace
        --it with the data here

        s_write <= '1';

        s_addr      <= to_address(4, 1, 0);
        s_writedata <= x"00000555";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#15: Read--------------------
        --This test reads the data written in Test#13 which
        --should be accessed from memory

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"000003B0");

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#16: Read--------------------
        --This test attemps to read the memory written in Test#14
        --which should now be in memory because of the read in Test#15

        s_read <= '1';

        s_addr <= to_address(4, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"00000555");

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#17: Write-------------------
        --This test writes some random data to random indices

        s_write <= '1';

        s_addr      <= to_address(5, 2, 0);
        s_writedata <= x"11111111";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(6, 4, 1);
        s_writedata <= x"22222222";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(7, 8, 2);
        s_writedata <= x"33333333";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(8, 12, 3);
        s_writedata <= x"44444444";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(9, 16, 0);
        s_writedata <= x"55555555";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(10, 20, 1);
        s_writedata <= x"66666666";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(11, 24, 2);
        s_writedata <= x"77777777";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(12, 28, 3);
        s_writedata <= x"88888888";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(13, 31, 0);
        s_writedata <= x"99999999";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#18: Write-------------------
        --This test writes data to same indices as in Test#16
        --but with different data/tags
        s_addr      <= to_address(14, 2, 0);
        s_writedata <= x"AAAAAAAA";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(15, 4, 0);
        s_writedata <= x"BBBBBBBB";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(16, 8, 0);
        s_writedata <= x"CCCCCCCC";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(17, 12, 0);
        s_writedata <= x"DDDDDDDD";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(18, 16, 0);
        s_writedata <= x"EEEEEEEE";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(19, 20, 0);
        s_writedata <= x"FFFFFFFF";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(20, 24, 0);
        s_writedata <= x"01234567";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(21, 28, 0);
        s_writedata <= x"89ABCDEF";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_addr      <= to_address(22, 31, 0);
        s_writedata <= x"AAAAAAAA";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#19: Read--------------------
        --This test reads the original data that was written in
        --Test#17, it also moves Test#18 data to memory

        s_read <= '1';

        s_addr      <= to_address(5, 2, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"11111111");

        s_addr      <= to_address(6, 4, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"22222222");

        s_addr      <= to_address(7, 8, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"33333333");

        s_addr      <= to_address(8, 12, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"44444444");

        s_addr      <= to_address(9, 16, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"55555555");

        s_addr      <= to_address(10, 20, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"66666666");

        s_addr      <= to_address(11, 24, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"77777777");

        s_addr      <= to_address(12, 28, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"88888888");

        s_addr      <= to_address(13, 31, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);

        assert_equal(s_readdata, x"99999999");

        s_read <= '0';

        wait;

    end process;

end behavior;
