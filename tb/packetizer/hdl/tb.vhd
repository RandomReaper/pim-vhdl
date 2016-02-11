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
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	
	signal counter			: unsigned(7 downto 0);
	signal counter_rx		: unsigned(7 downto 0);
	
	signal read				: std_ulogic;
	signal empty			: std_ulogic;
	
	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write			: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal full				: std_ulogic;
	
	signal read_valid		: std_ulogic;
	signal d_in				: std_ulogic_vector(7 downto 0);
	signal d_out			: std_ulogic_vector(7 downto 0);
begin

i_packetizer : entity work.packetizer
generic map
(
	g_nrdata_log2		=> 3,
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
read <= counter_rx(3) and not empty;

process(reset, clock)
begin
	if reset = '1' then
		counter_rx <= (others => '0');
	elsif rising_edge(clock) then
		counter_rx <= counter_rx + 1;
	end if;
end process;

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

i_clock : entity work.clock
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock	=> clock
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

end bhv;
