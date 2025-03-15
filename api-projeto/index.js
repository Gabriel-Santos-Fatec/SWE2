const express = require("express");
const cors = require("cors");
const pool = require("./db");

const app = express();
const PORT = 4000;

// Middlewares
app.use(cors());
app.use(express.json());

// Testa conexão com o banco
app.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT NOW()");
        res.json({ message: "Conexão bem-sucedida!", timestamp: result.rows[0] });
    } catch (error) {
        console.error("Erro ao conectar ao banco:", error);
        res.status(500).json({ error: "Erro ao conectar ao banco" });
    }
});

// Importando e configurando rotas
const engenheirosRoutes = require("./routes/engenheiros");
const tarefasRoutes = require("./routes/tarefas");
const alocacaoRoutes = require("./routes/alocador");

app.use("/engenheiros", engenheirosRoutes);
app.use("/tarefas", tarefasRoutes);
app.use("/alocar", alocacaoRoutes);

// Inicía o servidor
app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});

// Executa a alocação de tarefas automaticamente a cada 30 segundos
setInterval(async () => {
    try {
        await fetch(`http://localhost:${PORT}/alocar/alocar`, { method: "POST" });
    } catch (error) {
        console.error("Erro ao executar alocação automática:", error);
    }
}, 30000);
