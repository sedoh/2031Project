library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integer_division_peripheral is
    port(
        clk     	          : in  std_logic;
		    address 	          : in  unsigned(7 downto 0) -- memory address being accessed by the CPU
        data_in             : in unsigned(15 downto 0); -- data CPU is writing to peripheral
        data_out            : out unsigned(15 downto 0); -- data the peripheral reads back to CPU during a read
        mem_read, mem_write : in std_logic; -- tells peripheral whether CPU is reading or writing to memory
        done                : out std_logic -- high if operation is done
		    resetn              : in  std_logic 
    );
end integer_division_peripheral;

architecture rtl of integer_division_peripheral is
    -- Address map
    constant A_ADDR     : unsigned(7 downto 0) := x"90"; -- Write: Dividend (D)
    constant B_ADDR     : unsigned(7 downto 0) := x"91"; -- Write: Divisor (V)
    constant START_ADDR : unsigned(7 downto 0) := x"92"; -- Write: Start command
    constant RES_ADDR   : unsigned(7 downto 0) := x"93"; -- Read: Quotient (Q)
    constant DONE_ADDR  : unsigned(7 downto 0) := x"94"; -- Read: Remainder (R) / Clear Done

    -- Registers
    signal reg_a, reg_b     : unsigned(15 downto 0) := (others => '0'); -- Dividend, divisor
    signal reg_result       : unsigned(15 downto 0) := (others => '0'); -- Quotient
    signal reg_done         : std_logic := '0';
    signal start_req        : std_logic := '0';
    signal reg_remainder    : unsigned(15 downto 0) := (others => '0'); -- Remainder

    -- Non-restoring division working registers
    constant N_BITS         : integer := 16;
    signal pr_reg           : signed(N_BITS downto 0) := (others => '0');
    signal q_reg            : unsigned(N_BITS-1 downto 0) := (others => '0');
    signal v_ext            : signed(N_BITS downto 0) := (others => '0');
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

    -- Intermediate signals
    signal pr_minus_v : signed(N_BITS downto 0);
    signal pr_plus_v  : signed(N_BITS downto 0);

begin
    -- Combinational logic for next PR values
    v_ext <= signed('0' & reg_b);
    pr_minus_v <= pr_reg - v_ext;
    pr_plus_v  <= pr_reg + v_ext;

    -- Sequential logic
    process(clk, resetn)
    begin
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
                if address = A_ADDR      then reg_a <= data_in; end if;
                if address = B_ADDR      then reg_b <= data_in; end if;
                if address = START_ADDR  then start_req <= data_in(0); end if;
            end if;

            -- Reading a result clears DONE
            if mem_read = '1' and (address = RES_ADDR or address = DONE_ADDR) then
                reg_done <= '0';
            end if;

            -- Consume START
            if (st = IDLE) and (start_req = '1') then
                start_req <= '0';
                reg_done  <= '0';
                state     <= INIT_OP;
            end if;

            -- Non-restoring division FSM logic
            case state is
                when IDLE =>
                    null;

                when INIT_OP =>
                    if reg_b = 0 then
                        reg_result      <= (others => '1');
                        reg_remainder   <= reg_a;
                        state           <= FINISH;
                    else
                        pr_reg      <= (others => '0');
                        q_reg       <= reg_a;
                        step_count  <= to_unsigned(N_BITS, step_count'length);
                        state       <= CALCULATE;
                    end if;

                when CALCULATE =>
                    pr_reg <= pr_reg(pr_reg'left-1 downto 0) & q_reg(q_reg'left);
                    q_reg  <= q_reg(q_reg'left-1 downto 0) & '0';

                    if pr_reg(pr_reg'left) = '0' then
                        pr_reg <= pr_reg - v_ext;
                        if pr_minus_v(pr_minus_v'left) = '0' then
                            q_reg(0) <= '1';
                        else
                            q_reg(0) <= '0';
                        end if;
                    else
                        pr_reg <= pr_reg + v_ext;
                        if pr_plus_v(pr_plus_v'left) = '0' then
                            q_reg(0) <= '1';
                        else
                            q_reg(0) <= '0';
                        end if;
                    end if;

                    step_count <= step_count - 1;

                    if step_count = 1 then
                        state <= FINAL_RESTORE;
                    else
                        state <= CALCULATE;
                    end if;

                when FINAL_RESTORE =>
                    if pr_reg(pr_reg'left) = '1' then
                        pr_reg <= pr_reg + v_ext;
                    end if;
                    state <= FINISH;

                when FINISH =>
                    reg_result      <= q_reg;
                    reg_remainder   <= unsigned(pr_reg(N_BITS-1 downto 0));
                    reg_done        <= '1';
                    state           <= HOLD_DONE;

                when HOLD_DONE =>
                    if reg_done = '0' then
                        state <= IDLE;
                    end if;

                when others =>
                    state <= IDLE;
						  
            end case;
        end if;
    end process;

    -- Combinational logic
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
