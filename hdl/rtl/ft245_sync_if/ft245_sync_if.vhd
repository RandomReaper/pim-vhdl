-----------------------------------------------------------------------------
-- file			: ft245_sync_if.vhd 
--
-- brief		: Interface for FTDI ft2232h in ft245 synchronous mode
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
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
	in_data			: out	std_ulogic_vector(7 downto 0);
	in_data_read	: in	std_ulogic;
	in_data_valid	: out	std_ulogic;
	
	out_data		: in	std_ulogic_vector(7 downto 0);
	out_data_write	: in	std_ulogic;
	out_data_ack	: out	std_ulogic
);
end ft245_sync_if;

architecture rtl of ft245_sync_if is
	signal clock		: std_ulogic;
	signal oe			: std_ulogic;
	signal in_data_int	: std_ulogic_vector(in_data'range);
	signal out_data_int : std_ulogic_vector(out_data'range);
	signal tx_not_full	: std_ulogic;
	signal rx_not_empty : std_ulogic;
	signal read			: std_ulogic;
	signal write		: std_ulogic;
	signal write_ext	: std_ulogic;
	signal write_done	: std_ulogic;
	signal status_full	: std_ulogic;
	signal status_empty	: std_ulogic;

	
	-- Force signals into IO pads
	-- Warning XST specific syntax
	attribute iob					: string;
	attribute iob of adbus			: signal is "FORCE";
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

-- Signal polarity and renaming
oe_n <= not oe;
clock <= clkout;
write <= not status_empty;

-- FIXME reading is not implemented
oe		<= '0';
read	<= '0';

-- Tristate
adbus <= std_logic_vector(out_data_int) when oe = '0' else (others => 'Z');

-- Synchronize input signals
in_sample: process(reset, clock)
begin
	if reset = '1' then
		in_data_int		<= (others => '0');
		tx_not_full		<= '0';
		rx_not_empty	<= '0';
	elsif rising_edge(clock) then
		in_data_int		<= std_ulogic_vector(adbus);
		tx_not_full		<= not txe_n;
		rx_not_empty	<= not rxf_n;
	end if;
end process;

-- Synchronize output signals
out_sync: process(reset, clock)
begin
	if reset = '1' then
		--out_data_int	<= (others => '0');
		rd_n			<= '1';
		wr_n			<= '1';
	elsif rising_edge(clock) then
		--out_data_int	<= out_data;
		rd_n			<= not read;
		wr_n			<= not (write and tx_not_full);
	end if;
end process;

out_data_ack <= not status_full;
i_fifo : entity work.fifo
generic map
(
	g_depth_log2 => 1
)
port map
(
	clock				=> clock,
	reset				=> reset,

	-- input
	sync_reset			=> '0',
	write				=> out_data_write,
	write_data			=> out_data,

	-- outputs
	read				=> tx_not_full,
	read_data			=> out_data_int,

	--status
	status_full			=> status_full,
	status_empty		=> status_empty,
	status_write_error	=> open,
	status_read_error	=> open,
	
	free 				=> open,
	used 				=> open
);

-- Write to FTDI has succeeded when write is active at the same time as
-- fifo was not full.
data_out_ok: process(reset, clock)
begin
	if reset = '1' then
		write_ext		<= '0';
		write_done		<= '0';
	elsif rising_edge(clock) then
		write_ext		<= write;
		write_done		<= write_ext and tx_not_full;
	end if;
end process;

end rtl;
