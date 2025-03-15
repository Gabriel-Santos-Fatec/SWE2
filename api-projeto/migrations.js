const pool = require("./db");

const criarTabelas = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS Engenheiros (
                Id SERIAL PRIMARY KEY,
                Nome TEXT NOT NULL,
                CargaMaxima INTEGER NOT NULL,
                Eficiencia REAL NOT NULL
            );
            
            CREATE TABLE IF NOT EXISTS Tarefas (
                Id SERIAL PRIMARY KEY,
                Nome TEXT NOT NULL,
                Prioridade TEXT NOT NULL,
                Tempo INTEGER NOT NULL,
                Status TEXT DEFAULT 'Pendente',
                Inicio TIMESTAMP,
                Conclusao TIMESTAMP,
                IdEngenheiro INTEGER REFERENCES Engenheiros(Id) ON DELETE SET NULL,
                TempoTrabalhado REAL DEFAULT 0,
                UltimaPausa TIMESTAMP,
                UltimoInicio TIMESTAMP,
                TempoGasto INTEGER DEFAULT 0,
                DataUltimaAtualizacao TIMESTAMP
            );
        `);

        console.log("Tabelas criadas e alteradas com sucesso");
        pool.end();
    } catch (error) {
        console.error("Erro ao criar/alterar tabelas:", error);
        pool.end();
    }
};

criarTabelas();
