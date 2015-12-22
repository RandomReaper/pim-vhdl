library ieee;
use ieee.std_logic_1164.all;

entity top is
	port
	(
		clock			: in	std_logic;
		reset			: in	std_logic;
		data			: out	std_logic_vector(7 downto 0);
		ft_reset		: out	std_logic;
		tx_empty		: in	std_logic;
		rx_not_full		: in	std_logic;
		write			: out	std_logic;
		read			: out	std_logic;
		now				: out	std_logic;
		oe				: out	std_logic;
		suspend			: in	std_logic
	);
end top;

architecture bhv of top is

begin
	read <= '0';
	oe <= '0';
	ft_reset <= '0';
	data <= x"aa";
	
	process(reset, clock)
	begin
		if reset = '1' then
			write <= '0';
		elsif rising_edge(clock) then
			write <= tx_empty;
		end if;
	end process;
end bhv;

