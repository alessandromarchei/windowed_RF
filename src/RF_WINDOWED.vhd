library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.math_real.all;
use WORK.all;

--NBIT = DATA PARALLELISM OF EACH REGISTER
--NREG = NUMBER OF REGISTERS IN THE FILE
entity RF_WINDOWED is
 generic(NBIT : integer := 32;
         M : integer := 4;     --NUMBER OF GLOBAL REGISTERS(#GLOBAL EACH WINDOW = M/F)
         N : integer := 2;      --NUMBER OF IN, OUT, LOCALS FOR EACH WINDOW
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
end RF_WINDOWED;

architecture BEHAVIORAL of RF_WINDOWED is

  subtype REG_ADDR is natural range 0 to (2*N*F + M)-1; -- ADDRESSES OF THE PHYSICAL RF
  type REG_ARRAY is array (REG_ADDR) of std_logic_vector(NBIT - 1 downto 0);
--BANK OF REGISTERS
  signal RF : REG_ARRAY;
  
	
begin 

reg : process(CLK)
  
  variable cwp_v : integer := 0;      --current window pointer
  variable swp_v : integer := 0;      --save window pointer
  variable spill_v: integer := 0;     --spill variable
  variable i: integer := 0;           --counter 
  variable cansave : integer := F-1;    --if cansave = F, then all windows are available
  variable canrestore : integer := 0; --if canrestore = 0, then there are no
                                     --data into memory
  
 
  begin

   
    if(CLK = '1' and CLK' event) then
      
      if(RESET = '1') then               --SYNCHRONOUS RESET
        for i in 0 to (2*N*F + M)-1 loop 
          RF(i) <= (others => '0');      --EVERY REGISTER IS CLEARED                      -
        end loop;
       OUT1 <= (others =>'0');
       OUT2 <= (others => '0');
        
      elsif(ENABLE = '1') then           --WR/RD ONLY IF ENABLE IS ACTIVE

       FILL <= '0';
       if (spill_v = 0) then
         
         if(CALL = '1') then
           --INCREMENT CWP BY 1
           if (cwp_v = F-1) then
             cwp_v := 0; --CIRCULAR BUFFER
           else
             cwp_v := cwp_v + 1;
           end if;
            --CWP <= std_logic_vector(conv_unsigned(cwp_v,CWP 'length));
           --CHECK IF THERE ARE ANY FREE WINDOWS
           if(cansave > 0) then
            --NO NEED TO REPLACE A WINDOW
            cansave := cansave - 1;
           else
             --NEED TO STORE WINDOW INTO MEMORY --> SPILL
             SPILL <= '1';
             spill_v := 1;
             swp_v := cwp_v;
             canrestore := canrestore + 1; --update the number of windows stored
                                           --into memory
             DATABUS <= RF (2*N*cwp_v);    --data stored into the 1st register of that window are
                                           --sent to memory (i=0)
             i:=i+1;
           end if;

        elsif (RET = '1') then
          --DECREMENT CWP BY 1
          if (cwp_v = 0) then
            cwp_v := F-1; --CIRCULAR BUFFER
          else
            cwp_v := cwp_v - 1;
          end if;
          -- CWP <= std_logic_vector(conv_unsigned(cwp_v,CWP 'length));
          if(canrestore > 0 and (swp_v = cwp_v)) then 
            FILL <= '1'; --We assume data transfer is instantaneous
            swp_v := swp_v - 1;
          end if;
        end if;
            
        else -- spill_v = 1
          --SENDING DATA ONE BYTE FOR EACH CLOCK CYCLE
              if (i < 2*N) then
                DATABUS <= RF(2*N*cwp_v + i);
                i := i+1;
              else
                SPILL <= '0';
                spill_v := 0;
                i:=0;
              end if;
        end if;          

        
        if(WR = '1') then
          if(conv_integer(ADD_WR) < 3*N) then
            --access within in-local-out addresses
            RF(cwp_v*2*N + conv_integer(ADD_WR)) <= DATAIN;
          else
            --WRITING A GLOBAL REGISTER
            if (ADD_WR < 3*N+M) then
              RF(2*N*F + conv_integer(ADD_WR) - 3*N) <= DATAIN;
            end if;
          end if;
        end if;

        if(RD1 = '1') then
          if(conv_integer(ADD_RD1) < 3*N) then
            --access within in-local-out addresses
            OUT1 <= RF(cwp_v*2*N + conv_integer(ADD_RD1));
          else
            --READING FROM A GLOBAL REGISTER
            if (ADD_RD1 < 3*N+M) then
              OUT1 <= RF(2*N*F + conv_integer(ADD_RD1) -3*N);
            end if;
          end if;
        end if;

        if(RD2 = '1') then
          if(conv_integer(ADD_RD2) < 3*N) then
            --access within in-local-out addresses
            OUT2 <= RF(cwp_v*2*N + conv_integer(ADD_RD2));
          else
            --READING FROM A GLOBAL REGISTER
            if (ADD_RD2 < 3*N+M) then
              OUT2 <= RF(2*N*F + conv_integer(ADD_RD2) -3*N);
            end if;
          end if;
       end if;
      
    end if;
  end if;
end process;


end BEHAVIORAL;

configuration CFG_RF_WIND_BEH of RF_WINDOWED is
  for BEHAVIORAL
  end for;
end configuration;
