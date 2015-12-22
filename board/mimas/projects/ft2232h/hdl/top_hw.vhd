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
	
	-- Force signals into IO pads
	attribute iob				: string;
	attribute iob of FT_nWR		: signal is "FORCE";
	attribute iob of FT_nTXE	: signal is "FORCE";

begin
	FT_nWR <= not write;
	FT_nRD <= not read;
	FT_SIWUA <= not now;
	FT_nOE <= not oe;
	FT_nRESET <= not ft_reset;

	i_top : entity work.top
	port map
	(
		clock			=> FT_CLKOUT,
		reset			=> '0',
		data			=> FT_DATA,
		ft_reset		=> ft_reset,
		tx_empty		=> not FT_nTXE,
		rx_not_full		=> not FT_nRXF,
		write			=> write,
		read			=> read,
		now				=> now,
		oe				=> oe,
		suspend			=> not FT_nSUSPEND
	);

		
end bhv;

