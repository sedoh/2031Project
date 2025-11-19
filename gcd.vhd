library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd_peripheral is
    port(
        clk        : in  std_logic;
        address    : in  unsigned(7 downto 0);      -- CPU address (low byte)
        data_in    : in  unsigned(15 downto 0);     -- CPU write data
        data_out   : out unsigned(15 downto 0);     -- CPU read data
        mem_read   : in  std_logic;                 -- CPU is reading
        mem_write  : in  std_logic;                 -- CPU is writing
        done       : out std_logic;                 -- high when finished
        resetn     : in  std_logic                  -- active-low reset
    );
end gcd_peripheral;

architecture rtl of gcd_peripheral is
    -- NEW address map in 0x90–0x9F window
    constant A_ADDR     : unsigned(7 downto 0) := x"90";
    constant B_ADDR     : unsigned(7 downto 0) := x"91";
    constant START_ADDR : unsigned(7 downto 0) := x"92";
    constant RES_ADDR   : unsigned(7 downto 0) := x"93";
    constant DONE_ADDR  : unsigned(7 downto 0) := x"94";

    -- MMIO registers
    signal reg_a, reg_b   : unsigned(15 downto 0) := (others => '0');
    signal reg_result     : unsigned(15 downto 0) := (others => '0');
    signal reg_done       : std_logic := '0';
    signal start_req      : std_logic := '0';  -- latched start

    -- Binary GCD (Stein) working regs
    type state_t is (
        IDLE, CHECK_ZERO, STRIP_COMMON, MAKE_A_ODD, MAKE_B_ODD,
        ORDER_AB, SUBTRACT, TEST_B_ZERO, FINISH, HOLD_DONE
    );
    signal st             : state_t := IDLE;
    signal a_w, b_w       : unsigned(15 downto 0) := (others => '0');
    signal shift_cnt      : unsigned(4 downto 0)  := (others => '0'); -- 0..16
begin
	 -- Main sequential logic block
    process(clk, resetn)
    begin
        if resetn = '0' then
            reg_a      <= (others => '0');
            reg_b      <= (others => '0');
            reg_result <= (others => '0');
            reg_done   <= '0';
            start_req  <= '0';
            a_w        <= (others => '0');
            b_w        <= (others => '0');
            shift_cnt  <= (others => '0');
            st         <= IDLE;
        elsif rising_edge(clk) then
            -- MMIO writes
            if mem_write = '1' then
                if address = A_ADDR     then reg_a <= data_in; end if;
                if address = B_ADDR     then reg_b <= data_in; end if;
                if address = START_ADDR then start_req <= data_in(0); end if;
            end if;

            -- Reading DONE clears it
            if mem_read = '1' and address = DONE_ADDR then
                reg_done <= '0';
            end if;

            -- Consume START only when idle
            if (st = IDLE) and (start_req = '1') then
                start_req <= '0';
                reg_done  <= '0';
                a_w       <= reg_a;
                b_w       <= reg_b;
                shift_cnt <= (others => '0');
                st        <= CHECK_ZERO;
            end if;

            -- GCD FSM (Stein’s algorithm; no divider)
            case st is
                when IDLE =>
                    null;

                when CHECK_ZERO =>
                    if a_w = 0 then
                        reg_result <= b_w;  st <= FINISH;
                    elsif b_w = 0 then
                        reg_result <= a_w;  st <= FINISH;
                    else
                        st <= STRIP_COMMON;
                    end if;

                when STRIP_COMMON =>
                    if (a_w(0) = '0') and (b_w(0) = '0') then
                        a_w      <= '0' & a_w(15 downto 1);
                        b_w      <= '0' & b_w(15 downto 1);
                        shift_cnt<= shift_cnt + 1;
                    else
                        st <= MAKE_A_ODD;
                    end if;

                when MAKE_A_ODD =>
                    if a_w(0) = '0' then
                        a_w <= '0' & a_w(15 downto 1);
                    else
                        st <= MAKE_B_ODD;
                    end if;

                when MAKE_B_ODD =>
                    if b_w(0) = '0' then
                        b_w <= '0' & b_w(15 downto 1);
                    else
                        st <= ORDER_AB;
                    end if;

                when ORDER_AB =>
                    if a_w > b_w then
                        -- swap a_w and b_w
                        a_w <= b_w;
                        b_w <= a_w;
                    end if;
                    st <= SUBTRACT;

                when SUBTRACT =>
                    b_w <= b_w - a_w;
                    st  <= TEST_B_ZERO;

                when TEST_B_ZERO =>
                    if b_w = 0 then
                        reg_result <= shift_left(a_w, to_integer(shift_cnt));
                        st <= FINISH;
                    else
                        st <= MAKE_B_ODD;
                    end if;

                when FINISH =>
                    reg_done <= '1';
                    st <= HOLD_DONE;

                when HOLD_DONE =>
                    -- Hold DONE high until CPU reads DONE and clears it
                    if reg_done = '0' then
                        st <= IDLE;
                    end if;

                when others =>
                    st <= IDLE;
            end case;
        end if;
    end process;

    -- Main combinational logic block
    process(address, mem_read, reg_a, reg_b, reg_result, reg_done)
    begin
        if mem_read = '1' then
            case address is
                when A_ADDR     => data_out <= reg_a;
                when B_ADDR     => data_out <= reg_b;
                when START_ADDR => data_out <= (others => '0'); -- optional readback
                when RES_ADDR   => data_out <= reg_result;
                when DONE_ADDR  => data_out <= (15 downto 1 => '0') & reg_done;
                when others     => data_out <= (others => '0');
            end case;
        else
            data_out <= (others => 'Z'); -- tri-state when not being read
        end if;
    end process;

    done <= reg_done;
	 
end rtl;
