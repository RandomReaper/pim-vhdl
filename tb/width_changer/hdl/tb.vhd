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
	
	signal data4			: unsigned(3 downto 0);
	signal data12			: std_ulogic_vector(11 downto 0);
	signal data12_valid		: std_ulogic;
	signal data6			: std_ulogic_vector(5 downto 0);
	signal data6_valid		: std_ulogic;	
	signal data24			: std_ulogic_vector(23 downto 0);
	signal data24_valid		: std_ulogic;	
	signal data4_bis		: std_ulogic_vector(3 downto 0);
	signal data4_bis_valid	: std_ulogic;	
begin

i_dut0: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,
	
	in_data			=> std_ulogic_vector(data4),
	in_data_valid	=> '1',
	in_data_ready	=> open,
	out_data		=> data12,
	out_data_valid	=> data12_valid
);

i_dut1: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,
	
	in_data			=> data12,
	in_data_valid	=> data12_valid,
	in_data_ready	=> open,
	out_data		=> data6,
	out_data_valid	=> data6_valid
);

i_dut2: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,
	
	in_data			=> data6,
	in_data_valid	=> data6_valid,
	in_data_ready	=> open,
	out_data		=> data24,
	out_data_valid	=> data24_valid
);

i_dut3: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,
	
	in_data			=> data24,
	in_data_valid	=> data24_valid,
	in_data_ready	=> open,
	out_data		=> data4_bis,
	out_data_valid	=> data4_bis_valid
);

counter: process(reset, clock)
begin
	if reset = '1' then
		data4 <= (others => '0');
	elsif rising_edge(clock) then
		data4 <= data4+1;
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
