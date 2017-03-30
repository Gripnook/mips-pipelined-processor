library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bp_2bit_predictor is
    generic(BHT_BITS : integer);
    port(
        clock                : in  std_logic;
        reset                : in  std_logic;
        pc                   : in  std_logic_vector(31 downto 0);
        update               : in  std_logic; -- '1' if a prediction should be updated, '0' otherwise
        previous_pc          : in  std_logic_vector(31 downto 0);
        previous_prediction  : in  std_logic;
        prediction_incorrect : in  std_logic; -- '1' if prediction was incorrect, '0' otherwise
        prediction           : out std_logic -- '1' = predict taken, '0' = predict not taken
    );
end bp_2bit_predictor;

architecture arch of bp_2bit_predictor is
    type bht_type is array (0 to 2 ** BHT_BITS - 1) of std_logic_vector(1 downto 0);

    constant Taken0    : std_logic_vector(1 downto 0) := "10";
    constant Taken1    : std_logic_vector(1 downto 0) := "11";
    constant NotTaken0 : std_logic_vector(1 downto 0) := "01";
    constant NotTaken1 : std_logic_vector(1 downto 0) := "00";

    signal bht                 : bht_type;
    signal prediction_internal : std_logic := '0';

begin
    prediction <= prediction_internal;

    state_update : process(clock, reset)
        variable idx : integer;
    begin
        if reset = '1' then
            for i in 0 to 2 ** BHT_BITS - 1 loop
                bht(i) <= NotTaken1;
            end loop;
        elsif rising_edge(clock) then
            if update = '1' then
                -- We ignore the lower two bits since the PC is word aligned
                idx := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                case bht(idx) is
                    when NotTaken0 =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= Taken0;
                        else
                            bht(idx) <= NotTaken1;
                        end if;
                    when NotTaken1 =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= NotTaken0;
                        end if;
                    when Taken0 =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= NotTaken0;
                        else
                            bht(idx) <= Taken1;
                        end if;
                    when Taken1 =>
                        if prediction_incorrect = '1' then
                            bht(idx) <= Taken0;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    output : process(clock, reset)
        variable state : std_logic_vector(1 downto 0);
    begin
        if reset = '1' then
            prediction_internal <= '0';
        elsif falling_edge(clock) then
            -- We ignore the lower two bits since the PC is word aligned
            state := bht(to_integer(unsigned(pc(BHT_BITS + 1 downto 2))));
            if state = Taken0 or state = Taken1 then
                prediction_internal <= '1';
            else
                prediction_internal <= '0';
            end if;
        end if;
    end process;
end architecture;
