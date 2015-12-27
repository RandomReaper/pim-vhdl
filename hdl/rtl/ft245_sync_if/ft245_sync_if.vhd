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
	write			: in	std_ulogic;
	write_full		: out	std_ulogic;
	
	read_data		: out	std_ulogic_vector(7 downto 0);
	read_valid		: out	std_ulogic
);
end ft245_sync_if;

architecture rtl of ft245_sync_if is
	constant g_depth_log2 : natural := 2;
	alias clock				: std_ulogic is clkout;
	signal oe				: std_ulogic;
	signal read_data_sync	: std_ulogic_vector(read_data'range);
	signal write_data_sync	: std_ulogic_vector(write_data'range);
	signal tx_not_full		: std_ulogic;
	signal rx_not_empty		: std_ulogic;
	signal ft_read			: std_ulogic;
	signal ft_write			: std_ulogic;
	signal ft_suspend		: std_ulogic;
	signal write_try		: std_ulogic;
	signal write_failed		: std_ulogic;
	signal write_ok			: std_ulogic;
	signal read_ok			: std_ulogic;
	signal write_data_int	: std_ulogic_vector(write_data'range);
	
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

-- Synchronize input signals
in_sample: process(reset, clock)
begin
	if reset = '1' then
		read_data_sync	<= (others => '0');
		tx_not_full		<= '0';
		rx_not_empty	<= '0';
		ft_suspend		<= '0';
	elsif rising_edge(clock) then
		read_data_sync	<= std_ulogic_vector(adbus);
		tx_not_full		<= not txe_n;
		rx_not_empty	<= not rxf_n;
		ft_suspend		<= not suspend_n;
	end if;
end process;

ft_read	<= rx_not_empty;
oe		<= ft_read;

-- Synchronize output signals
out_sync: process(reset, clock)
begin
	if reset = '1' then
		write_data_sync	<= (others => '0');
		rd_n			<= '1';
		wr_n			<= '1';
		oe_n			<= '1';
	elsif rising_edge(clock) then
		write_data_sync	<= write_data_int;
		rd_n			<= not ft_read;
		wr_n			<= not (ft_write and tx_not_full);
		oe_n			<= not oe;
	end if;
end process;

in_sync: process(reset, clock)
begin
	if reset = '1' then
		read_data	<= (others => '0');
		read_valid	<= '0';
		read_ok		<= '0';
	elsif rising_edge(clock) then
		read_data	<= std_ulogic_vector(adbus);
		read_ok		<= ft_read;
		read_valid	<= read_ok;
	end if;
end process;

try_out: process(reset, clock)
begin
	if reset = '1' then
		write_try		<= '0';
	elsif rising_edge(clock) then
		write_try		<= ft_write and tx_not_full;
	end if;	
end process;
write_failed	<= write_try and not tx_not_full;
write_ok		<= write_try and tx_not_full;

write_full		<= not tx_not_full;
process(reset, clock)
begin
	if reset = '1' then
		write_data_int			<= (others => '0');
		ft_write				<= '0';
	elsif rising_edge(clock) then
		ft_write				<= '0';
		if write = '1' then
			write_data_int		<= write_data;
			ft_write			<= '1';
		end if;
	end if;	
end process;

end rtl;
