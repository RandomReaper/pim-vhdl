-----------------------------------------------------------------------------
-- brief		: Test bench
-- author(s)	: marc at pignat dot org
-----------------------------------------------------------------------------
-- Copyright 2015-2019 Marc Pignat
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
library vunit_lib;
	context vunit_lib.vunit_context;

entity tb_ad7476_00_reset is
generic
(
	runner_cfg		: string;
	g_parallel		: natural := 3
);
end tb_ad7476_00_reset
;

architecture bhv of tb_ad7476_00_reset is
	constant bug_severity : severity_level := failure;

	signal reset			: std_ulogic;
	signal clock			: std_ulogic;

	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);

	signal data_valid		: std_ulogic;
	signal data				: std_ulogic_vector(g_parallel*12 - 1 downto 0);
	signal expected_data	: std_ulogic_vector(data'range);
begin

	tb : process
	begin

		test_runner_setup(runner, runner_cfg);
		-----------------------------------------------------------------------------
		-- No reset
		-----------------------------------------------------------------------------
		reset		<= '0';

		wait until rising_edge(clock);
		wait until falling_edge(clock);

		assert (data_valid				= '0')			report "data_valid should be '0' and is " & std_ulogic'image(data_valid) severity bug_severity;
		assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity bug_severity;
		assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity bug_severity;
		assert (unsigned(data)			= 0)			report "data should be 0" severity bug_severity;

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

		assert (data_valid				= '0')			report "data_valid should be '0' and is " & std_ulogic'image(data_valid) severity bug_severity;
		assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity bug_severity;
		assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity bug_severity;
		assert (unsigned(data)			= 0)			report "data should be 0" severity bug_severity;

		wait until rising_edge(clock);
		wait until falling_edge(clock);

		-----------------------------------------------------------------------------
		-- End of test
		-----------------------------------------------------------------------------
		test_runner_cleanup(runner);

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


i_clock : entity work.clock
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock		=> clock
);

end bhv;
