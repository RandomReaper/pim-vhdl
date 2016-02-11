-----------------------------------------------------------------------------
-- file			: ad7476_parallel_sim.vhd
--
-- brief		: ad7476 (for simulation)
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

entity ad7476_parallel_sim is
generic
(
	g_parallel	: natural := 2
);
port
(
	sclk		: in	std_ulogic;
	n_cs		: in	std_ulogic;
	sdata		: out	std_ulogic_vector(g_parallel-1 downto 0)
);
end ad7476_parallel_sim;

architecture bhv of ad7476_parallel_sim is
begin
gen_adc_sim: for i in 0 to g_parallel-1 generate
	i_adc_sim_x: entity work.ad7476_sim
		port map
		(
			sdata	=> sdata(i),
			n_cs	=> n_cs,
			sclk	=> sclk
		);
end generate;
end architecture bhv;
