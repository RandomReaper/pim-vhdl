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
	signal out_data_full	: std_ulogic;
	signal out_counter		: unsigned(7 downto 0);
	signal out_value		: unsigned(7 downto 0);
	signal in_counter		: unsigned(8 downto 0);
	signal in_value			: unsigned(7 downto 0);
	signal write			: std_ulogic;
	signal d_write			: std_ulogic;
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
	read_data		=> open,
	read_valid		=> open,
	
	write_data		=> std_ulogic_vector(out_value),
	write			=> write,
	write_full		=> out_data_full
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
	
	d_data_in	=> std_ulogic_vector(in_value),
	d_data_write=> d_write
);

i_reset : entity work.reset
port map
(
	reset	=> reset,
	clock	=> clock
);

counter_out_gen: process(reset, clock)
begin
	if reset = '1' then
		out_counter <= (others => '0');
		out_value	<= (others => '-');
		write <= '0';
		
	elsif rising_edge(clock) then
		write <= '0';
		out_value	<= (others => '-');
		if out_data_full = '0' then
			out_counter <= out_counter + 1;
			write <= '1';
			out_value <= out_counter;
		end if;
	end if;
end process;

counter_in_gen: process(reset, clock)
begin
	if reset = '1' then
		in_counter <= (others => '1');
		in_value	<= (others => '-');
		d_write <= '0';
		
	elsif rising_edge(clock) then
		d_write <= '0';
		in_value	<= (others => '-');
		in_counter <= in_counter + 1;
		if in_counter(4) = '1' then
			d_write <= '1';
			in_value <= in_counter(in_value'range);
		end if;
	end if;
end process;

end bhv;