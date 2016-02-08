-----------------------------------------------------------------------------
-- file			: width_changer.vhd 
--
-- brief		: Minimal fifo for translating std_ulogic_vector widths
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-- limitations	: Only implemented for "N downto 0" ranges (with N > 0)
--
-- remarks		: MSB first !
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity width_changer_internal is
	port
	(
		clock			: in	std_ulogic;
		reset			: in	std_ulogic;
		
		in_data			: in	std_ulogic_vector;
		in_data_valid	: in	std_ulogic;
		in_data_ready	: out	std_ulogic;
		
		out_data		: out	std_ulogic_vector;
		out_data_valid	: out	std_ulogic
	);
end width_changer_internal;

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
		out_data_valid	: out	std_ulogic
	);
end width_changer;

architecture rtl of width_changer is

begin
	assert
		    (in_data'right = 0)
		and (out_data'right = 0)
		and (in_data'left > 0)
		and (out_data'left > 0)
	report "Unsupported feature, feel free to improve this code" severity failure;

smaller: if out_data'length < in_data'length generate
	assert (in_data'length mod out_data'length) = 0 report "width_changer smaller : modulo size failed" severity failure;

	i_smaller: entity work.width_changer_internal(rtl_smaller)
	port map
	(
		clock			=> clock,
		reset			=> reset,
		
		in_data			=> in_data,
		in_data_valid	=> in_data_valid,
		in_data_ready	=> in_data_ready,
		out_data		=> out_data,
		out_data_valid	=> out_data_valid
	);
end generate;

bigger: if out_data'length > in_data'length generate
	assert (out_data'length mod in_data'length) = 0 report "width_changer bigger : modulo size failed" severity failure;
	i_bigger: entity work.width_changer_internal(rtl_bigger)
	port map
	(
		clock			=> clock,
		reset			=> reset,
		
		in_data			=> in_data,
		in_data_valid	=> in_data_valid,
		in_data_ready	=> in_data_ready,
		out_data		=> out_data,
		out_data_valid	=> out_data_valid
	);
end generate;

same: if out_data'left = in_data'left generate
	in_data_ready	<= '1';
	out_data		<= in_data;
	out_data_valid	<= in_data_valid;
end generate;

end rtl;

architecture rtl_smaller of width_changer_internal is
	signal memory		: std_ulogic_vector((in_data'length - out_data'length) -1 downto 0);
	signal state		: std_ulogic_vector((in_data'length/out_data'length) - 2 downto 0);
begin

state_proc: process(reset, clock)
begin
	if reset = '1' then
		state <= (others => '0');
		memory <= (others => '0');
	elsif rising_edge(clock) then
		state <= std_ulogic_vector(unsigned(state) srl 1);
		if in_data_valid = '1' then
			state <= (state'left => '1', others => '0');
			memory <= in_data(memory'range);
			
			assert unsigned(state) = 0 report "in_data_valid while not empty" severity warning;

		end if;
	end if;
end process;

process(state, in_data, in_data_valid, memory)
begin
	out_data_valid <= in_data_valid;
	out_data <= in_data(in_data'left downto in_data'left - out_data'left);
	in_data_ready <= not in_data_valid;
	
	for i in state'range loop
		if state(i) = '1' then
			out_data_valid <= '1';
			in_data_ready <= '0';
			out_data <= memory(((i+1)*out_data'length) - 1 downto (i+0)*out_data'length);
		end if;
	end loop;

	if state(0) = '1' then
		in_data_ready <= '1';
	end if;

end process;

end rtl_smaller;

architecture rtl_bigger of width_changer_internal is
	signal memory		: std_ulogic_vector(out_data'left downto in_data'left + 1);
	signal state		: std_ulogic_vector((out_data'length/in_data'length) - 1  downto 0);
	signal state_changed: std_ulogic;
begin

in_data_ready <= '1';

state_proc: process(reset, clock)
begin
	if reset = '1' then
		state <= (state'left => '1', others => '0');
		state_changed <= '0';
	elsif rising_edge(clock) then
		state_changed <= '0';
		if in_data_valid = '1' then
			state <= std_ulogic_vector(unsigned(state) ror 1);
			state_changed <= '1';
		end if;
	end if;
end process;

data_proc: process(reset, clock)
begin
	if reset = '1' then
		memory(out_data'left downto in_data'left+1) <= (others => '-');
	elsif rising_edge(clock) then
		if in_data_valid = '1' then
			for i in state'left downto 1 loop
				if state(i) = '1' then
					memory(((i+1)*in_data'length) - 1 downto (i+0)*in_data'length) <= in_data;
				end if;
			end loop;
		end if;
	end if;
end process;

out_data(in_data'range) <= in_data;
out_data(out_data'left downto in_data'left + 1) <= memory;
out_data_valid <= in_data_valid when state(0) = '1' and in_data_valid = '1' else '0';

end rtl_bigger;