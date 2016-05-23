-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench
-- author(s)	: marc at pignat dot org
-----------------------------------------------------------------------------
-- Copyright 2015,2016 Marc Pignat
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- 		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- See the License for the specific language governing permissions and
-- limitations under the License.
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity tb is
generic
(
	g_parallel	: natural := 3
);
end tb;

architecture bhv of tb is

	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	signal stop				: std_ulogic;

	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);

	signal data_valid		: std_ulogic;
	signal data				: std_ulogic_vector(g_parallel*12 - 1 downto 0);
	signal expected_data	: std_ulogic_vector(data'range);
begin

	tb : process
	begin

	-----------------------------------------------------------------------------
	-- No reset
	-----------------------------------------------------------------------------
	stop		<= '0';
	reset		<= '0';

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (data_valid				= '0')			report "data_valid should be '0' and is " & std_ulogic'image(data_valid) severity warning;
	assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity warning;
	assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity warning;
	assert (unsigned(data)			= 0)			report "data should be 0";

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- Async reset
	-----------------------------------------------------------------------------

	reset		<= '1';
	wait until falling_edge(clock);
	wait until falling_edge(clock);
	reset		<= '0';
	wait until falling_edge(clock);

	assert (data_valid				= '0')			report "data_valid should be '0' and is " & std_ulogic'image(data_valid) severity warning;
	assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity warning;
	assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity warning;
	assert (unsigned(data)			= 0)			report "data should be 0";

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	stop <= '1';

	wait;

	end process;

i_adc_if : entity work.ad7476_parallel_if
generic map
(
	g_prescaler	=> 1,
	g_parallel	=> g_parallel
)
port map
(
	reset		=> reset,
	clock		=> clock,

	sclk		=> sclk,
	n_cs		=> n_cs,
	sdata		=> sdata,

	data		=> data,
	data_valid	=> data_valid
);

i_adc_sim : entity work.ad7476_parallel_sim
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	reset		=> reset,
	sclk		=> sclk,
	n_cs		=> n_cs,
	sdata		=> sdata
);


i_clock : entity work.clock_stop
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock		=> clock,
	stop	   	=> stop
);

end bhv;
