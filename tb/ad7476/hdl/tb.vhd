-----------------------------------------------------------------------------
-- file			: tb.vhd 
--
-- brief		: Test bench
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
-----------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
entity tb is
generic
(
	g_parallel	: natural := 3
);
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	signal stop				: std_ulogic;

	signal sclk				: std_ulogic;
	signal n_cs				: std_ulogic;
	signal sdata			: std_ulogic_vector(g_parallel-1 downto 0);

	signal data_valid		: std_ulogic;
	signal data				: std_ulogic_vector(g_parallel*12 - 1 downto 0);
	signal expected_data	: std_ulogic_vector(data'range);
begin

tb_process: process
	variable timeout : integer;
begin
	stop <= '0';

	expected_data <= (others => '0');
	for i in 0 to g_parallel - 1 loop
		expected_data(12*i) <= '1';
	end loop;

	wait until falling_edge(reset);

	for i in 0 to 100 loop
		timeout := 100;
		while data_valid /= '1' loop
			wait until falling_edge(clock);

			assert timeout > 0 report "Timeout waiting for data_valid" severity failure;

			timeout := timeout - 1;
		end loop;

		assert data = expected_data report "Wrong data" severity failure;
		wait until falling_edge(clock);
		assert data_valid = '0' report "Wrong data valid duration" severity failure;
	
		expected_data <= std_ulogic_vector(unsigned(expected_data) rol 1);

	end loop;

	stop <= '1';
	wait;

end process;

i_adc_if : entity work.ad7476_parallel_if
generic map
(
	g_prescaler	=> 1,
	g_parallel	=> g_parallel
)
port map
(
	reset		=> reset,
	clock		=> clock,
	
	sclk		=> sclk,
	n_cs		=> n_cs,
	sdata		=> sdata,
	
	data		=> data,
	data_valid	=> data_valid
);

i_adc_sim : entity work.ad7476_parallel_sim
generic map
(
	g_parallel	=> g_parallel
)
port map
(
	sclk		=> sclk,
	n_cs		=> n_cs,
	sdata		=> sdata
);

i_clock : entity work.clock_stop
generic map
(
	frequency	=> 80.0e6
)
port map
(
	clock		=> clock,
	stop	   	=> stop
);

i_reset : entity work.reset
port map
(
	reset		=> reset,
	clock		=> clock
);

end bhv;
