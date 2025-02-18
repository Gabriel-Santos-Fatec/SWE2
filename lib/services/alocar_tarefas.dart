import '../database/db_helper.dart';
import '../models/engenheiro.dart';
import '../models/tarefa.dart';

class AlocadorTarefas {
  final DBHelper _dbHelper = DBHelper();

  Future<void> alocarTarefas() async {
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();
    List<Tarefa> tarefas = await _dbHelper.listarTarefas();

    // Ordena as tarefas por prioridade: "Alta" primeiro, "Média" e "Baixa" mescladas
    tarefas.sort((a, b) {
      if (a.prioridade == "Alta" && b.prioridade != "Alta") return -1;
      if (b.prioridade == "Alta" && a.prioridade != "Alta") return 1;
      return 0;
    });

    // Obtém os engenheiros já ocupados (com tarefa em andamento ou pausada)
    Set<int> engenheirosOcupados = await _dbHelper.buscarEngenheirosOcupados();

    // Obtém tarefas que ainda não foram alocadas
    List<Tarefa> tarefasNaoAlocadas =
        tarefas.where((t) => t.idEngenheiro == null).toList();

    // Obtém tarefas de prioridade Média ou Baixa que podem ser realocadas
    List<Tarefa> tarefasMediaBaixaAlocadas =
        tarefas
            .where(
              (t) =>
                  t.idEngenheiro != null &&
                  t.status == "Pendente" &&
                  t.prioridade != "Alta",
            )
            .toList();

    // **REALOCA ENGENHEIROS PARA TAREFAS DE PRIORIDADE ALTA**
    for (Tarefa tarefaAlta in tarefas.where(
      (t) => t.prioridade == "Alta" && t.idEngenheiro == null,
    )) {
      if (tarefasMediaBaixaAlocadas.isNotEmpty) {
        Tarefa tarefaAntiga = tarefasMediaBaixaAlocadas.removeAt(0);
        int engenheiroId = tarefaAntiga.idEngenheiro!;

        // Desvincula o engenheiro da tarefa de prioridade menor
        await _dbHelper.desvincularEngenheiroDaTarefa(tarefaAntiga.id!);

        // Aloca o engenheiro na tarefa de prioridade Alta
        await _dbHelper.alocarTarefa(tarefaAlta.id!, engenheiroId);

        // Atualiza a lista de engenheiros ocupados
        engenheirosOcupados.add(engenheiroId);
      }
    }

    // **ALOCAR ENGENHEIROS DISPONÍVEIS NAS TAREFAS RESTANTES**
    List<Engenheiro> engenheirosDisponiveis =
        engenheiros.where((e) => !engenheirosOcupados.contains(e.id!)).toList();

    for (Tarefa tarefa in tarefasNaoAlocadas) {
      if (engenheirosDisponiveis.isEmpty) break;

      // Ordena engenheiros pelo menor número de tarefas atribuídas
      engenheirosDisponiveis.sort((a, b) => a.id!.compareTo(b.id!));

      Engenheiro engenheiro = engenheirosDisponiveis.removeAt(0);

      // Aloca a tarefa para o engenheiro e remove ele da lista de disponíveis
      await _dbHelper.alocarTarefa(tarefa.id!, engenheiro.id!);
      engenheirosOcupados.add(engenheiro.id!);
    }
  }
}
