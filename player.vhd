LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY player IS
	PORT(
		reset									: IN STD_LOGIC;
		Clock_slow							: IN STD_LOGIC;
		-- For keyboard
		CLK_48Mhz, PS2_CLK, PS2_DATA					: IN STD_LOGIC;
		
		
		is_player_1							: IN STD_LOGIC;
		
		position								: buffer STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END player;

ARCHITECTURE a OF player IS
	
	COMPONENT keyboard IS
		PORT(	keyboard_clk, keyboard_data, clock_48Mhz , 
				reset, read		: IN	STD_LOGIC;
				scan_code		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
				scan_ready		: OUT	STD_LOGIC);
	END COMPONENT;
	
	SIGNAL read_sig				: STD_LOGIC;
	SIGNAL scan_code			: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL scan_ready			: STD_LOGIC;

	SIGNAL next_move			: STD_LOGIC_VECTOR(1 DOWNTO 0);
	-- 00 : UP, 01 : DOWN, 10 : LEFT, 11 : RIGHT
	
	SIGNAL initalize			: STD_LOGIC := '1';
	SIGNAL p1ready				: STD_LOGIC := '0';
	
		
	TYPE STATE_TYPE IS (wait_ready, read_data, read_low);
	SIGNAL state: STATE_TYPE;
	
BEGIN

	PROCESS(reset, Clock_slow, scan_ready) BEGIN
		IF (reset = '0' OR initalize = '1') THEN
			IF (is_player_1 = '1') THEN
				position <= "0001000000010000";
			ELSE
				position <= "0001100000011000";
			END IF;
			initalize <= '0';
			state <= read_low;
		ELSE
			IF (Clock_slow'event AND Clock_slow = '1') THEN
				IF ((position(15 DOWNTO 8) < "01110000" OR NOT(position(15 DOWNTO 8) = "01110000" AND (next_move = "01")))
				AND (position(15 DOWNTO 8) > "00000000" OR NOT(position(15 DOWNTO 8) = "00000000" AND (next_move = "00")))
				AND (position(7 DOWNTO 0) < "10100000" OR NOT(position(7 DOWNTO 0) = "10100000" AND (next_move = "11")))
				AND (position(7 DOWNTO 0) > "00000000" OR NOT(position(7 DOWNTO 0) = "00000000" AND (next_move = "10")))) THEN
					CASE next_move IS
						WHEN "00" => position <= position - "0000000100000000";
						WHEN "01" => position <= position + "0000000100000000";
						WHEN "10" => position <= position - "0000000000000001";
						WHEN "11" => position <= position + "0000000000000001";
						WHEN OTHERS => position <= position;
					END CASE;
				END IF;
			ELSE
				position <= position;
			END IF;
			IF (CLK_48Mhz'EVENT) AND CLK_48Mhz = '1' THEN
				CASE state IS
					WHEN read_low =>
						state <= wait_ready;
					WHEN wait_ready =>
						IF scan_ready = '1' THEN
							state <= read_data;
						ELSE
							state <= wait_ready;
						END IF;
					WHEN read_data =>
						IF (is_player_1 = '1') THEN
							
								CASE scan_code(7 DOWNTO 0) IS
									WHEN x"75" => next_move <= "00";
									WHEN x"72" => next_move <= "01";
									WHEN x"6b" => next_move <= "10";
									WHEN x"74" => next_move <= "11";
									WHEN OTHERS => next_move <= next_move;
								END CASE;
							
						ELSE
							CASE scan_code(7 DOWNTO 0) IS
								WHEN x"1d" => next_move <= "00";
								WHEN x"1b" => next_move <= "01";
								WHEN x"1c" => next_move <= "10";
								WHEN x"23" => next_move <= "11";
								WHEN OTHERS => next_move <= next_move;
							END CASE;
						END IF;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	

	keyboard_inst: keyboard PORT MAP(
		PS2_CLK, PS2_DATA, CLK_48Mhz,
		'1', read_sig,
		scan_code,
		scan_ready);
		
END a;

