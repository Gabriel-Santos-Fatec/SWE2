import 'dart:async';
import '../database/db_helper.dart';
import '../models/tarefa.dart';
import '../models/engenheiro.dart';
import 'package:collection/collection.dart';

class TarefaMonitor {
  static final TarefaMonitor _instance = TarefaMonitor._internal();
  factory TarefaMonitor() => _instance;

  final DBHelper _dbHelper = DBHelper();
  Timer? _timer;

  TarefaMonitor._internal() {
    _iniciarMonitoramento(); // O monitor inicia automaticamente
  }

  /// Inicia o monitoramento e verifica as tarefas a cada 15 segundos
  void _iniciarMonitoramento() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      _verificarTarefasAtivas();
    });
  }

  /// Verifica todas as tarefas em andamento e pausa se necessário
  Future<void> _verificarTarefasAtivas() async {
    List<Tarefa> tarefas = await _dbHelper.listarTarefas();
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();
    Map<int, Engenheiro> engenheirosMap = {
      for (var eng in engenheiros) eng.id!: eng,
    };

    for (var tarefa in tarefas) {
      if (tarefa.status == "Em andamento" && tarefa.ultimoInicio != null) {
        int minutosDecorridos =
            DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;

        if (tarefa.ultimaPausa == null ||
            tarefa.ultimoInicio!.isAfter(tarefa.ultimaPausa!)) {
          tarefa.tempoTrabalhado =
              (tarefa.tempoGastoHoje) + minutosDecorridos.toDouble();
        }
      }
    }

    for (var engenheiro in engenheirosMap.values) {
      int totalTempoGastoHoje = tarefas
          .where((t) => t.idEngenheiro == engenheiro.id)
          .fold(0, (sum, tarefa) {
            int tempoAtual = tarefa.tempoGastoHoje;

            if (tarefa.status == "Em andamento" &&
                tarefa.ultimoInicio != null &&
                (tarefa.ultimaPausa == null ||
                    tarefa.ultimoInicio!.isAfter(tarefa.ultimaPausa!))) {
              int minutosDecorridos =
                  DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;
              tempoAtual += minutosDecorridos;
            }

            return sum + tempoAtual;
          });

      int cargaMaximaMinutos = (engenheiro.cargaMaxima * 60).toInt();

      if (totalTempoGastoHoje * 60 >= cargaMaximaMinutos) {
        Tarefa? tarefaAtiva = tarefas.firstWhereOrNull(
          (t) => t.idEngenheiro == engenheiro.id && t.status == "Em andamento",
        );

        if (tarefaAtiva != null) {
          await _dbHelper.pausarTarefaComTempo(tarefaAtiva.id!);
        }
      }
    }
  }
}
