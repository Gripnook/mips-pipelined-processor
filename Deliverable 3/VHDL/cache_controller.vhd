library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_controller is
    port(
        iClock        : in  std_logic;
        iReset        : in  std_logic;
        -- Avalon interface
        iSRead        : in  std_logic;
        iSWrite       : in  std_logic;
        iMWaitRequest : in  std_logic;
        -- Cache Logic Inteface 
        iTagHit       : in  std_logic;
        iByteDone     : in  std_logic;
        iWordDone     : in  std_logic;
        -- Cache storage interface
        iValid        : in  std_logic;
        iDirty        : in  std_logic;
        iDirtyData    : in  std_logic;
        -- Avalon interface
        oMRead        : out std_logic;
        oMWrite       : out std_logic;
        oSWaitrequest : out std_logic;
        -- Cache storage interface
        oCRead        : out std_logic;
        oCWrite       : out std_logic;
        oCWriteSel    : out std_logic;
        oCWriteRegEn  : out std_logic;
        oCDirtyClr    : out std_logic;
        -- Cache Logic Inteface
        oTagSel       : out std_logic;
        oWordSel      : out std_logic;
        oWordEn       : out std_logic;
        oWordClr      : out std_logic;
        oByteEn       : out std_logic;
        oByteClr      : out std_logic);
end cache_controller;

architecture arch of cache_controller is
    type state_type is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11);
    signal state : state_type;
begin
    process(iClock, iReset)
    begin
        if (iReset = '1') then
            state <= S0;
        elsif rising_edge(iClock) then
            -- Default outputs
            oMRead        <= '0';
            oMWrite       <= '0';
            oSWaitrequest <= '0';
            oCRead        <= '0';
            oCWrite       <= '0';
            oCWriteSel    <= '0';
            oCWriteRegEn  <= '0';
            oCDirtyClr    <= '0';
            oTagSel       <= '0';
            oWordSel      <= '0';
            oWordEn       <= '0';
            oWordClr      <= '0';
            oByteEn       <= '0';
            oByteClr      <= '0';

            case state is
                when S0 =>
                    if iSRead = '1' or iSWrite = '1' then
                        oSWaitrequest <= '1';
                        oCRead        <= '1';
                        state         <= S1;
                    else
                        state <= S0;
                    end if;
                when S1 =>
                    if iValid = '0' then
                        oSWaitrequest <= '1';
                        oWordSel      <= '1';
                        oMRead        <= '1';
                        state         <= S3;
                    else
                        if iTagHit = '0' then
                            oSWaitrequest <= '1';
                            oWordSel      <= '1';
                            if iDirty = '0' then
                                oMRead <= '1';
                                state  <= S3;
                            else
                                oTagSel <= '1';
                                if iDirtyData = '0' then
                                    oWordEn <= '1';
                                    state   <= S10;
                                else
                                    oMWrite <= '1';
                                    state   <= S8;
                                end if;
                            end if;
                        else
                            if iSRead = '1' then
                                state <= S0;
                            else
                                oSWaitrequest <= '1';
                                oCWrite       <= '1';
                                oCWriteSel    <= '1';
                                state         <= S2;
                            end if;
                        end if;
                    end if;
                when S2 =>
                    state <= S0;
                when S3 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    if iMWaitRequest = '1' then
                        oMRead <= '1';
                        state  <= S3;
                    else
                        oCWriteRegEn <= '1';
                        if iByteDone = '0' then
                            oByteEn <= '1';
                            state   <= S4;
                        else
                            if iWordDone = '0' then
                                state <= S5;
                            else
                                state <= S6;
                            end if;
                        end if;
                    end if;
                when S4 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    oMRead        <= '1';
                    state         <= S3;
                when S5 =>
                    oSWaitrequest <= '1';
                    oCWrite       <= '1';
                    oByteClr      <= '1';
                    oWordSel      <= '1';
                    oWordEn       <= '1';
                    oCDirtyClr    <= '1';
                    state         <= S4;
                when S6 =>
                    oSWaitrequest <= '1';
                    oCWrite       <= '1';
                    oWordSel      <= '1';
                    oWordClr      <= '1';
                    oByteClr      <= '1';
                    oCDirtyClr    <= '1';
                    state         <= S7;
                when S7 =>
                    oSWaitrequest <= '1';
                    state         <= S2;
                    if iSRead = '1' then
                        oCRead <= '1';
                    else
                        oCWrite    <= '1';
                        oCWriteSel <= '1';
                    end if;
                when S8 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    oTagSel       <= '1';
                    if iMWaitRequest = '1' then
                        oMWrite <= '1';
                        state   <= S8;
                    else
                        if iByteDone = '0' then
                            oByteEn <= '1';
                            state   <= S9;
                        else
                            oByteClr   <= '1';
                            oCDirtyClr <= '1';
                            if iWordDone = '0' then
                                oWordEn <= '1';
                                state   <= S10;
                            else
                                oWordClr <= '1';
                                state    <= S11;
                            end if;
                        end if;
                    end if;
                when S9 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    oTagSel       <= '1';
                    oMWrite       <= '1';
                    state         <= S8;
                when S10 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    oTagSel       <= '1';
                    if iDirtyData = '1' then
                        oMWrite <= '1';
                        state   <= S8;
                    else
                        if iWordDone = '1' then
                            oByteClr <= '1';
                            oWordClr <= '1';
                            state    <= S11;
                        else
                            oWordEn <= '1';
                            state   <= S10;
                        end if;
                    end if;
                when S11 =>
                    oSWaitrequest <= '1';
                    oWordSel      <= '1';
                    oMRead        <= '1';
                    state         <= S3;
            end case;
        end if;
    end process;
end arch;