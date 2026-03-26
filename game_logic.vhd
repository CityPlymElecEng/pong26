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

signal plyr1Score	: integer := 0;
signal plyr2Score	: integer := 0;
signal player1wins : std_logic;
signal player2wins : std_logic;
signal plyr1units : integer;
signal plyr1tens  : integer;
signal plyr2units : integer;
signal plyr2tens  : integer;

signal blip			: std_logic := '0' ; -- initiate a sound
signal blop			: std_logic := '0' ;
signal blipping	: std_logic := '0' ;	-- latches the sound request
signal blopping	: std_logic := '0' ;
signal blipcount  : integer;
signal blopcount  : integer;
signal bliptime   : integer;
signal bloptime   : integer;
signal sound    	: std_logic := '0' ;


signal memwrState : integer := 0;

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
	
	process(reset, VS, xpix, ypix, blipping, blopping)
		begin
			if reset = '0' then
				ballx <= 319;
				bally <= 239;
				plyr1score <= 0;
				plyr2score <= 0;
				player1wins <= '0';
				player2wins <= '0';
				
--				paddle1_val <= 240;
--				paddle2_val <= 240;
			elsif rising_edge(VS) then
				if player1wins = '1' OR player2wins = '1' then
					ballx <= 319;
					-- show winning screen maybe
				else
					ballx <= ballx + ballspeed * balldirew;
				end if;
				bally <= bally + ballspeed * balldirns;
				
--				paddle1_val <= to_integer(unsigned(paddle1(11 downto 2)));
--				paddle2_val <= to_integer(unsigned(paddle2(11 downto 2)));				
--				-- attempt to filter bad readings from adc
--				if abs(to_integer(unsigned(paddle2(11 downto 2))) - paddle2_val) < 70 then 
--					paddle2_val <= to_integer(unsigned(paddle2(11 downto 2)));
--
--				end if;
				if blip = '1' and blipping = '1' then
					blip <= '0';
				end if;
				if blop = '1' and blopping = '1' then
					blop <= '0';
				end if;

				if bally >= 479  then
					balldirns <= -1;
					bally <= 478;
					blip <= '1';
				elsif bally <= titleSize + 10 then
					balldirns <= 1;
					bally <= titleSize + 15;
					blip <= '1';
				end if;
				if ballx >= 639  then -- player1 scores
					balldirew <= -1;
					plyr1Score <= plyr1Score + 1;
					if plyr1score = 10 then
						player1Wins <= '1';
						-- initiate winning anthem	
					end if;
					ballx <= 400;
					blop <= '1';
					
				elsif ballx <= 10 then -- player2 scores
					balldirew <= 1;
					plyr2Score <= plyr2Score + 1;
					if plyr2score = 10 then
						player2Wins <= '1';
						-- initiate winning anthem
					end if;
					ballx <= 200;
					blop <= '1';
					
				end if;
				
				-- detect collisions with paddles
				if (paddle1_val < bally + paddlesize) and (paddle1_val > bally - paddlesize) and
				(ballx > 50) and (ballx < 50 + paddlewidth) then
					balldirew <= 1;
					ballx <= 60;
					blip <= '1';
				end if;

				if (paddle2_val < bally + paddlesize) and (paddle2_val > bally - paddlesize) and
				(ballx > 590) and (ballx < 590 + paddlewidth) then
					balldirew <= -1;
					ballx <= 580;
					blip <= '1';
				end if;

				
			end if;	
	end process;
	
	-- make a blip sound
	process ( blip, pixel_clk, reset )
		begin
			if reset = '0' then
				blipping <= '0';
			elsif rising_edge( pixel_clk) then
				if blip = '1' then -- make a noise
					blipping <= '1';
				end if;
				if blipping = '1' then -- make a sound for half a second
					if bliptime < 2500000 then
						if blipcount > 25000 then -- make the sound
							blipcount <= 0;
							sound <= not sound;
						else
							blipcount <= blipcount + 1;
						end if;
						bliptime <= bliptime + 1;
					else 
						bliptime <= 0;
						blipping <= '0';
					end if;
				end if;
			end if;
		end process;
	audio <= sound;
				
				
			
	-- scoring to screen process
	process(reset, pixel_clk, plyr1score, plyr2Score)
		begin
			if reset = '0' then
				
			elsif rising_edge(pixel_clk) then
				plyr1tens <= 48 + plyr1score / 10;  -- convert to ascii also
				plyr1units <= 48 + plyr1Score mod 10;
				plyr2tens <= 48 + plyr2score / 10;
				plyr2units <= 48 + plyr2Score mod 10;
			
				case memwrState is
					when 0 => -- write to memory
						scrAddress <= std_logic_vector(to_unsigned( 82, 12));
						scrdata <= std_logic_vector(to_unsigned(plyr1tens, 8));
						memwrState <= 1;
					when 1 =>
						nwr <= '1';
						memwrstate <= 2;
					when 2 =>
						nwr <= '0';
						memwrState <= 3;
										
					when 3 => 
						scrAddress <= std_logic_vector(to_unsigned( 83, 12));
						scrdata <= std_logic_vector(to_unsigned(plyr1units, 8));
						memwrState <= 4;
					when 4 =>
						nwr <= '1';
						memwrstate <= 5;
					when 5 =>
						nwr <= '0';
						memwrState <= 6;
						
					when 6 => -- write to memory
						scrAddress <= std_logic_vector(to_unsigned( 116, 12));
						scrdata <= std_logic_vector(to_unsigned(plyr2tens, 8));
						memwrState <= 7;
					when 7 =>
						nwr <= '1';
						memwrstate <= 8;
					when 8 =>
						nwr <= '0';
						memwrState <= 9;
										
					when 9 => 
						scrAddress <= std_logic_vector(to_unsigned( 117, 12));
						scrdata <= std_logic_vector(to_unsigned(plyr2units, 8));
						memwrState <= 10;
					when 10 =>
						nwr <= '1';
						memwrstate <= 11;
					when 11 =>
						nwr <= '0';
						memwrState <= 0;
					when others =>
						memwrstate <= 0;
						
				end case;
			end if;
		end process;

	
end behaviour;