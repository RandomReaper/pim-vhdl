-----------------------------------------------------------------------------
-- file			: tb.vhd 
--
-- brief		: Test bench for ft245_sync_if test data tx ok.
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
	signal reset 			: std_ulogic;
	signal clock 			: std_ulogic;

	signal adbus			: std_logic_vector(7 downto 0) := (others => 'Z');
	signal rxf_n			: std_ulogic;
	signal txe_n			: std_ulogic;
	signal rd_n				: std_ulogic;
	signal wr_n				: std_ulogic;
	signal clkout			: std_ulogic;
	signal oe_n				: std_ulogic;
	
	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write_empty		: std_ulogic;
	signal write_read		: std_ulogic;
	
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal read_valid		: std_ulogic;
	
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

	write_data		=> write_data,
	write_empty		=> write_empty,
	write_read		=> write_read,

	read_data		=> read_data,
	read_valid		=> read_valid
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
	clock	=> clkout,
	stop	=> stop
);

clock <= not clkout;

i_fifo : entity work.fifo
generic map
(
	g_depth_log2	=> 4
)
port map
(
	reset			=> reset,
	clock			=> clock,
	
	sync_reset		=> fifo_reset,
	
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
		assert (adbus(i) /= 'X')	report "adbus MUST never be X" severity failure;
	end loop;
end process;

tbp: process
	procedure waitFor
	(
		signal clock  : in std_ulogic;
		signal sig	  : in std_ulogic;
		val	: in std_ulogic;
		t : in integer;
		m : string
	) is
		variable timeout : integer := t;
	begin
	
	while sig /= val loop
		wait until rising_edge(clock);
		
		assert timeout > 0 report "Timeout while waiting for: '" & m & "' = '" & std_ulogic'image(val)& "'" severity failure;
		
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

wait until rising_edge(clock);

reset			<= '0';
-----------------------------------------------------------------------------
-- Verify all outputs after reset
-----------------------------------------------------------------------------
assert (rd						= '0')			report "ouch !?!" severity failure;
assert (wr						= '0')			report "ouch !?!" severity failure;
assert (oe						= '0')			report "ouch !?!" severity failure;

-----------------------------------------------------------------------------
-- Host sends one byte
-----------------------------------------------------------------------------
adbus_wr			<= (others => 'Z');
rxf	<= '1';

waitFor(clkout, oe, '1', 10, "oe");

assert (adbus					= (adbus'left downto adbus'right => 'Z'))	report "adbus MUST be Hi-Z (1)" severity failure;
adbus_wr	<= x"aa"; wait for 1 ns;
assert (rd						= '0')			report "oe MUST be set at least one clock before read" severity failure;
assert (adbus					= x"aa")		report "adbus MUST be Hi-Z (2)" severity failure;

waitFor(clkout, rd, '1', 10, "rd");
adbus_wr	<= x"cc";
rxf	<= '0';

waitFor(clkout, read_valid, '1', 10, "read_valid");
assert (read_data					= x"aa")		report "read_data => wrong data" severity failure;

wait until rising_edge(clkout);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity failure;

waitFor(clkout, rd, '0', 10, "rd");

-----------------------------------------------------------------------------
-- Host sends two bytes
-----------------------------------------------------------------------------
adbus_wr			<= (others => 'Z');
rxf	<= '1';

waitFor(clkout, oe, '1', 10, "oe");

assert (adbus					= (adbus'left downto adbus'right => 'Z'))	report "adbus MUST be Hi-Z (1)" severity failure;
adbus_wr	<= x"55"; wait for 0.1 ns;
assert (rd						= '0')			report "oe MUST be set at least one clock before read" severity failure;
assert (adbus					= x"55")		report "adbus MUST be Hi-Z (2)" severity failure;

waitFor(clkout, rd, '1', 10, "rd");
--wait until rising_edge(clkout);
adbus_wr	<= x"66"; wait for 0.1 ns;
assert (adbus					= x"66")		report "read_data => wrong data" severity failure;

waitFor(clkout, read_valid, '1', 10, "read_valid");
assert (read_data					= x"55")		report "read_data => wrong data (0x55)" severity failure;
wait until rising_edge(clkout);
assert (read_data					= x"66")		report "read_data => wrong data (0x66)" severity failure;
rxf	<= '0';
adbus_wr	<= x"cc";

wait until rising_edge(clkout);
assert (read_valid					= '0')			report "read_valid => wrong duration" severity failure;

waitFor(clkout, rd, '0', 10, "rd");

-----------------------------------------------------------------------------
-- Send one byte to host, host as much space
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"aa";
txe <= '1';
wait until rising_edge(clock);
fifo_write <= '0';

waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"aa")		report "adbus => wrong data" severity failure;
wait until rising_edge(clock);
wait until falling_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity failure;
txe <= '0';

-----------------------------------------------------------------------------
-- Send one byte to host, host as only one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"bb";
txe <= '1';
wait until rising_edge(clock);
fifo_write <= '0';

waitFor(clkout, wr, '1', 10, "wr");
assert (adbus				= x"bb")		report "adbus => wrong data" severity failure;
wait until rising_edge(clock);
txe <= '0';
wait until rising_edge(clock);
assert (wr					= '0')			report "wr => wrong duration" severity failure;

-----------------------------------------------------------------------------
-- Send two bytes to host, host as much space
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"cc";
txe <= '1';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"dd";
wait until rising_edge(clock);
fifo_write <= '0';

waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"cc")	report "adbus => wrong data (0xcc)" severity failure;
wait until rising_edge(clkout);
assert (adbus					= x"dd")	report "adbus => wrong data (0xdd)" severity failure;
assert (wr						= '1')		report "wr => wrong duration" severity failure;
wait until rising_edge(clkout);
assert (wr					= '0')			report "wr => wrong duration" severity failure;
txe <= '0';

-----------------------------------------------------------------------------
-- Send two bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"ee";
txe <= '1';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"ff";
wait until rising_edge(clock);
fifo_write <= '0';

waitFor(clkout, wr, '1', 10, "wr");
txe <= '0';
assert (adbus					= x"ee")	report "adbus => wrong data (0xee)" severity failure;
waitFor(clkout, wr, '0', 10, "wr");
txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
txe <= '0';
assert (adbus					= x"ff")	report "adbus => wrong data (0xff)" severity failure;

-----------------------------------------------------------------------------
-- Send 3 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"01";
wait until rising_edge(clock);
fifo_data <= x"02";
wait until rising_edge(clock);
fifo_data <= x"03";
wait until rising_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
txe <= '0';
assert (adbus					= x"01")	report "adbus => wrong data (0x01)" severity failure;
waitFor(clkout, wr, '0', 10, "wr");
txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"02")	report "adbus => wrong data (0x02)" severity failure;
wait until rising_edge(clkout);
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"03")	report "adbus => wrong data (0x03)" severity failure;
wait until rising_edge(clkout);
assert (wr					= '0')			report "wr => wrong duration" severity failure;
txe <= '0';
-----------------------------------------------------------------------------
-- Send 4 bytes to host, host one space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"11";
wait until rising_edge(clock);
fifo_data <= x"12";
wait until rising_edge(clock);
fifo_data <= x"13";
wait until rising_edge(clock);
fifo_data <= x"14";
wait until rising_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
txe <= '0';
assert (adbus					= x"11")	report "adbus => wrong data (0x11)" severity failure;
waitFor(clkout, wr, '0', 10, "wr");
txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"12")	report "adbus => wrong data (0x12)" severity failure;
wait until rising_edge(clkout);
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"13")	report "adbus => wrong data (0x13)" severity failure;
wait until rising_edge(clkout);
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"14")	report "adbus => wrong data (0x14)" severity failure;
wait until rising_edge(clkout);
assert (wr					= '0')			report "wr => wrong duration" severity failure;
txe <= '0';

-----------------------------------------------------------------------------
-- Send 3 bytes to host, host two space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"21";
wait until rising_edge(clock);
fifo_data <= x"22";
wait until rising_edge(clock);
fifo_data <= x"23";
wait until rising_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"21")	report "adbus => wrong data (0x21)" severity failure;
txe <= '0';
waitFor(clkout, wr, '0', 10, "wr");
txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"22")	report "adbus => wrong data (0x22)" severity failure;
wait until rising_edge(clkout);
assert (adbus					= x"23")	report "adbus => wrong data (0x23)" severity failure;
txe <= '0';
wait until rising_edge(clkout);
assert (wr					= '0')			report "wr => wrong duration" severity failure;

-----------------------------------------------------------------------------
-- Send 4 bytes to host, host 3 space left
-----------------------------------------------------------------------------
fifo_reset <= '1';
wait until rising_edge(clock);
fifo_reset <= '0';
wait until rising_edge(clock);
fifo_write <= '1';
fifo_data <= x"31";
wait until rising_edge(clock);
fifo_data <= x"32";
wait until rising_edge(clock);
fifo_data <= x"33";
wait until rising_edge(clock);
fifo_data <= x"34";
wait until rising_edge(clock);
fifo_write <= '0';

txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"31")	report "adbus => wrong data (0x21)" severity failure;
wait until rising_edge(clkout);
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"32")	report "adbus => wrong data (0x21)" severity failure;
wait until rising_edge(clkout);
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"33")	report "adbus => wrong data (0x21)" severity failure;

txe <= '0';
waitFor(clkout, wr, '0', 10, "wr");
wait until rising_edge(clkout);
txe <= '1';
waitFor(clkout, wr, '1', 10, "wr");
assert (adbus					= x"34")	report "adbus => wrong data (0x22)" severity failure;
wait until rising_edge(clkout);
txe <= '0';
wait until rising_edge(clkout);
assert (wr					= '0')			report "wr => wrong duration" severity failure;

-----------------------------------------------------------------------------
-- End of test
-----------------------------------------------------------------------------

wait until rising_edge(clock);
wait until rising_edge(clock);
wait until rising_edge(clock);
wait until rising_edge(clock);
wait until rising_edge(clock);
wait until rising_edge(clock);
wait until rising_edge(clock);

stop			<= '1';

wait;

end process;

end bhv;
