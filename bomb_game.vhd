LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY bomb_game IS
	PORT(
		reset									: IN STD_LOGIC;
		-- For keyboard
		PS2_CLK, PS2_DATA					: IN STD_LOGIC;
		
		-- For VGA
		Clock_48Mhz 							: IN STD_LOGIC;
		VGA_Red,VGA_Green,VGA_Blue 		: OUT STD_LOGIC;
		VGA_Hsync,VGA_Vsync,
		Video_blank_out, Video_clock_out : OUT STD_LOGIC
	);
END bomb_game;

ARCHITECTURE a OF bomb_game IS
	

	
	COMPONENT screen IS
		PORT(
			Clock_48Mhz 							: IN STD_LOGIC;
			VGA_Red,VGA_Green,VGA_Blue 		: OUT STD_LOGIC;
			VGA_Hsync,VGA_Vsync,
			Video_blank_out, Video_clock_out : OUT STD_LOGIC;
					-- From bomb
			bomb_position									: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			player1_position								: IN STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT counter_30 IS
		PORT
		(
			clock		: IN STD_LOGIC ;
			q		: OUT STD_LOGIC_VECTOR (29 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT player IS
		PORT(
			reset									: IN STD_LOGIC;
			Clock_slow							: IN STD_LOGIC;
			-- For keyboard
			CLK_48Mhz, PS2_CLK, PS2_DATA					: IN STD_LOGIC;
			is_player_1							: IN STD_LOGIC;
			position								: buffer STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
	END COMPONENT;
	
	SIGNAL Clock_slow								: STD_LOGIC;
	SIGNAL Clock_slow_q							: STD_LOGIC_VECTOR(29 DOWNTO 0);
	
	SIGNAL position_p1 			: STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL position_p2 			: STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

	player1_inst: player PORT MAP(
			reset,
			Clock_slow,
			Clock_48Mhz, PS2_CLK, PS2_DATA,
			'1',
			position_p1
		);
		
	player2_inst: player PORT MAP(
			reset,
			Clock_slow,
			Clock_48Mhz, PS2_CLK, PS2_DATA,
			'0',
			position_p2
		);

	slow_clk_cnt: counter_30 PORT MAP(
			clock => Clock_48Mhz,
			q => Clock_slow_q
	);
	Clock_slow <= clock_slow_q(21);
	
	screen_inst: screen PORT MAP(
		Clock_48Mhz,
		VGA_Red,VGA_Green,VGA_Blue,
		VGA_Hsync,VGA_Vsync,
		Video_blank_out, Video_clock_out,
		position_p2,
		position_p1
	);
	
END a;

