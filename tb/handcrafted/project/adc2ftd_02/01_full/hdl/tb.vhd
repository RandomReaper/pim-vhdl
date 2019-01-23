-----------------------------------------------------------------------------
-- file			: tb.vhd
--
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

architecture bhv of managed_tbc is
	constant bug_severity	: severity_level := failure;
	constant g_parallel		: natural := 4;
	constant g_nrdata_log2	: natural := 5;

	signal adbus			: std_logic_vector(7 downto 0);
	signal reset_n			: std_ulogic;
	signal txe_n			: std_ulogic;
	signal rxf_n			: std_ulogic;
	signal wr_n				: std_ulogic;
	signal rd_n				: std_ulogic;
	signal siwu				: std_ulogic;
	signal oe_n				: std_ulogic;
	signal suspend_n		: std_ulogic;

	-- ADCs
	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);

	signal d_data_out		: std_ulogic_vector(7 downto 0);
	signal d_data_out_valid : std_ulogic;
	signal out_data			: std_ulogic_vector(7 downto 0);
	signal out_valid		: std_ulogic;
	signal adc_data			: std_ulogic_vector(g_parallel*16-1 downto 0);
	signal adc_data_valid	: std_ulogic;

	signal tmp				: std_ulogic_vector(11 downto 0);
	signal expected_data	: std_ulogic_vector(g_parallel*16-1 downto 0);
begin

frequency <= 60.0e6;

tb_proc: process
	variable timeout : integer;
	begin
	stop <= '0';

	tmp <= (0 => '1', others => '0');
	wait for 0 ns;

	for i in 0 to 1000 loop

		for i in g_parallel - 1 downto 0 loop
			expected_data(16*i+3 downto 16*i+0) <= std_ulogic_vector(to_unsigned(i + 1, 4));
			expected_data(16*i+15 downto 16*i+4) <= tmp;
		end loop;

		timeout := 1000;
		while adc_data_valid /= '1' loop
			wait until falling_edge(clock);

			assert timeout > 0 report "Timeout waiting for adc_data_valid" severity bug_severity;

			timeout := timeout - 1;
		end loop;

		while adc_data_valid = '1' loop

			assert adc_data = expected_data report "Wrong data out_data:" &integer'image(to_integer(unsigned(adc_data))) &" expected : " &integer'image(to_integer(unsigned(expected_data))) severity bug_severity;
			tmp <= std_ulogic_vector(rotate_left(unsigned(tmp), 1));
			wait until falling_edge(clock);
		end loop;

	end loop;

	stop <= '1';

	wait;

end process;

i_top: entity work.top
generic map
(
	g_parallel		=> g_parallel,
	g_nrdata_log2	=> g_nrdata_log2
)
port map
(
	-- Mimas
	led				=> open,

	-- FT2232h
	clkout			=> clock,
	adbus			=> adbus,
	reset_n			=> reset_n,
	txe_n			=> txe_n,
	rxf_n			=> rxf_n,
	wr_n			=> wr_n,
	rd_n			=> rd_n,
	siwu			=> siwu,
	oe_n			=> oe_n,
	suspend_n		=> suspend_n,

	-- ADCs
	sclk			=> sclk,
	n_cs			=> n_cs,
	sdata			=> sdata,

	reset			=> reset
);

i_ft245_sim: entity work.ft245_sync_sim
port map
(
	adbus			=> adbus,
	rxf_n			=> rxf_n,
	txe_n			=> txe_n,
	rd_n			=> rd_n,
	wr_n			=> wr_n,
	clock			=> clock,
	oe_n			=> oe_n,
	siwu			=> siwu,
	reset_n			=> reset_n,
	suspend_n		=> suspend_n,

	d_data_out		=> d_data_out,
	d_data_out_valid=> d_data_out_valid,
	d_data_in		=> x"00",
	d_data_write	=> '0',
	d_data_full		=> open
);

i_ad7476_parallel_sim: entity work.ad7476_parallel_sim
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	reset			=> reset,
	sclk			=> sclk,
	n_cs			=> n_cs,
	sdata			=> sdata
);

i_depacketizer : entity work.depacketizer
generic map
(
	g_nrdata_log2		=> g_nrdata_log2
)
port map
(
	clock			=> clock,
	reset			=> reset,

	in_data			=> d_data_out,
	in_valid		=> d_data_out_valid,

	out_data		=> out_data,
	out_valid		=> out_valid
);

i_wc: entity work.width_changer
port map
(
	clock		=> clock,
	reset		=> reset,

	in_data		=> out_data,
	in_write	=> out_valid,

	out_ready	=> '1',
	out_data	=> adc_data,
	out_write	=> adc_data_valid
);

end bhv;
