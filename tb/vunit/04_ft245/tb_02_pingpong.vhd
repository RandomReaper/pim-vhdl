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

architecture bhv of managed_tbc is
	constant bug_severity : severity_level := failure;

	signal adbus			: std_logic_vector(7 downto 0);
	signal txe_n			: std_ulogic;
	signal rxf_n			: std_ulogic;
	signal wr_n				: std_ulogic;
	signal rd_n				: std_ulogic;
	signal oe_n				: std_ulogic;
	signal siwu				: std_ulogic;
	signal suspend_n		: std_ulogic;
	signal reset_n			: std_ulogic;
	signal d_counter		: unsigned(7 downto 0) := (others => '0');
	signal d_data_in		: std_ulogic_vector(7 downto 0) := (others => '-');
	signal d_data_write		: std_ulogic := '0';
	signal d_data_full		: std_ulogic;
	signal status_full		: std_ulogic;
	signal in_empty			: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal in_data			: std_ulogic_vector(7 downto 0);
	signal in_read			: std_ulogic;
	signal read_valid		: std_ulogic;
	signal expected_data	: std_ulogic_vector(7 downto 0);
	signal d_data_out		: std_ulogic_vector(7 downto 0);
	signal d_data_out_valid	: std_ulogic;
begin

frequency <= 60.0e6;

tb_proc: process
	variable timeout : integer;
begin
	stop <= '0';

	expected_data <= (others => '0');

	for i in 0 to 15 loop
		timeout := 100;
		while d_data_out_valid /= '1' loop
			wait until falling_edge(clock);

			assert timeout > 0 report "Timeout waiting for data_valid" severity bug_severity;

			timeout := timeout - 1;
		end loop;

		assert d_data_out = expected_data report "Wrong data (is " & integer'image(to_integer(unsigned(d_data_out))) & " ) exptected : " & integer'image(to_integer(unsigned(expected_data))) severity bug_severity;
		expected_data <= std_ulogic_vector(unsigned(expected_data) + 1);
		wait until falling_edge(clock);

	end loop;

	assert d_data_out_valid = '0' report "Wrong data valid duration" severity bug_severity;

	stop <= '1';

	wait;
end process;

reset_n <= not reset;
i_ft_if : entity work.ft245_sync_if
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
	suspend_n		=> suspend_n,

	reset			=> reset,

	out_data		=> read_data,
	out_valid		=> read_valid,
	out_full		=> status_full,

	in_data			=> in_data,
	in_read			=> in_read,
	in_empty		=> in_empty
);

i_fifo : entity work.fifo
generic map
(
	g_depth_log2 => 3
)
port map
(
	clock		=> clock,
	reset		=> reset,

	-- input
	reset_sync	=> '0',
	write		=> read_valid,
	write_data	=> read_data,

	-- outputs
	read		=> in_read,
	read_data	=> in_data,

	--status
	status_full	=> status_full,
	status_empty=> in_empty
	--status_write_error	: out std_ulogic;
	--status_read_error	: out std_ulogic;

	--free 				: out std_ulogic_vector(g_depth_log2 downto 0);
	--used 				: out std_ulogic_vector(g_depth_log2 downto 0)

);

i_ft_sim : entity work.ft245_sync_sim
generic map
(
	g_to_host_depth_log2 => 3
)
port map
(
	adbus		=> adbus,
	rxf_n		=> rxf_n,
	txe_n		=> txe_n,
	rd_n		=> rd_n,
	wr_n		=> wr_n,
	clock		=> clock,
	oe_n		=> oe_n,
	siwu		=> siwu,
	reset_n		=> reset_n,
	suspend_n	=> suspend_n,

	d_data_in	=> d_data_in,
	d_data_write=> d_data_write,
	d_data_full	=> d_data_full,

	d_data_out	=> d_data_out,
	d_data_out_valid => d_data_out_valid
);

sim_pc: process(reset, clock)
begin
	if reset = '1' then
		d_data_in <= (others => '-');
		d_data_write <= '0';
		d_counter <= (others => '0');
	elsif rising_edge(clock) then
		d_data_in <= (others => '-');
		d_data_write <= '0';
		if d_data_full = '0' then
			d_counter <= d_counter + 1;
			if d_counter(d_counter'left downto d_counter'left-3) = 0 then
				d_data_write <= '1';
				d_data_in <= std_ulogic_vector(d_counter);
			end if;
		end if;
	end if;
end process;

end architecture;
