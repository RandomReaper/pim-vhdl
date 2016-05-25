-----------------------------------------------------------------------------
-- file			: managed_tb.vhd
--
-- brief		: managed_tb and top_tb
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

entity managed_tb is
	port
	(
		clock	: in		std_ulogic;
		reset	: in		std_ulogic;
		stop	: out		std_ulogic
	);
end managed_tb;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity tb is
begin
end tb;

architecture bhv_with_reset of tb is
	signal clock	: std_ulogic;
	signal reset	: std_ulogic := '0';
	signal stop		: std_ulogic;
begin

	i_managed_tb: entity work.managed_tb
	port map
	(
		reset	=> reset,
		clock	=> clock,
		stop	=> stop
	);

	i_clock : entity work.clock_stop
	generic map
	(
		frequency	=> 80.0e6
	)
	port map
	(
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
	signal clock	: std_ulogic;
	signal reset	: std_ulogic := '0';
	signal stop		: std_ulogic;
begin

	i_managed_tb: entity work.managed_tb
	port map
	(
		reset	=> reset,
		clock	=> clock,
		stop	=> stop
	);

	i_clock : entity work.clock_stop
	generic map
	(
		frequency	=> 80.0e6
	)
	port map
	(
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

