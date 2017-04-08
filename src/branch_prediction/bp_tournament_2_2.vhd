library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bp_tournament_2_2 is
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
end bp_tournament_2_2;

architecture arch of bp_tournament_2_2 is
    type global_predict_entry is array (0 to 3) of std_logic_vector(1 downto 0);
    type global_predict is array (0 to 2 ** BHT_BITS - 1) of global_predict_entry;
    type local_predict is array (0 to 2 ** BHT_BITS - 1) of std_logic_vector(1 downto 0);
    type predict_type is array (0 to 2 ** BHT_BITS - 1) of std_logic_vector(1 downto 0);
    signal global_table     : global_predict               := (others => (others => (others => '0')));
    signal local_table      : local_predict                := (others => (others => '0'));
    signal prediction_table : predict_type                 := (others => (others => '0'));
    signal global_last      : std_logic_vector(1 downto 0) := "00";
begin
    update_global : process(clock, reset)
        variable table_index : integer;
        variable prev_res    : std_logic;
    begin
        if reset = '1' then
            global_table <= (others => (others => (others => '0')));
        elsif rising_edge(clock) then
            if update = '1' then
                if prediction_incorrect = '1' then
                    prev_res := not previous_prediction;
                else
                    prev_res := previous_prediction;
                end if;

                -- We ignore the lower two bits since the PC is word aligned
                table_index := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                case global_table(table_index)(to_integer(unsigned(global_last))) is
                    when "00" =>
                        if prev_res = '0' then
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                        else
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "01";
                        end if;
                    when "01" =>
                        if prev_res = '0' then
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                        else
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                        end if;
                    when "11" =>
                        if prev_res = '0' then
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "10";
                        else
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                        end if;
                    when others =>
                        if prev_res = '0' then
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "00";
                        else
                            global_table(table_index)(to_integer(unsigned(global_last))) <= "11";
                        end if;
                end case;
            end if;
        end if;
    end process;

    update_local : process(clock, reset)
        variable table_index : integer;
        variable prev_res    : std_logic;
    begin
        if reset = '1' then
            local_table <= (others => (others => '0'));
        elsif rising_edge(clock) then
            if update = '1' then
                if prediction_incorrect = '1' then
                    prev_res := not previous_prediction;
                else
                    prev_res := previous_prediction;
                end if;

                -- We ignore the lower two bits since the PC is word aligned
                table_index := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                case local_table(table_index) is
                    when "00" =>
                        if prev_res = '0' then
                            local_table(table_index) <= "00";
                        else
                            local_table(table_index) <= "01";
                        end if;
                    when "01" =>
                        if prev_res = '0' then
                            local_table(table_index) <= "00";
                        else
                            local_table(table_index) <= "11";
                        end if;
                    when "11" =>
                        if prev_res = '0' then
                            local_table(table_index) <= "10";
                        else
                            local_table(table_index) <= "11";
                        end if;
                    when others =>
                        if prev_res = '0' then
                            local_table(table_index) <= "00";
                        else
                            local_table(table_index) <= "11";
                        end if;
                end case;
            end if;
        end if;
    end process;

    update_pred : process(clock, reset)
        variable table_index          : integer;
        variable prev_res             : std_logic;
        variable prev_glob_pred_right : std_logic;
        variable prev_loc_pred_right  : std_logic;
    begin
        if reset = '1' then
            prediction_table <= (others => (others => '0'));
        elsif rising_edge(clock) then
            if update = '1' then
                if prediction_incorrect = '1' then
                    prev_res := not previous_prediction;
                else
                    prev_res := previous_prediction;
                end if;

                -- We ignore the lower two bits since the PC is word aligned
                table_index := to_integer(unsigned(previous_pc(BHT_BITS + 1 downto 2)));
                if global_table(table_index)(to_integer(unsigned(global_last)))(1) = prev_res then
                    prev_glob_pred_right := '1';
                else
                    prev_glob_pred_right := '0';
                end if;

                if local_table(table_index)(1) = prev_res then
                    prev_loc_pred_right := '1';
                else
                    prev_loc_pred_right := '0';
                end if;

                case prediction_table(table_index) is
                    when "00" =>
                        if prev_loc_pred_right = '0' and prev_glob_pred_right = '1' then
                            prediction_table(table_index) <= "01";
                        else
                            prediction_table(table_index) <= "00";
                        end if;
                    when "01" =>
                        if prev_loc_pred_right = '1' and prev_glob_pred_right = '0' then
                            prediction_table(table_index) <= "00";
                        elsif prev_loc_pred_right = '0' and prev_glob_pred_right = '1' then
                            prediction_table(table_index) <= "10";
                        else
                            prediction_table(table_index) <= "01";
                        end if;
                    when "11" =>
                        if prev_loc_pred_right = '1' and prev_glob_pred_right = '0' then
                            prediction_table(table_index) <= "10";
                        else
                            prediction_table(table_index) <= "11";
                        end if;
                    when others =>
                        if prev_loc_pred_right = '1' and prev_glob_pred_right = '0' then
                            prediction_table(table_index) <= "01";
                        elsif prev_loc_pred_right = '0' and prev_glob_pred_right = '1' then
                            prediction_table(table_index) <= "11";
                        else
                            prediction_table(table_index) <= "10";
                        end if;
                end case;
            end if;
        end if;
    end process;

    global_shift : process(clock, reset)
    begin
        if reset = '1' then
            global_last <= "00";
        elsif rising_edge(clock) then
            if update = '1' then
                global_last(1) <= global_last(0);
                if prediction_incorrect = '1' then
                    global_last(0) <= not previous_prediction;
                else
                    global_last(0) <= previous_prediction;
                end if;
            end if;
        end if;
    end process;

    output : process(clock, reset)
        variable table_index : integer;
        variable pred_type   : std_logic;
    begin
        if reset = '1' then
            prediction <= '0';
        elsif falling_edge(clock) then
            -- We ignore the lower two bits since the PC is word aligned
            table_index := to_integer(unsigned(pc(BHT_BITS + 1 downto 2)));
            if prediction_table(table_index)(1) = '0' then
                pred_type := '0';
            else
                pred_type := '1';
            end if;

            if pred_type = '0' then
                if local_table(table_index)(1) = '0' then
                    prediction <= '0';
                else
                    prediction <= '1';
                end if;
            else
                if global_table(table_index)(to_integer(unsigned(global_last)))(1) = '0' then
                    prediction <= '0';
                else
                    prediction <= '1';
                end if;
            end if;
        end if;
    end process;

end architecture;
