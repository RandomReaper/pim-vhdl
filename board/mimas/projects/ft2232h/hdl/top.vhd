library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity top is
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;
		data			: out	std_ulogic_vector(7 downto 0);
		write_full		: in	std_ulogic;
		write			: out	std_ulogic
	);
end top;

architecture bhv of top is
	signal counter : unsigned(data'range);
begin

data <= std_ulogic_vector(counter);

data_gen: process(reset, clock)
begin
	if reset = '1' then
		counter 		<= (others => '0');
		write			<= '0';
	elsif rising_edge(clock) then
		write			<= '0';
		if write_full = '0' then
			counter		<= counter + 1;
			write		<= '1';
		end if;
	end if;
end process;

end bhv;

