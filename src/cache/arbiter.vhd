library ieee;
use ieee.std_logic_1164.all;

entity arbiter is
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
end arbiter;

architecture arch of arbiter is
    type state_type is (IDLE, I_CACHE, D_CACHE);
    signal state : state_type := IDLE;

begin
    i_readdata <= m_readdata;
    d_readdata <= m_readdata;

    state_transition : process(clock, reset)
    begin
        if (reset = '1') then
            state <= IDLE;
        elsif (rising_edge(clock)) then
            case state is
                when IDLE =>
                    if (d_read = '1' or d_write = '1') then
                        state <= D_CACHE;
                    elsif (i_read = '1' or i_write = '1') then
                        state <= I_CACHE;
                    else
                        state <= IDLE;
                    end if;
                when D_CACHE =>
                    if (d_read = '0' and d_write = '0') then
                        state <= IDLE;
                    else
                        state <= D_CACHE;
                    end if;
                when I_CACHE =>
                    if (i_read = '0' and i_write = '0') then
                        state <= IDLE;
                    else
                        state <= I_CACHE;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end process;

    outputs : process(state, d_read, d_write, d_writedata, d_addr, i_read, i_write, i_writedata, i_addr, m_waitrequest)
    begin
        -- default outputs
        i_waitrequest <= '1';
        d_waitrequest <= '1';
        m_read        <= '0';
        m_write       <= '0';
        m_writedata   <= (others => '0');
        m_addr        <= 0;

        case state is
            when D_CACHE =>
                d_waitrequest <= m_waitrequest;
                m_read        <= d_read;
                m_write       <= d_write;
                m_writedata   <= d_writedata;
                m_addr        <= d_addr;
            when I_CACHE =>
                i_waitrequest <= m_waitrequest;
                m_read        <= i_read;
                m_write       <= i_write;
                m_writedata   <= i_writedata;
                m_addr        <= i_addr;
            when others =>
                null;
        end case;
    end process;

end architecture arch;
