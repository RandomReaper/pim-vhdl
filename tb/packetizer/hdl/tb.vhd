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
	
	signal counter			: unsigned(9 downto 0);
	signal ft_read			: std_ulogic;
	signal ft_empty			: std_ulogic;
	signal ft_valid			: std_ulogic;
	signal adc_data_valid	: std_ulogic;
begin

i_packetizer : entity work.packetizer
generic map
(
	g_nrdata_log2		=> 3,
	g_depth_in_log2		=> 2,
	g_depth_out_log2	=> 5
)
port map
(
	reset	=> reset,
	clock	=> clock,
	
	adc_data		=> std_ulogic_vector(counter(counter'left downto counter'left-7)),
	adc_data_valid	=> adc_data_valid,
	ft_empty		=> ft_empty,
	ft_data			=> open,
	ft_read			=> ft_read
);

ft_read <= not ft_empty;

adc_data_valid <= '1' when counter(counter'left-8 downto 0) = 0 else '0';

process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
	elsif rising_edge(clock) then
		counter <= counter + 1;
	end if;
end process;

process(reset, clock)
begin
	if reset = '1' then
		ft_valid <= '0';
	elsif rising_edge(clock) then
		ft_valid <= ft_read;
	end if;
end process;

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
