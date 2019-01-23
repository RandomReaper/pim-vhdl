-----------------------------------------------------------------------------
-- file			: tb.vhd
--
-- brief		: Test bench for ft245_sync_if test data tx ok.
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

entity tb is
end tb;

architecture bhv of tb is
	constant bug_severity : severity_level := failure;

	signal reset			: std_ulogic;
	signal clock			: std_ulogic;

	signal adbus			: std_logic_vector(7 downto 0) := (others => 'Z');
	signal rxf_n			: std_ulogic;
	signal txe_n			: std_ulogic;
	signal rd_n				: std_ulogic;
	signal wr_n				: std_ulogic;
	signal oe_n				: std_ulogic;

	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write_empty		: std_ulogic;
	signal write_read		: std_ulogic;

	signal read_data		: std_ulogic_vector(7 downto 0);
	signal read_valid		: std_ulogic;
	signal read_full		: std_ulogic;

	signal rxf				: std_ulogic;
	signal txe				: std_ulogic;
	signal rd				: std_ulogic;
	signal wr				: std_ulogic;
	signal oe				: std_ulogic;

	signal stop				: std_ulogic := '0';
	signal adbus_wr			: std_logic_vector(7 downto 0);

	signal fifo_reset		: std_logic;
	signal fifo_data		: std_ulogic_vector(write_data'range);
	signal fifo_full		: std_logic;
	signal fifo_write		: std_logic;
begin

i_dut : entity work.ft245_sync_if
port map
(
	-- Interface to the ftdi chip
	adbus			=> adbus,
	rxf_n			=> rxf_n,
	txe_n			=> txe_n,
	rd_n			=> rd_n,
	wr_n			=> wr_n,
	clock			=> clock,
	oe_n			=> oe_n,
	siwu			=> open,
	reset_n			=> open,
	suspend_n		=> '0',

	-- Interface to the internal logic
	reset			=> reset,

	in_data			=> write_data,
	in_read			=> write_read,
	in_empty		=> write_empty,


	out_data		=> read_data,
	out_valid		=> read_valid,
	out_full		=> read_full
);

adbus <= adbus_wr when oe = '1' else (others => 'Z');
rxf_n <= not rxf;
txe_n <= not txe;
rd	<= not rd_n;
wr	<= not wr_n;
oe	<= not oe_n;

i_clock: entity work.clock_stop
port map
(
	frequency	=> 1.0e6,
	clock		=> clock,
	stop		=> stop
);

i_fifo : entity work.fifo
generic map
(
	g_depth_log2	=> 4
)
port map
(
	reset			=> reset,
	clock			=> clock,

	reset_sync		=> fifo_reset,

	write_data		=> fifo_data,
	write			=> fifo_write,
	status_empty	=> write_empty,

	read_data		=> write_data,
	read			=> write_read,
	status_full		=> fifo_full
);

bus_safety: process(adbus)
begin
	for i in adbus'range loop
		--assert (adbus(i) /= 'X')	report "adbus MUST never be X" severity bug_severity;
	end loop;
end process;

tbp: process
	procedure waitFor
	(
		signal clock	: in std_ulogic;
		signal sig		: in std_ulogic;
		val	: in std_ulogic;
		t : in integer;
		m : string
	) is
		variable timeout : integer := t;
	begin

	while sig /= val loop
		wait until falling_edge(clock);

		assert timeout > 0 report "Timeout while waiting for: '" & m & "' = '" & std_ulogic'image(val)& "'" severity bug_severity;

		timeout := timeout - 1;
	end loop;

	end procedure;
begin

-----------------------------------------------------------------------------
-- Full nice reset
-----------------------------------------------------------------------------
reset			<= '1';
txe				<= '0';
rxf				<= '0';
adbus_wr		<= (others => 'Z');
fifo_data		<= (others => '0');
fifo_write		<= '0';
read_full		<= '0';

wait until falling_edge(clock);

reset			<= '0';

wait until falling_edge(clock);

-----------------------------------------------------------------------------
-- Verify all outputs after reset
-----------------------------------------------------------------------------
assert (rd						= '0')			report "ouch !?!" severity bug_severity;
assert (wr						= '0')			report "ouch !?!" severity bug_severity;
assert (oe						= '0')			report "ouch !?!" severity bug_severity;

-----------------------------------------------------------------------------
-- Host sends one byte, slave has much space
-----------------------------------------------------------------------------
read_full		<= '0';
adbus_wr			<= (others => 'Z');
rxf	<= '1';
adbus_wr	<= x"aa";

waitFor(clock, oe, '1', 10, "oe");
assert (rd						= '0')			report "oe MUST be set at least one clock before read" severity bug_severity;

waitFor(clock, rd, '1', 10, "rd");
wait until falling_edge(clock);
adbus_wr	<= x"cc";
rxf	<= '0';

waitFor(clock, read_valid, '1', 10, "read_valid");
assert (read_data					= x"aa")		report "read_data => wrong data (0xaa)" severity bug_severity;
wait until falling_edge(clock);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity bug_severity;

waitFor(clock, rd, '0', 10, "rd");

-----------------------------------------------------------------------------
-- Host sends two bytes, slave has much space
-----------------------------------------------------------------------------
read_full		<= '0';
adbus_wr			<= (others => 'Z');
rxf	<= '1';

waitFor(clock, oe, '1', 10, "oe");
assert (rd						= '0')			report "oe MUST be set at least one clock before read" severity bug_severity;

assert (adbus					= (adbus'left downto adbus'right => 'Z'))	report "adbus MUST be Hi-Z (1)" severity bug_severity;
adbus_wr	<= x"55";
wait on adbus;
assert (adbus					= x"55")		report "adbus MUST be Hi-Z (2)" severity bug_severity;


waitFor(clock, rd, '1', 10, "rd");
wait until falling_edge(clock);
adbus_wr	<= x"66";
wait on adbus;
assert (adbus					= x"66")		report "read_data => wrong data" severity bug_severity;

waitFor(clock, read_valid, '1', 10, "read_valid");
assert (read_data					= x"55")		report "read_data => wrong data (0x55)" severity bug_severity;
wait until falling_edge(clock);
assert (read_data					= x"66")		report "read_data => wrong data (0x66)" severity bug_severity;
rxf	<= '0';
adbus_wr	<= x"cc";

wait until falling_edge(clock);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity bug_severity;

waitFor(clock, rd, '0', 10, "rd");

-----------------------------------------------------------------------------
-- Host sends two bytes, slave has one space
-----------------------------------------------------------------------------
read_full		<= '0';
adbus_wr			<= (others => 'Z');
rxf	<= '1';

waitFor(clock, oe, '1', 10, "oe");
assert (rd						= '0')			report "oe MUST be set at least one clock before read" severity bug_severity;

assert (adbus					= (adbus'left downto adbus'right => 'Z'))	report "adbus MUST be Hi-Z (1)" severity bug_severity;
adbus_wr	<= x"b1";
wait on adbus;
assert (adbus					= x"b1")		report "adbus MUST be Hi-Z (2)" severity bug_severity;


waitFor(clock, rd, '1', 10, "rd");
wait until falling_edge(clock);
adbus_wr	<= x"b2";
wait on adbus;
assert (adbus					= x"b2")		report "adbus MUST be Hi-Z (3)" severity bug_severity;

waitFor(clock, read_valid, '1', 10, "read_valid");
assert (read_data					= x"b1")		report "read_data => wrong data (0xb1)" severity bug_severity;
wait until rising_edge(clock);
read_full		<= '1';
wait until falling_edge(clock);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity bug_severity;
read_full		<= '0';
waitFor(clock, read_valid, '1', 10, "read_valid");
assert (read_data					= x"b2")		report "read_data => wrong data (0xb2)" severity note;
rxf	<= '0';
adbus_wr	<= x"cc";

wait until falling_edge(clock);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity bug_severity;

waitFor(clock, rd, '0', 10, "rd");

-----------------------------------------------------------------------------
-- Send one byte to host, host as much space
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"aa";
txe <= '1';
wait until falling_edge(clock);
fifo_write <= '0';

waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"aa")		report "adbus => wrong data" severity bug_severity;
wait until falling_edge(clock);
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
wait until falling_edge(clock);
wait until falling_edge(clock);

txe <= '0';

-----------------------------------------------------------------------------
-- Send one byte to host, host as only one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"bb";
txe <= '1';
wait until falling_edge(clock);
fifo_write <= '0';

waitFor(clock, wr, '1', 10, "wr");
assert (adbus				= x"bb")		report "adbus => wrong data" severity bug_severity;
wait until falling_edge(clock);
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
txe <= '0';

-----------------------------------------------------------------------------
-- Send two bytes to host, host as much space
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"cc";
txe <= '1';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"dd";
wait until falling_edge(clock);
fifo_write <= '0';

waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"cc")	report "adbus => wrong data (0xcc)" severity bug_severity;
wait until falling_edge(clock);
assert (adbus					= x"dd")	report "adbus => wrong data (0xdd)" severity bug_severity;
assert (wr						= '1')		report "wr => wrong duration" severity bug_severity;
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
wait until falling_edge(clock);
txe <= '0';

-----------------------------------------------------------------------------
-- Send two bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"ee";
txe <= '1';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"ff";
wait until falling_edge(clock);
fifo_write <= '0';

waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"ee")	report "adbus => wrong data (0xee)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"ff")	report "adbus => wrong data (0xff)" severity bug_severity;
wait until falling_edge(clock);
wait until falling_edge(clock);
txe <= '0';

-----------------------------------------------------------------------------
-- Send 3 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"01";
wait until falling_edge(clock);
fifo_data <= x"02";
wait until falling_edge(clock);
fifo_data <= x"03";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"01")	report "adbus => wrong data (0x01)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"02")	report "adbus => wrong data (0x02)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"03")	report "adbus => wrong data (0x03)" severity bug_severity;
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
txe <= '0';


-----------------------------------------------------------------------------
-- Send 4 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"11";
wait until falling_edge(clock);
fifo_data <= x"12";
wait until falling_edge(clock);
fifo_data <= x"13";
wait until falling_edge(clock);
fifo_data <= x"14";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"11")	report "adbus => wrong data (0x11)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"12")	report "adbus => wrong data (0x12)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"13")	report "adbus => wrong data (0x13)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"14")	report "adbus => wrong data (0x14)" severity bug_severity;
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
txe <= '0';

-----------------------------------------------------------------------------
-- Send 5 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"21";
wait until falling_edge(clock);
fifo_data <= x"22";
wait until falling_edge(clock);
fifo_data <= x"23";
wait until falling_edge(clock);
fifo_data <= x"24";
wait until falling_edge(clock);
fifo_data <= x"25";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"21")	report "adbus => wrong data (0x21)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"22")	report "adbus => wrong data (0x22)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"23")	report "adbus => wrong data (0x23)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"24")	report "adbus => wrong data (0x24)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"25")	report "adbus => wrong data (0x23)" severity bug_severity;
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
txe <= '0';

-----------------------------------------------------------------------------
-- Send 10 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"71";
wait until falling_edge(clock);
fifo_data <= x"72";
wait until falling_edge(clock);
fifo_data <= x"73";
wait until falling_edge(clock);
fifo_data <= x"74";
wait until falling_edge(clock);
fifo_data <= x"75";
wait until falling_edge(clock);
fifo_data <= x"76";
wait until falling_edge(clock);
fifo_data <= x"77";
wait until falling_edge(clock);
fifo_data <= x"78";
wait until falling_edge(clock);
fifo_data <= x"79";
wait until falling_edge(clock);
fifo_data <= x"7a";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"71")	report "adbus => wrong data (0x71)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"72")	report "adbus => wrong data (0x72)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"73")	report "adbus => wrong data (0x73)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"74")	report "adbus => wrong data (0x74)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"75")	report "adbus => wrong data (0x75)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"76")	report "adbus => wrong data (0x76)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"77")	report "adbus => wrong data (0x77)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"78")	report "adbus => wrong data (0x78)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"79")	report "adbus => wrong data (0x79)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"7a")	report "adbus => wrong data (0x7a)" severity bug_severity;
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;
txe <= '0';

-----------------------------------------------------------------------------
-- Send 3 bytes to host, host two space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"31";
wait until falling_edge(clock);
fifo_data <= x"32";
wait until falling_edge(clock);
fifo_data <= x"33";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"31")	report "adbus => wrong data (0x31)" severity bug_severity;
wait until falling_edge(clock);
assert (adbus					= x"32")	report "adbus => wrong data (0x32)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"33")	report "adbus => wrong data (0x33)" severity bug_severity;
wait until falling_edge(clock);
txe <= '0';
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;

-----------------------------------------------------------------------------
-- Send 4 bytes to host, host 3 space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until falling_edge(clock);
fifo_reset <= '0';
wait until falling_edge(clock);
fifo_write <= '1';
fifo_data <= x"41";
wait until falling_edge(clock);
fifo_data <= x"42";
wait until falling_edge(clock);
fifo_data <= x"43";
wait until falling_edge(clock);
fifo_data <= x"44";
wait until falling_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"41")	report "adbus => wrong data (0x41)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"42")	report "adbus => wrong data (0x42)" severity bug_severity;
wait until falling_edge(clock);
waitFor(clock, wr, '1', 10, "wr");
assert (adbus					= x"43")	report "adbus => wrong data (0x43)" severity bug_severity;

wait until falling_edge(clock);
txe <= '0';
waitFor(clock, wr, '0', 10, "wr");
txe <= '1';
waitFor(clock, wr, '1', 10, "wr");

assert (adbus					= x"44")	report "adbus => wrong data (0x34)" severity bug_severity;
wait until falling_edge(clock);
txe <= '0';
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity bug_severity;

-----------------------------------------------------------------------------
-- End of test
-----------------------------------------------------------------------------

wait until falling_edge(clock);
wait until falling_edge(clock);
wait until falling_edge(clock);
wait until falling_edge(clock);
wait until falling_edge(clock);
wait until falling_edge(clock);
wait until falling_edge(clock);

stop			<= '1';

wait;

end process;

end bhv;
