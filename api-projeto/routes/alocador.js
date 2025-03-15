const express = require("express");
const pool = require("../db");
const axios = require("axios");

const router = express.Router();
const API_URL = "http://localhost:4000";

// Função para alocar tarefas automaticamente
router.post("/alocar", async (req, res) => {
    try {
        console.log("⏳ Executando alocação automática de tarefas...");

        // Busca engenheiros e tarefas do banco
        const engenheirosResult = await pool.query("SELECT * FROM engenheiros");
        const tarefasResult = await pool.query("SELECT * FROM tarefas");

        let engenheiros = engenheirosResult.rows;
        let tarefas = tarefasResult.rows;

        // Ordena tarefas por prioridade (Alta primeiro)
        tarefas.sort((a, b) => {
            if (a.prioridade === "Alta" && b.prioridade !== "Alta") return -1;
            if (b.prioridade === "Alta" && a.prioridade !== "Alta") return 1;
            return 0;
        });

        // Busca engenheiros que não estão disponíveis
        const engenheirosOcupadosResult = await pool.query(`
            SELECT DISTINCT idengenheiro 
            FROM tarefas 
            WHERE idengenheiro IS NOT NULL 
            AND status NOT IN ('Concluída')  
        `);
        let engenheirosOcupados = new Set(engenheirosOcupadosResult.rows.map(row => row.idengenheiro));

        // Remove engenheiros que só têm tarefas concluídas
        const engenheirosComApenasTarefasConcluidas = await pool.query(`
            SELECT idengenheiro 
            FROM tarefas 
            WHERE idengenheiro IS NOT NULL 
            GROUP BY idengenheiro 
            HAVING BOOL_AND(status = 'Concluída')  
        `);

        for (let row of engenheirosComApenasTarefasConcluidas.rows) {
            engenheirosOcupados.delete(row.idengenheiro);
        }

        // Filtrar tarefas sem engenheiro
        let tarefasNaoAlocadas = tarefas.filter(t => !t.idengenheiro);

        // Tarefas de prioridade Média/Baixa que podem ser realocadas
        let tarefasMediaBaixaAlocadas = tarefas.filter(
            t => t.idengenheiro && t.status === "Pendente" && t.prioridade !== "Alta"
        );

        // Realoca engenheiros para tarefas de prioridade alta
        for (let tarefaAlta of tarefas.filter(t => t.prioridade === "Alta" && !t.idengenheiro)) {
            if (tarefasMediaBaixaAlocadas.length > 0) {
                let tarefaAntiga = tarefasMediaBaixaAlocadas.shift();
                let engenheiroId = tarefaAntiga.idengenheiro;

                if (!engenheirosOcupados.has(engenheiroId)) {
                    await pool.query("UPDATE tarefas SET idengenheiro = NULL WHERE id = $1", [tarefaAntiga.id]);
                    await pool.query("UPDATE tarefas SET idengenheiro = $1 WHERE id = $2", [engenheiroId, tarefaAlta.id]);
                    engenheirosOcupados.add(engenheiroId);
                }
            }
        }

        // Aloca engenheiros disponíveis nas tarefas restantes
        let engenheirosDisponiveis = engenheiros.filter(e => !engenheirosOcupados.has(e.id));

        for (let tarefa of tarefasNaoAlocadas) {
            if (engenheirosDisponiveis.length === 0) break;

            engenheirosDisponiveis.sort((a, b) => a.id - b.id);
            let engenheiro = engenheirosDisponiveis.shift();

            if (!engenheirosOcupados.has(engenheiro.id)) {
                await pool.query("UPDATE tarefas SET idengenheiro = $1 WHERE id = $2", [engenheiro.id, tarefa.id]);
                engenheirosOcupados.add(engenheiro.id);
            }
        }

        // Pausa tarefas que ultrapassam a carga máxima diária dos engenheiros
        const tarefasAtivas = await pool.query(`
            SELECT t.id, t.idengenheiro, t.ultimoinicio, e.cargamaxima, e.tempogastohoje
            FROM tarefas t
            INNER JOIN engenheiros e ON t.idengenheiro = e.id
            WHERE t.status = 'Em andamento'
        `);

        for (let tarefa of tarefasAtivas.rows) {
            const { id, idengenheiro, ultimoinicio, cargamaxima, tempogastohoje } = tarefa;
            if (!ultimoinicio) continue;

            const hoje = new Date().toDateString();
            const dataUltimoInicio = new Date(ultimoinicio).toDateString();

            // Se `ultimoinicio` for de um dia diferente, zera `tempogastohoje`
            if (dataUltimoInicio !== hoje) {
                console.log(`Resetando tempogastohoje do engenheiro ${idengenheiro}`);
                await pool.query(`
                    UPDATE engenheiros
                    SET tempogastohoje = 0
                    WHERE id = $1
                `, [idengenheiro]);
            }

            // Busca tempo total trabalhado HOJE diretamente da tabela `Engenheiros`
            const engenheiroResult = await pool.query(`
                SELECT tempogastohoje FROM engenheiros WHERE id = $1
            `, [idengenheiro]);

            let tempoTotalHoje = engenheiroResult.rows[0].tempogastohoje;
            console.log(`tempoTotalHoje antes: ${tempoTotalHoje}`);

            // Calcula tempo desde o último início somente se ultimoinicio for de hoje
            let minutosDecorridos = 0;
            if (new Date(ultimoinicio).toDateString() === new Date().toDateString()) {
                minutosDecorridos = Math.floor((new Date() - new Date(ultimoinicio)) / 60000);
            }

            // Soma os minutos desde `ultimoinicio`
            tempoTotalHoje += minutosDecorridos;

            // Converte carga máxima para minutos
            let cargaMaximaMinutos = cargamaxima * 60;

            console.log(`🔍 Engenheiro ${idengenheiro} trabalhou ${tempoTotalHoje} minutos hoje. Carga máxima: ${cargaMaximaMinutos} minutos.`);
            console.log(`tempogastohoje (antes): ${tempogastohoje}`);
            console.log(`minutosDecorridos: ${minutosDecorridos}`);
            console.log(`tempoTotalHoje (após cálculo): ${tempoTotalHoje}`);

            if (tempoTotalHoje >= cargaMaximaMinutos) {
                try {
                    await axios.put(`${API_URL}/tarefas/${id}/pausar`);
                    console.log(`Tarefa ${id} pausada pois o engenheiro ${idengenheiro} atingiu sua carga máxima diária.`);

                    // Atualiza `tempogastohoje` do engenheiro após a pausa
                    await pool.query(`
                        UPDATE engenheiros
                        SET tempogastohoje = $1
                        WHERE id = $2
                    `, [tempoTotalHoje, idengenheiro]);

                } catch (error) {
                    console.error(`Erro ao pausar tarefa ${id}:`, error.message);
                }
            }
        }

        return res.status(200).json({ success: true, message: "Tarefas alocadas e verificadas!" });

    } catch (error) {
        console.error("Erro ao alocar tarefas:", error);
        res.status(500).json({ error: "Erro ao alocar tarefas" });
    }
});

module.exports = router;