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
		STATE_WRITE_FIRST,
		STATE_WRITE_FIFO,
		STATE_WRITE_FAILED
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

state_machine_next: process(state, write_empty, rx_not_empty, tx_not_full, ft_write)
begin
	next_state <= state;
	
	case state is
		when STATE_RESET =>
				next_state <= STATE_IDLE;

		when STATE_IDLE =>
			if write_empty = '0' then
				next_state <= STATE_WRITE_FIRST;
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
			
		when STATE_WRITE_FIRST =>
			if tx_not_full ='1' and write_empty = '0' then
				next_state <= STATE_WRITE_FIFO;
			elsif tx_not_full ='0' and write_empty = '0' then
				next_state <= STATE_IDLE;
			else 
				next_state <= STATE_IDLE;
			end if;
			
		when STATE_WRITE_FIFO =>
			if tx_not_full ='1' and write_empty = '0' then
				next_state <= STATE_WRITE_FIFO;
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
		'1' when STATE_WRITE_FIRST | STATE_WRITE_FIFO,
		'0' when others;
		
with state select read_valid <=
		read_old_old and rx_not_empty when STATE_READ,
		'0' when others;
		
with state select write_read <=
		not write_empty and not(rx_not_empty) when STATE_WRITE_FIRST | STATE_WRITE_FIFO | STATE_IDLE,
		'0' when others;
		
end rtl;
