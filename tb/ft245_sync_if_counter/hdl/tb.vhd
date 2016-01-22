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
end tb;

architecture bhv of tb is
	signal reset			: std_ulogic;
	signal clock			: std_ulogic;
	signal adbus			: std_logic_vector(7 downto 0);
	signal txe_n			: std_ulogic;
	signal rxf_n			: std_ulogic;
	signal wr_n				: std_ulogic;
	signal rd_n				: std_ulogic;
	signal oe_n				: std_ulogic;
	signal siwu				: std_ulogic;
	signal suspend_n		: std_ulogic;
	signal reset_n			: std_ulogic;
	signal d_counter		: unsigned(7 downto 0);
	signal d_data_in		: std_ulogic_vector(7 downto 0);
	signal d_data_write		: std_ulogic;
	signal d_data_full		: std_ulogic;
	signal status_full		: std_ulogic;
	signal status_empty		: std_ulogic;
	signal read_data		: std_ulogic_vector(7 downto 0);
	signal write_data		: std_ulogic_vector(7 downto 0);
	signal write_read		: std_ulogic;
	signal read_valid		: std_ulogic;
begin

reset_n <= not reset;

i_ft_if : entity work.ft245_sync_if
port map
(
	adbus			=> adbus,
	rxf_n			=> rxf_n,
	txe_n			=> txe_n,
	rd_n			=> rd_n,
	wr_n			=> wr_n,
	clkout			=> clock,
	oe_n			=> oe_n,
	siwu			=> siwu,
	reset_n			=> '0',
	suspend_n		=> suspend_n,
	
	reset			=> reset,
	read_data		=> read_data,
	read_valid		=> read_valid,
	
	write_data		=> write_data,
	write_read		=> write_read,
	write_empty		=> status_empty
);

i_fifo : entity work.fifo
generic map
(
	g_depth_log2 => 4
)
port map
(
	clock		=> clock,
	reset		=> reset,

	-- input
	sync_reset	=> '0',
	write		=> read_valid,
	write_data	=> read_data,

	-- outputs
	read		=> write_read,
	read_data	=> write_data,

	--status
	status_full	=> status_full,
	status_empty	=> status_empty
	--status_write_error	: out std_ulogic;
	--status_read_error	: out std_ulogic;
	
	--free 				: out std_ulogic_vector(g_depth_log2 downto 0);
	--used 				: out std_ulogic_vector(g_depth_log2 downto 0)	

);

i_ft_sim : entity work.ft245_sync_sim
port map
(
	adbus		=> adbus,
	rxf_n		=> rxf_n,
	txe_n		=> txe_n,
	rd_n		=> rd_n,
	wr_n		=> wr_n,
	clkout		=> clock,
	oe_n		=> oe_n,
	siwu		=> siwu,
	reset_n		=> reset_n,
	suspend_n	=> suspend_n,
	
	d_data_in	=> d_data_in,
	d_data_write=> d_data_write,
	d_data_full	=> d_data_full
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

sim_pc: process(reset, clock)
begin
	if reset = '1' then
		d_data_in <= (others => '-');
		d_data_write <= '0';
		d_counter <= (others => '0');
	elsif rising_edge(clock) then
		d_data_in <= (others => '-');
		d_data_write <= '0';
		if d_data_full = '0' then
			d_counter <= d_counter + 1;
			if d_counter(d_counter'left downto d_counter'left-4) = 0 then
				d_data_write <= '1';
				d_data_in <= std_ulogic_vector(d_counter);			
			end if;
		end if;
	end if;
end process;

end bhv;
