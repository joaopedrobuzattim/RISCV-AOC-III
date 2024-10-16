-------------------------------------------------------------------------
-- Design unit: Data path
-- Description: MIPS data path supporting ADDU, SUBU, AND, OR, LW, SW,  
--                  ADDIU, ORI, SLT, BEQ, J, LUI instructions.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 
use work.RISC_V_package.all;


   
entity DataPath is
    generic (
        PC_START_ADDRESS    : integer := 0
    );
    port (  
        clock, reset : in std_logic;
        clock_register : in std_logic;
        instruction_id : out std_logic_vector(31 downto 0);
        uins_id : in Microinstruction;

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
end DataPath;

architecture structural of DataPath is

    signal MemWrite, register_enable, pc_enable: std_logic;
    signal instructionAddress, dataAddress, data_i : std_logic_vector(31 downto 0);
   
-- propagate the instruction decoded
    signal uins_stall_enable: Microinstruction;
    signal uins_ex: Microinstruction;
    signal uins_mem: Microinstruction;
    signal uins_wb: Microinstruction;
    signal uins_stall: Microinstruction;

    
-- propagate the pc in each stage    
    signal new_pc: std_logic_vector(31 downto 0);
  --  signal pc: std_logic_vector(31 downto 0);
    
    signal pc_if: std_logic_vector(31 downto 0);
    signal pc_id: std_logic_vector(31 downto 0);
    signal pc_ex: std_logic_vector(31 downto 0);
    signal pc_mem: std_logic_vector(31 downto 0);
    signal pc_cal: std_logic_vector(31 downto 0);
    signal pc_predict: std_logic_vector(31 downto 0);
    signal incrementedPC : std_logic_vector(31 downto 0);
    
--  propagate the operand between the id and ex stage  
    signal data_1_id: std_logic_vector(31 downto 0);
    signal data_1_ex: std_logic_vector(31 downto 0);
    signal data_2_id: std_logic_vector(31 downto 0);
    signal data_2_ex: std_logic_vector(31 downto 0);
    
    
-- propagate the instruction from the if to ex to enable sign and zero extention of the instruction
    signal instruction_if: std_logic_vector(31 downto 0);
    signal instruction_ex: std_logic_vector(31 downto 0);
--    signal instruction_stall: std_logic_vector(31 downto 0);
  
  
-- propagate the data to load  
    signal data_load_mem: std_logic_vector(31 downto 0);
    signal data_load_wb: std_logic_vector(31 downto 0);

-- propagate the data to store in the register and in the data memory
    signal resultat_mul : std_logic_vector(31 downto 0);
    signal resultalu : std_logic_vector(31 downto 0);
    signal result_ex : std_logic_vector(31 downto 0);
    signal resultalumem: std_logic_vector(31 downto 0);
    signal resultaluwb : std_logic_vector(31 downto 0);
    signal data_store_mem  : std_logic_vector(31 downto 0);
    
-- propagate the address of the destination register 
    signal rd_stall: std_logic_vector(4 downto 0);
    signal rd_mem: std_logic_vector(4 downto 0);
    signal rd_wb: std_logic_vector(4 downto 0);
    
    
    -- Risc-v version  
    
    -- Retrieves the rs1 field from the instruction

    alias rs1_id: std_logic_vector(4 downto 0) is instruction_id(19 downto 15); 
         
    -- Retrieves the rs2 field from the instruction

    alias rs2_id: std_logic_vector(4 downto 0) is instruction_id(24 downto 20);
        
    -- Retrieves the rd field from the instruction
        
    alias rd_id: std_logic_vector(4 downto 0) is instruction_id(11 downto 7);


-- Retrieves the rs1 field from the instruction

    alias rs1_if: std_logic_vector(4 downto 0) is instruction_if(19 downto 15); 
         
    -- Retrieves the rs2 field from the instruction

    alias rs2_if: std_logic_vector(4 downto 0) is instruction_if(24 downto 20);
        
    -- Retrieves the rd field from the instruction
        
    alias rd_if: std_logic_vector(4 downto 0) is instruction_if(11 downto 7);
            

-- Retrieves the rs1 field from the instruction

    alias rs1_ex: std_logic_vector(4 downto 0) is instruction_ex(19 downto 15); 
         
    -- Retrieves the rs2 field from the instruction

    alias rs2_ex: std_logic_vector(4 downto 0) is instruction_ex(24 downto 20);
        
    -- Retrieves the rd field from the instruction
        
    alias rd_ex: std_logic_vector(4 downto 0) is instruction_ex(11 downto 7);  
            
--  Data for the alu and the register   
            
    -- signal readRegister1_stall, readRegister2_stall, readRS1, readRS2   : std_logic_vector(4 downto 0);
     signal result, readData1, readData2, ALUoperand2, ALUoperand1, mux_alu, writeData: std_logic_vector(31 downto 0);
     --signal data_1_stall, data_2_stall: std_logic_vector(31 downto 0);
--
    
     signal branch_mem, branch_ex, predict_if, predict_id , predict_ex, predict_mem: std_logic;

    constant RARS_INSTRUCTION_OFFSET    : std_logic_vector(31 downto 0) := x"00400000"; -- begining addresse of instruction in risc v
    constant RARS_DATA_OFFSET           : std_logic_vector(31 downto 0) := x"10010000"; -- begining addresse of data in risc v
    
    signal data_o : std_logic_vector(31 downto 0);
    
-- Signal to enable forward and stall     
    signal forwardRS1, forwardRS2 : std_logic_vector(1 downto 0);
    signal enable_pipeline, enable_pipeline_data, enable_pipeline_jump, reset_predict: std_logic;     
    
begin

-- This MUX enable the choice of the new pc depending on the branch signal.     
    
   ADDER_PC: incrementedPC <= STD_LOGIC_VECTOR(UNSIGNED(pc_if) + TO_UNSIGNED(4,32));
                        
   MUX_PC: new_pc <=   pc_mem when ( branch_mem /= predict_mem ) else
                       pc_predict when predict_if ='1' else
                       incrementedPC;                     
                        
                        
-- This MUX enable the forwarding of data to avoid data dependency.                        
                        
    MUX_FORWARDRS1: ALUoperand1 <=  resultalumem when forwardRS1 = "01" else
                                    writeData    when forwardRS1 = "10" else
                                    data_1_ex;
                        
    MUX_FORWARDRS2: ALUoperand2 <=  resultalumem when forwardRS2 = "01" else
                                    writeData    when forwardRS2 = "10" else
                                    mux_alu;          
 
--   MUX to choose the result between the ALU and MUL_DIV_UNIT
                          
   MUX_RESULT_EX: result_ex <=   resultat_mul when   uins_ex.instruction  =   MUL       or uins_ex.instruction  =   MULH  or 
                                                     uins_ex.instruction  =   MULHSU    or uins_ex.instruction  =   MULHU or
                                                     uins_ex.instruction  =   DIV       or uins_ex.instruction  =   DIVU  or
                                                     uins_ex.instruction  =   REMins    or uins_ex.instruction  =   REMU  else
                                 resultalu;

                     
-- MUXs to stall the pipeline and put a nop instruction in the ex stage.                                   
                        
    MUX_STALL_ENABLE_1 : uins_stall_enable.MemToReg <= uins_id.MemToReg when enable_pipeline ='1' and enable_pipeline_jump ='1' else
                         '0';
                         
    MUX_STALL_ENABLE_2 : uins_stall_enable.MemWrite <= uins_id.MemWrite when enable_pipeline ='1' and enable_pipeline_jump ='1' else
                         '0';
                         
    MUX_STALL_ENABLE_3 : uins_stall_enable.RegWrite <= uins_id.RegWrite when enable_pipeline ='1' and enable_pipeline_jump ='1' else
                         '0';
                       
    MUX_STALL_ENABLE_4 : uins_stall_enable.format <= uins_id.format when enable_pipeline ='1' and enable_pipeline_jump ='1'  else
                        I;
                         
    MUX_STALL_ENABLE_5 : uins_stall_enable.instruction <= uins_id.instruction when enable_pipeline ='1' and enable_pipeline_jump ='1' else
                        ADDI;
                                                  
 --   MUX_STALL_ENABLE_6 : enable_pipeline <= enable_pipeline_data and (branch_ex xnor predict_ex);

    MUX_STALL_ENABLE_6 : enable_pipeline <= enable_pipeline_data and
((predict_ex and branch_ex) or (not(predict_ex) and not(branch_ex)) 
or (not(branch_mem) and predict_mem) or (branch_mem and not(predict_mem)));

    PROPAGATE_PREDICTION : predict_id <=  predict_if when rising_edge(clock) and enable_pipeline_data ='1';


--    RESET_PREDICTION : reset_predict <= '1' when rising_edge(clock) and ( branch_mem /= predict_mem ) else 
--					'0';
    
    -- INSTRUCTION MEMORY PORTS
    INST_MEM_DATA_OUTPUT : inst_mem_data_o <= data_o;
    INST_MEM_ADDR_OUTPUT : inst_mem_addr_o <= pc_if;
    INST_MEM_DATA_INPUT  : instruction_if <=  inst_mem_data_i;

    -- DATA MEMORY PORTS
    DATA_MEM_DATA_OUTPUT : data_mem_data_o <= data_o;
    DATA_MEM_ADDR_OUTPUT : data_mem_addr_o <= resultalumem;
    DATA_MEM_WR_OUTPUT   : data_mem_wr_o   <= uins_mem.MemWrite;
    DATA_MEM_DATA_INPUT  : data_load_mem  <=  data_mem_data_i;

process(clock)
begin
    if rising_edge(clock) then
        if branch_mem /= predict_mem then
            reset_predict <= '1';
        else
            reset_predict <= '0';
        end if;
    end if;
end process;

  
-- The pc give the next instruction address.                
    PROGRAM_COUNTER:    entity work.RegisterNbits
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => TO_INTEGER(UNSIGNED(RARS_INSTRUCTION_OFFSET))
        )
        port map (
            clock       => clock,
            reset       => reset,
            --ce          => '1',
            ce          => enable_pipeline,
            d           => new_pc, 
            q           => pc_if
        );            
        
-- PC_calculus calcul the next pc in the ex stage if there is a J and B type instruction.    
    PC_CALCULUS:  entity work.NEW_PC
    port map(  rs1             => readData1,
               pc              => pc_ex,
               instruction     => instruction_ex,
               new_pc          => pc_cal,
               branch          => branch_ex,
               uins            => uins_ex 
            );

    -- Selects the second ALU operand
    -- MUX at the ALU input
    
    MUX_ALU_RISC_V:  entity work.MUX_ALU
    port map(  register2       => data_2_ex,
               instruction     => instruction_ex,
               data_mux        => mux_alu,
               uins            => uins_ex 
            );

     
    
    -- Selects the data to be written in the register file
    -- MUX at the data memory output
    MUX_DATA_LOAD:  entity work.MUX_LOAD
    port map(   mem_data         => data_load_wb,
                result_ALU       => resultaluwb,
                writeData        => writeData,
                uins             => uins_wb 
            );
            
    -- Selects the data to be written in the data memory
    -- MUX at the data memory input

    MUX_DATA_STORE:  entity work.MUX_STORE
    port map(   rs2             => data_store_mem,  
                data_to_mem     => data_o,                  
                uins            => uins_mem 
            );

    
    -- ALU output address the data memory
--    dataAddress <= result;
    
    
    -- Register file
    REGISTER_FILE: entity work.RegisterFile(structural)
        port map (
            clock            => clock_register,
            reset            => reset,            
            write            => uins_wb.RegWrite,            
            readRegister1    => rs1_id,    
            readRegister2    => rs2_id,
            writeRegister    => rd_wb,
            writeData        => writeData,          
            readData1        => data_1_id,        
            readData2        => data_2_id
        );
    
    
    -- Arithmetic/Logic Unit
    ALU: entity work.ALU(behavioral)
        port map (
            pc          => pc_ex,
            operand1    => ALUoperand1,
            operand2    => ALUoperand2,
            result      => resultalu,
            branch      => branch_ex,
            operation   => uins_ex.instruction
        );
    
                
        -- Registers of the different stage of the pipeline that propagate the data and the comtrol signal in the next stage in each new clock
        
        IF_ID_Register:    entity work.IF_ID_Register
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            --ce          => '1',
            ce          => enable_pipeline, 
            pc_if       => pc_if,    
            pc_id       => pc_id,
	    --predict_if => predict_if,
            --predict_id => predict_id,   
            instruction_if    => instruction_if,      
            instruction_id    => instruction_id   
        );
        
        ID_EX_Register:    entity work.ID_EX_Register
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            -- ce          => enable_pipeline,
	    ce          => '1',
            pc_ex       => pc_ex,    
            pc_id       => pc_id,
            instruction_ex    => instruction_ex,      
            instruction_id    => instruction_id,
            uins_id    => uins_stall_enable,   
            uins_ex    => uins_ex,
            --rd_ex      => rd_ex,
            --rd_stall   => rd_stall,
           data_1_id  => data_1_id,
           data_1_ex  => data_1_ex,
           data_2_id  => data_2_id,
           data_2_ex  => data_2_ex,
	   reset_predict => reset_predict,
           predict_ex => predict_ex,
           predict_id => predict_id
        );
        
        EX_MEM_Register:    entity work.EX_MEM_Register
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => '1',
            branch_mem  => branch_mem,
            branch_ex   => branch_ex,
            uins_mem    => uins_mem,      
            uins_ex     => uins_ex,
            rd_ex       => rd_ex,
            rd_mem      => rd_mem,
            resultalumem => resultalumem,
            resultaluex => result_ex,
	        data_store_ex => data_2_ex,
	        data_store_mem => data_store_mem,
            pc_cal      => pc_cal,
            pc_mem      => pc_mem,
	        reset_predict => reset_predict,
            predict_ex => predict_ex,
            predict_mem => predict_mem
        );
        
        MEM_WB_Register:    entity work.MEM_WB_Register
        generic map (
            LENGTH      => 32,
            INIT_VALUE  => PC_START_ADDRESS
        )
        port map (
            clock       => clock,
            reset       => reset,
            ce          => '1',
            uins_mem    => uins_mem,      
            uins_wb     => uins_wb,
            resultalumem => resultalumem,
            resultaluwb => resultaluwb,
            rd_wb       => rd_wb,
            rd_mem      => rd_mem,
            data_load_mem      => data_load_mem,
            data_load_wb      => data_load_wb
               
        );
      
      
-- Unit to detect jump and branch type and stall the pipeline      
       Stall_unit:    entity work.Stall_unit
       port map (
             clock  	=> clock,                 
             branch_ex 	=> branch_ex,
	     predict_ex => predict_ex,    
             enable_pipeline_jump => enable_pipeline_jump
       );

-- Forward data dependency from the mem and wb stage to the alu
       Forward_unit:   entity work.Forward_unit
       port map (
	        uins_ex => uins_ex.format,          -- check the format to enable forwarding
            RegWrite_wb => uins_wb.RegWrite,    -- forward data from alu
            RegWrite_mem => uins_mem.RegWrite,  -- forward data before wb
            rd_wb   => rd_wb,                   
            rd_mem  => rd_mem,
            rs1_ex   =>  rs1_ex,
            rs2_ex   =>  rs2_ex,
            rd_ex    =>  rd_ex,
            forwardRS1 =>  forwardRS1,          -- forward rs1 depending on the value of this signal
            forwardRS2 =>  forwardRS2           -- forward rs2 depending on the value of this signal
       );
       
 -- Unit to detect load instruction with data dependency and stall the pipeline          
       Hazard_Unit:   entity work.Hazard_Unit
       port map (
            Memread_ex => uins_ex.MemToReg, -- detect load
            rs1_id   =>  rs1_id,
            rs2_id   =>  rs2_id,
            rd_ex    =>  rd_ex,
            enable_pipeline_data => enable_pipeline_data
       );
        
-- Unit to detect load instruction with data dependency and stall the pipeline          
       Branch_predictor:   entity work.Branch_predictor
       generic map(
        SIZE      => 512     -- Size of the branch history table ( Index of the pc )
        )
        port map (
            clock       =>      clock_register,
            branch_ex   =>      branch_ex, 
            reset       =>      reset,  
            pc_if       =>      pc_if, 
            pc_ex       =>      pc_ex,
            pc_cal      =>      pc_cal,
            pc_predict  =>      pc_predict,
            predict_if  =>      predict_if
        );
        
        
        MUL_DIV_UNIT:  entity work.MUL_DIV_UNIT
        port map (
            operand1    => ALUoperand1,
            operand2    => ALUoperand2,
            result      => resultat_mul,
            operation   => uins_ex.instruction
        );
 
end structural;



   