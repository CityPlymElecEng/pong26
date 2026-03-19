-- Game logic and other operations for the CITY2077 assignment 2
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game_logic is
	port(
			pixel_clk		: in std_logic;
			max10_clk1_50	: in std_logic;
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

  component paddles is  -- get the current values of the potentiometers
    port (
      -- Clocks
      MAX10_CLK1_50 : in  std_logic;
      -- KEY
      reset         : in  std_logic;
      -- paddle positions from adc
      player1       : out std_logic_vector(7 downto 0);
      player2       : out std_logic_vector(7 downto 0)
      );
  end component paddles;
  component txtscreen is
		port (
    hp, vp :    integer;
    addr   : in std_logic_vector(11 downto 0);  -- text screen ram
    data   : in std_logic_vector(7 downto 0);
    nWr    : in std_logic;
    pClk   : in std_logic;
    nblnk  : in std_logic;

    pix : out std_logic

    );
	end component txtScreen;
--  component paddles is
--		port (
--			CLOCK : in  std_logic                     := 'X'; -- clk
--			RESET : in  std_logic                     := 'X'; -- reset
--			CH0   : out std_logic_vector(11 downto 0);        -- CH0
--			CH1   : out std_logic_vector(11 downto 0);        -- CH1
--			CH2   : out std_logic_vector(11 downto 0);        -- CH2
--			CH3   : out std_logic_vector(11 downto 0);        -- CH3
--			CH4   : out std_logic_vector(11 downto 0);        -- CH4
--			CH5   : out std_logic_vector(11 downto 0)        -- CH5
--		);
--	end component paddles;



-- signals

signal scrAddress : std_logic_vector (11 downto 0);
signal scrData		: std_logic_vector (7 downto 0);
signal nWr			: std_logic;
signal txtRGB		: std_logic;

signal resetn		: std_logic;
signal titleSize	: integer range 0 to 511 := 80;  -- Marquee size

signal xPix			: integer range 0 to 799; 
signal yPix			: integer range 0 to 525;

signal ballx		: integer range 0 to 639 := 319;
signal bally		: integer range 0 to 479 := 239;

signal ballspeed	: integer := 4;
signal balldirns	: integer range -1 to 1 := 1; -- +1 down, -1 up 0 no vertical movement
signal balldirew	: integer range -1 to 1 := 1; -- +1 right, -1 left 0 no horizontal movement

signal ballsize	: integer range 1 to 20 := 10;

signal paddlesize : integer := 20;
signal paddlewidth :	integer := 10;

signal paddle1		: std_logic_vector (7 downto 0);
signal paddle2		: std_logic_vector (7 downto 0);
signal dummy0		: std_logic_vector (7 downto 0);
signal dummy1		: std_logic_vector (7 downto 0);
signal dummy2		: std_logic_vector (7 downto 0);
signal dummy3		: std_logic_vector (7 downto 0);

signal paddle1_val : integer := 240; -- range 0 to 480;
signal paddle2_val : integer := 240; -- range 0 to 480;

signal cycle	: integer range 0 to 1 := 0; 

begin

--	pad0 : component paddles
--		port map (
--			CLOCK => ADC_CLK, --      clk.clk
--			RESET => RESETn, 	--    reset.reset
--			CH0   => paddle1,   -- readings.CH0
--			CH1   => dummy0,   --         .CH1
--			CH2   => dummy1,   --         .CH2
--			CH3   => dummy2,   --         .CH3
--			CH4   => dummy3,   --         .CH4
--			CH5   => paddle2   --         .CH5
--		);
	
	resetn <= not reset;
	
	-- testing output to VGA display 
	-- two red diagonal lines on a white background
	xpix <= to_integer(unsigned(xpos)); -- changing position to numeric for ease
	ypix <= to_integer(unsigned(ypos)); -- of calculations
	txtscr : txtScreen  -- memory mapped screen display for 40 x 24 ascii characters
    port map (xpix, ypix, scrAddress, scrData, nWr, pixel_clk, blank_n, txtRGB);

	paddlePositions : paddles port map (max10_clk1_50, resetn, paddle1, paddle2);
	paddle1_val <= (to_integer(unsigned(paddle1)))*2 + titlesize; -- avoid marquee
	paddle2_val <= (to_integer(unsigned(paddle2)))*2 + titlesize;

	process(xpix, ypix, blank_n)
		begin
			VGA_R <= "0000";-- set default to black
			VGA_G <= "0000";
			VGA_B <= "0000";
		
		if blank_n = '1' then -- inside display area
			if (xpix >= 0 ) and (xpix < 640) and (ypix >= titleSize) and (ypix < 480) then
				VGA_R <= "0001";
				VGA_G <= "0111";
				VGA_B <= "0001";
			else 
				VGA_R <= "0000";
				VGA_G <= "0000";
				VGA_B <= "0000";
			end if;
			-- text display
			if (txtRGB = '1') then 
				VGA_R <= "1111";
				VGA_G <= "1111";
				VGA_B <= "1111";
			end if;	
			-- display paddles
			if (paddle1_val < ypix + paddlesize) and (paddle1_val > ypix - paddlesize) and
				(xpix > 40) and (xpix < 40 + paddlewidth) then
				VGA_R <= "1111";
				VGA_G <= "1111";
				VGA_B <= "0000";
			end if;
			if (paddle2_val < ypix + paddlesize) and (paddle2_val > ypix - paddlesize) and
				(xpix > 590) and (xpix < 590 + paddlewidth) then
				VGA_R <= "0000";
				VGA_G <= "1111";
				VGA_B <= "1111";
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
--				paddle1_val <= 240;
--				paddle2_val <= 240;
			elsif rising_edge(VS) then
				ballx <= ballx + ballspeed * balldirew;
				bally <= bally + ballspeed * balldirns;
				
--				paddle1_val <= to_integer(unsigned(paddle1(11 downto 2)));
--				paddle2_val <= to_integer(unsigned(paddle2(11 downto 2)));				
--				-- attempt to filter bad readings from adc
--				if abs(to_integer(unsigned(paddle2(11 downto 2))) - paddle2_val) < 70 then 
--					paddle2_val <= to_integer(unsigned(paddle2(11 downto 2)));
--
--				end if;

				if bally >= 479  then
					balldirns <= -1;
					bally <= 478;
				elsif bally <= titleSize + 10 then
					balldirns <= 1;
					bally <= titleSize + 15;
				end if;
				if ballx >= 639  then
					balldirew <= -1;
					ballx <= 638;
					-- player1 scores
				elsif ballx <= 10 then
					balldirew <= 1;
					ballx <= 11;
					-- player2 scores
				end if;
				
				-- detect collisions with paddles
				if (paddle1_val < bally + paddlesize) and (paddle1_val > bally - paddlesize) and
				(ballx > 50) and (ballx < 50 + paddlewidth) then
					balldirew <= 1;
					ballx <= 60;
				end if;

				if (paddle2_val < bally + paddlesize) and (paddle2_val > bally - paddlesize) and
				(ballx > 590) and (ballx < 590 + paddlewidth) then
					balldirew <= -1;
					ballx <= 580;
				end if;

				
			end if;	
	end process;
end behaviour;