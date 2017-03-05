library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port(a      : in  std_logic_vector(31 downto 0);
         b      : in  std_logic_vector(31 downto 0);
         opcode : in  std_logic_vector(5  downto 0);
         shamt  : in  std_logic_vector(4  downto 0);
         funct  : in  std_logic_vector(5  downto 0);
         output : out std_logic_vector(63 downto 0));
end alu;

architecture a1 of alu is
begin
    alu : process(a, b, opcode, shamt, funct)
    begin
        output(63 downto 0) <= 64x"0";
        OP : case opcode is
            when 6x"0" =>
                FN : case funct is
                    when 6x"20" => output(31 downto 0)  <= std_logic_vector(signed(a) + signed(b));                            -- ADD
                    when 6x"22" => output(31 downto 0)  <= std_logic_vector(signed(a) - signed(b));                            -- SUB
                    when 6x"18" => output               <= std_logic_vector(signed(32x"0" & a) * signed(b));                   -- MULT
                    when 6x"1a" => output(63 downto 32) <= std_logic_vector(signed(a) mod signed(b));                          -- DIV
                                   output(31 downto 0)  <= std_logic_vector(signed(a) / signed(b));
                    when 6x"2a" =>                                                                                             -- SLT
                        if signed(a) < signed(b) then output <= std_logic_vector(to_signed(1, 64));
                        else                          output <= std_logic_vector(to_signed(0, 64));
                        end if;
                    when 6x"24" => output(31 downto 0)  <= a and b;                                                            -- AND
                    when 6x"25" => output(31 downto 0)  <= a or  b;                                                            -- OR
                    when 6x"27" => output(31 downto 0)  <= a nor b;                                                            -- NOR
                    when 6x"26" => output(31 downto 0)  <= a xor b;                                                            -- XOR
                    when 6x"10" => NULL;                                                                                       -- MFHI
                    when 6x"12" => NULL;                                                                                       -- MFLO
                    when 6x"0"  => output(31 downto 0)  <= std_logic_vector(unsigned(b) sll to_integer(unsigned(shamt)));      -- SLL
                    when 6x"2"  => output(31 downto 0)  <= std_logic_vector(unsigned(b) srl to_integer(unsigned(shamt)));      -- SRL
                    when 6x"3"  => output(31 downto 0)  <= to_stdlogicvector(to_bitvector(b) sra to_integer(unsigned(shamt))); -- SRA
                    when 6x"8"  => NULL;                                                                                       -- JR
                    when others => NULL;
                end case FN;
            when 6x"2" => NULL;                                                                                                -- J
            when 6x"3" => output(31 downto 0) <= a;                                                                            -- JAL
            when 6x"8" => output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));                                      -- ADDI
            when 6x"a" =>                                                                                                      -- SLTI
                if signed(a) < signed(b) then output <= std_logic_vector(to_unsigned(1, 64));
                else                          output <= std_logic_vector(to_unsigned(0, 64));
                end if;
            when 6x"c"  => output(31 downto 0) <= a and b;                                                                     -- ANDI
            when 6x"d"  => output(31 downto 0) <= a or  b;                                                                     -- ORI
            when 6x"e"  => output(31 downto 0) <= a xor b;                                                                     -- XORI
            when 6x"f"  => output(31 downto 0) <= std_logic_vector(unsigned(b) sll 16);                                        -- LUI 
            when 6x"23" => output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));                                     -- LW
            when 6x"2b" => output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));                                     -- SW
            when others => NULL;
        end case OP;
    end process;
end a1;
