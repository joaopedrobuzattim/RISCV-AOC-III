# RISC-V Arquitetura e Organização de Computadores III

## Executando testes

Os testes estão contidos no caminho: `RV32IM/testbench`, e podem ser executados utilizando as ferramentas Xcelium ou GHDL + GTKWave. Para cada teste contido no diretório, é preciso alterar o conteúdo dos arquivos `txt` de memória de instruções e memória de dados.

### Xcelium

Executar o comando `make run`.

### GHDL + GTKWave
Executar o comando `make run-ghdl SIM_TIME <tempo de simulacao (ns)>`. <br> Se a variável `SIM_TIME` não for informada, a simulação ocorrerá por 500ns. <br>
A forma de onda gerada pela execução do GHDL pode ser observada utilizando o GTKWave com o comando: `make gtk`.
