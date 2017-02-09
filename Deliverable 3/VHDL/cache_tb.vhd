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
    signal reset        : std_logic := '0';
    signal clk          : std_logic := '0';
    constant clk_period : time      := 1 ns;

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

begin

    -- Connect the components which we instantiated above to their
    -- respective signals.
    dut : cache
        port map(
            clock         => clk,
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
            clock       => clk,
            writedata   => m_writedata,
            address     => m_addr,
            memwrite    => m_write,
            memread     => m_read,
            readdata    => m_readdata,
            waitrequest => m_waitrequest
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    test_process : process
    begin

      wait for clk_period;
      reset <= '1';
      wait for clk_period;
      reset <= '0';
      wait for clk_period;

      -----------------------------------------------------
      ---------------------Test#1: Write-------------------
      --This test performs the first write operation
      --Tag:1 -Index:1 -Block: 0 -Byte: 0

      s_addr <= "00000000000000000000001000010000";
      s_writedata <= x"FFFFFFFF";
      s_write <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_write <= '0';


      -----------------------------------------------------
      ---------------------Test#2: Read--------------------
      --This test confirms that Test#1 was sucessfull and checks
      --the ability to read from an address
      --Tag: 1 -Index: 1 -Block: 0 -Byte: 0

      s_addr <= "00000000000000000000001000010000";
      s_read <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_read <= '0';
      wait for clk_period;
      ASSERT (s_readdata = x"FFFFFFFF") REPORT "The data should be 0xFFFFFFFF" SEVERITY ERROR;


      -----------------------------------------------------
      ---------------------Test#3: Write-------------------
      --This test attempts to overwrite the data stored from Test#1
      --with different data. This checks that writeback works
      --Tag:1 -Index:1 -Block: 0 -Byte: 0

      s_addr <= "00000000000000000000001000010000";
      s_writedata <= x"00000057";
      s_write <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_write <= '0';

      -----------------------------------------------------
      ---------------------Test#4: Read--------------------
      --This test ensures that the data written in Test#1 was successfully
      --overwritten with the data from Test#3
      --Tag: 1 -Index: 1 -Block: 1 -Byte: 0

      s_addr <= "00000000000000000000001000010000";
      s_read <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_read <= '0';
      wait for clk_period;
      ASSERT (s_readdata = x"00000057") REPORT "The data should be 0x00000057" SEVERITY ERROR;


      -----------------------------------------------------
      ---------------------Test#5: Write-------------------
      --This test fills up the remaining 3 word blocks
      --in the line ensuring that we can write to full 16B lines
      --Tag:1 -Index:1 -Block: 2 -Byte: 0
      --Tag:1 -Index:1 -Block: 3 -Byte: 0
      --Tag:1 -Index:1 -Block: 4 -Byte: 0

      s_addr <= "00000000000000000000001000010100";
      s_writedata <= x"00000058";
      s_write <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      wait for clk_period;

      s_addr <= "00000000000000000000001000011000";
      s_writedata <= x"00000059";
      s_write <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      wait for clk_period;

      s_addr <= "00000000000000000000001000011100";
      s_writedata <= x"0000005A";
      s_write <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      wait for clk_period;

      -----------------------------------------------------
      ---------------------Test#6: Read--------------------
      --This test confirms that Test#5 was sucessfull and
      --ensures that we can address individual words
      --Tag:1 -Index:1 -Block: 2 -Byte: 0
      --Tag:1 -Index:1 -Block: 3 -Byte: 0
      --Tag:1 -Index:1 -Block: 4 -Byte: 0

      s_addr <= "00000000000000000000001000010100";
      s_read <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_read <= '0';
      wait for clk_period;
      ASSERT (s_readdata = x"00000058") REPORT "The data should be 0x00000058" SEVERITY ERROR;

      s_addr <= "00000000000000000000001000011000";
      s_read <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_read <= '0';
      wait for clk_period;
      ASSERT (s_readdata = x"00000059") REPORT "The data should be 0x00000059" SEVERITY ERROR;

      s_addr <= "00000000000000000000001000011100";
      s_read <= '1';
      wait until rising_edge(s_waitrequest);
      wait until falling_edge(s_waitrequest);
      s_read <= '0';
      wait for clk_period;
      ASSERT (s_readdata = x"00000058") REPORT "The data should be 0x0000005A" SEVERITY ERROR;

      wait;

    end process;

end;
