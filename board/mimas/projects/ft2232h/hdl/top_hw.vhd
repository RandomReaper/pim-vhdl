library ieee;
	use ieee.std_logic_1164.all;

entity top_hw is
	port
	(
		FT_CLKOUT		: in	std_logic;
		FT_DATA			: out	std_logic_vector(7 downto 0);
		FT_nRESET		: out	std_logic;
		FT_nTXE			: in	std_logic;
		FT_nRXF			: in	std_logic;
		FT_nWR			: out	std_logic;
		FT_nRD			: out	std_logic;
		FT_SIWUA		: out	std_logic;
		FT_nOE			: out	std_logic;
		FT_nSUSPEND		: in	std_logic
	);
end top_hw;

architecture bhv of top_hw is
	signal write : std_logic;
	signal read : std_logic;
	signal now : std_logic;
	signal oe : std_logic;
	signal ft_reset : std_logic;
	signal data	: std_logic_vector(FT_DATA'range);
	signal tx_not_full : std_logic;
	signal rx_not_empty : std_logic;
	signal suspend : std_logic;
	signal clock : std_logic;
	signal reset : std_logic;
	
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

