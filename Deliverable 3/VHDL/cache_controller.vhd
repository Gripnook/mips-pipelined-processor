library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_controller is
    port(
        clock          : in  std_logic;
        reset          : in  std_logic;
        -- Avalon interface
        s_read         : in  std_logic;
        s_write        : in  std_logic;
        m_waitrequest  : in  std_logic;
        -- Cache logic interface 
        tag_hit        : in  std_logic;
        byte_done      : in  std_logic;
        word_done      : in  std_logic;
        -- Cache storage interface
        valid          : in  std_logic;
        dirty          : in  std_logic;
        dirty_data     : in  std_logic;
        -- Avalon interface
        m_read         : out std_logic;
        m_write        : out std_logic;
        s_waitrequest  : out std_logic;
        -- Cache storage interface
        c_read         : out std_logic;
        c_write        : out std_logic;
        c_write_sel    : out std_logic;
        c_write_reg_en : out std_logic;
        c_dirty_clr    : out std_logic;
        -- Cache Logic interface
        tag_sel        : out std_logic;
        word_sel       : out std_logic;
        word_en        : out std_logic;
        word_clr       : out std_logic;
        byte_en        : out std_logic;
        byte_clr       : out std_logic);
end cache_controller;

architecture arch of cache_controller is
    type state_type is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
    signal state : state_type := S0;
begin
    state_transition_process : process(clock, reset)
    begin
        if (reset = '1') then
            state <= S0;
        elsif rising_edge(clock) then
            case state is
                when S0 =>
                    if s_read = '1' or s_write = '1' then
                        state <= S1;
                    else
                        state <= S0;
                    end if;
                when S1 =>
                    if valid = '0' then
                        state <= S3;
                    else
                        if tag_hit = '0' then
                            if dirty = '0' then
                                state <= S3;
                            else
                                if dirty_data = '0' then
                                    state <= S10;
                                else
                                    state <= S8;
                                end if;
                            end if;
                        else
                            state <= S2;
                        end if;
                    end if;
                when S2 =>
                    state <= S0;
                when S3 =>
                    if m_waitrequest = '1' then
                        state <= S3;
                    else
                        if byte_done = '0' then
                            state <= S4;
                        else
                            if word_done = '0' then
                                state <= S5;
                            else
                                state <= S6;
                            end if;
                        end if;
                    end if;
                when S4 =>
                    state <= S3;
                when S5 =>
                    state <= S4;
                when S6 =>
                    state <= S7;
                when S7 =>
                    state <= S2;
                when S8 =>
                    if m_waitrequest = '1' then
                        state <= S8;
                    else
                        if byte_done = '0' then
                            state <= S9;
                        else
                            if word_done = '0' then
                                state <= S10;
                            else
                                state <= S11;
                            end if;
                        end if;
                    end if;
                when S9 =>
                    state <= S8;
                when S10 =>
                    if dirty_data = '1' then
                        state <= S8;
                    else
                        if word_done = '1' then
                            state <= S11;
                        else
                            state <= S10;
                        end if;
                    end if;
                when S11 =>
                    state <= S3;
            end case;
        end if;
    end process;

    output_process : process(s_read, s_write, m_waitrequest, tag_hit, byte_done, word_done, valid, dirty, dirty_data, state)
    begin
        -- Default outputs
        m_read         <= '0';
        m_write        <= '0';
        s_waitrequest  <= '0';
        c_read         <= '0';
        c_write        <= '0';
        c_write_sel    <= '0';
        c_write_reg_en <= '0';
        c_dirty_clr    <= '0';
        tag_sel        <= '0';
        word_sel       <= '0';
        word_en        <= '0';
        word_clr       <= '0';
        byte_en        <= '0';
        byte_clr       <= '0';

        case state is
            when S0 =>
                if s_read = '1' or s_write = '1' then
                    s_waitrequest <= '1';
                    c_read        <= '1';
                end if;
            when S1 =>
                s_waitrequest <= '1';
                if valid = '1' then
                    if tag_hit = '1' then
                        if s_write = '1' then
                            c_write     <= '1';
                            c_write_sel <= '1';
                        end if;
                    else
                        word_sel <= '1';
                        if dirty = '1' then
                            tag_sel <= '1';
                            if dirty_data = '1' then
                                m_write <= '1';
                            else
                                word_en <= '1';
                            end if;
                        else
                            m_read <= '1';
                        end if;
                    end if;
                else
                    word_sel <= '1';
                    m_read   <= '1';
                end if;
            when S2 =>
            when S3 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                if m_waitrequest = '1' then
                    m_read <= '1';
                else
                    c_write_reg_en <= '1';
                    if byte_done = '0' then
                        byte_en <= '1';
                    end if;
                end if;
            when S4 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                m_read        <= '1';
            when S5 =>
                s_waitrequest <= '1';
                c_write       <= '1';
                byte_clr      <= '1';
                word_sel      <= '1';
                word_en       <= '1';
                c_dirty_clr   <= '1';
            when S6 =>
                s_waitrequest <= '1';
                c_write       <= '1';
                word_sel      <= '1';
                word_clr      <= '1';
                byte_clr      <= '1';
                c_dirty_clr   <= '1';
            when S7 =>
                s_waitrequest <= '1';
                if s_read = '1' then
                    c_read <= '1';
                else
                    c_write     <= '1';
                    c_write_sel <= '1';
                end if;
            when S8 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                tag_sel       <= '1';
                if m_waitrequest = '1' then
                    m_write <= '1';
                else
                    if byte_done = '1' then
                        byte_clr    <= '1';
                        c_dirty_clr <= '1';
                        if word_done = '1' then
                            word_clr <= '1';
                        else
                            word_en <= '1';
                        end if;
                    else
                        byte_en <= '1';
                    end if;
                end if;
            when S9 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                tag_sel       <= '1';
                m_write       <= '1';
            when S10 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                tag_sel       <= '1';
                if dirty_data = '1' then
                    m_write <= '1';
                else
                    if word_done = '1' then
                        byte_clr <= '1';
                        word_clr <= '1';
                    else
                        word_en <= '1';
                    end if;
                end if;
            when S11 =>
                s_waitrequest <= '1';
                word_sel      <= '1';
                m_read        <= '1';
        end case;
    end process;
end arch;
