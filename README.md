# Projeto Flutter com SQLite

Este projeto é um aplicativo desenvolvido em Flutter que utiliza o banco de dados SQLite para gerenciamento de engenheiros e tarefas. Ele permite cadastrar engenheiros, criar e atualizar tarefas e acompanhar o tempo trabalhado.

## Requisitos
- Flutter instalado
- SQLite configurado
- Dependências do projeto instaladas

## Como Executar
1. Clone o repositório:
   git clone git clone -b development https://github.com/Gabriel-Santos-Fatec/SWE2.git
   
2. Acesse o diretório do projeto:
   cd seuprojeto

3. Instale as dependências necessárias:
   flutter pub get

4. Execute o aplicativo em um dispositivo ou emulador:
   flutter run


## Estrutura do Banco de Dados
O banco de dados possui as seguintes tabelas:
- **Engenheiros**: Armazena informações dos engenheiros, incluindo nome, carga máxima e eficiência.
- **Tarefas**: Contém informações sobre as tarefas, como nome, prioridade, tempo estimado, status e o engenheiro responsável.

## Funcionalidades
- Cadastro e gerenciamento de engenheiros
- Criação, atualização e exclusão de tarefas
- Alocação de tarefas para engenheiros
- Registro do tempo trabalhado por tarefa
- Persistência dos dados com SQLite
