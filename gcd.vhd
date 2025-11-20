library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd_peripheral is
    port(
        clk     	          : in std_logic;
		  address 	          : in unsigned(7 downto 0); -- memory address being accessed by the CPU
        data_in             : in unsigned(15 downto 0); -- data CPU is writing to peripheral
        data_out            : out unsigned(15 downto 0); -- data the peripheral reads back to CPU during a read
        mem_read, mem_write : in std_logic; -- tells peripheral whether CPU is reading or writing to memory
        done                : out std_logic; -- high if operation is done
		  resetn              : in std_logic 
    );
end gcd_peripheral;

architecture rtl of gcd_peripheral is
    -- Address map
    constant A_ADDR     : unsigned(7 downto 0) := x"90";
    constant B_ADDR     : unsigned(7 downto 0) := x"91";
    constant START_ADDR : unsigned(7 downto 0) := x"92";
    constant RES_ADDR   : unsigned(7 downto 0) := x"93";
    constant DONE_ADDR  : unsigned(7 downto 0) := x"94";

    -- General registers
    signal reg_a, reg_b   : unsigned(15 downto 0) := (others => '0');
    signal reg_result     : unsigned(15 downto 0) := (others => '0');
    signal reg_done       : std_logic := '0';
    signal start_req      : std_logic := '0'; -- latched start
	 
	 -- Binary GCD (Stein's algorithm) working registers
    signal a_w, b_w       : unsigned(15 downto 0) := (others => '0');
    signal shift_cnt      : unsigned(4 downto 0)  := (others => '0'); -- 0..16

    -- States
    type state_t is (
        IDLE,
		  CHECK_ZERO,
		  STRIP_COMMON,
		  MAKE_A_ODD,
		  MAKE_B_ODD,
        ORDER_AB,
		  SUBTRACT,
		  TEST_B_ZERO,
		  FINISH,
		  HOLD_DONE
    );
    signal state          : state_t := IDLE;

begin
    -- Main sequential logic process
    process(clk, resetn)
    begin
		  -- Reset
        if resetn = '0' then
            reg_a      <= (others => '0');
            reg_b      <= (others => '0');
            reg_result <= (others => '0');
            reg_done   <= '0';
            start_req  <= '0';
            a_w        <= (others => '0');
            b_w        <= (others => '0');
            shift_cnt  <= (others => '0');
            state         <= IDLE;
        elsif rising_edge(clk) then
            -- Writes
            if mem_write = '1' then
                if address = A_ADDR     then reg_a <= data_in; end if;
                if address = B_ADDR     then reg_b <= data_in; end if;
                if address = START_ADDR then start_req <= '1'; end if;
            end if;
            
            -- Consume START only when idle
            if (state = IDLE) and (start_req = '1') then
                start_req <= '0';
                reg_done  <= '0';         -- This clears the flag for the new run
                a_w       <= reg_a;
                b_w       <= reg_b;
                shift_cnt <= (others => '0');
                state        <= CHECK_ZERO;
            end if;

            -- GCD FSM logic (Stein’s algorithm)
            case state is
					 -- Wait
                when IDLE =>
                    null;

					 -- Handle zero-valued arguments and begin algorithm
                when CHECK_ZERO =>
                    if a_w = 0 then
                        reg_result <= b_w;
                        state <= FINISH;
                    elsif b_w = 0 then
                        reg_result <= a_w;
                        state <= FINISH;
                    else
                        state <= STRIP_COMMON;
                    end if;

					 -- Extract common divisor
                when STRIP_COMMON =>
                    if (a_w(0) = '0') and (b_w(0) = '0') then
                        a_w      <= '0' & a_w(15 downto 1);
                        b_w      <= '0' & b_w(15 downto 1);
                        shift_cnt<= shift_cnt + 1;
                    else
                        state <= MAKE_A_ODD;
                    end if;

                when MAKE_A_ODD =>
                    if a_w(0) = '0' then
                        a_w <= '0' & a_w(15 downto 1);
                    else
                        state <= MAKE_B_ODD;
                    end if;

                when MAKE_B_ODD =>
                    if b_w(0) = '0' then
                        b_w <= '0' & b_w(15 downto 1);
                    else
                        state <= ORDER_AB;
                    end if;

					 -- Swap
                when ORDER_AB =>
                    if a_w > b_w then
                        -- swap a_w and b_w
                        a_w <= b_w;
                        b_w <= a_w;
                    end if;
                    state <= SUBTRACT;

                when SUBTRACT =>
                    b_w <= b_w - a_w;
                    state  <= TEST_B_ZERO;

                when TEST_B_ZERO =>
                    if b_w = 0 then
                        reg_result <= shift_left(a_w, to_integer(shift_cnt));
                        state <= FINISH;
                    else
                        state <= MAKE_B_ODD;
                    end if;

					 -- Finish GCD
                when FINISH =>
                    reg_done <= '1';
                    state <= HOLD_DONE;

                when HOLD_DONE =>
                    -- Hold DONE high until CPU starts a NEW request
                    state <= IDLE; 

					 -- Default idle behavior
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- Main combination logic process
    process(address, mem_read, reg_a, reg_b, reg_result, reg_done)
    begin
        if mem_read = '1' then
            case address is
                when A_ADDR     => data_out <= reg_a;
                when B_ADDR     => data_out <= reg_b;
                when START_ADDR => data_out <= (others => '0'); -- Start
                when RES_ADDR   => data_out <= reg_result; -- GCD result
                when DONE_ADDR  => data_out <= (15 downto 1 => '0') & reg_done;
                when others     => data_out <= (others => '0');
            end case;
        else
            data_out <= (others => 'Z'); -- tri-state when not being read
        end if;
    end process;

    done <= reg_done;

end rtl;
