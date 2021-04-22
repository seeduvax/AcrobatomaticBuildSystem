library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TAndGate is 
end entity;

architecture AndGateBench of TAndGate is
	signal clk : std_logic;
	constant clkPeriod : time := 10 ns;
	signal a,b : std_logic;
begin
	pClock: process
	begin
		clk <= '0';
		wait for clkPeriod / 2;
		clk <= '1';
		wait for clkPeriod / 2;
	end process;

	pStimu: process
	begin
		a <= '0';
		b <= '0';
		wait for clkPeriod;
		a <= '1';
		wait for clkPeriod;
		b <= '1';
		wait for clkPeriod;
		a <= '0';
		wait for clkPeriod;	
	end process;

	gateInstance : entity work.AndGate
	port map (
		a0 => a,
		a1 => b
	);
end architecture;
