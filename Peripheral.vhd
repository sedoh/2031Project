library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Peripheral is
    port(
        clk     : in  std_logic;
        reset   : in  std_logic;
        start   : in  std_logic;
        a, b    : in  unsigned(15 downto 0);
        result  : out unsigned(15 downto 0);
        done    : out std_logic
    );
end modulus_peripheral;

architecture a of Peripheral is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            result <= (others => '0');
            done <= '0';
        elsif rising_edge(clk) then
            if start = '1' then
                result <= a mod b;
                done <= '1';
            else
                done <= '0';
            end if;
        end if;
    end process;
end a;
