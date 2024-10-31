library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity RISC_V_pipeline_tb is
end RISC_V_pipeline_tb;

architecture behavioral of RISC_V_pipeline_tb is

    constant RARS_INSTRUCTION_OFFSET : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#00400000#, 32));
    constant RARS_DATA_OFFSET        : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(16#10010000#, 32));



    signal clock                        : std_logic := '0';
    signal reset                        : std_logic;
    signal data_out_mem                 : std_logic_vector (31 downto 0);

    -- Sinais da Memória de Instruções
    signal inst_mem_addr                : std_logic_vector (31 downto 0);
    signal inst_mem_o_data              : std_logic_vector (31 downto 0);
    signal inst_mem_i_data              : std_logic_vector (31 downto 0);

    -- Sinais da Memória de Dados
    signal data_mem_addr                : std_logic_vector (31 downto 0);
    signal data_mem_o_data              : std_logic_vector (31 downto 0);
    signal data_mem_i_data              : std_logic_vector (31 downto 0);
    signal data_mem_wr                  : std_logic;

    signal const_zero : std_logic := '0';

    -- Declaração do componente Memory
    component Memory
        generic (
            SIZE            : integer := 32;                -- Profundidade da memória
            START_ADDRESS   : std_logic_vector(31 downto 0) := (others => '0');  -- Endereço inicial mapeado para 0x00000000
            imageFileName   : string := "UNUSED"            -- Nome do arquivo com o conteúdo da memória
        );
        port (
            clock           : in  std_logic;
            MemWrite        : in  std_logic;
            address         : in  std_logic_vector(31 downto 0);
            data_i          : in  std_logic_vector(31 downto 0);
            data_o          : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Declaração do componente RISC_V_pipeline_top
    component RISC_V_pipeline_top
        port (
            -- Clock e Reset
            clk              : in  std_logic;
            rst_n            : in  std_logic;
            
            -- Portas da Memória de Instruções
            inst_mem_addr_o  : out std_logic_vector(31 downto 0);  
            inst_mem_data_i  : in  std_logic_vector(31 downto 0);  
            inst_mem_data_o  : out std_logic_vector(31 downto 0); 
            
            -- Portas da Memória de Dados
            data_mem_addr_o  : out std_logic_vector(31 downto 0);  
            data_mem_data_i  : in  std_logic_vector(31 downto 0);  
            data_mem_data_o  : out std_logic_vector(31 downto 0);  
            data_mem_wr_o    : out std_logic
        );
    end component;

begin

    -- Geração de clock e reset
    clock <= not clock after 2.5 ns;
    reset <= '1', '0' after 7 ns;

    -- Instância da Memória de Instruções
    INSTRUCTION_MEMORY: Memory
        generic map (
            SIZE            => 100,
            START_ADDRESS   => RARS_INSTRUCTION_OFFSET, 
            imageFileName   => "instructionmemory.txt"
        )
        port map (
            clock           => clock,
            MemWrite        => const_zero,
            address         => inst_mem_addr,    
            data_i          => inst_mem_i_data,
            data_o          => inst_mem_o_data
        );
        
    -- Instância da Memória de Dados
    DATA_MEMORY: Memory
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

    -- Instância do RISC_V_pipeline_top
    RISCV_PIPELINE_TOP: RISC_V_pipeline_top
        port map (
            clk             => clock,
            rst_n           => reset,
            
            -- Portas da Memória de Instruções         
            inst_mem_addr_o =>   inst_mem_addr,
            inst_mem_data_i =>   inst_mem_o_data,
            inst_mem_data_o =>   inst_mem_i_data,
    
            -- Portas da Memória de Dados
            data_mem_addr_o =>   data_mem_addr,
            data_mem_data_i =>   data_mem_o_data,
            data_mem_data_o =>   data_mem_i_data,
            data_mem_wr_o   =>   data_mem_wr
        );

end behavioral;

