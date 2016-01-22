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
	generic
	(
		g_width_in		: positive := 3;
		g_width_out		: positive := 1
	);
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
	generic
	(
		g_width_in		: positive := 3;
		g_width_out		: positive := 1
	);
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

smaller: if out_data'left < in_data'left generate
	assert (in_data'left mod out_data'left) = 0 report "width_changer smaller : modulo size failed" severity failure;

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

bigger: if out_data'left > in_data'left generate
	assert (out_data'left mod in_data'left) = 0 report "width_changer bigger : modulo size failed" severity failure;
	i_smaller: entity work.width_changer_internal(rtl_bigger)
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
	signal memory	: std_ulogic_vector(in_data'range);
begin
end rtl_smaller;

architecture rtl_bigger of width_changer_internal is
	signal memory	: std_ulogic_vector(out_data'range);
begin
end rtl_bigger;