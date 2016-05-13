-----------------------------------------------------------------------------
-- file			: width_changer.vhd
--
-- brief		: Minimal fifo for translating std_ulogic_vector widths
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
-- limitations	: Only implemented for "N downto 0" ranges (with N >= 0)
--
-- remarks		: MSB first !
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity wc_int is
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;

		in_data			: in	std_ulogic_vector;
		in_data_valid	: in	std_ulogic;
		in_data_ready	: out	std_ulogic;

		out_data		: out	std_ulogic_vector;
		out_data_valid	: out	std_ulogic;
		out_data_ready	: in	std_ulogic
	);
end wc_int;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity width_changer is
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;

		in_data			: in	std_ulogic_vector;
		in_data_valid	: in	std_ulogic;
		in_data_ready	: out	std_ulogic;

		out_data		: out	std_ulogic_vector;
		out_data_valid	: out	std_ulogic;
		out_data_ready	: in	std_ulogic
	);
end width_changer;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity wc_gen is
	generic
	(
		g_in_width		: positive;
		g_out_width		: positive
	);
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;

		in_data			: in	std_ulogic_vector;
		in_data_valid	: in	std_ulogic;
		in_data_ready	: out	std_ulogic;

		out_data		: out	std_ulogic_vector;
		out_data_valid	: out	std_ulogic;
		out_data_ready	: in	std_ulogic
	);
end wc_gen;

architecture rtl of wc_gen is
begin
	assert
		    (in_data'right = 0)
		and (out_data'right = 0)
		and (in_data'left >= 0)
		and (out_data'left >= 0)
	report "Unsupported feature, feel free to improve this code" severity failure;

smaller: if g_out_width < g_in_width generate
	assert (in_data'length mod out_data'length) = 0 report "width_changer smaller : modulo size failed" severity failure;

	i_smaller: entity work.wc_int(rtl_smaller)
	port map
	(
		clock			=> clock,
		reset			=> reset,

		in_data			=> in_data,
		in_data_valid	=> in_data_valid,
		in_data_ready	=> in_data_ready,

		out_data		=> out_data,
		out_data_valid	=> out_data_valid,
		out_data_ready	=> out_data_ready
	);
end generate;

bigger: if g_out_width > g_in_width generate
	assert (out_data'length mod in_data'length) = 0 report "width_changer bigger : modulo size failed" severity failure;
	i_bigger: entity work.wc_int(rtl_bigger)
	port map
	(
		clock			=> clock,
		reset			=> reset,

		in_data			=> in_data,
		in_data_valid	=> in_data_valid,
		in_data_ready	=> in_data_ready,

		out_data		=> out_data,
		out_data_valid	=> out_data_valid,
		out_data_ready	=> out_data_ready
	);
end generate;

same: if g_out_width = g_in_width generate
	in_data_ready	<= out_data_ready;
	out_data		<= in_data;
	out_data_valid	<= in_data_valid;
end generate;

end rtl;

architecture rtl of width_changer is
begin
	i_changer: entity work.wc_gen
	generic map
	(
		g_in_width		=> in_data'length,
		g_out_width		=> out_data'length
	)
	port map
	(
		clock			=> clock,
		reset			=> reset,

		in_data			=> in_data,
		in_data_valid	=> in_data_valid,
		in_data_ready	=> in_data_ready,

		out_data		=> out_data,
		out_data_valid	=> out_data_valid,
		out_data_ready	=> out_data_ready
	);
end rtl;

architecture rtl_smaller of wc_int is
	signal memory				: std_ulogic_vector(in_data'range);
	signal state				: std_ulogic_vector((in_data'length/out_data'length) - 1 downto 0);
	signal out_data_valid_int	: std_ulogic;
begin

state_proc: process(reset, clock)
begin
	if reset = '1' then
		state <= (others => '0');
		memory <= (others => '0');
	elsif rising_edge(clock) then
		if out_data_ready = '1' then
			state <= std_ulogic_vector(unsigned(state) srl 1);
		end if;

		--pragma synthesis_off
		if out_data_valid_int = '1' and (unsigned(state) = 0 or unsigned(state) = 1) then
			memory	<= (others => 'U');
		end if;
		--pragma synthesis_on

		if in_data_valid = '1' then
			state(state'range) <= (others => '0');
			state(state'left) <= '1';
			memory <= in_data;

			assert unsigned(state) = 0 or unsigned(state) = 1 report "in_data_valid while not empty" severity warning;
		end if;

	end if;
end process;

out_data_valid <= out_data_valid_int;
process(state, memory, out_data_ready)
begin
	out_data_valid_int	<= '0';
	in_data_ready 	<= '1';
	out_data		<= memory((1*out_data'length) - 1 downto 0);
	--pragma synthesis_off
	out_data(out_data'range)	<= (others => 'U');
	--pragma synthesis_on
	for i in state'range loop
		if state(i) = '1' then
			in_data_ready 	<= '0';
			out_data_valid_int	<= out_data_ready;
			out_data			<= memory(((i+1)*out_data'length) - 1 downto (i+0)*out_data'length);
		end if;
	end loop;

	if state(state'right) = '1' then
		in_data_ready		<= out_data_ready;
	end if;
end process;

end rtl_smaller;

architecture rtl_bigger of wc_int is
	signal memory				: std_ulogic_vector(out_data'range);
	signal state				: std_ulogic_vector((out_data'length/in_data'length) downto 0);
	signal out_data_valid_int	: std_ulogic;
begin

out_data_valid <= out_data_valid_int;
state_proc: process(reset, clock)
begin
	if reset = '1' then
		state <= (others => '0');
		state(state'left) <= '1';
		out_data_valid_int	<= '0';
	elsif rising_edge(clock) then
		out_data_valid_int	<= '0';

		if in_data_valid = '1' then
			state <= std_ulogic_vector(unsigned(state) srl 1);
		end if;

		if (state(state'right + 1) = '1' and in_data_valid = '1') or state(state'right) = '1' then
			if out_data_ready = '1' then
				out_data_valid_int	<= '1';
				state <= (others => '0');
				state(state'left) <= '1';
			end if;
		end if;
	end if;
end process;

data_ready_proc: process(state, in_data_valid, out_data_ready)
begin
	in_data_ready	<= '1';

	if state(state'right) = '1' or state(state'right + 1) = '1'then
		in_data_ready	<= out_data_ready;
	end if;

end process;

data_proc: process(reset, clock)
begin
	if reset = '1' then
		memory<= (others => '-');
	elsif rising_edge(clock) then

		--pragma synthesis_off
		if out_data_valid_int = '1' then
			memory <= (others => '-');
		end if;
		--pragma synthesis_on

		if in_data_valid = '1' then
			for i in state'left downto 1 loop
				if state(i) = '1' then
					memory(((i-0)*in_data'length) - 1 downto (i-1)*in_data'length) <= in_data;
				end if;
			end loop;
		end if;
	end if;
end process;

out_data <= memory;

end rtl_bigger;