library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity top is
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;
		data			: out	std_ulogic_vector(7 downto 0);
		ft_reset		: out	std_ulogic;
		tx_not_full		: in	std_ulogic;
		rx_not_empty	: in	std_ulogic;
		write			: out	std_ulogic;
		read			: out	std_ulogic;
		now				: out	std_ulogic;
		oe				: out	std_ulogic;
		suspend			: in	std_ulogic
	);
end top;

architecture bhv of top is
	signal counter : unsigned(data'range);
begin

read <= '0';
oe <= '0';
ft_reset <= '0';
data <= std_ulogic_vector(counter);
now <= '0';

write_gen: process(reset, clock)
begin
	if reset = '1' then
		write <= '0';
	elsif rising_edge(clock) then
		write <= tx_not_full;
	end if;
end process;

data_gen: process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
	elsif rising_edge(clock) then
		if tx_not_full = '1' then
			counter <= counter + 1;
		end if;
	end if;
end process;

end bhv;

