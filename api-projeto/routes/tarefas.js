const express = require("express");
const pool = require("../db");

const router = express.Router();

// Cria uma nova tarefa
router.post("/", async (req, res) => {
    try {
        const { nome, prioridade, tempo, idEngenheiro, status, inicio, conclusao, tempoTrabalhado, ultimaPausa, ultimoInicio, tempoGasto, dataUltimaAtualizacao } = req.body;

        const result = await pool.query(
            `INSERT INTO tarefas (nome, prioridade, tempo, idengenheiro, status, inicio, conclusao, tempotrabalhado, ultimapausa, ultimoinicio, tempogasto, dataultimaatualizacao)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING *`,
            [nome, prioridade, tempo, idEngenheiro || null, status, inicio, conclusao, tempoTrabalhado, ultimaPausa, ultimoInicio, tempoGasto, dataUltimaAtualizacao]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao criar tarefa:", error);
        res.status(500).json({ error: "Erro ao criar tarefa" });
    }
});


// Obtém todas as tarefas
router.get("/", async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                t.*, 
                e.cargamaxima,
                e.eficiencia,
                -- Calcula o tempo estimado
                CASE 
                    WHEN e.eficiencia IS NOT NULL THEN
                        CONCAT(
                            FLOOR(((t.tempo / 60) * (2 - e.eficiencia)) + 
                            CASE 
                                WHEN ROUND((((t.tempo / 60) * (2 - e.eficiencia)) - FLOOR(((t.tempo / 60) * (2 - e.eficiencia)))) * 60) = 60 
                                THEN 1 ELSE 0 
                            END) || 'h ',
                            CASE 
                                WHEN ROUND((((t.tempo / 60) * (2 - e.eficiencia)) - FLOOR(((t.tempo / 60) * (2 - e.eficiencia)))) * 60) = 60 
                                THEN '0' ELSE ROUND((((t.tempo / 60) * (2 - e.eficiencia)) - FLOOR(((t.tempo / 60) * (2 - e.eficiencia)))) * 60) 
                            END || 'm'
                        )
                    ELSE NULL
                END AS tempoestimado,
                -- Calcula o tempo necessário para concluir a tarefa
                CASE 
                    WHEN e.cargamaxima IS NOT NULL AND e.cargamaxima > 0 
                    THEN CEIL(((t.tempo / 60) * (2 - e.eficiencia)) / e.cargamaxima)
                    ELSE NULL
                END AS diasnecessarios
            FROM tarefas t
            LEFT JOIN engenheiros e ON t.idengenheiro = e.id
            ORDER BY t.nome
        `);

        res.json(result.rows);
    } catch (error) {
        console.error("Erro ao buscar tarefas:", error);
        res.status(500).json({ error: "Erro ao buscar tarefas" });
    }
});


// Obtém uma tarefa por ID
router.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("SELECT * FROM tarefas WHERE id = $1", [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao buscar tarefa:", error);
        res.status(500).json({ error: "Erro ao buscar tarefa" });
    }
});

// Atualiza uma tarefa
router.put("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { nome, prioridade, tempo, status, inicio, conclusao, idEngenheiro, tempoTrabalhado, ultimaPausa, ultimoInicio, tempoGasto, dataUltimaAtualizacao } = req.body;

        // Verifica se a tarefa existe
        const tarefaExiste = await pool.query("SELECT * FROM tarefas WHERE id = $1", [id]);
        if (tarefaExiste.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        const result = await pool.query(
            `UPDATE tarefas 
             SET nome = $1, prioridade = $2, tempo = $3, status = $4, inicio = $5, conclusao = $6, 
                 idengenheiro = $7, tempotrabalhado = $8, ultimapausa = $9, ultimoinicio = $10, 
                 tempogasto = $11, dataultimaatualizacao = $12
             WHERE id = $13 RETURNING *`,
            [nome, prioridade, tempo, status, inicio, conclusao, idEngenheiro || null, tempoTrabalhado, ultimaPausa, ultimoInicio, tempoGasto, dataUltimaAtualizacao, id]
        );

        res.json(result.rows[0]);
    } catch (error) {
        console.error("Erro ao atualizar tarefa:", error);
        res.status(500).json({ error: "Erro ao atualizar tarefa" });
    }
});


// Exclúi uma tarefa
router.delete("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("DELETE FROM tarefas WHERE id = $1 RETURNING *", [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        res.json({ message: "Tarefa excluída com sucesso" });
    } catch (error) {
        console.error("Erro ao excluir tarefa:", error);
        res.status(500).json({ error: "Erro ao excluir tarefa" });
    }
});

// Inicía uma tarefa
router.put("/:id/iniciar", async (req, res) => {
    const { id } = req.params;

    try {
        const tarefa = await pool.query("SELECT * FROM tarefas WHERE id = $1", [id]);

        if (tarefa.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        const { idengenheiro, status } = tarefa.rows[0];

        if (status === "Em andamento") {
            return res.status(400).json({ error: "A tarefa já está em andamento" });
        }

        if (!idengenheiro) {
            return res.status(400).json({ error: "A tarefa não possui engenheiro alocado" });
        }

        // Busca carga máxima e tempo gasto hoje do engenheiro
        const engenheiroResult = await pool.query("SELECT cargamaxima, tempogastohoje FROM engenheiros WHERE id = $1", [idengenheiro]);
        if (engenheiroResult.rows.length === 0) {
            return res.status(404).json({ error: "Engenheiro não encontrado" });
        }

        const cargaMaximaMinutos = engenheiroResult.rows[0].cargamaxima * 60;
        let tempoGastoHoje = engenheiroResult.rows[0].tempogastohoje;

        if (tempoGastoHoje >= cargaMaximaMinutos) {
            return res.status(400).json({ error: "O engenheiro atingiu a carga máxima diária" });
        }

        const agora = new Date();
        const dataFormatada = new Date(agora.getTime() - (agora.getTimezoneOffset() * 60000)).toISOString();

        await pool.query(`
            UPDATE tarefas 
            SET status = 'Em andamento', 
                inicio = COALESCE(inicio, $1),
                ultimoinicio = $1,
                ultimapausa = NULL
            WHERE id = $2
        `, [dataFormatada, id]);

        res.json({ message: "Tarefa iniciada com sucesso!" });
    } catch (error) {
        console.error("Erro ao iniciar tarefa:", error.message);
        res.status(500).json({ error: "Erro ao iniciar tarefa" });
    }
});

// Pausa uma tarefa
router.put("/:id/pausar", async (req, res) => {
    const { id } = req.params;

    try {
        const tarefa = await pool.query("SELECT * FROM tarefas WHERE id = $1", [id]);

        if (tarefa.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        const { idengenheiro, ultimoinicio, tempogasto } = tarefa.rows[0];

        if (!ultimoinicio) {
            return res.status(400).json({ error: "A tarefa não estava em andamento" });
        }

        const agora = new Date();
        const minutosDecorridos = Math.floor((agora - new Date(ultimoinicio)) / 60000);
        const tempoGastoAtualizado = (tempogasto || 0) + minutosDecorridos;

        //  Atualiza `tempogastohoje` do engenheiro
        await pool.query(`
            UPDATE engenheiros
            SET tempogastohoje = tempogastohoje + $1
            WHERE id = $2
        `, [minutosDecorridos, idengenheiro]);

        // Atualiza `tempogasto` da tarefa corretamente (corrigido)
        await pool.query(`
            UPDATE tarefas 
            SET status = 'Pausada', 
                ultimapausa = $1, 
                tempogasto = $2, 
                ultimoinicio = NULL
            WHERE id = $3
        `, [agora, tempoGastoAtualizado, id]);

        res.json({ message: "Tarefa pausada com sucesso!" });
    } catch (error) {
        console.error("Erro ao pausar tarefa:", error.message);
        res.status(500).json({ error: "Erro ao pausar tarefa" });
    }
});

// Conclúi uma tarefa
router.put("/:id/concluir", async (req, res) => {
    const { id } = req.params;

    try {
        const tarefa = await pool.query("SELECT * FROM tarefas WHERE id = $1", [id]);
        if (tarefa.rows.length === 0) {
            return res.status(404).json({ error: "Tarefa não encontrada" });
        }

        const { idengenheiro, ultimoinicio, tempogasto } = tarefa.rows[0];

        if (!ultimoinicio) {
            return res.status(400).json({ error: "A tarefa não estava em andamento" });
        }

        const agora = new Date();
        const minutosDecorridos = Math.floor((agora - new Date(ultimoinicio)) / 60000);
        const tempoGastoAtualizado = (tempogasto || 0) + minutosDecorridos;

        // Atualiza `tempogastohoje` do engenheiro
        await pool.query(`
            UPDATE engenheiros
            SET tempogastohoje = tempogastohoje + $1
            WHERE id = $2
        `, [minutosDecorridos, idengenheiro]);

        // Atualiza `tempogasto` da tarefa
        await pool.query(`
            UPDATE tarefas 
            SET status = 'Concluída', 
                conclusao = $1, 
                tempogasto = $2, 
                ultimoinicio = NULL
            WHERE id = $3
        `, [agora, tempoGastoAtualizado, id]);

        res.json({ message: "Tarefa concluída com sucesso!" });
    } catch (error) {
        console.error("Erro ao concluir tarefa:", error.message);
        res.status(500).json({ error: "Erro ao concluir tarefa" });
    }
});


module.exports = router;
