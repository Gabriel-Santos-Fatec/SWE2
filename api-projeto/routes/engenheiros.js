const express = require("express");
const pool = require("../db");

const router = express.Router();

// Cria um engenheiro
router.post("/", async (req, res) => {
    try {
        const { nome, cargaMaxima, eficiencia } = req.body;
        const result = await pool.query(
            "INSERT INTO engenheiros (nome, cargamaxima, eficiencia) VALUES ($1, $2, $3) RETURNING *",
            [nome, cargaMaxima, eficiencia]
        );
        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao criar engenheiro:", error);
        res.status(500).json({ error: "Erro ao criar engenheiro" });
    }
});

// Obtém todos os engenheiros
router.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM engenheiros");
        res.json(result.rows);
    } catch (error) {
        console.error("Erro ao buscar engenheiros:", error);
        res.status(500).json({ error: "Erro ao buscar engenheiros" });
    }
});

// Obtém um engenheiro por ID
router.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("SELECT * FROM engenheiros WHERE id = $1", [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Engenheiro não encontrado" });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao buscar engenheiro:", error);
        res.status(500).json({ error: "Erro ao buscar engenheiro" });
    }
});

router.put("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { nome, cargaMaxima, eficiencia } = req.body;

        // Verifica se o engenheiro existe
        const engenheiroExiste = await pool.query("SELECT * FROM engenheiros WHERE id = $1", [id]);
        if (engenheiroExiste.rows.length === 0) {
            return res.status(404).json({ error: "Engenheiro não encontrado" });
        }

        const result = await pool.query(
            "UPDATE engenheiros SET nome = $1, cargamaxima = $2, eficiencia = $3 WHERE id = $4 RETURNING *",
            [nome, cargaMaxima, eficiencia, id]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao atualizar engenheiro:", error);
        res.status(500).json({ error: "Erro ao atualizar engenheiro" });
    }
});


router.delete("/:id", async (req, res) => {
    try {
        const { id } = req.params;

        // Verifica se o engenheiro existe
        const engenheiroExiste = await pool.query("SELECT * FROM engenheiros WHERE id = $1", [id]);
        if (engenheiroExiste.rows.length === 0) {
            return res.status(404).json({ error: "Engenheiro não encontrado" });
        }

        // Busca todas as tarefas associadas ao engenheiro
        const tarefas = await pool.query("SELECT * FROM tarefas WHERE idengenheiro = $1", [id]);

        for (const tarefa of tarefas.rows) {
            // Se a tarefa estiver em andamento ou pausada, mudar status para "Pendente"
            if (["Em andamento", "Pausada"].includes(tarefa.status)) {
                await pool.query("UPDATE tarefas SET status = 'Pendente' WHERE id = $1", [tarefa.id]);
            }

            // Remove engenheiro da tarefa e zera tempo gasto hoje
            await pool.query(
                "UPDATE tarefas SET idengenheiro = NULL, tempogastohoje = 0 WHERE id = $1",
                [tarefa.id]
            );
        }

        // Exclúi engenheiro
        await pool.query("DELETE FROM engenheiros WHERE id = $1", [id]);

        res.json({ message: "Engenheiro excluído com sucesso" });
    } catch (error) {
        console.error("Erro ao excluir engenheiro:", error);
        res.status(500).json({ error: "Erro ao excluir engenheiro" });
    }
});


module.exports = router;
