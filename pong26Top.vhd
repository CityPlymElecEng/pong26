-- City2077 vga game top level 2026
--
-- this will be the top level of the design and is responsible for interconnecting
-- all the sub modules within the design and interface to signals in the outside
-- world
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong26Top is
	port(
			MAX10_CLK1_50  : in  std_logic;
			KEY				: in  std_logic_vector(1 downto 0);
			SW					: in  std_logic_vector(9 downto 0);
			LEDR				: out std_logic_vector(9 downto 0);
			HEX0				: out std_logic_vector(7 downto 0);
			HEX1				: out std_logic_vector(7 downto 0);
			HEX2				: out std_logic_vector(7 downto 0);
			HEX3				: out std_logic_vector(7 downto 0);
			HEX4				: out std_logic_vector(7 downto 0);
			HEX5				: out std_logic_vector(7 downto 0);
			VGA_R				: out std_logic_vector(3 downto 0);
			VGA_G				: out std_logic_vector(3 downto 0);
			VGA_B				: out std_logic_vector(3 downto 0);
			VGA_HS			: out std_logic;
			VGA_VS			: out std_logic;
			ARDUINO_IO		: inout std_logic_vector(15 downto 0)
		);
end entity pong26top;

architecture behaviour of pong26top is

-- components of the design

	component video_sync_generator 
		Port
		( 
				vga_clk : in  STD_LOGIC;
				reset   : in  STD_LOGIC;
				HS      : out STD_LOGIC;
				VS      : out STD_LOGIC;
				blank_n : out STD_LOGIC;
				xPos    : out STD_LOGIC_VECTOR(10 downto 0);
				yPos    : out STD_LOGIC_VECTOR(9 downto 0)
		);
	end component;
	
	component pll25 is
		port (
				ref_clk_clk        : in  std_logic := 'X'; -- clk
				ref_reset_reset    : in  std_logic := 'X'; -- reset
				vga_clk_clk        : out std_logic;        -- clk
				reset_source_reset : out std_logic         -- reset
		);
	end component pll25;
	
	component game_logic is
		port (
		
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
	end component game_logic;
			


-- signals

signal vga_clk 	: std_logic;
signal reset    	: std_logic;
signal resetn		: std_logic; 
signal reset_out	: std_logic; -- add
signal HSync	   : std_logic;
signal VSync		: std_logic;
signal blanking	: std_logic;
signal xPos 		: STD_LOGIC_VECTOR(10 downto 0);
signal yPos 		: STD_LOGIC_VECTOR(9 downto 0);

begin


-- instantiate components

	video : video_sync_generator port map (
	
			vga_clk  => vga_clk,
			reset	   => resetn,
			HS			=> HSync,
			VS			=> VSync,
			blank_n	=> blanking,
			xPos		=> xPos,
			yPos		=> yPos
		);
	pll0 :  pll25
		port map (
			ref_clk_clk        => MAX10_CLK1_50,      --      ref_clk.clk
			ref_reset_reset    => reset,    				--    ref_reset.reset
			vga_clk_clk        => vga_clk,        		--      vga_clk.clk
			reset_source_reset => reset_out  			-- reset_source.reset
		);
	gl0 : game_logic port map(
			
			pixel_clk		=> vga_clk,
			reset          => reset,
			VGA_R				=> VGA_R,
			VGA_G				=> VGA_G,
			VGA_B				=> VGA_B,
			VS					=> Vsync,
			blank_n			=> blanking,
			xpos				=> xpos,
			ypos				=> ypos,
			audio				=> arduino_io(0)
		);
	
	resetn <= not key(0);
	reset <= NOT resetn;
	VGA_VS <= Vsync;
	VGA_HS <= HSync;
	ledr(0) <= blanking;
	
--	-- @ToDo move this into the game logic or rendering modules.
--	-- testing output to VGA display 
--	-- two red diagonal lines on a white background
--	
--	xpix <= to_integer(unsigned(xpos)); -- changing position to numeric for ease
--	ypix <= to_integer(unsigned(ypos)); -- of calculations
--	
--	process(xpix, ypix, blanking)
--		begin
--		if blanking = '1' then
--			if (xpix = ypix) or (xpix - 160 = ypix) then
--				VGA_R <= "1111";
--				VGA_G <= "0000";
--				VGA_B <= "0000";
--			elsif (xpix >= 0 ) and (xpix < 640) and (ypix >= 0) and (ypix < 480) then
--				VGA_R <= "1111";
--				VGA_G <= "1111";
--				VGA_B <= "1111";
--			else 
--				VGA_R <= "0000";
--				VGA_G <= "0000";
--				VGA_B <= "0000";
--			end if;
--		end if;
--		end process;
--	-- end of VGA testing
end behaviour;
