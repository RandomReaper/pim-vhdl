-----------------------------------------------------------------------------
-- file			: managed_tbc.vhd
--
-- brief		: managed_tbc a managed test bench controller
-- author(s)	: marc at pignat dot org
--
-- This entity runs a tb, with clock and optional asynchronous reset.
-- The reset feature is selected by the architecture (bhv_with_reset,
-- or bhv_with_reset).
--
-- The bhv_with_reset is a realistic test for some RAM based FPGA, like
-- Xilinx, where the RAM and flip-flops are initialized by the bitstream, but
-- there is no global network for routing an asynchronous reset.
--
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

entity managed_tbc is
	port
	(
		clock		: in	std_ulogic;
		reset		: in	std_ulogic;
		stop		: out	std_ulogic;
		frequency	: out	real := 1.0e6
	);
end managed_tbc;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity tb is
begin
end tb;

architecture bhv_with_reset of tb is
	signal clock		: std_ulogic;
	signal reset		: std_ulogic := '0';
	signal stop			: std_ulogic;
	signal frequency	: real := 1.0e6;
begin

	i_managed_tbc: entity work.managed_tbc
	port map
	(
		reset	=> reset,
		clock	=> clock,
		stop	=> stop
	);

	i_clock : entity work.clock_stop
	port map
	(
		frequency	=> frequency,
		clock		=> clock,
		stop		=> stop
	);

	i_reset : entity work.reset
	port map
	(
		reset		=> reset,
		clock		=> clock
	);

end architecture bhv_with_reset;

architecture bhv_without_reset of tb is
	signal clock		: std_ulogic;
	signal reset		: std_ulogic := '0';
	signal stop			: std_ulogic;
	signal frequency	: real := 1.0e6;
begin

	i_managed_tbc: entity work.managed_tbc
	port map
	(
		frequency	=> frequency,
		reset		=> reset,
		clock		=> clock,
		stop		=> stop
	);

	i_clock : entity work.clock_stop
	port map
	(
		frequency	=> frequency,
		clock		=> clock,
		stop		=> stop
	);

	i_reset : entity work.reset
	port map
	(
		reset		=> open,
		clock		=> clock
	);

end architecture bhv_without_reset;

