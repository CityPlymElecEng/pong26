library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Required for unsigned arithmetic and subtraction

entity video_sync_generator is
    Port ( 
        vga_clk : in  STD_LOGIC;
        reset   : in  STD_LOGIC;
        HS      : out STD_LOGIC;
        VS      : out STD_LOGIC;
        blank_n : out STD_LOGIC;
        xPos    : out STD_LOGIC_VECTOR(10 downto 0);
        yPos    : out STD_LOGIC_VECTOR(9 downto 0)
    );
end video_sync_generator;

architecture Behavioral of video_sync_generator is


--VGA Timing
--Horizontal :
--                ______________                 _____________
--               |              |               |
--_______________|  VIDEO       |_______________|  VIDEO (next line)

--___________   _____________________   ______________________
--           |_|                     |_|
--            B <-C-><----D----><-E->
--           <------------A--------->
--The Unit used below are pixels;  
--  B->Sync_cycle                   :H_sync_cycle
--  C->Back_porch                   :hori_back
--  D->Visable Area
--  E->Front porch                  :hori_front
--  A->horizontal line total length :hori_line
--Vertical :
--               ______________                 _____________
--              |              |               |          
--______________|  VIDEO       |_______________|  VIDEO (next frame)
--
--__________   _____________________   ______________________
--          |_|                     |_|
--           P <-Q-><----R----><-S->
--          <-----------O---------->
--The Unit used below are horizontal lines;  
--  P->Sync_cycle                   :V_sync_cycle
--  Q->Back_porch                   :vert_back
--  R->Visable Area
--  S->Front porch                  :vert_front
--  O->vertical line total length :vert_line
                      
-- Parameters
constant hori_line  : integer := 800;                           
constant hori_back  : integer := 144;
constant hori_front : integer := 16;
constant vert_line  : integer := 525;
constant vert_back  : integer := 34;
constant vert_front : integer := 11;
constant H_sync_cycle : integer := 96;
constant V_sync_cycle : integer := 2;
constant H_BLANK : integer := hori_front + H_sync_cycle; -- add by yang

-- Internal Signals
signal h_cnt : unsigned(10 downto 0);
signal v_cnt : unsigned(9 downto 0);
signal cHD, cVD, cDEN : STD_LOGIC;
signal hori_valid, vert_valid : STD_LOGIC;

begin

-- Counter Logic
process(vga_clk)
begin
    if (reset = '1') then
        h_cnt <= (others => '0');
        v_cnt <= (others => '0');
    elsif (falling_edge( vga_clk )) then
        if (h_cnt = hori_line - 1) then
            h_cnt <= (others => '0');
            if (v_cnt = vert_line - 1) then
                v_cnt <= (others => '0');
            else
                v_cnt <= v_cnt + 1;
            end if;
        else
            h_cnt <= h_cnt + 1;
        end if;
--		  xPos <= std_logic_vector(h_cnt - hori_back);
--        yPos <= std_logic_vector(v_cnt - vert_back);
    end if;
	 
end process;

-- Sync Signal Generation
cHD <= '0' when (h_cnt < H_sync_cycle) else '1';
cVD <= '0' when (v_cnt < V_sync_cycle) else '1';

hori_valid <= '1' when (h_cnt >= hori_back and h_cnt < (hori_line - hori_front)) else '0';
vert_valid <= '1' when (v_cnt >= vert_back and v_cnt < (vert_line - vert_front)) else '0';

cDEN <= hori_valid and vert_valid;

-- Output Assignment 
process(vga_clk)
begin
    if (falling_edge( vga_clk)) then
        HS <= cHD;
        VS <= cVD;
        blank_n <= cDEN;
        xPos <= std_logic_vector(h_cnt - hori_back + 1); -- taking account of 1 clk cycle delay
        yPos <= std_logic_vector(v_cnt - vert_back); 
    end if;
end process;

end Behavioral;
