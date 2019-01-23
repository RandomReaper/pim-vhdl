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

architecture bhv of managed_tbc is
	constant bug_severity	: severity_level := failure;

	constant g_parallel		: natural := 3;

	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);

	signal data_valid		: std_ulogic;
	signal data				: std_ulogic_vector(g_parallel*12 - 1 downto 0);
	signal expected_data	: std_ulogic_vector(data'range);
begin

tb_process: process
	variable timeout : integer;
begin
	stop <= '0';

	expected_data <= (others => '0');
	for i in 0 to g_parallel - 1 loop
		expected_data(12*i) <= '1';
	end loop;

	for i in 0 to 100 loop
		timeout := 100;
		while data_valid /= '1' loop
			wait until falling_edge(clock);

			assert timeout > 0 report "Timeout waiting for data_valid" severity bug_severity;

			timeout := timeout - 1;
		end loop;

		assert data = expected_data report "Wrong data" severity bug_severity;
		wait until falling_edge(clock);
		assert data_valid = '0' report "Wrong data valid duration" severity bug_severity;

		expected_data <= std_ulogic_vector(unsigned(expected_data) rol 1);

	end loop;

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

end bhv;
