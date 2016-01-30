-----------------------------------------------------------------------------
-- file			: tb.vhd 
--
-- brief		: Test bench
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
entity tb is
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	
	signal counter			: unsigned(7 downto 0);
	signal counter_enable		: unsigned(7 downto 0);
	
	signal read				: std_ulogic;
	signal empty			: std_ulogic;
	
	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write			: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal full				: std_ulogic;
	
	signal read_valid		: std_ulogic;
	signal d_in				: std_ulogic_vector(7 downto 0);
	signal d_out			: std_ulogic_vector(7 downto 0);
begin

i_fifo_preread : entity work.fifo_preread
generic map
(
	g_depth_log2	=> 1
)
port map
(
	reset			=> reset,
	clock			=> clock,
	
	sync_reset	=> '0',
	
	write_data		=> write_data,
	write			=> write,
	status_empty	=> empty,
	
	read_data		=> read_data,
	read			=> read,
	status_full		=> full
);

-- Fill with consecutive numbers
write_data <= std_ulogic_vector(counter);
write <= not full and not reset and counter_enable(2);
process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
	elsif rising_edge(clock) then
		if full = '0' and counter_enable(2) = '1' then
			counter <= counter + 1;
		end if;
	end if;
end process;

-- Read 
read <= counter_enable(3) and not empty;

process(reset, clock)
begin
	if reset = '1' then
		counter_enable <= (others => '0');
	elsif rising_edge(clock) then
		counter_enable <= counter_enable + 1;
	end if;
end process;

-- Highlight data in/out when valid for debugging
d_out <= read_data when read_valid ='1' else (others => '-');
d_in <= write_data when write ='1' else (others => '-');

read_valid <= read and not reset;

i_clock : entity work.clock
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock	=> clock
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

end bhv;
