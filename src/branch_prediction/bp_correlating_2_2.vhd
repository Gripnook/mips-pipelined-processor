library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bp_correlating_2_2 is
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
end bp_correlating_2_2;

architecture arch of bp_correlating_2_2 is
    type global is array (0 to 3) of std_logic_vector(1 downto 0);
    type predictor_table is array (0 to ((2 ** BHT_BITS) - 1)) of global;
    signal branch_predictor_table : predictor_table              := (others => (others => (others => '0')));
    signal prediction_internal    : std_logic                    := '0';
    signal global_last            : std_logic_vector(1 downto 0) := "00";
begin
    prediction <= prediction_internal;

    state_update : process(clock, reset) is
        variable table_index : integer;
    begin
        if reset = '1' then
            branch_predictor_table <= (others => (others => (others => '0')));
        elsif rising_edge(clock) then
            if update = '1' then
                table_index := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                if prediction_incorrect = '1' then
                    case branch_predictor_table(table_index)(to_integer(unsigned(global_last))) is
                        when "00" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "01";
                            end if;
                        when "01" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            end if;
                        when "11" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "10";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            end if;
                        when others =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            end if;
                    end case;
                else
                    case branch_predictor_table(table_index)(to_integer(unsigned(global_last))) is
                        when "00" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "01";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            end if;
                        when "01" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            end if;
                        when "11" =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "10";
                            end if;
                        when others =>
                            if previous_prediction = '1' then
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                            else
                                branch_predictor_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process;

    output : process(clock, reset) is
        variable table_index : integer;
    begin
        if reset = '1' then
            prediction_internal <= '0';
        elsif falling_edge(clock) then
            global_last(1) <= global_last(0);
            if prediction_incorrect = '1' then
                global_last(0) <= not previous_prediction;
            else
                global_last(0) <= previous_prediction;
            end if;
            
            table_index := to_integer(unsigned(pc(BHT_BITS + 1 downto 2)));
            case branch_predictor_table(table_index)(to_integer(unsigned(global_last))) is
                when "00" | "01" =>
                    prediction_internal <= '0';
                when others =>
                    prediction_internal <= '1';
            end case;
            
        end if;
    end process;

end architecture;
