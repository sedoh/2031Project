library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity modulus_peripheral is
    port(
        clk     	 : in  std_logic;
		  address 	 : in  unsigned(7 downto 0); -- memory address being accessed by the CPU
        data_in    : in unsigned(15 downto 0); -- data CPU is writing to peripheral
        data_out   : out unsigned(15 downto 0); -- data the peripheral reads back to CPU during a read
        mem_read, mem_write : in std_logic; -- tells peripheral whether CPU is reading or writing to memory
        done       : buffer std_logic; -- high if operation is done
		  resetn      : in  std_logic
    );
end modulus_peripheral;

architecture perif_process of modulus_peripheral is
	 signal a, b, result : unsigned(15 downto 0); -- registers for mod operation and result (a mod b = result)
    signal start        : std_logic := '0'; -- trigger for mod operation
begin
    process(clk, resetn)
    begin
        if resetn = '0' then
				a <= (others => '0'); 
            b <= (others => '0');
            result <= (others => '0');
            start <= '0';
            done <= '0';
        elsif rising_edge(clk) then 
            if mem_write = '1' then -- check if CPU is writing to peripheral 
					case address is -- if yes, determine the register to write to
						when x"F0" => a <= data_in; -- 0xF0 - a input
					   when x"F1" => b <= data_in; -- 0xF1 - b input
					   when x"F2" => start <= '1'; -- 0xF2 - start signal
					   when others => null;
					end case;
				else
					start <= '0'; -- reset start when not writing
            end if;
				
			   if start = '1' then -- perform mod if start is on
					result <= a mod b;
					done <= '1';
			   else
					done <= '0';
			   end if;
        end if;
    end process;
	 
	  process(address, mem_read)
		 begin
			  if mem_read = '1' then -- check if CPU is reading from peripheral
					case address is -- if yes, check the address its reading from
						 when x"F3" => data_out <= result; -- 0xF3 - result
						 when x"F4" => data_out <= (15 downto 1 => '0') & done; -- 0xF4 - status of function (if done or not)
						 when others => data_out <= (others => '0'); -- default output when address is not mapped
					end case;
			  else
					data_out <= (others => 'Z'); -- tristate when not being read
			  end if;
    end process;
end perif_process;
