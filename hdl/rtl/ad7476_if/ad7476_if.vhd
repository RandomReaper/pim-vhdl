-----------------------------------------------------------------------------
-- file			: ad7476_if.vhd
--
-- brief		: adc7476 interface
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
--
-- limitations	: uses a 2^prescaler clock (prescaler >= 1)
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_if is
generic
(
	g_prescaler : natural := 1
);
port
(
	clock		: in	std_ulogic;
	reset		: in	std_ulogic;

	-- To the adc7476
	sclk		: out	std_ulogic;
	n_cs		: out	std_ulogic;
	sdata		: in	std_ulogic;

	-- To the internal logic

	data		: out	std_ulogic_vector(11 downto 0);
	data_valid	: out	std_ulogic
);
end ad7476_if;

architecture rtl of ad7476_if is
	signal cs				: std_ulogic		:= '0';
	signal c_counter		: unsigned((2**g_prescaler)-1 downto 0) := (others => '0');
	signal b_counter		: unsigned(4 downto 0) := (others => '1');

	signal sclk_int			: std_ulogic		:= '0';
	signal sclk_old			: std_ulogic;
	signal sample			: std_ulogic;
	signal data_valid_int	: std_ulogic		:= '0';
	signal data_int			: std_ulogic_vector(data'range) := (others => '0');
begin

-- Internal to external signal mapping
n_cs <= not cs;
sclk <= sclk_int;

clock_prescale: process(reset, clock)
begin
	if reset = '1' then
		c_counter <= (others => '0');
	elsif rising_edge(clock) then
		c_counter <= c_counter + 1;
	end if;
end process;

sclk_int <= c_counter(c_counter'left);

bit_counter: process(reset, clock)
begin
	if reset = '1' then
		b_counter <= (others => '1');
	elsif rising_edge(clock) then
		if c_counter = 0 then
			b_counter <= b_counter + 1;
			if b_counter >= 19 then
				b_counter <= (others => '0');
			end if;
		end if;
	end if;
end process;

sclk_rising: process(reset, clock)
begin
	if reset = '1' then
		sclk_old <= '0';
	elsif rising_edge(clock) then
		sclk_old <= sclk_int;
	end if;
end process;
sample <= sclk_int and not sclk_old;

data_valid <= data_valid_int;
data <= data_int;

sample_gen: process(reset, clock)
begin
	if reset = '1' then
		data_int		<= (others => '0');
		data_valid_int	<= '0';
	elsif rising_edge(clock) then
		data_valid_int <= '0';

		if sample = '1' then
			case to_integer(b_counter) is
				when 4+0 to 4+10 =>
					data_int(11-to_integer(b_counter-4)) <= sdata;
				when 4+11 =>
					data_int(11-to_integer(b_counter-4)) <= sdata;
					data_valid_int <= '1';
				when others =>
			end case;
		end if;
	end if;
end process;

cs <= '1' when (b_counter < 18) else '0';

end rtl;
