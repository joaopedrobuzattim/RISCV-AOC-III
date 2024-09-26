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
    
    clock, clock_register, reset    : in std_logic;

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
    
begin

    CONTROL_PATH: entity work.ControlPath(behavioral)
         port map (
             clock          => clock,
             reset          => reset,
             instruction    => instruction_id,
             uins           => uins_id
         );

    DATA_PATH: entity work.DataPath(structural)
        port map (
            clock            => clock,
            clock_register   => clock_register,
            reset            => reset,
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


