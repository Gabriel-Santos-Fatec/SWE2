// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/tarefa.dart';
import '../models/engenheiro.dart';

class TarefasAlocadasScreen extends StatefulWidget {
  const TarefasAlocadasScreen({super.key});

  @override
  _TarefasAlocadasScreenState createState() => _TarefasAlocadasScreenState();
}

class _TarefasAlocadasScreenState extends State<TarefasAlocadasScreen> {
  final String apiUrl = "http://10.0.2.2:4000";
  List<Tarefa> _tarefas = [];
  Map<int, Engenheiro> _engenheiros = {};
  bool _carregando = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _alocarETrazerTarefas();

    // Atualiza a cada 60 segundos
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _carregarTarefas();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Chama a API para alocar tarefas e depois carrega a lista
  Future<void> _alocarETrazerTarefas() async {
    await _alocarTarefas();
    await _carregarTarefas();
  }

  // Chama a API para alocar tarefas
  Future<void> _alocarTarefas() async {
    try {
      final response = await http.post(Uri.parse("$apiUrl/alocar/alocar"));

      if (response.statusCode == 200) {
        print("Tarefas alocadas com sucesso");
      } else {
        print("Erro ao alocar tarefas: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro na alocação de tarefas: $e");
    }
  }

  // Carrega as tarefas e os engenheiros da API
  Future<void> _carregarTarefas() async {
    setState(() {
      _carregando = true;
    });

    try {
      final responseTarefas = await http.get(Uri.parse("$apiUrl/tarefas"));
      final responseEngenheiros = await http.get(
        Uri.parse("$apiUrl/engenheiros"),
      );

      if (responseTarefas.statusCode == 200 &&
          responseEngenheiros.statusCode == 200) {
        List<dynamic> tarefasData = jsonDecode(responseTarefas.body);
        List<dynamic> engenheirosData = jsonDecode(responseEngenheiros.body);

        setState(() {
          _tarefas = tarefasData.map((e) => Tarefa.fromMap(e)).toList();
          _engenheiros = {
            for (var e in engenheirosData) e["id"]: Engenheiro.fromMap(e),
          };
        });
      }
    } catch (e) {
      print("Erro ao carregar tarefas e engenheiros: $e");
    }

    setState(() {
      _carregando = false;
    });
  }

  // Inicia uma tarefa pela API
  Future<void> _iniciarTarefa(int id) async {
    final response = await http.put(Uri.parse("$apiUrl/tarefas/$id/iniciar"));

    if (response.statusCode == 200) {
      _carregarTarefas();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("O engenheiro atingiu a carga máxima diária!"),
        ),
      );
    }
  }

  // Pausa uma tarefa pela API
  Future<void> _pausarTarefa(int id) async {
    final response = await http.put(Uri.parse("$apiUrl/tarefas/$id/pausar"));

    if (response.statusCode == 200) {
      _carregarTarefas();
    } else {
      print("Erro ao pausar tarefa: ${response.body}");
    }
  }

  // Conclui uma tarefa pela API
  Future<void> _concluirTarefa(int id) async {
    final response = await http.put(Uri.parse("$apiUrl/tarefas/$id/concluir"));

    if (response.statusCode == 200) {
      _carregarTarefas();
    } else {
      print("Erro ao concluir tarefa: ${response.body}");
    }
  }

  // Formata a data de início
  String _formatarDataInicio(DateTime? data) {
    if (data == null) return "Não iniciado";
    return DateFormat("dd/MM/yyyy HH:mm").format(data);
  }

  // Formata a data de conclusão
  String _formatarDataConclusao(DateTime? data) {
    if (data == null) return "Não concluído";
    return DateFormat("dd/MM/yyyy HH:mm").format(data);
  }

  // Formatar tempo trabalhado
  String _formatarTempoTrabalhado(Tarefa tarefa) {
    int tempoTotal = tarefa.tempoGasto;

    if (tarefa.status == "Em andamento" && tarefa.ultimoInicio != null) {
      int minutosDecorridos =
          DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;
      tempoTotal += minutosDecorridos;
    }

    return _formatarHorasMinutos(tempoTotal);
  }

  // Formata minutos em "h min"
  String _formatarHorasMinutos(int minutos) {
    int horas = minutos ~/ 60;
    int min = minutos % 60;
    if (horas > 0 && min > 0) {
      return "$horas h $min min";
    } else if (horas > 0) {
      return "$horas h";
    } else {
      return "$min min";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gerenciar Tarefas")),
      body: Container(
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
        child:
            _carregando
                ? const Center(child: CircularProgressIndicator())
                : _tarefas.isEmpty
                ? const Center(
                  child: Text(
                    "Nenhuma tarefa alocada",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                )
                : ListView.builder(
                  itemCount: _tarefas.length,
                  itemBuilder: (context, index) {
                    Tarefa tarefa = _tarefas[index];
                    Engenheiro? engenheiro = _engenheiros[tarefa.idEngenheiro];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(
                          tarefa.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Prioridade: ${tarefa.prioridade}"),
                            Text("Status: ${tarefa.status}"),
                            Text(
                              "Engenheiro: ${engenheiro?.nome ?? 'Não alocado'}",
                            ),
                            Text(
                              "Início: ${_formatarDataInicio(tarefa.inicio)}",
                            ),
                            Text(
                              "Conclusão: ${_formatarDataConclusao(tarefa.conclusao)}",
                            ),
                            tarefa.tempoEstimado != null
                                ? Text(
                                  "Tempo estimado: ${tarefa.tempoEstimado} - ${tarefa.diasNecessarios} dias",
                                )
                                : const Center(),
                            Text(
                              "Tempo Trabalhado: ${_formatarTempoTrabalhado(tarefa)}",
                            ),
                          ],
                        ),
                        trailing: _botoesStatus(tarefa),
                      ),
                    );
                  },
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
