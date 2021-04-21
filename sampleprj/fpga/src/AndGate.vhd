library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AndGate is port(
	a0 : in std_logic;
	a1 : in std_logic;
	o : out std_logic);
end AndGate;

architecture AndGateArch of AndGate is
begin
	o <= '1' when ( a0='1' and a1='1' ) else '0';
end AndGateArch;
