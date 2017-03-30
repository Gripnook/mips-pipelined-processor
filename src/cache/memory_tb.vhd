library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_tb is
end memory_tb;

architecture behaviour of memory_tb is
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

    --all the input signals with initial values
    signal clock       : std_logic := '0';
    signal writedata   : std_logic_vector(31 downto 0);
    signal address     : integer   := 0;
    signal memwrite    : std_logic := '0';
    signal memread     : std_logic := '0';
    signal readdata    : std_logic_vector(31 downto 0);
    signal waitrequest : std_logic;

begin

    --dut => Device Under Test
    dut : memory
        port map(clock       => clock,
                 writedata   => writedata,
                 address     => address,
                 memwrite    => memwrite,
                 memread     => memread,
                 readdata    => readdata,
                 waitrequest => waitrequest);

    clock_process : process
    begin
        clock <= '0';
        wait for clock_period / 2;
        clock <= '1';
        wait for clock_period / 2;
    end process;

    test_process : process
    begin
        wait for clock_period;
        address   <= 14;
        writedata <= x"00000012";
        memwrite  <= '1';

        --waits are NOT synthesizable and should not be used in a hardware design
        wait until rising_edge(waitrequest);
        memwrite <= '0';
        memread  <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"00000012" report "write unsuccessful" severity error;
        memread <= '0';
        wait for clock_period;
        address <= 12;
        memread <= '1';
        wait until rising_edge(waitrequest);
        assert readdata = x"FFFFFFFF" report "write unsuccessful" severity error;
        memread <= '0';
        wait;
    end process;

end behaviour;
