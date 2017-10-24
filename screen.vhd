LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY screen IS
	PORT(
		-- For VGA
		Clock_48Mhz 							: IN STD_LOGIC;
		VGA_Red,VGA_Green,VGA_Blue 		: OUT STD_LOGIC;
		VGA_Hsync,VGA_Vsync,
		Video_blank_out, Video_clock_out : OUT STD_LOGIC;
		-- From bomb
		bomb_position									: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		player1_position								: IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END screen;

ARCHITECTURE a OF screen IS
	
	COMPONENT video_PLL
		PORT(
			inclk0		: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC );
	end component;
	
	COMPONENT ram_2 IS
		PORT
		(
			address_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			address_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			clock_a		: IN STD_LOGIC  := '1';
			clock_b		: IN STD_LOGIC ;
			data_a		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			data_b		: IN STD_LOGIC_VECTOR (0 DOWNTO 0);
			wren_a		: IN STD_LOGIC  := '0';
			wren_b		: IN STD_LOGIC  := '0';
			q_a		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
			q_b		: OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT VGA_SYNC IS
		PORT(clock_25Mhz, red, green, blue		: IN	STD_LOGIC;
			 red_out, green_out, blue_out, 
			 horiz_sync_out, vert_sync_out,
			 video_blank_out, video_clock_out		: OUT	STD_LOGIC;
			 pixel_row, pixel_column			: OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT counter_16 IS
		PORT
		(
			clock		: IN STD_LOGIC ;
			sclr		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL ram_bomb_q		: STD_LOGIC_VECTOR(0 DOWNTO 0);
	SIGNAL ram_bomb_q_before		: STD_LOGIC_VECTOR(0 DOWNTO 0);
	SIGNAL pixel_col_s, pixel_row_s	: std_logic_vector(9 DOWNTO 0);
	
		-- Video Display Signals
	SIGNAL Red_Data, Green_Data, Blue_Data  : std_logic; 
	SIGNAL Power_On, Rev_video,vert_sync_in, clock_25Mhz : std_logic;
	SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL isBomb, wren							: STD_LOGIC;
	SIGNAL refresh_position						: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL isBomb_v								: STD_LOGIC_VECTOR(0 DOWNTO 0);
	
	SIGNAL ctr_16_q								: STD_logic_vector(15 DOWNTO 0);
	
	SIGNAL white, green : STD_LOGIC;
	SIGNAL initalize			: STD_LOGIC := '1';
	SIGNAL death_signal : STD_LOGIC := '0';

	
	
BEGIN

	PROCESS(Clock_48Mhz) BEGIN
		IF (initalize = '1') THEN
			death_signal <= '0';
			initalize <= '0';
		ELSE
			IF (bomb_position = refresh_position) THEN
				isBomb <= '1';
			ELSE
				IF (ram_bomb_q_before(0) = '1') THEN
					isBomb <= '1';
				ELSE
					isBomb <= '0';
				END IF;
			END IF;
		END IF;
		IF(refresh_position = player1_position) THEN
			death_signal <= ram_bomb_q(0);
		END IF;
	END PROCESS;
	
	PROCESS(ctr_16_q(2)) BEGIN
		IF (ctr_16_q(2) = '1') THEN
			wren <= '1';
		ELSE
			wren <= '0';
		END IF;
	
	END PROCESS;

	counter_16_refresh: counter_16 PORT MAP(
			clock => clock_25Mhz,
			sclr => '0',
			q	=> ctr_16_q
		);
	
	refresh_position <= pixel_row(9 DOWNTO 2) & pixel_column(9 DOWNTO 2);
	isBomb_v(0) <= isBomb;
	
	ram_2_bomb: ram_2 PORT MAP(
			address_a => refresh_position - "0000000000000010",
			address_b => refresh_position,
			clock_a => clock_25Mhz,
			clock_b => clock_25Mhz,
			data_a  => isBomb_v,
			data_b  => isBomb_v,
			wren_a => wren,
			wren_b => '0',
			q_a => ram_bomb_q_before,
			q_b => ram_bomb_q
	);
	
	video_PLL_inst : video_PLL PORT MAP (
		inclk0	 => Clock_48Mhz,
		c0	 => clock_25Mhz
	);
	
	VGA_Vsync <= vert_sync_in;
	
	PROCESS(clock_25Mhz) BEGIN
		IF (refresh_position + "00000000000000010" = bomb_position) THEN
			white <= '1';
		ELSE
			white <= '0';
			IF (player1_position = refresh_position) THEN
				green <= '1';
			ELSE
				green <= '0';
			END IF;
		
		END IF;
		
		
	END PROCESS;
	
	vga_sync_inst: VGA_SYNC PORT MAP(
		clock_25Mhz => clock_25Mhz, 
		red => ram_bomb_q(0) OR death_signal, green => '0' OR white OR green , blue => '0' OR white OR green,	
		red_out => VGA_red, green_out => VGA_green, blue_out => VGA_blue,
		horiz_sync_out => VGA_Hsync, vert_sync_out => vert_sync_in,
		video_blank_out => video_blank_out, video_clock_out => video_clock_out,
		pixel_row => pixel_row, pixel_column => pixel_column
		);
	
END a;

