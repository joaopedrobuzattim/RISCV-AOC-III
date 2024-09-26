library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RISC_V_pipeline_tb  is
end RISC_V_pipeline_tb;

architecture behavioral of RISC_V_pipeline_tb is

    constant RARS_INSTRUCTION_OFFSET    : std_logic_vector(31 downto 0) := x"00400000"; -- begining addresse of instruction in risc v
    constant RARS_DATA_OFFSET           : std_logic_vector(31 downto 0) := x"10010000"; -- begining addresse of data in risc v

    signal clock, clock_register        : std_logic := '0';
    signal reset                        : std_logic;
    signal data_out_mem                 : std_logic_vector (31 downto 0);

    -- Instruction Memory Signals
    signal inst_mem_addr   : std_logic_vector (31 downto 0);
    signal inst_mem_o_data   : std_logic_vector (31 downto 0);
    signal inst_mem_i_data   : std_logic_vector (31 downto 0);

    -- Data Memory Signals
    signal data_mem_addr    : std_logic_vector (31 downto 0);
    signal data_mem_o_data  : std_logic_vector (31 downto 0);
    signal data_mem_i_data  : std_logic_vector (31 downto 0);
    signal data_mem_wr      : std_logic;
begin

    clock <= not clock after 5 ns;
    clock_register <= not clock_register after 2.5 ns;
    reset <= '1', '0' after 7 ns;


    INSTRUCTION_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 100,
            START_ADDRESS   => RARS_INSTRUCTION_OFFSET, 
            imageFileName   => "instructionmemory.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => '0',
            address         => inst_mem_addr,    
            data_i          => inst_mem_i_data,
            data_o          => inst_mem_o_data
        );
        
        
    DATA_MEMORY: entity work.Memory(behavioral)
        generic map (
            SIZE            => 100,
            START_ADDRESS   => RARS_DATA_OFFSET,
            imageFileName   => "datamemory.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => data_mem_wr,
            address         => data_mem_addr, 
            data_i          => data_mem_i_data,
            data_o          => data_mem_o_data
        );  

    RISCV_PIPELINE_TOP:    entity work.RISC_V_pipeline_top
        port map (
            clock           => clock,
            reset           => reset,
            clock_register  => clock_register,

            -- Instruction Memory Ports         
            inst_mem_addr_o =>   inst_mem_addr,
            inst_mem_data_i =>   inst_mem_o_data,
            inst_mem_data_o =>   inst_mem_i_data,
    
            -- Data Memory Ports
            data_mem_addr_o =>   data_mem_addr,
            data_mem_data_i =>   data_mem_o_data,
            data_mem_data_o =>   data_mem_i_data,
            data_mem_wr_o   =>   data_mem_wr
        );

end behavioral;