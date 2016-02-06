-----------------------------------------------------------------------------
-- file			: ft245_sync_if.vhd 
--
-- brief		: Interface for FTDI ft2232h in ft245 synchronous mode
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-- FIXME : loses bytes when the ft245 tx fifo is full
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ft245_sync_if is
port
(
	-- Interface to the ftdi chip
	adbus			: inout	std_logic_vector(7 downto 0);
	rxf_n			: in	std_ulogic;
	txe_n			: in	std_ulogic;
	rd_n			: out	std_ulogic;
	wr_n			: out	std_ulogic;
	clock			: in	std_ulogic;
	oe_n			: out	std_ulogic;
	siwu			: out	std_ulogic;
	reset_n			: out	std_ulogic;
	suspend_n		: in	std_ulogic;
	
	-- Interface to the internal logic
	reset			: in	std_ulogic;
	
	write_data		: in	std_ulogic_vector(7 downto 0);
	write_empty		: in	std_ulogic;
	write_read		: out	std_ulogic;
	
	read_data		: out	std_ulogic_vector(7 downto 0);
	read_valid		: out	std_ulogic
);

	-- Force signals into IO pads
	-- Warning XST specific syntax
	attribute iob					: string;
	attribute iob of rxf_n			: signal is "FORCE";
	attribute iob of txe_n			: signal is "FORCE";
	attribute iob of rd_n			: signal is "FORCE";
	attribute iob of wr_n			: signal is "FORCE";
	attribute iob of oe_n			: signal is "FORCE";
	attribute iob of siwu			: signal is "FORCE";
	attribute iob of reset_n		: signal is "FORCE";
	attribute iob of suspend_n		: signal is "FORCE";

end ft245_sync_if;

architecture rtl of ft245_sync_if is

	type state_e is
	(
		STATE_RESET,
		STATE_IDLE,
		STATE_WAIT_READ1,
		STATE_WAIT_READ2,
		STATE_READ,
		STATE_AFTER_READ1,
		STATE_AFTER_READ2,
		STATE_WRITE,
		STATE_WRITE_OLD
	);
	
	signal state			: state_e;
	signal next_state		: state_e;
	signal state_old		: state_e;
	
	signal ft_oe			: std_ulogic;
	signal oe				: std_ulogic;
	signal read				: std_ulogic;
	signal write_data_sync	: std_ulogic_vector(write_data'range);
	signal tx_possible		: std_ulogic;
	signal rx_req			: std_ulogic;
	signal ft_write			: std_ulogic;
	signal ft_suspend		: std_ulogic;
	signal read_old			: std_ulogic;
	signal read_old_old		: std_ulogic;
	signal write_old		: std_ulogic;
	signal write_old_old	: std_ulogic;
	signal write_failed		: std_ulogic;
	signal read_data_int	: std_ulogic_vector(read_data'range);
	signal read_valid_int	: std_ulogic;
	signal write_read_int	: std_ulogic;
	signal write_read_old	: std_ulogic;

	type old_elem_t is
	record
		data : std_ulogic_vector(write_data'range);
		failed : std_ulogic;
	end record;
	
	type old_t is array(2 downto 0) of old_elem_t;
	signal write_data_old	: old_t;
	signal old_counter		: unsigned(1 downto 0);
	
	-- Force signals into IO pads
	-- Warning XST specific syntax
	attribute iob of write_data_sync		: signal is "FORCE";
	attribute iob of rx_req					: signal is "FORCE";
	attribute iob of tx_possible			: signal is "FORCE";
	attribute iob of ft_suspend				: signal is "FORCE";

begin

-- Unused output (at this time)
reset_n <= '1';
siwu <= '1';

-- Tristate
adbus <= std_logic_vector(write_data_sync) when oe = '1' else (others => 'Z');

state_machine: process(reset, clock)
begin
	if reset = '1' then
		state <= STATE_RESET;
	elsif rising_edge(clock) then
		state <= next_state;
	end if;
end process;

state_machine_next: process(state, write_empty, rx_req, tx_possible, write_failed, ft_write, old_counter)
begin
	next_state <= state;
	
	case state is
		when STATE_RESET =>
			next_state <= STATE_IDLE;

		when STATE_IDLE =>
			if write_empty = '0' and tx_possible = '1' then
				next_state <= STATE_WRITE;
			end if;

			if write_failed = '1' and tx_possible = '1' then
				next_state <= STATE_WRITE_OLD;
			end if;

			if rx_req = '1' then
				next_state <= STATE_WAIT_READ1;
			end if;

		when STATE_WAIT_READ1 =>
			next_state <= STATE_WAIT_READ2;

		when STATE_WAIT_READ2 =>
			next_state <= STATE_READ;

		when STATE_READ =>
			if rx_req = '0' then
				next_state <= STATE_AFTER_READ1;
			end if;

		when STATE_AFTER_READ1 =>
			next_state <= STATE_AFTER_READ2;
		when STATE_AFTER_READ2 =>
			next_state <= STATE_IDLE;

		when STATE_WRITE_OLD =>
			if old_counter = write_data_old'left then
				next_state <= STATE_IDLE;
			end if;
			
		when STATE_WRITE =>
			if tx_possible = '1' and write_empty = '0' then
				next_state <= STATE_WRITE;
			else 
				next_state <= STATE_IDLE;
			end if;
	end case;
end process;

-- Synchronize input signals
in_sample: process(reset, clock)
begin
	if reset = '1' then
		read_data_int	<= (others => '0');
		tx_possible		<= '0';
		rx_req			<= '0';
		ft_suspend		<= '0';
	elsif rising_edge(clock) then
		read_data_int	<= std_ulogic_vector(adbus);
		tx_possible		<= not txe_n;
		rx_req			<= not rxf_n;
		ft_suspend		<= not suspend_n;
	end if;
end process;

read_data_proc: process(read_data_int, read_valid_int)
begin
	read_data <= read_data_int;

	--pragma synthesis_off
	if read_valid_int = '0' then
		read_data <= (others => '-');
	end if;
	--pragma synthesis_on

end process;

-- Synchronize output signals
out_sync: process(reset, clock)
begin
	if reset = '1' then
		write_data_sync	<= (others => '0');
		rd_n			<= '1';
		wr_n			<= '1';
		oe_n			<= '1';
	elsif rising_edge(clock) then
		write_data_sync	<= write_data;
		rd_n			<= not read;
		wr_n			<= not ft_write;
		oe_n			<= not ft_oe;
		if state = STATE_WRITE_OLD then
			write_data_sync <= write_data_old(write_data_old'left).data;
		end if;
	end if;
end process;

-- Old values
old_values: process(reset, clock)
begin
	if reset = '1' then
		read_old		<= '0';
		read_old_old	<= '0';
		write_old		<= '0';
		write_old_old	<= '0';
		state_old		<= STATE_RESET;
		write_read_old	<= '0';
	elsif rising_edge(clock) then
		read_old		<= read;
		read_old_old	<= read_old;
		write_old		<= ft_write;
		write_old_old	<= write_old;
		state_old		<= state;
		write_read_old	<= write_read_int;
	end if;
end process;

with state select ft_oe <=
		'1' when STATE_WAIT_READ1 | STATE_WAIT_READ2 | STATE_READ,
		'0' when others;

with state select oe <=
		'0' when STATE_WAIT_READ1 | STATE_WAIT_READ2 | STATE_READ | STATE_AFTER_READ1 | STATE_AFTER_READ2,
		'1' when others;

with state select read <=
		'1' when STATE_WAIT_READ2 | STATE_READ,
		'0' when others;

with state select ft_write <=
		tx_possible when STATE_WRITE,
		write_data_old(write_data_old'left).failed when STATE_WRITE_OLD,
		'0' when others;
		
read_valid <= read_valid_int;
read_valid_int <= read_old and rx_req;

write_read <= write_read_int;
with next_state select write_read_int <=
		tx_possible when STATE_WRITE,
		'0' when others;
		
process(reset, clock)
begin
	if reset = '1' then
		for i in write_data_old'range loop
			write_data_old(i).data	 <= (others => '0');
			write_data_old(i).failed <= '0';

			--pragma synthesis_off
			write_data_old(i).data <= (others => '-');
			--pragma synthesis_on

		end loop;

		old_counter <= (others => '0');
		write_failed<= '0';
	elsif rising_edge(clock) then

		if write_read_old = '1' then
			for i in write_data_old'left downto 1 loop
				write_data_old(i) <= write_data_old(i-1);
			end loop;
			write_data_old(0).data <= write_data;
			write_data_old(0).failed <= '1';
		end if;

		if write_old = '1' and tx_possible = '1' then
			if write_read_old = '1' then
				write_data_old(1).failed <= '0';
			else
				write_data_old(0).failed <= '0';
			end if;
		end if;

		if state_old = STATE_WRITE and tx_possible = '0' then
			--write_data_old(0).failed <= '1';
			write_failed <= '1';
		end if;
		
		if state = STATE_WRITE_OLD then
			old_counter <= old_counter + 1;
			for i in write_data_old'left downto 1 loop
				write_data_old(i) <= write_data_old(i-1);
			end loop;

			write_data_old(0).failed <= '0';

			--pragma synthesis_off
			write_data_old(0).data <= (others => '-');
			--pragma synthesis_on

			if next_state = STATE_IDLE then
				old_counter <= (others => '0');
				write_failed <= '0';
			end if;
		end if;
	end if;
end process;

end rtl;
