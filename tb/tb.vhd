library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.math_real.all;
use WORK.all;

entity tb is
end tb;

architecture TESTA of tb is
	
       signal CLK: std_logic:= '0';
       signal RESET: std_logic;
       signal ENABLE: std_logic;
       signal RD1: std_logic;
       signal RD2: std_logic;
       signal WR: std_logic;
       signal ADD_WR: std_logic_vector(3 downto 0);
       signal ADD_RD1: std_logic_vector(3 downto 0);
       signal ADD_RD2: std_logic_vector(3 downto 0);
       signal DATAIN: std_logic_vector(31 downto 0);
       signal OUT1: std_logic_vector(31 downto 0);
       signal OUT2: std_logic_vector(31 downto 0);
       signal DATABUS: std_logic_vector (31 downto 0);
       signal CALL, RET, FILL, SPILL: std_logic := '0';

component RF_WINDOWED
  generic(NBIT : integer := 32;
         M : integer := 4;     --NUMBER OF GLOBAL REGISTERS(#GLOBAL EACH WINDOW = M/F)
         N : integer := 4;      --NUMBER OF IN, OUT, LOCALS FOR EACH WINDOW
         F : integer := 4);     --NUMBER OF WINDOWS
  port ( CLK: 		IN std_logic;
         RESET: 	IN std_logic;
	 ENABLE: 	IN std_logic;
         CALL:          IN std_logic;
         RET:           IN std_logic;
	 RD1: 		IN std_logic;
	 RD2: 		IN std_logic;
	 WR: 		IN std_logic;
         DATABUS:       INOUT std_logic_vector(NBIT - 1 downto 0);
	 ADD_WR: 	IN std_logic_vector(integer(ceil(log2(real(3*N + M))))-1 downto 0);
	 ADD_RD1: 	IN std_logic_vector(integer(ceil(log2(real(3*N + M))))-1 downto 0);
	 ADD_RD2: 	IN std_logic_vector(integer(ceil(log2(real(3*N + M))))-1 downto 0);
	 DATAIN: 	IN std_logic_vector(NBIT - 1 downto 0);
         OUT1: 		OUT std_logic_vector(NBIT - 1 downto 0);
	 OUT2: 		OUT std_logic_vector(NBIT - 1 downto 0);
         FILL:          OUT std_logic;
         SPILL:         OUT std_logic);
        
end component;

begin 

RG:RF_WINDOWED
GENERIC MAP (32,4,2,4)
port map (CLK, RESET, ENABLE, CALL, RET, RD1, RD2, WR, DATABUS, ADD_WR, ADD_RD1, ADD_RD2, DATAIN, OUT1, OUT2, FILL, SPILL);

	RESET <= '1','0' after 1 ns ;
	ENABLE <= '0','1' after 1 ns;
	WR <= '1',  '0' after 8 ns;
	RD1 <= '1','0' after 5 ns, '1' after 13 ns, '0' after 20 ns; 
	RD2 <= '0','1' after 17 ns;
        CALL <= '0', '1' after 9 ns, '0' after 10 ns, '1' after 11 ns, '0' after 12 ns ,'1' after 13 ns, '0' after 14 ns,  '1' after 15 ns, '0' after 16 ns, '1' after 17 ns, '0' after 18 ns;
        --CALL <= '0', '1' after 4.3 ns, '0' after 4.8 ns, '1' after 8.3 ns, '0' after 8.8 ns, '1' after 12.3 ns, '0' after 12.8 ns, '1' after 15.3 ns, '0' after 15.8 ns, '1' after 19.4 ns, '0' after 19.9 ns ;
        RET <= '0';
	ADD_WR <= "0001", "0010" after 1.7 ns, "0011" after 3.7 ns, "0100" after 5.7 ns;
	ADD_RD1 <="0001", "0010" after 9 ns, "0100" after 15 ns;
	ADD_RD2 <= "0100", "0000" after 9 ns, "0110" after 19 ns;
	DATAIN <=  std_logic_vector(conv_unsigned(1,32)) , std_logic_vector(conv_unsigned(2,32)) after 2 ns , std_logic_vector(conv_unsigned(3,32)) after 4 ns , std_logic_vector(conv_unsigned(4,32)) after 6 ns;



	PCLOCK : process(CLK)
	begin
		CLK <= not(CLK) after 0.5 ns;	
	end process;

      

end TESTA;


configuration CFG_RF_WINDOWED_TEST of tb is
  for TESTA
	for RG : RF_WINDOWED
		use configuration WORK.CFG_RF_WIND_BEH;
	end for; 
  end for;
end CFG_RF_WINDOWED_TEST;

