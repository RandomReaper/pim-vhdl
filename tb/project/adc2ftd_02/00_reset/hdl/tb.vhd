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
	constant bug_severity : severity_level := failure;

	signal reset 			: std_ulogic;
	signal clock 			: std_ulogic;

	signal adbus			: std_logic_vector(7 downto 0) := (others => 'Z');
	signal rxf_n			: std_ulogic;
	signal txe_n			: std_ulogic;
	signal rd_n				: std_ulogic;
	signal wr_n				: std_ulogic;
	signal oe_n				: std_ulogic;

	signal rxf				: std_ulogic;
	signal txe				: std_ulogic;
	signal rd				: std_ulogic;
	signal wr				: std_ulogic;
	signal oe				: std_ulogic;

	signal siwu				: std_ulogic;
	signal reset_n			: std_ulogic;

	signal stop				: std_ulogic := '0';
	signal adbus_wr			: std_logic_vector(7 downto 0);

	signal led				: std_ulogic_vector(7 downto 0);
	signal n_cs				: std_ulogic;
	signal sclk				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);
begin

	adbus <= adbus_wr when oe = '1' else (others => 'Z');
	rxf_n <= not rxf;
	txe_n <= not txe;
	rd	<= not rd_n;
	wr	<= not wr_n;
	oe	<= not oe_n;

	tb : process
	begin

	-----------------------------------------------------------------------------
	-- No reset
	-----------------------------------------------------------------------------
	stop		<= '0';
	reset		<= '0';
	rxf			<= '0';
	txe			<= '0';
	adbus_wr	<= (others => 'Z');

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	assert (rd						= '0')			report "rd should be '0' and is " & std_ulogic'image(rd) severity bug_severity;
	assert (wr						= '0')			report "wr should be '0' and is " & std_ulogic'image(wr) severity bug_severity;
	assert (oe						= '0')			report "oe should be '0' and is " & std_ulogic'image(oe) severity bug_severity;
	assert (siwu					= '1')			report "siwu should be '1' and is " & std_ulogic'image(siwu) severity bug_severity;
	assert (reset_n					= '1')			report "reset_n should be '1' and is " & std_ulogic'image(reset_n) severity bug_severity;
	assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity bug_severity;
	assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity bug_severity;

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

	assert (rd						= '0')			report "rd should be '0' and is " & std_ulogic'image(rd) severity bug_severity;
	assert (wr						= '0')			report "wr should be '0' and is " & std_ulogic'image(wr) severity bug_severity;
	assert (oe						= '0')			report "oe should be '0' and is " & std_ulogic'image(oe) severity bug_severity;
	assert (siwu					= '1')			report "siwu should be '1' and is " & std_ulogic'image(siwu) severity bug_severity;
	assert (reset_n					= '1')			report "reset_n should be '1' and is " & std_ulogic'image(reset_n) severity bug_severity;
	assert (sclk					= '0')			report "sclk should be '0' and is " & std_ulogic'image(sclk) severity bug_severity;
	assert (n_cs					= '0')			report "n_cs should be '0' and is " & std_ulogic'image(n_cs) severity bug_severity;

	wait until rising_edge(clock);
	wait until falling_edge(clock);

	-----------------------------------------------------------------------------
	-- End of test
	-----------------------------------------------------------------------------

	stop <= '1';

	wait;

	end process;

i_dut : entity work.top
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	-- Interface to the ftdi chip
	adbus			=> adbus,
	rxf_n			=> rxf_n,
	txe_n			=> txe_n,
	rd_n			=> rd_n,
	wr_n			=> wr_n,
	clkout			=> clock,
	oe_n			=> oe_n,
	siwu			=> siwu,
	reset_n			=> reset_n,
	suspend_n		=> '0',

	led				=> led,

	reset			=> reset,
	-- ADCs
	sclk			=> sclk,
	n_cs			=> n_cs,
	sdata			=> sdata
);


i_clock : entity work.clock_stop
generic map
(
	frequency	=> 60.0e6
)
port map
(
	clock		=> clock,
	stop		=> stop
);

end bhv;
