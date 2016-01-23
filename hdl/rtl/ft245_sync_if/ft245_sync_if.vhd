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
	clkout			: in	std_ulogic;
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
end ft245_sync_if;

architecture rtl of ft245_sync_if is

	alias clock				: std_ulogic is clkout;

	type state_e is
	(
		STATE_RESET,
		STATE_IDLE,
		STATE_WAIT_READ1,
		STATE_WAIT_READ2,
		STATE_READ,
		STATE_WRITE,
		STATE_WRITE_FAILED,
		STATE_WRITE_OLD
	);
	
	signal state			: state_e;
	signal next_state		: state_e;
	
	signal oe				: std_ulogic;
	signal read				: std_ulogic;
	signal write_data_sync	: std_ulogic_vector(write_data'range);
	signal tx_not_full		: std_ulogic;
	signal rx_not_empty		: std_ulogic;
	signal ft_write			: std_ulogic;
	signal ft_suspend		: std_ulogic;
	signal read_old			: std_ulogic;
	signal read_old_old		: std_ulogic;
	
	type old_t is array(3 downto 0) of std_ulogic_vector(write_data'range);
	signal failed			: std_ulogic;
	signal write_data_old	: old_t;
	signal old_counter		: unsigned(1 downto 0);
	
	-- Force signals into IO pads
	-- Warning XST specific syntax
	attribute iob					: string;
	attribute iob of write_data_sync: signal is "FORCE";
	attribute iob of rxf_n			: signal is "FORCE";
	attribute iob of txe_n			: signal is "FORCE";
	attribute iob of rd_n			: signal is "FORCE";
	attribute iob of wr_n			: signal is "FORCE";
	attribute iob of clkout			: signal is "FORCE";
	attribute iob of oe_n			: signal is "FORCE";
	attribute iob of siwu			: signal is "FORCE";
	attribute iob of reset_n		: signal is "FORCE";
	attribute iob of suspend_n		: signal is "FORCE";
begin

-- Unused output (at this time)
reset_n <= '1';
siwu <= '1';

-- Tristate
adbus <= std_logic_vector(write_data_sync) when oe = '0' else (others => 'Z');

state_machine: process(reset, clock)
begin
	if reset = '1' then
		state <= STATE_RESET;
	elsif rising_edge(clock) then
		state <= next_state;
	end if;
end process;

state_machine_next: process(state, write_empty, rx_not_empty, tx_not_full, ft_write, failed, old_counter)
begin
	next_state <= state;
	
	case state is
		when STATE_RESET =>
				next_state <= STATE_IDLE;

		when STATE_IDLE =>
			if write_empty = '0' and tx_not_full = '1' then
				next_state <= STATE_WRITE;
			end if;
		
			if failed = '1' and tx_not_full = '1' then
				next_state <= STATE_WRITE_OLD;
			end if;
		
			if rx_not_empty = '1' then
				next_state <= STATE_WAIT_READ1;
			end if;

		when STATE_WAIT_READ1 =>
			next_state <= STATE_WAIT_READ2;

		when STATE_WAIT_READ2 =>
			next_state <= STATE_READ;

		when STATE_READ =>
			if rx_not_empty = '0' then
				next_state <= STATE_IDLE;
			end if;
			
		when STATE_WRITE_OLD =>
			if old_counter = write_data_old'left then
				next_state <= STATE_IDLE;
			end if;
			
		when STATE_WRITE =>
			if tx_not_full ='1' and write_empty = '0' then
				next_state <= STATE_WRITE;
			elsif tx_not_full ='0' and write_empty = '0' then
				next_state <= STATE_WRITE_FAILED;
			else 
				next_state <= STATE_IDLE;
			end if;
			
		when STATE_WRITE_FAILED =>
			next_state <= STATE_IDLE;
	end case;
end process;

-- Synchronize input signals
in_sample: process(reset, clock)
begin
	if reset = '1' then
		read_data		<= (others => '0');
		tx_not_full		<= '0';
		rx_not_empty	<= '0';
		ft_suspend		<= '0';
	elsif rising_edge(clock) then
		read_data		<= std_ulogic_vector(adbus);
		tx_not_full		<= not txe_n;
		rx_not_empty	<= not rxf_n;
		ft_suspend		<= not suspend_n;
	end if;
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
		if state = STATE_WRITE_OLD then
			write_data_sync <= write_data_old(write_data_old'left);
		end if;
		rd_n			<= not read;
		wr_n			<= not ft_write;
		oe_n			<= not oe;
	end if;
end process;

-- Old values
old_values: process(reset, clock)
begin
	if reset = '1' then
		read_old		<= '0';
		read_old_old	<= '0';
	elsif rising_edge(clock) then
		read_old		<= read;
		read_old_old	<= read_old;
	end if;
end process;

with state select oe <=
		'1' when STATE_WAIT_READ1 | STATE_WAIT_READ2 | STATE_READ,
		'0' when others;

with state select read <=
		'1' when STATE_WAIT_READ2 | STATE_READ,
		'0' when others;

with state select ft_write <=
		tx_not_full when STATE_WRITE | STATE_WRITE_OLD,
		'0' when others;
		
with state select read_valid <=
		read_old_old and rx_not_empty when STATE_READ,
		'0' when others;
		
with next_state select write_read <=
		tx_not_full when STATE_WRITE,
		'0' when others;
		
process(reset, clock)
begin
	if reset = '1' then
		write_data_old <= (others => (others => '0'));
		failed <= '0';
		old_counter <= (others => '0');
	elsif rising_edge(clock) then

		if state = STATE_WRITE then
			for i in write_data_old'left downto 1 loop
				write_data_old(i) <= write_data_old(i-1);
			end loop;
			write_data_old(0) <= write_data;
		end if;
		
		if state = STATE_WRITE and next_state = STATE_WRITE_FAILED then
			failed <= '1';
		end if;

		if state = STATE_WRITE_OLD and next_state = STATE_IDLE then
			old_counter <= (others => '0');
			failed <= '0';
		end if;
		
		if state = STATE_WRITE_OLD then
			old_counter <= old_counter + 1;
			for i in write_data_old'left downto 1 loop
				write_data_old(i) <= write_data_old(i-1);
			end loop;
		end if;
	end if;
end process;
		
end rtl;
