-----------------------------------------------------------------------------
-- file			: ad7476_if.vhd 
--
-- brief		: adc7476 interface
-- author(s)	: marc at pignat dot org
-- license		: The MIT License (MIT) (http://opensource.org/licenses/MIT)
--				  Copyright (c) 2015 Marc Pignat
--
-----------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity ad7476_if is
port
(
	clock	: in	std_ulogic;
	reset	: in	std_ulogic;
	
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
	signal cs			: std_ulogic;
	signal c_counter	: unsigned(2 downto 0);
	signal w_counter	: unsigned(4 downto 0);
begin

n_cs <= not cs;

bit_divider: process(reset, clock)
begin
	if reset = '1' then
		c_counter <= (others => '0');
	elsif rising_edge(clock) then
		c_counter <= c_counter + 1;
		if c_counter = 5 then
			c_counter <= (others => '0');
		end if;
	end if;
end process;
sclk <= c_counter(c_counter'left);

word_divider: process(reset, clock)
begin
	if reset = '1' then
		w_counter <= (others => '0');
	elsif rising_edge(clock) then
		if c_counter = 0 then
			w_counter <= w_counter + 1;
			if w_counter = 19 then
				w_counter <= (others => '0');
			end if;
		end if;
	end if;
end process;

cs_gen: process(w_counter)
begin
	cs <= '0';
	if w_counter < 15 then
		cs <= '1';
	end if;
end process;

end rtl;
