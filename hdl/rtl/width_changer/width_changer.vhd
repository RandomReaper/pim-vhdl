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
		clock			: in	std_logic;
		reset			: in	std_logic;
		
		in_data			: in	std_logic_vector(g_width_in-1 downto 0);
		in_data_ready	: out	std_logic;
		out_data		: out	std_logic_vector(g_width_out-1 downto 0);
		out_data_valid	: out	std_logic
	);
end width_changer;

architecture bhv of width_changer is
	signal memory : std_logic_vector(MAX(g_width_out, g_width_in)-1 downto 0);


begin

assert (((g_width_in mod g_width_out) /= 0) and ((g_width_out mod g_width_in) /= 0)) report "oula" severity FAILURE;

end bhv;

