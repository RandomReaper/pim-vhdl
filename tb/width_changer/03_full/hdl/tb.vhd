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
	signal data4_ready		: std_ulogic;
	signal data16			: std_ulogic_vector(15 downto 0);
	signal data16_valid		: std_ulogic;
	signal data16_ready		: std_ulogic;
	signal data8			: std_ulogic_vector(7 downto 0);
	signal data8_valid		: std_ulogic;
	signal data8_ready		: std_ulogic;
	signal data24			: std_ulogic_vector(23 downto 0);
	signal data24_valid		: std_ulogic;
	signal data24_ready		: std_ulogic;
	signal data4_bis		: std_ulogic_vector(3 downto 0);
	signal data4_bis_valid	: std_ulogic;
	signal data4_bis_ready	: std_ulogic;
	signal counter			: unsigned(data4'range);
	signal counter_bis		: unsigned(data4'range);
	signal timeout			: integer;

begin

-- Generate a counter on the input
data4 <= std_ulogic_vector(counter);
process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '1');
		data4_valid <= '0';
	elsif rising_edge(clock) then
		data4_valid <= '0';
		if data4_ready = '1' then
			counter <= counter + 1;
			data4_valid <= '1';
		end if;
	end if;
end process;

process
begin
	stop <= '0';

	wait until falling_edge(reset);
	wait until rising_edge(clock);

	counter_bis <= (others => '0');

	for i in 0 to 100 loop
		timeout <= 10;
		while data4_bis_valid /= '1' loop

			wait until rising_edge(clock);

			timeout <= timeout - 1;

			assert timeout > 0 report "timeout waiting for data4_bis_valid" severity failure;

		end loop;

		assert unsigned(data4_bis) = counter_bis report "wrong data" severity failure;

		wait until rising_edge(clock);
		counter_bis <= counter_bis + 1;

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
	in_data_ready	=> data4_ready,

	out_data_ready	=> data16_ready,
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
	in_data_ready	=> data16_ready,

	out_data_ready	=> data8_ready,
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
	in_data_ready	=> data8_ready,

	out_data_ready	=> data24_ready,
	out_data		=> data24,
	out_data_valid	=> data24_valid
);

i_dut3: entity work.width_changer
port map
(
	reset			=> reset,
	clock			=> clock,

	in_data			=> data24,
	in_data_valid	=> data24_valid,
	in_data_ready	=> data24_ready,

	out_data_ready	=> '1',
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
