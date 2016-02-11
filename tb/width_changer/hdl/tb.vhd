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
end tb;

architecture bhv of tb is
	constant clock_frequency: real := 100.0e6;
	--constant clock_period	: time := 1.0 * sec/clock_frequency;

	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	signal stop				: std_ulogic;

	signal data4			: std_ulogic_vector(3 downto 0);
	signal data4_valid		: std_ulogic;
	signal data16			: std_ulogic_vector(15 downto 0);
	signal data16_valid		: std_ulogic;
	signal data8			: std_ulogic_vector(7 downto 0);
	signal data8_valid		: std_ulogic;
	signal data24			: std_ulogic_vector(23 downto 0);
	signal data24_fifo		: std_ulogic_vector(23 downto 0);
	signal data24_valid		: std_ulogic;
	signal data4_bis		: std_ulogic_vector(3 downto 0);
	signal data4_bis_valid	: std_ulogic;
	signal data4_bis_ready	: std_ulogic;
	signal fifo24_read		: std_ulogic;
	signal fifo24_empty		: std_ulogic;
	signal fifo24_read_old	: std_ulogic;
	signal counter			: unsigned(data4'range);
	signal delay			: unsigned(data4'range);
begin

data4 <= std_ulogic_vector(counter);

process
begin
	stop <= '0';
	data4_valid <= '0';
	wait until falling_edge(reset);

	wait until rising_edge(clock);

	counter <= (others => '0');
	data4_valid <= '1';

	delay <= (others => '0');
	while data4_bis_valid /= '1' loop

		wait until rising_edge(clock);

		counter <= counter + 1;

		delay <= delay + 1;

		assert delay < 10 report "timeout waiting for data4_bis_valid" severity failure;

	end loop;

	assert unsigned(data4_bis) = 0 report "wrong data" severity failure;

	for i in 0 to 100 loop
		counter <= counter + 1;

		wait until rising_edge(clock);

		assert counter = unsigned(data4_bis)+delay-1 report "wrong_data" severity failure;

	end loop;

	stop <= '1';

	wait;

end process;

i_dut0: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,

	in_data			=> data4,
	in_data_valid	=> data4_valid,
	in_data_ready	=> open,
	out_data		=> data16,
	out_data_valid	=> data16_valid
);

i_dut1: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,

	in_data			=> data16,
	in_data_valid	=> data16_valid,
	in_data_ready	=> open,
	out_data		=> data8,
	out_data_valid	=> data8_valid
);

i_dut2: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,

	in_data			=> data8,
	in_data_valid	=> data8_valid,
	in_data_ready	=> open,
	out_data		=> data24,
	out_data_valid	=> data24_valid
);

i_fifo_2_3: entity work.fifo
generic map
(
	g_depth_log2 => 1
)
port map
(
	reset				=> reset,
	clock				=> clock,

	-- input
	sync_reset			=> '0',
	write				=> data24_valid,
	write_data			=> data24,

	-- outputs
	read				=> fifo24_read,
	read_data			=> data24_fifo,

	--status
	status_full			=> open,
	status_empty		=> fifo24_empty,
	status_write_error	=> open,
	status_read_error	=> open,

	free 				=> open,
	used 				=> open
);

fifo24_read <= not fifo24_empty and data4_bis_ready;

process(reset, clock)
begin
	if reset = '1' then
		fifo24_read_old <= '0';
	elsif rising_edge(clock) then
		fifo24_read_old <= fifo24_read;
	end if;
end process;

i_dut3: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,

	in_data			=> data24_fifo,
	in_data_valid	=> fifo24_read_old,
	in_data_ready	=> data4_bis_ready,
	out_data		=> data4_bis,
	out_data_valid	=> data4_bis_valid
);

i_clock : entity work.clock_stop
generic map
(
	frequency	=> clock_frequency
)
port map
(
	clock	=> clock,
	stop	=> stop
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

end bhv;
