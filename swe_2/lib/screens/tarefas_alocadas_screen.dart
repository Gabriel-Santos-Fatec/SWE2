// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/tarefa.dart';
import '../models/engenheiro.dart';
import '../services/alocar_tarefas.dart';
import 'package:intl/intl.dart';

class TarefasAlocadasScreen extends StatefulWidget {
  const TarefasAlocadasScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TarefasAlocadasScreenState createState() => _TarefasAlocadasScreenState();
}

class _TarefasAlocadasScreenState extends State<TarefasAlocadasScreen> {
  final DBHelper _dbHelper = DBHelper();
  final AlocadorTarefas _alocadorTarefas = AlocadorTarefas();
  List<Tarefa> _tarefas = [];
  Map<int, Engenheiro> _engenheiros = {};
  bool _carregando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _alocarTarefas();

    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      _atualizarTempoTarefasAtivas();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    setState(() {
      _carregando = true;
    });

    List<Tarefa> lista = await _dbHelper.listarTarefas();
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();

    Map<int, Engenheiro> engenheiroMap = {for (var e in engenheiros) e.id!: e};

    setState(() {
      _tarefas = lista;
      _engenheiros = engenheiroMap;
      _carregando = false;
    });

    _atualizarTempoTarefasAtivas();
  }

  Future<void> _alocarTarefas() async {
    setState(() {
      _carregando = true;
    });

    await _alocadorTarefas.alocarTarefas();
    await _carregarTarefas();
  }

  void _atualizarTempoTarefasAtivas() async {
    setState(() {
      for (var tarefa in _tarefas) {
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
    });

    for (var engenheiro in _engenheiros.values) {
      int totalTempoGastoHoje = _tarefas
          .where((tarefa) => tarefa.idEngenheiro == engenheiro.id)
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
        Tarefa? tarefaAtiva = _tarefas.firstWhereOrNull(
          (tarefa) =>
              tarefa.idEngenheiro == engenheiro.id &&
              tarefa.status == "Em andamento",
        );

        if (tarefaAtiva != null) {
          Future.delayed(Duration(milliseconds: 100), () {
            _pausarTarefa(tarefaAtiva.id!);
          });
        }
      }
    }
  }

  void _iniciarTarefa(int id) async {
    final tarefa = _tarefas.firstWhere((t) => t.id == id);
    final engenheiro = _engenheiros[tarefa.idEngenheiro];

    if (engenheiro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: Engenheiro não encontrado!")),
      );
      return;
    }

    double tempoTrabalhadoHoje = await _dbHelper.obterTempoTotalTrabalhadoHoje(
      engenheiro.id!,
    );

    if (tempoTrabalhadoHoje >= engenheiro.cargaMaxima) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Engenheiro atingiu a carga máxima diária!")),
      );
      return;
    }

    await _dbHelper.iniciarTarefa(id);

    setState(() {
      tarefa.status = "Em andamento";
      tarefa.ultimoInicio = DateTime.now();
      tarefa.inicio = DateTime.now();
    });
  }

  void _concluirTarefa(int id) async {
    await _dbHelper.concluirTarefa(id);

    setState(() {
      final tarefa = _tarefas.firstWhere((t) => t.id == id);
      tarefa.status = "Concluída";
      tarefa.conclusao = DateTime.now();
    });
  }

  void _pausarTarefa(int id) async {
    final tarefa = _tarefas.firstWhere((t) => t.id == id);

    if (tarefa.ultimoInicio != null) {
      await _dbHelper.pausarTarefaComTempo(id);

      setState(() {
        int minutosDecorridos =
            DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;

        tarefa.tempoGastoHoje =
            (tarefa.tempoGastoHoje ?? 0) + minutosDecorridos;
        tarefa.tempoGasto = (tarefa.tempoGasto ?? 0) + minutosDecorridos;
        tarefa.status = "Pausada";
        tarefa.ultimoInicio = null;
        tarefa.ultimaPausa = DateTime.now();
      });
    }
  }

  String _formatarDataInicio(DateTime? data) {
    if (data == null) return "Não iniciado";
    return DateFormat("dd/MM/yyyy HH:mm").format(data);
  }

  String _formatarDataConclusao(DateTime? data) {
    if (data == null) return "Não concluído";
    return DateFormat("dd/MM/yyyy HH:mm").format(data);
  }

  String _formatarTempoTrabalhado(double tempoTrabalhado) {
    int horas = tempoTrabalhado.floor();
    int minutos = ((tempoTrabalhado - horas) * 60).round();
    return "${horas}h ${minutos}min";
  }

  String _formatarTempoGasto(int minutosTotais) {
    int horas = minutosTotais ~/ 60;
    int minutos = minutosTotais % 60;

    if (horas > 0 && minutos > 0) {
      return "$horas h $minutos min";
    } else if (horas > 0) {
      return "$horas h";
    } else {
      return "$minutos min";
    }
  }

  double _calcularTempoPrevisto(Tarefa tarefa, Engenheiro? engenheiro) {
    if (engenheiro == null) return tarefa.tempo.toDouble();

    return tarefa.tempo * (2 - engenheiro.eficiencia);
  }

  int _calcularDiasNecessarios(Tarefa tarefa, Engenheiro? engenheiro) {
    if (engenheiro == null || engenheiro.cargaMaxima <= 0) return 1;

    double tempoPrevisto = _calcularTempoPrevisto(tarefa, engenheiro);
    return (tempoPrevisto / engenheiro.cargaMaxima).ceil();
  }

  String _obterTempoTotalTrabalhado(Tarefa tarefa) {
    int tempoGasto = tarefa.tempoGasto;

    if (tarefa.status == "Em andamento" && tarefa.ultimoInicio != null) {
      int minutosDecorridos =
          DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;
      tempoGasto += minutosDecorridos;
    }

    return _formatarTempoGasto(tempoGasto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gerenciar Tarefas")),
      body:
          _carregando
              ? SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade400,
                        Colors.blue.shade300,
                      ],
                    ),
                  ),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
              : _tarefas.isEmpty
              ? SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade400,
                        Colors.blue.shade300,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "Nenhuma tarefa alocada",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ),
              )
              : SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade400,
                        Colors.blue.shade300,
                      ],
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _tarefas.length,
                    itemBuilder: (context, index) {
                      Tarefa tarefa = _tarefas[index];
                      Engenheiro? engenheiro =
                          _engenheiros[tarefa.idEngenheiro];

                      String engenheiroResponsavel =
                          engenheiro != null ? engenheiro.nome : "Não alocado";
                      print(tarefa.ultimaPausa);
                      print(DateTime.now().toIso8601String());
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            tarefa.nome,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Prioridade: ${tarefa.prioridade}"),
                              Text("Status: ${tarefa.status}"),
                              Text("Engenheiro: $engenheiroResponsavel"),
                              Text(
                                "Início: ${_formatarDataInicio(tarefa.inicio)}",
                              ),
                              Text(
                                "Conclusão: ${_formatarDataConclusao(tarefa.conclusao)}",
                              ),
                              Text(
                                "Tempo Previsto: ${_formatarTempoTrabalhado(_calcularTempoPrevisto(tarefa, engenheiro))} - ${_calcularDiasNecessarios(tarefa, engenheiro)} dia(s)",
                              ),
                              Text(
                                "Tempo Trabalhado: ${_obterTempoTotalTrabalhado(tarefa)}",
                              ),
                            ],
                          ),
                          trailing: _botoesStatus(tarefa),
                        ),
                      );
                    },
                  ),
                ),
              ),
    );
  }

  Widget _botoesStatus(Tarefa tarefa) {
    if (tarefa.idEngenheiro == null) {
      return SizedBox.shrink();
    } else if (tarefa.status == "Pendente") {
      return CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.2),
        child: IconButton(
          onPressed: () => _iniciarTarefa(tarefa.id!),
          icon: Icon(Icons.play_arrow, color: Colors.blue, size: 24),
        ),
      );
    } else if (tarefa.status == "Em andamento") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red.withOpacity(0.2),
            child: IconButton(
              onPressed: () => _pausarTarefa(tarefa.id!),
              icon: Icon(Icons.pause, color: Colors.red, size: 24),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green.withOpacity(0.2),
            child: IconButton(
              onPressed: () => _concluirTarefa(tarefa.id!),
              icon: Icon(
                Icons.check_circle,
                color: Colors.green.shade300,
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else if (tarefa.status == "Pausada") {
      return CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.2),
        child: IconButton(
          onPressed: () => _iniciarTarefa(tarefa.id!),
          icon: Icon(Icons.play_arrow, color: Colors.blue, size: 24),
        ),
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.2),
        child: Icon(Icons.check_circle, color: Colors.green, size: 24),
      );
    }
  }
}
