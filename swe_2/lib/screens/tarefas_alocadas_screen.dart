// ignore_for_file: deprecated_member_use

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

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
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
        if (tarefa.status == "Em andamento" && tarefa.inicio != null) {
          Duration tempoDecorrido = DateTime.now().difference(tarefa.inicio!);
          double tempoAtual = tempoDecorrido.inMinutes / 60.0;

          tarefa.tempoTrabalhado = tempoAtual;
        }
      }
    });

    for (var engenheiro in _engenheiros.values) {
      double horasTrabalhadasHoje = await _dbHelper
          .obterTempoTotalTrabalhadoHoje(engenheiro.id!);

      double tempoAtivoEngenheiro = _tarefas
          .where(
            (tarefa) =>
                tarefa.idEngenheiro == engenheiro.id &&
                tarefa.status == "Em andamento",
          )
          .fold(0.0, (sum, tarefa) => sum + (tarefa.tempoTrabalhado ?? 0));

      double cargaTotal = horasTrabalhadasHoje + tempoAtivoEngenheiro;

      if (cargaTotal >= engenheiro.cargaMaxima) {
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
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Engenheiro atingiu a carga máxima diária!")),
      );
      return;
    }

    tarefa.inicio ??= DateTime.now();

    await _dbHelper.iniciarTarefa(id);
    _carregarTarefas();
  }

  void _concluirTarefa(int id) async {
    await _dbHelper.concluirTarefa(id);
    _carregarTarefas();
  }

  void _pausarTarefa(int id) async {
    final tarefa = _tarefas.firstWhere((t) => t.id == id);

    if (tarefa.inicio != null) {
      Duration tempoDecorrido = DateTime.now().difference(tarefa.inicio!);
      double tempoAtual = tempoDecorrido.inMinutes / 60.0;

      double novoTempoTrabalhado = tempoAtual;

      await _dbHelper.pausarTarefaComTempo(id, novoTempoTrabalhado);

      setState(() {
        tarefa.tempoTrabalhado = novoTempoTrabalhado;
        tarefa.status = "Pausada";
        tarefa.inicio = null;
      });

      _carregarTarefas();
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

  double _calcularTempoPrevisto(Tarefa tarefa, Engenheiro? engenheiro) {
    if (engenheiro == null) return tarefa.tempo.toDouble();

    return tarefa.tempo * (2 - engenheiro.eficiencia);
  }

  int _calcularDiasNecessarios(Tarefa tarefa, Engenheiro? engenheiro) {
    if (engenheiro == null || engenheiro.cargaMaxima <= 0) return 1;

    double tempoPrevisto = _calcularTempoPrevisto(tarefa, engenheiro);
    return (tempoPrevisto / engenheiro.cargaMaxima).ceil();
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
                  child: Center(child: Text("Nenhuma tarefa alocada")),
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

                      String tempoTrabalhado = _formatarTempoTrabalhado(
                        tarefa.tempoTrabalhado ?? 0,
                      );

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
                              Text("Tempo Trabalhado: $tempoTrabalhado"),
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
