library ieee;
	use ieee.std_logic_1164.all;

entity top_hw is
	port
	(
		-- Mimas
		clk				: in	std_ulogic;
		sw				: in	std_ulogic_vector(3 downto 0);
		led				: out	std_ulogic_vector(7 downto 0);
		
		-- FT2232h
		FT_CLKOUT		: in	std_ulogic;
		FT_DATA			: inout	std_logic_vector(7 downto 0);
		FT_nRESET		: out	std_ulogic;
		FT_nTXE			: in	std_ulogic;
		FT_nRXF			: in	std_ulogic;
		FT_nWR			: out	std_ulogic;
		FT_nRD			: out	std_ulogic;
		FT_SIWUA		: out	std_ulogic;
		FT_nOE			: out	std_ulogic;
		FT_nSUSPEND		: in	std_ulogic
	);
end top_hw;

architecture bhv of top_hw is
	alias clock			: std_ulogic is FT_CLKOUT;
	signal reset		: std_ulogic;
	
	signal write_data	: std_ulogic_vector(FT_DATA'range);
	signal write		: std_ulogic;
	signal write_full	: std_ulogic;
	signal read_data	: std_ulogic_vector(FT_DATA'range);
	signal read_valid	: std_ulogic;
begin

i_ft245_sync_if : entity work.ft245_sync_if
port map
(
	-- Interface to the ftdi chip
	adbus			=> FT_DATA,
	rxf_n			=> FT_nRXF,
	txe_n			=> FT_nTXE,
	rd_n			=> FT_nRD,
	wr_n			=> FT_nWR,
	clkout			=> FT_CLKOUT,
	oe_n			=> FT_nOE,
	siwu			=> FT_SIWUA,
	reset_n			=> FT_nRESET, 
	suspend_n		=> FT_nSUSPEND,
	
	-- Interface to the internal logic
	reset			=> reset,
	
	write_data		=> write_data,
	write			=> write,
	write_full		=> write_full,
	
	read_data		=> read_data,
	read_valid		=> read_valid
);

-- FIXME reset should be generated
reset <= '0';

i_top : entity work.top
port map
(
	clock			=> FT_CLKOUT,
	reset			=> reset,
	data			=> write_data,
	write_full		=> write_full,
	write			=> write
);

led_out: process(reset, clock)
begin
	if reset = '1' then
		led <= (others => '0');
	elsif rising_edge(clock) then
		if read_valid = '1' then
			led <= read_data;
		end if;
	end if;
end process;

end bhv;

