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
			audio				: out std_logic;
			HEX0				: out std_logic_vector(7 downto 0);
			HEX1				: out std_logic_vector(7 downto 0);
			HEX2				: out std_logic_vector(7 downto 0);
			HEX3				: out std_logic_vector(7 downto 0);
			HEX4				: out std_logic_vector(7 downto 0);
			HEX5				: out std_logic_vector(7 downto 0)

			
		);
end entity game_logic;

architecture behaviour of game_logic is

-- instantiate any components



-- signals


signal xPix			: integer range 0 to 799; 
signal yPix			: integer range 0 to 525;

signal ballx		: integer range 0 to 639 := 319;
signal bally		: integer range 0 to 479 := 239;

signal ballspeed	: integer := 1;
signal balldirns	: integer range -1 to 1 := 1; -- +1 down, -1 up 0 no vertical movement
signal balldirew	: integer range -1 to 1 := 1; -- +1 right, -1 left 0 no horizontal movement

signal ballsize	: integer range 1 to 20 := 4;


begin
	-- testing output to VGA display 
	-- two red diagonal lines on a white background
	xpix <= to_integer(unsigned(xpos)); -- changing position to numeric for ease
	ypix <= to_integer(unsigned(ypos)); -- of calculations
	
	process(xpix, ypix, blank_n)
		begin
			VGA_R <= "0000";-- set default to black
			VGA_G <= "0000";
			VGA_B <= "0000";
		
		if blank_n = '1' then -- inside display area
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
			if (ballx > xpix) and (ballx < (xpix + ballsize)) and (bally >ypix) and (bally < (ypix + ballsize)) then
				vga_r <= "0000";
				vga_g <= "0000";
				vga_b <= "1111";
			end if;
		end if;
	end process;
	-- movement process
	
	process(reset, VS, xpix, ypix)
		begin
			if reset = '0' then
				ballx <= 319;
				bally <= 239;
			elsif rising_edge(VS) then
				ballx <= ballx + ballspeed * balldirew;
				bally <= bally + ballspeed * balldirns;

				if bally >= 479  then
					balldirns <= -1;
					bally <= 478;
				elsif bally <= 10 then
					balldirns <= 1;
					bally <= 11;
				end if;
				if ballx >= 639  then
					balldirew <= -1;
					ballx <= 638;
				elsif ballx <= 10 then
					balldirew <= 1;
					ballx <= 11;
				end if;
			end if;	
	end process;
end behaviour;