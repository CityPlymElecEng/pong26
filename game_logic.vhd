-- Game logic and other operations for the CITY2077 assignment 2
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game_logic is
	port(
			pixel_clk		: in std_logic;
			reset				: in std_logic;
			VGA_R				: out std_logic_vector(3 downto 0);
			VGA_G				: out std_logic_vector(3 downto 0);
			VGA_B				: out std_logic_vector(3 downto 0);
			VS					: in std_logic;
			blank_n			: in std_logic;
			xpos				: in STD_LOGIC_VECTOR(10 downto 0);
			ypos				: in STD_LOGIC_VECTOR(9 downto 0);
			audio				: out std_logic
		);
end entity game_logic;

architecture behaviour of game_logic is

-- instantiate any components



-- signals


signal xPix			: integer range 0 to 799; 
signal yPix			: integer range 0 to 525; 


begin
	-- testing output to VGA display 
	-- two red diagonal lines on a white background
	xpix <= to_integer(unsigned(xpos)); -- changing position to numeric for ease
	ypix <= to_integer(unsigned(ypos)); -- of calculations
	
	process(xpix, ypix, blank_n)
		begin
		if blank_n = '1' then
			if (xpix = ypix) or (xpix - 160 = ypix) then
				VGA_R <= "1111";
				VGA_G <= "0000";
				VGA_B <= "0000";
			elsif (xpix >= 0 ) and (xpix < 640) and (ypix >= 0) and (ypix < 480) then
				VGA_R <= "1111";
				VGA_G <= "1111";
				VGA_B <= "1111";
			else 
				VGA_R <= "0000";
				VGA_G <= "0000";
				VGA_B <= "0000";
			end if;
		end if;
		end process;
	-- end of VGA testing
end behaviour;