-----------------------------------------------------------------------------
-- file			: packetizer.vhd 
--
-- brief		: adc7476 interface
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-- limitations	: uses a 2^prescaler clock (prescaler >= 1)
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity packetizer is
generic
(
	g_parallel		: natural := 1;
	g_nrdata_log2	: natural := 5
);
port
(
	clock			: in	std_ulogic;
	reset			: in	std_ulogic;
	
	adc_data		: in	std_ulogic_vector(g_parallel*12-1 downto 0);
	adc_data_valid	: in	std_ulogic;
	ft_empty		: out	std_ulogic;
	ft_data			: out	std_ulogic_vector(7 downto 0);
	ft_read			: in	std_ulogic
);
end packetizer;

architecture rtl of packetizer is
	signal tx_write		: std_ulogic;
	signal tx_data		: std_ulogic_vector(ft_data'range);
	signal rx_read		: std_ulogic;
	signal rx_empty		: std_ulogic;
	signal rx_data		: std_ulogic_vector(adc_data'range);
	
	signal packet_count : unsigned(7 downto 0);
	signal in_count		: unsigned(g_nrdata_log2 downto 0);
	
	type state_e is
	(
		STATE_RESET,
		STATE_IDLE,
		STATE_NEW_PACKET,
		STATE_HEADER0,
		STATE_HEADER1,
		STATE_HEADERN,
		STATE_DATA
	);
	
	signal state		: state_e;
	signal next_state	: state_e;
begin

state_machine: process(reset, clock)
begin
	if reset = '1' then
		state <= STATE_RESET;
	elsif rising_edge(clock) then
		state <= next_state;
	end if;
end process;

state_machine_next: process(state)
begin
	next_state <= state;
	
	case state is
		when STATE_RESET =>
			next_state <= STATE_IDLE;
			
		when STATE_IDLE =>
			if rx_empty = '1' then
				next_state <= STATE_NEW_PACKET;
			end if;
		
		when STATE_NEW_PACKET =>
			next_state <= STATE_HEADER0;
			
		when STATE_HEADER0 =>
			next_state <= STATE_HEADER1;

		when STATE_HEADER1 =>
			next_state <= STATE_HEADERN;
			
		when STATE_HEADERN =>
			next_state <= STATE_HEADERN;
			
		when STATE_DATA =>
			next_state <= STATE_IDLE;
	end case;
end process;

packet_count_gen: process(reset, clock)
begin
	if reset = '1' then
		packet_count <= (others => '0');
	elsif rising_edge(clock) then
		if state = STATE_NEW_PACKET then
			packet_count <= packet_count + 1;
		end if;
	end if;
end process;

in_count_gen: process(reset, clock)
begin
	if reset = '1' then
		in_count <= (others => '0');
	elsif rising_edge(clock) then
		if rx_read = '1' then
			in_count <= in_count + 1;
		end if;
	end if;
end process;

i_fifo_in: entity work.fifo
port map
(
	reset		=> reset,
	clock		=> clock,
	sync_reset	=> '0',
	write		=> adc_data_valid,
	write_data	=> adc_data,

	read		=> rx_read,
	read_data	=> rx_data,
	status_empty=> rx_empty
);

i_fifo_out: entity work.fifo
port map
(
	reset		=> reset,
	clock		=> clock,
	sync_reset	=> '0',
	write		=> tx_write,
	write_data	=> tx_data,

	read		=> ft_read,
	read_data	=> ft_data,
	status_empty=> ft_empty
);

end rtl;
