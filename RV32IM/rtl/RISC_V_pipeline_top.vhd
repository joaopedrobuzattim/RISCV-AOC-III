-------------------------------------------------------------------------
-- Design unit: RISC-V monocycle test bench
-- Description: 
-------------------------------------------------------------------------

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.RISC_V_package.all;


entity RISC_V_pipeline_top is
generic (
        PC_START_ADDRESS    : integer := 0 
    );
port (
    
    clk, rst_n    : in std_logic;

    -- Instruction Memory Ports
    inst_mem_addr_o    : out std_logic_vector (31 downto 0);
    inst_mem_data_i    : in std_logic_vector (31 downto 0);
    inst_mem_data_o    : out std_logic_vector (31 downto 0);
    
    -- Data Memory Ports
    data_mem_addr_o    : out std_logic_vector (31 downto 0);
    data_mem_data_i    : in std_logic_vector (31 downto 0);
    data_mem_data_o    : out std_logic_vector (31 downto 0);
    data_mem_wr_o      : out std_logic

);
end RISC_V_pipeline_top;


architecture structural of RISC_V_pipeline_top is
    signal instruction_id : std_logic_vector(31 downto 0);
    signal uins_id : Microinstruction;
    signal clk_div : std_logic;    

begin

    divisor: process(clk, rst_n) begin
	if rst_n = '1' then clk_div <= '0';
        elsif (clk'EVENT) and (clk='1') then
             if clk_div = '0' then clk_div <= '1';
             else clk_div <= '0';
             end if;        
        end if;
    end process divisor;
            

    CONTROL_PATH: entity work.ControlPath(behavioral)
         port map (
             clock          => clk_div,
             reset          => rst_n,
             instruction    => instruction_id,
             uins           => uins_id
         );

    DATA_PATH: entity work.DataPath(structural)
        port map (
            clock            => clk_div,
            clock_register   => clk,
            reset            => rst_n,
            instruction_id   => instruction_id,
            uins_id          => uins_id,
            inst_mem_addr_o  => inst_mem_addr_o,
            inst_mem_data_i  => inst_mem_data_i,
            inst_mem_data_o  => inst_mem_data_o,
            data_mem_addr_o  => data_mem_addr_o,
            data_mem_data_i  => data_mem_data_i,
            data_mem_data_o  => data_mem_data_o,
            data_mem_wr_o    => data_mem_wr_o

        );
end structural;


