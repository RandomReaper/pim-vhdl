-----------------------------------------------------------------------------
-- file			: ad7476_sim.vhd
--
-- brief		: ad7476 (for simulation)
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
-------------------------------------------------------------------------------
-- Expected output : 2^0, 2^1 ... 2^11, 2^0, ...
--
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_sim is
port
(
	reset		: in	std_ulogic;
	sclk		: in	std_ulogic;
	n_cs		: in	std_ulogic;
	sdata		: out	std_ulogic
);
end ad7476_sim;

architecture bhv of ad7476_sim is
	alias clock is sclk;
	signal data		: unsigned(11 downto 0) := (11 => '1', others => '0');
	signal cs		: std_ulogic := '0';
	signal cs_old	: std_ulogic := '0';
	signal counter	: unsigned(4 downto 0) := (others => '0');
begin

cs <= not(n_cs);

gen_data: process(reset, clock)
begin
	if reset = '1' then
		data <= (data'left => '1', others => '0');
	elsif falling_edge(clock) then
		if cs = '1' and cs_old = '0' then
			data <= rotate_left(data, 1);
		end if;
	end if;
end process;

data_out: process(reset, clock)
begin
	if reset = '1' then
		counter <= (others => '0');
		cs_old <= '0';
		sdata <= '0';
	elsif falling_edge(clock) then
		counter <= counter + 1;
		if counter = 19 then
			counter <= counter;
		end if;

		cs_old <= cs;
		if cs = '1' and cs_old = '0' then
			counter <= (others => '0');
		end if;

		case to_integer(counter) is
			when 2+0 to 2+11 =>
				sdata <= data(11-to_integer(counter-2));

			when others =>
				sdata <= '0';
		end case;

	end if;
end process;

end architecture bhv;
