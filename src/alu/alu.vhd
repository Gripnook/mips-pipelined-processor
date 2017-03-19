library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mips_instruction_set.all;

entity alu is
    port(a      : in  std_logic_vector(31 downto 0);
         b      : in  std_logic_vector(31 downto 0);
         opcode : in  std_logic_vector(5 downto 0);
         shamt  : in  std_logic_vector(4 downto 0);
         funct  : in  std_logic_vector(5 downto 0);
         output : out std_logic_vector(63 downto 0));
end alu;

architecture arch of alu is
begin
    alu : process(a, b, opcode, shamt, funct)
    begin
        output <= (others => '0');
        case opcode is
            when OP_R_TYPE =>
                case funct is
                    when FUNCT_ADD =>
                        output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));
                    when FUNCT_SUB =>
                        output(31 downto 0) <= std_logic_vector(signed(a) - signed(b));
                    when FUNCT_MULT =>
                        output <= std_logic_vector(signed(a) * signed(b));
                    when FUNCT_DIV =>
                        -- This is needed to avoid warnings caused by signal path differences
                        if (b /= x"00000000") then
                            output(63 downto 32) <= std_logic_vector(signed(a) rem signed(b));
                            output(31 downto 0)  <= std_logic_vector(signed(a) / signed(b));
                        end if;
                    when FUNCT_SLT =>
                        if signed(a) < signed(b) then
                            output(31 downto 0) <= std_logic_vector(to_signed(1, 32));
                        else
                            output(31 downto 0) <= std_logic_vector(to_signed(0, 32));
                        end if;
                    when FUNCT_AND =>
                        output(31 downto 0) <= a and b;
                    when FUNCT_OR =>
                        output(31 downto 0) <= a or b;
                    when FUNCT_NOR =>
                        output(31 downto 0) <= a nor b;
                    when FUNCT_XOR =>
                        output(31 downto 0) <= a xor b;
                    when FUNCT_SLL =>
                        output(31 downto 0) <= std_logic_vector(unsigned(b) sll to_integer(unsigned(shamt)));
                    when FUNCT_SRL =>
                        output(31 downto 0) <= std_logic_vector(unsigned(b) srl to_integer(unsigned(shamt)));
                    when FUNCT_SRA =>
                        output(31 downto 0) <= to_stdlogicvector(to_bitvector(b) sra to_integer(unsigned(shamt)));
                    when others =>
                        null;
                end case;
            when OP_JAL =>
                output(31 downto 0) <= a;
            when OP_ADDI =>
                output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));
            when OP_SLTI =>
                if signed(a) < signed(b) then
                    output(31 downto 0) <= std_logic_vector(to_unsigned(1, 32));
                else
                    output(31 downto 0) <= std_logic_vector(to_unsigned(0, 32));
                end if;
            when OP_ANDI =>
                output(31 downto 0) <= a and b;
            when OP_ORI =>
                output(31 downto 0) <= a or b;
            when OP_XORI =>
                output(31 downto 0) <= a xor b;
            when OP_LUI =>
                output(31 downto 0) <= std_logic_vector(unsigned(b) sll 16);
            when OP_LW =>
                output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));
            when OP_SW =>
                output(31 downto 0) <= std_logic_vector(signed(a) + signed(b));
            when others =>
                null;
        end case;
    end process;
end arch;
