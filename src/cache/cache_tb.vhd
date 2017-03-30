library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is
    component cache is
        generic(CACHE_SIZE : integer := 512;
                RAM_SIZE   : integer := 8192);
        port(clock         : in  std_logic;
             reset         : in  std_logic;
             -- Avalon interface --
             s_addr        : in  std_logic_vector(31 downto 0);
             s_read        : in  std_logic;
             s_readdata    : out std_logic_vector(31 downto 0);
             s_write       : in  std_logic;
             s_writedata   : in  std_logic_vector(31 downto 0);
             s_waitrequest : out std_logic;
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

    constant clock_period : time := 1 ns;

    signal clock : std_logic := '0';
    signal reset : std_logic := '0';

    signal s_addr        : std_logic_vector(31 downto 0) := (others => '0');
    signal s_read        : std_logic;
    signal s_readdata    : std_logic_vector(31 downto 0);
    signal s_write       : std_logic;
    signal s_writedata   : std_logic_vector(31 downto 0);
    signal s_waitrequest : std_logic;

    signal m_addr        : integer;
    signal m_read        : std_logic;
    signal m_readdata    : std_logic_vector(31 downto 0);
    signal m_write       : std_logic;
    signal m_writedata   : std_logic_vector(31 downto 0);
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

    procedure assert_equal(actual, expected : in std_logic_vector(31 downto 0); error_count : inout integer) is
    begin
        if (actual /= expected) then
            error_count := error_count + 1;
        end if;
        assert (actual = expected) report "The data should be " & integer'image(to_integer(signed(expected))) & " but was " & integer'image(to_integer(signed(actual))) severity error;
    end assert_equal;

begin

    --dut => Device Under Test
    dut : cache
        port map(clock         => clock,
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
                 m_waitrequest => m_waitrequest);

    mem : memory
        port map(clock       => clock,
                 writedata   => m_writedata,
                 address     => m_addr,
                 memwrite    => m_write,
                 memread     => m_read,
                 readdata    => m_readdata,
                 waitrequest => m_waitrequest);

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
        s_write <= '0';
        s_read  <= '0';

        reset <= '1';
        wait for clock_period;
        reset <= '0';
        wait for clock_period;

        -----------------------------------------------------
        ---------------------Test#1: Write-------------------
        --This test performs the first write operation
        report "Test#1: Write";
        report "Covers cases write/invalid/x/x";

        s_addr      <= to_address(1, 1, 0);
        s_writedata <= x"FFFFFFFF";
        s_write     <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);
        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#2: Read--------------------
        --This test confirms that Test#1 was successful and checks
        --the ability to read from an address
        report "Test#2: Read";
        report "Covers cases read/valid/hit/x";

        s_addr <= to_address(1, 1, 0);
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);
        s_read <= '0';

        assert_equal(s_readdata, x"FFFFFFFF", error_count);

        -----------------------------------------------------
        ---------------------Test#3: Write-------------------
        --This test attempts to overwrite the data stored from Test#1
        --with different data. This checks that we can overwrite data
        report "Test#3: Write";
        report "Covers cases write/valid/hit/x";

        s_addr      <= to_address(1, 1, 0);
        s_writedata <= x"00000057";
        s_write     <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);
        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#4: Read--------------------
        --This test ensures that the data written in Test#1 was successfully
        --overwritten with the data from Test#3
        report "Test#4: Read";
        report "Covers cases read/valid/hit/x";

        s_addr <= to_address(1, 1, 0);
        s_read <= '1';
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);
        s_read <= '0';

        assert_equal(s_readdata, x"00000057", error_count);

        -----------------------------------------------------
        ---------------------Test#5: Write-------------------
        --This test fills up the remaining 3 word blocks
        --in the line ensuring that we can write to full 16B lines
        report "Test#5: Write";
        report "Covers cases write/valid/hit/x";

        s_write <= '1';

        s_addr      <= to_address(1, 1, 1);
        s_writedata <= x"00000058";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(1, 1, 2);
        s_writedata <= x"00000059";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(1, 1, 3);
        s_writedata <= x"0000005A";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#6: Read--------------------
        --This test confirms that Test#5 was successful and
        --ensures that we can address individual words
        report "Test#6: Read";
        report "Covers cases read/valid/hit/x";

        s_read <= '1';

        s_addr <= to_address(1, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000057", error_count);

        s_addr <= to_address(1, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000058", error_count);

        s_addr <= to_address(1, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000059", error_count);

        s_addr <= to_address(1, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000005A", error_count);

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#7: Write-------------------
        --This test overwrites the data written in Tests#3,5
        --with data with a different tag. The whole block must
        --be then written to memory
        report "Test#7: Write";
        report "Covers cases write/valid/miss/dirty";

        s_write <= '1';

        s_addr      <= to_address(2, 1, 0);
        s_writedata <= x"0000002C";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(2, 1, 1);
        s_writedata <= x"0000002D";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(2, 1, 2);
        s_writedata <= x"0000002E";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(2, 1, 3);
        s_writedata <= x"0000002F";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#8: Read--------------------
        --This test confirms that Test#7 successfully wrote the
        --data from 5 to memory and was retrieved
        report "Test#8: Read";
        report "Covers cases read/valid/miss/dirty";

        s_read <= '1';

        s_addr <= to_address(1, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000057", error_count);

        s_addr <= to_address(1, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000058", error_count);

        s_addr <= to_address(1, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000059", error_count);

        s_addr <= to_address(1, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000005A", error_count);

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#9: Read--------------------
        --This test confirms that we can still access the data
        --we wrote in Test#7 which has a different tag
        report "Test#9: Read";
        report "Covers cases read/valid/miss/clean";

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002C", error_count);

        s_addr <= to_address(2, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002D", error_count);

        s_addr <= to_address(2, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002E", error_count);

        s_addr <= to_address(2, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002F", error_count);

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#10: Write-------------------
        --This test writes data to a line in cache that should
        --have valid bit but not dirty bit since the data was
        --retrieved from memory in Test#9, hence clean
        report "Test#10: Write";
        report "Covers cases write/valid/miss/clean";

        s_write <= '1';

        s_addr      <= to_address(3, 1, 0);
        s_writedata <= x"000003B1";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(3, 1, 1);
        s_writedata <= x"000003B2";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(3, 1, 2);
        s_writedata <= x"000003B3";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(3, 1, 3);
        s_writedata <= x"000003B4";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#11: Read--------------------
        --This test confirms that the write in Test#10 did
        --indeed overwrite the data in the block and that
        --it doesn't redundantly write back to memory
        report "Test#11: Read";
        report "Covers cases read/valid/hit/x";

        s_read <= '1';

        s_addr <= to_address(3, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"000003B1", error_count);

        s_addr <= to_address(3, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"000003B2", error_count);

        s_addr <= to_address(3, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"000003B3", error_count);

        s_addr <= to_address(3, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"000003B4", error_count);

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#12: Read--------------------
        --This test reads the data written in Test#7, putting
        --non-dirty data in the cache
        report "Test#12: Read";
        report "Covers cases read/valid/miss/dirty";

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002C", error_count);

        s_addr <= to_address(2, 1, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002D", error_count);

        s_addr <= to_address(2, 1, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002E", error_count);

        s_addr <= to_address(2, 1, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"0000002F", error_count);

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#13: Write-------------------
        --This test overwrites one of the words in the block retrieved
        --in Test#12 thus making it dirty and should be written to
        --memory on the next cache index write
        report "Test#13: Write";
        report "Covers cases write/valid/hit/x";

        s_write <= '1';

        s_addr      <= to_address(2, 1, 0);
        s_writedata <= x"000003B0";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#14: Write-------------------
        --This test writes data to the same index as Test#13,
        --which should move that data to memory and then replace
        --it with the data here
        report "Test#14: Write";
        report "Covers cases write/valid/miss/dirty";

        s_write <= '1';

        s_addr      <= to_address(4, 1, 0);
        s_writedata <= x"00000555";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#15: Read--------------------
        --This test reads the data written in Test#13 which
        --should be accessed from memory
        report "Test#15: Read";
        report "Covers cases read/valid/miss/dirty";

        s_read <= '1';

        s_addr <= to_address(2, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"000003B0", error_count);

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#16: Read--------------------
        --This test attempts to read the memory written in Test#14
        --which should now be in memory because of the read in Test#15
        report "Test#16: Read";
        report "Covers cases read/valid/miss/clean";

        s_read <= '1';

        s_addr <= to_address(4, 1, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"00000555", error_count);

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#17: Read--------------------
        --This test attempts to read a block of memory we haven't accessed
        --yet, and hence is invalid and should be retrieved from main memory
        --We assume that the bytes in memory have been initialized to 0xFF
        report "Test#17: Read";
        report "Covers cases read/invalid/x/x";

        s_read <= '1';

        s_addr <= to_address(0, 0, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"FFFFFFFF", error_count);

        s_read <= '0';

        -----------------------------------------------------
        ---------------------Test#18: Write-------------------
        --This test writes some random data to random indices
        report "Test#18: Write";
        report "Covers cases write/invalid/x/x";

        s_write <= '1';

        s_addr      <= to_address(5, 2, 0);
        s_writedata <= x"11111111";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(6, 4, 1);
        s_writedata <= x"22222222";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(7, 8, 2);
        s_writedata <= x"33333333";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(8, 12, 3);
        s_writedata <= x"44444444";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(9, 16, 0);
        s_writedata <= x"55555555";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(10, 20, 1);
        s_writedata <= x"66666666";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(11, 24, 2);
        s_writedata <= x"77777777";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(12, 28, 3);
        s_writedata <= x"88888888";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(13, 31, 0);
        s_writedata <= x"99999999";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        -----------------------------------------------------
        ---------------------Test#19: Write-------------------
        --This test writes data to same indices as in Test#18
        --but with different data/tags
        report "Test#19: Write";
        report "Covers cases write/valid/miss/dirty";

        s_write <= '1';

        s_addr      <= to_address(14, 2, 0);
        s_writedata <= x"AAAAAAAA";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(15, 4, 0);
        s_writedata <= x"BBBBBBBB";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(16, 8, 0);
        s_writedata <= x"CCCCCCCC";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(17, 12, 0);
        s_writedata <= x"DDDDDDDD";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(18, 16, 0);
        s_writedata <= x"EEEEEEEE";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(19, 20, 0);
        s_writedata <= x"FFFFFFFF";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(20, 24, 0);
        s_writedata <= x"01234567";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(21, 28, 0);
        s_writedata <= x"89ABCDEF";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_addr      <= to_address(22, 31, 0);
        s_writedata <= x"AAAAAAAA";
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        s_write <= '0';

        ------------------------------------------------------
        ---------------------Test#20: Read--------------------
        --This test reads the original data that was written in
        --Test#18, it also moves Test#19 data to memory
        report "Test#20: Read";
        report "Covers cases read/valid/miss/dirty";

        s_read <= '1';

        s_addr <= to_address(5, 2, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"11111111", error_count);

        s_addr <= to_address(6, 4, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"22222222", error_count);

        s_addr <= to_address(7, 8, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"33333333", error_count);

        s_addr <= to_address(8, 12, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"44444444", error_count);

        s_addr <= to_address(9, 16, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"55555555", error_count);

        s_addr <= to_address(10, 20, 1);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"66666666", error_count);

        s_addr <= to_address(11, 24, 2);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"77777777", error_count);

        s_addr <= to_address(12, 28, 3);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"88888888", error_count);

        s_addr <= to_address(13, 31, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"99999999", error_count);

        s_read <= '0';

        ------------------------------------------------------
        ---------------------Test#21: Read--------------------
        --This test reads the data that was written in Test#19
        report "Test#21: Read";
        report "Covers cases read/valid/miss/clean";

        s_read <= '1';

        s_addr <= to_address(14, 2, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"AAAAAAAA", error_count);

        s_addr <= to_address(15, 4, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"BBBBBBBB", error_count);

        s_addr <= to_address(16, 8, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"CCCCCCCC", error_count);

        s_addr <= to_address(17, 12, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"DDDDDDDD", error_count);

        s_addr <= to_address(18, 16, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"EEEEEEEE", error_count);

        s_addr <= to_address(19, 20, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"FFFFFFFF", error_count);

        s_addr <= to_address(20, 24, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"01234567", error_count);

        s_addr <= to_address(21, 28, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"89ABCDEF", error_count);

        s_addr <= to_address(22, 31, 0);
        wait until rising_edge(s_waitrequest);
        wait until falling_edge(s_waitrequest);
        wait until rising_edge(clock);

        assert_equal(s_readdata, x"AAAAAAAA", error_count);

        s_read <= '0';

        report "Done. Found " & integer'image(error_count) & " error(s).";

        wait;
    end process;

end behavior;
