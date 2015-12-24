library ieee;
	use ieee.std_logic_1164.all;

entity top_hw is
	port
	(
		FT_CLKOUT		: in	std_ulogic;
		FT_DATA			: out	std_ulogic_vector(7 downto 0);
		FT_nRESET		: out	std_ulogic;
		FT_nTXE			: in	std_ulogic;
		FT_nRXF			: in	std_ulogic;
		FT_nWR			: out	std_ulogic;
		FT_nRD			: out	std_ulogic;
		FT_SIWUA		: out	std_ulogic;
		FT_nOE			: out	std_ulogic;
		FT_nSUSPEND		: in	std_ulogic
	);
end top_hw;

architecture bhv of top_hw is
	signal write : std_ulogic;
	signal read : std_ulogic;
	signal now : std_ulogic;
	signal oe : std_ulogic;
	signal ft_reset : std_ulogic;
	signal data	: std_ulogic_vector(FT_DATA'range);
	signal tx_not_full : std_ulogic;
	signal rx_not_empty : std_ulogic;
	signal suspend : std_ulogic;
	signal clock : std_ulogic;
	signal reset : std_ulogic;
	
	-- Force signals into IO pads
	attribute iob					: string;
	
	attribute iob of FT_DATA		: signal is "FORCE";
	attribute iob of FT_nRESET		: signal is "FORCE";
	attribute iob of FT_nTXE		: signal is "FORCE";
	attribute iob of FT_nRXF		: signal is "FORCE";
	attribute iob of FT_nWR			: signal is "FORCE";
	attribute iob of FT_nRD			: signal is "FORCE";
	attribute iob of FT_SIWUA		: signal is "FORCE";
	attribute iob of FT_nOE			: signal is "FORCE";
	attribute iob of FT_nSUSPEND	: signal is "FORCE";

begin

clock <= FT_CLKOUT;

-- FIXME reset should be generated
reset <= '0';

io_sync: process(reset, clock)
begin
	if reset = '1' then
		FT_nWR <= '1';
		FT_nRD <= '1';
		FT_SIWUA <= '1';
		FT_nOE <= '1';
		FT_nRESET <= '1';
		tx_not_full <= '0';
		rx_not_empty <= '0';
		suspend <= '0';
	elsif rising_edge(clock) then
		FT_DATA <= data;
		FT_nWR <= not write;
		FT_nRD <= not read;
		FT_SIWUA <= not now;
		FT_nOE <= not oe;
		FT_nRESET <= not ft_reset;
		tx_not_full <= not FT_nTXE;
		rx_not_empty <= not FT_nRXF;
		suspend <= not FT_nSUSPEND;
	end if;
end process;
	

i_top : entity work.top
port map
(
	clock			=> clock,
	reset			=> reset,
	data			=> data,
	ft_reset		=> ft_reset,
	tx_not_full		=> tx_not_full,
	rx_not_empty	=> rx_not_empty,
	write			=> write,
	read			=> read,
	now				=> now,
	oe				=> oe,
	suspend			=> suspend
);
		
end bhv;

