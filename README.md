# Projeto Flutter com API Node.js

Este projeto é um aplicativo desenvolvido em Flutter que consome uma API Node.js para gerenciamento de engenheiros e tarefas. Ele permite cadastrar engenheiros, criar e atualizar tarefas e acompanhar o tempo trabalhado.

## Requisitos
- Flutter instalado
- Node.js e PostgreSQL configurados
- Dependências do projeto instaladas

## Como Executar
1. Clone o repositório:
   git clone -b development https://github.com/Gabriel-Santos-Fatec/SWE2.git
   
2. Acesse o diretório do projeto:
   cd SWE2

3. Configure e inicie a API:
   cd api
   npm install
   npm start

4. Volte ao diretório do Flutter, instale as dependências e execute o app:
   cd ..
   flutter pub get
   flutter run

## Estrutura do Banco de Dados
O banco de dados possui as seguintes tabelas:
- **Engenheiros**: Armazena informações dos engenheiros, incluindo nome, carga máxima, eficiência e tempo gasto hoje.
- **Tarefas**: Contém informações sobre as tarefas, como nome, prioridade, tempo estimado, status e o engenheiro responsável.

## Funcionalidades
- Cadastro e gerenciamento de engenheiros
- Criação, atualização e exclusão de tarefas
- Alocação automática de tarefas
- Registro do tempo trabalhado por tarefa
- Comunicação com API Node.js e PostgreSQL
