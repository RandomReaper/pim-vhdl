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
	constant g_nrdata_log2	: natural := 3;

	signal counter			: unsigned(7 downto 0);

	signal read				: std_ulogic;
	signal empty			: std_ulogic;

	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write			: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal full				: std_ulogic;

	signal read_valid		: std_ulogic;
	signal d_in				: std_ulogic_vector(7 downto 0);
	signal d_out			: std_ulogic_vector(7 downto 0);

	signal out_data			: std_ulogic_vector(7 downto 0);
	signal out_valid		: std_ulogic;

	signal expected_data	: std_ulogic_vector(7 downto 0);

	signal rx				: std_ulogic;
begin

rx_proc: process
	variable timeout : integer;
begin

	stop <= '0';

	for i in 0 to 20 loop
		for j in 0 to 20 loop
			rx <= '0';
			timeout := i;
			while timeout > 0 loop
				timeout := timeout -1;
				wait until falling_edge(clock);
			end loop;

			rx <= '1';
			timeout := j;
			while timeout > 0 loop
				timeout := timeout -1;
				wait until falling_edge(clock);
			end loop;

			wait until falling_edge(clock);
		end loop;
	end loop;

	stop <= '1';

	wait;

end process;

tb_proc: process
variable timeout : integer;
begin
	expected_data <= (others => '0');

	wait until falling_edge(reset);

	while true loop

		timeout := 10000;
		while out_valid /= '1' loop
			wait until falling_edge(clock);

			assert timeout > 0 report "Timeout waiting for data_valid" severity bug_severity;

			timeout := timeout - 1;
		end loop;

		while out_valid = '1' loop

			assert out_data = expected_data report "Wrong data out_data:" &integer'image(to_integer(unsigned(out_data))) &" expected : " &integer'image(to_integer(unsigned(expected_data))) severity bug_severity;
			expected_data <= std_ulogic_vector(unsigned(expected_data) + 1);
			wait until falling_edge(clock);
		end loop;

	end loop;

	assert out_valid = '0' report "Wrong data valid duration" severity bug_severity;

	wait;
end process;


i_dut : entity work.packetizer
generic map
(
	g_nrdata_log2		=> g_nrdata_log2,
	g_depth_in_log2		=> 3,
	g_depth_out_log2	=> 1
)
port map
(
	reset	=> reset,
	clock	=> clock,

	write_data		=> write_data,
	write			=> write,
	status_empty	=> empty,

	read_data		=> read_data,
	read			=> read,
	status_full		=> full
);

i_depacketizer : entity work.depacketizer
generic map
(
	g_nrdata_log2		=> g_nrdata_log2
)
port map
(
	clock		=> clock,
	reset		=> reset,

	in_data		=> read_data,
	in_valid	=> read_valid,

	out_data	=> out_data,
	out_valid	=> out_valid
);

-- Fill with consecutive numbers
write_data <= std_ulogic_vector(counter);
write <= not full;
process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
	elsif rising_edge(clock) then
		if full = '0' then
			counter <= counter + 1;
		end if;
	end if;
end process;

-- Read
read <= rx and not empty;

-- Highlight data in/out when valid for debugging
d_out <= read_data when read_valid = '1' else (others => '-');
d_in <= write_data when write = '1' and reset = '0' else (others => '-');

process(reset, clock)
begin
	if reset = '1' then
		read_valid <= '0';
	elsif rising_edge(clock) then
		read_valid <= read;
	end if;
end process;

end bhv;
