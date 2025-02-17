import '../database/db_helper.dart';
import '../models/engenheiro.dart';
import '../models/tarefa.dart';

class AlocadorTarefas {
  final DBHelper _dbHelper = DBHelper();

  Future<void> alocarTarefas() async {
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();
    List<Tarefa> tarefas = await _dbHelper.listarTarefas();

    // Ordena tarefas por prioridade (Alta → Média → Baixa)
    tarefas.sort((a, b) {
      Map<String, int> prioridadeMap = {"Alta": 1, "Média": 2, "Baixa": 3};
      return prioridadeMap[a.prioridade]!.compareTo(
        prioridadeMap[b.prioridade]!,
      );
    });

    // Obtém a contagem real de tarefas já alocadas por engenheiro
    Map<int, int> contagemTarefas = await _contarTarefasPorEngenheiro(
      engenheiros,
    );

    // Obtém a lista de engenheiros que já estão ocupados em tarefas pendentes, em andamento ou pausadas
    Set<int> engenheirosOcupados = await _buscarEngenheirosOcupados();

    // Mapa para contar a carga diária dos engenheiros (inicia com 0)
    Map<int, double> cargaDiaria = {for (var eng in engenheiros) eng.id!: 0.0};

    // Obtém tarefas que ainda precisam ser alocadas
    List<Tarefa> tarefasNaoAlocadas =
        tarefas.where((t) => t.idEngenheiro == null).toList();

    // Inicia a alocação das tarefas
    for (Tarefa tarefa in tarefasNaoAlocadas) {
      bool tarefaAlocada = false;

      while (!tarefaAlocada) {
        // Filtra engenheiros disponíveis (não podem estar em tarefas pendentes, em andamento ou pausadas)
        List<Engenheiro> engenheirosDisponiveis =
            engenheiros.where((e) {
              return !engenheirosOcupados.contains(e.id!) &&
                  (cargaDiaria[e.id!] ?? 0.0) < 8.0;
            }).toList();

        // Ordena engenheiros pelo menor número de tarefas e menor carga de trabalho
        engenheirosDisponiveis.sort((a, b) {
          int totalA = contagemTarefas[a.id!] ?? 0;
          int totalB = contagemTarefas[b.id!] ?? 0;

          int comparacaoTarefas = totalA.compareTo(totalB);
          if (comparacaoTarefas != 0) return comparacaoTarefas;
          return (cargaDiaria[a.id!] ?? 0.0).compareTo(
            cargaDiaria[b.id!] ?? 0.0,
          );
        });

        if (engenheirosDisponiveis.isEmpty) break;

        for (Engenheiro engenheiro in engenheirosDisponiveis) {
          // Ajusta o tempo da tarefa pela eficiência do engenheiro
          double tempoAjustado =
              tarefa.tempo /
              (engenheiro.eficiencia == 0 ? 1 : engenheiro.eficiencia);
          double tempoDisponivel = 8.0 - (cargaDiaria[engenheiro.id!] ?? 0.0);

          if (tempoAjustado <= tempoDisponivel) {
            // Se a tarefa couber dentro das 8h disponíveis, aloca tudo
            cargaDiaria[engenheiro.id!] =
                (cargaDiaria[engenheiro.id!] ?? 0.0) + tempoAjustado;
            contagemTarefas[engenheiro.id!] =
                (contagemTarefas[engenheiro.id!] ?? 0) + 1;

            await _dbHelper.alocarTarefa(tarefa.id!, engenheiro.id!);
            tarefaAlocada = true;
            break;
          } else {
            // Se a tarefa exceder as 8h, aloca o máximo possível e divide o restante
            cargaDiaria[engenheiro.id!] = 8.0;
            tarefa.tempo -= (tempoDisponivel * engenheiro.eficiencia).toInt();
            await _dbHelper.alocarTarefa(tarefa.id!, engenheiro.id!);
            contagemTarefas[engenheiro.id!] =
                (contagemTarefas[engenheiro.id!] ?? 0) + 1;
          }
        }
      }
    }
  }

  // **Obtém os engenheiros que já estão ocupados com tarefas pendentes, em andamento ou pausadas**
  Future<Set<int>> _buscarEngenheirosOcupados() async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> resultados = await db.rawQuery('''
      SELECT DISTINCT IdEngenheiro 
      FROM Tarefas 
      WHERE Status IN ('Pendente', 'Em andamento', 'Pausada')
    ''');

    return resultados
        .where((row) => row['IdEngenheiro'] != null)
        .map((row) => row['IdEngenheiro'] as int)
        .toSet();
  }

  // **Obtém a contagem de tarefas alocadas por engenheiro diretamente do banco**
  Future<Map<int, int>> _contarTarefasPorEngenheiro(
    List<Engenheiro> engenheiros,
  ) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> resultados = await db.rawQuery('''
      SELECT IdEngenheiro, COUNT(*) as TotalTarefas
      FROM Tarefas
      WHERE IdEngenheiro IS NOT NULL
      GROUP BY IdEngenheiro
    ''');

    // Converte o resultado para um mapa de ID do engenheiro → Número de tarefas
    Map<int, int> contagem = {for (var eng in engenheiros) eng.id!: 0};

    for (var row in resultados) {
      contagem[row['IdEngenheiro'] as int] = row['TotalTarefas'] as int;
    }

    return contagem;
  }
}
