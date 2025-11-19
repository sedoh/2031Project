library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integer_division_peripheral is
    port(
        clk     	          : in std_logic;
		  address 	          : in unsigned(7 downto 0); -- memory address being accessed by the CPU
        data_in             : in unsigned(15 downto 0); -- data CPU is writing to peripheral
        data_out            : out unsigned(15 downto 0); -- data the peripheral reads back to CPU during a read
        mem_read, mem_write : in std_logic; -- tells peripheral whether CPU is reading or writing to memory
        done                : out std_logic; -- high if operation is done
		  resetn              : in std_logic 
    );
end integer_division_peripheral;

architecture rtl of integer_division_peripheral is
    -- Address map
    constant A_ADDR     : unsigned(7 downto 0) := x"9A"; -- Write: Dividend (D)
    constant B_ADDR     : unsigned(7 downto 0) := x"9B"; -- Write: Divisor (V)
    constant START_ADDR : unsigned(7 downto 0) := x"9C"; -- Write: Start command
    constant RES_ADDR   : unsigned(7 downto 0) := x"9D"; -- Read: Quotient (Q)
    constant DONE_ADDR  : unsigned(7 downto 0) := x"9E"; -- Read: Remainder (R) / Clear Done

    -- General registers
    signal reg_a, reg_b     : unsigned(15 downto 0) := (others => '0'); -- Dividend, divisor
    signal reg_result       : unsigned(15 downto 0) := (others => '0'); -- Quotient
    signal reg_done         : std_logic := '0';
    signal start_req        : std_logic := '0';
    signal reg_remainder    : unsigned(15 downto 0) := (others => '0'); -- Remainder

    -- Non-restoring division working registers
    signal pr_reg           : signed(16 downto 0) := (others => '0');
    signal q_reg            : unsigned(15 downto 0) := (others => '0');
    signal v_ext            : signed(16 downto 0) := (others => '0');
    signal step_count       : unsigned(4 downto 0)  := (others => '0');

    -- States
    type state_t is (
        IDLE,
        INIT_OP,
        CALCULATE,
        FINAL_RESTORE,
        FINISH,
        HOLD_DONE
    );
    signal state            : state_t := IDLE;

begin
    v_ext <= signed('0' & reg_b);

    -- Main sequential logic process
    process(clk, resetn)
	      -- Variables for intermediate calculations
			variable pr_shifted_v : signed(pr_reg'range);
			variable pr_next_minus_v : signed(pr_reg'range);
			variable pr_next_plus_v : signed(pr_reg'range);
			variable q_bit_v : std_logic;
    begin
		  -- Reset
        if resetn = '0' then
            reg_a           <= (others => '0');
            reg_b           <= (others => '0');
            reg_result      <= (others => '0');
            reg_remainder   <= (others => '0');
            reg_done        <= '0';
            start_req       <= '0';
            pr_reg          <= (others => '0');
            q_reg           <= (others => '0');
            step_count      <= (others => '0');
            state           <= IDLE;
        elsif rising_edge(clk) then
            -- Writes
            if mem_write = '1' then
                if address = A_ADDR then 
							reg_a <= data_in;
					 end if;
                if address = B_ADDR then
							reg_b <= data_in;
					 end if;
                if address = START_ADDR then
							start_req <= '1';
					 end if;
            end if;

            -- Reading result clears DONE
            if mem_read = '1' and (address = RES_ADDR or address = DONE_ADDR) then
                reg_done <= '0';
            end if;

            -- Consume START
            if (state = IDLE) and (start_req = '1') then
                start_req <= '0';
                reg_done  <= '0';
                state     <= INIT_OP;
            end if;

            -- Non-restoring division FSM logic
            case state is
				    -- Wait
                when IDLE =>
                    null;
					 
				    -- Handle division by 0 and initialize working registers
                when INIT_OP =>
                    if reg_b = 0 then
                        reg_result      <= (others => '1');
                        reg_remainder   <= reg_a;
								reg_done        <= '1';
                        state           <= HOLD_DONE;
                    else
                        pr_reg      <= (others => '0');
								q_reg       <= reg_a;
                        step_count  <= to_unsigned(16, step_count'length);
                        state       <= CALCULATE;
                    end if;

					 -- Division calculation
                when CALCULATE =>
						  -- Prepare PR registers
                    pr_shifted_v := pr_reg(pr_reg'left-1 downto 0) & q_reg(q_reg'left);
                    pr_next_minus_v := pr_shifted_v - v_ext;
                    pr_next_plus_v  := pr_shifted_v + v_ext;

                    if pr_shifted_v(pr_shifted_v'left) = '0' then
                        -- PR was >= 0 -> Subtract
                        pr_reg <= pr_next_minus_v;
                        
                        -- Set Q bit based on sign of new PR
                        if pr_next_minus_v(pr_next_minus_v'left) = '0' then
                            q_bit_v := '1';
                        else
                            q_bit_v := '0';
                        end if;
                    else
                        -- PR was < 0 -> Add
                        pr_reg <= pr_next_plus_v;
                        
                        -- Set Q bit based on sign of new PR
                        if pr_next_plus_v(pr_next_plus_v'left) = '0' then
                            q_bit_v := '1';
                        else
                            q_bit_v := '0';
                        end if;
                    end if;

                    -- Shift Q left and insert calculated bit into LSB
                    q_reg  <= q_reg(q_reg'left-1 downto 0) & q_bit_v;
							
						  -- Decrement step count
                    step_count <= step_count - 1;

                    if step_count = 1 then
                        state <= FINAL_RESTORE;
                    else
                        state <= CALCULATE;
                    end if;

				    -- Handle negative remainder
                when FINAL_RESTORE =>
                    if pr_reg(pr_reg'left) = '1' then
                        pr_reg <= pr_reg + v_ext;
                    end if;
                    state <= FINISH;

				    -- Finish division
                when FINISH =>
                    reg_result      <= q_reg;
                    reg_remainder   <= unsigned(pr_reg(15 downto 0));
                    reg_done        <= '1';
                    state           <= HOLD_DONE;

					 -- Assert done and wait for clear
                when HOLD_DONE =>
                    if reg_done = '0' then
                        state <= IDLE;
                    end if;

					 -- Default idle behavior
                when others =>
                    state <= IDLE;
						  
            end case;
        end if;
    end process;

    -- Main combinational logic process
    process(address, mem_read, reg_a, reg_b, reg_result, reg_remainder)
    begin
        data_out <= (others => 'Z');

        if mem_read = '1' then
            case address is
                when A_ADDR      => data_out <= reg_a; -- Dividend
                when B_ADDR      => data_out <= reg_b; -- Divisor
                when START_ADDR  => data_out <= (others => '0'); -- Control
                when RES_ADDR    => data_out <= reg_result; -- Quotient
                when DONE_ADDR   => data_out <= reg_remainder; -- Remainder
                when others      => data_out <= (others => '0');
            end case;
        end if;
    end process;

    done <= reg_done;

end rtl;
