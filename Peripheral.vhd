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
        done       : out std_logic; -- high if operation is done
		  resetn      : in  std_logic
    );
end modulus_peripheral;

architecture perif_process of modulus_peripheral is
	 signal a, b, result : unsigned(15 downto 0); -- registers for mod operation and result (a mod b = result)
    signal start        : std_logic := '0'; -- trigger for mod operation
	 signal done_internal : std_logic := '0';
	 signal error        : std_logic := '0';  -- error flag
begin

	 -- connect internal signal to output port
	 done <= done_internal;
    process(clk, resetn)
    begin
        if resetn = '0' then
				a <= (others => '0'); 
            b <= (others => '0');
            result <= (others => '0');
            start <= '0';
            done_internal <= '0';
				error <= '0';
        elsif rising_edge(clk) then 
            if mem_write = '1' then -- check if CPU is writing to peripheral 
					case address is -- if yes, determine the register to write to
						when x"95" => a <= data_in; -- 0x95 - a input
					   when x"96" => b <= data_in; -- 0x96 - b input
					   when x"97" => start <= '1'; -- 0x97 - start signal
					   when others => null;
					end case;
				else
					start <= '0'; -- reset start when not writing
            end if;
				
			   if start = '1' then -- perform mod if start is on
					if b = x"0000" then -- if b = 0
                    result <= (others => '0');  -- indicate error, set result to 0
                    error <= '1';
                    done_internal <= '1';
					else 
						  result <= a mod b;
						  error <= '0';
						  done_internal <= '1';
					end if;
			   else
					done_internal <= '0';
					error <= '0';
			   end if;
        end if;
    end process;
	 
	  process(address, mem_read)
		 begin
			  if mem_read = '1' then -- check if CPU is reading from peripheral
					case address is -- if yes, check the address its reading from
						 when x"98" => data_out <= result; -- 0x98 - result
						 when x"99" => data_out <= (15 downto 2 => '0') & error & done_internal; -- 0x99 - status of function (if done or not)
						 when others => data_out <= (others => '0'); -- default output when address is not mapped
					end case;
			  else
					data_out <= (others => 'Z'); -- tristate when not being read
			  end if;
    end process;
end perif_process;
