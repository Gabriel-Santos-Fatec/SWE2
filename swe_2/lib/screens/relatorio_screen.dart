import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/db_helper.dart';
import '../models/engenheiro.dart';
import '../models/tarefa.dart';

class ProgressoEngenheirosScreen extends StatefulWidget {
  const ProgressoEngenheirosScreen({super.key});

  @override
  _ProgressoEngenheirosScreenState createState() =>
      _ProgressoEngenheirosScreenState();
}

class _ProgressoEngenheirosScreenState
    extends State<ProgressoEngenheirosScreen> {
  final DBHelper _dbHelper = DBHelper();
  List<Engenheiro> _engenheiros = [];
  Map<int, double> _horasTrabalhadas = {};
  Map<int, List<Tarefa>> _tarefasEngenheiro = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarDados();

    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _carregarDados();
      _atualizarHorasTrabalhadas();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();
    List<Tarefa> tarefas = await _dbHelper.listarTarefas();
    Map<int, double> horasTrabalhadas = {};
    Map<int, List<Tarefa>> tarefasEngenheiro = {};

    for (var engenheiro in engenheiros) {
      double horas = await _dbHelper.obterTempoTotalTrabalhadoHoje(
        engenheiro.id!,
      );
      horasTrabalhadas[engenheiro.id!] = horas;
      tarefasEngenheiro[engenheiro.id!] =
          tarefas.where((t) => t.idEngenheiro == engenheiro.id).toList();
    }

    setState(() {
      _engenheiros = engenheiros;
      _horasTrabalhadas = horasTrabalhadas;
      _tarefasEngenheiro = tarefasEngenheiro;
    });
  }

  void _atualizarHorasTrabalhadas() {
    setState(() {
      for (var engenheiro in _engenheiros) {
        double totalHoras = _horasTrabalhadas[engenheiro.id!] ?? 0;

        for (var tarefa in _tarefasEngenheiro[engenheiro.id!] ?? []) {
          if (tarefa.status == "Em andamento" && tarefa.inicio != null) {
            Duration tempoDecorrido = DateTime.now().difference(tarefa.inicio!);
            totalHoras += tempoDecorrido.inMinutes / 60.0;
          }
        }

        _horasTrabalhadas[engenheiro.id!] = totalHoras;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Progresso dos Engenheiros")),
      body:
          _engenheiros.isEmpty
              ? Center(child: Text("Nenhum engenheiro encontrado"))
              : ListView.builder(
                itemCount: _engenheiros.length,
                itemBuilder: (context, index) {
                  Engenheiro engenheiro = _engenheiros[index];
                  double horasTrabalhadas =
                      _horasTrabalhadas[engenheiro.id!] ?? 0;
                  double horasRestantes =
                      engenheiro.cargaMaxima - horasTrabalhadas;

                  if (horasRestantes < 0) horasRestantes = 0;

                  return Card(
                    margin: EdgeInsets.all(10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            engenheiro.nome,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildCircularChart(
                                  horasTrabalhadas,
                                  horasRestantes,
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatarHorasMinutos(horasTrabalhadas),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "trabalhados",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          horasRestantes == 0
                              ? Text(
                                "O engenheiro atingiu o limite diário",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                              : Text(
                                "Faltam ${_formatarHorasMinutos(horasRestantes)} para atingir o limite diário",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          SizedBox(height: 10),
                          Divider(),
                          Text(
                            "Tarefas atribuídas:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          _buildListaTarefas(engenheiro),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildListaTarefas(Engenheiro engenheiro) {
    List<Tarefa> tarefas = _tarefasEngenheiro[engenheiro.id!] ?? [];

    if (tarefas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Nenhuma tarefa atribuída",
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children:
          tarefas.map((tarefa) {
            double tempoEstimado = tarefa.tempo * (2 - engenheiro.eficiencia);

            return Card(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow("Status: ${tarefa.status}"),
                    _buildInfoRow(
                      "Tempo da Tarefa: ${_formatarHorasMinutos(tarefa.tempo.toDouble())}",
                    ),
                    _buildInfoRow(
                      "Estimado com eficiência: ${_formatarHorasMinutos(tempoEstimado)}",
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.blue, // Mesma cor do gráfico
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  String _formatarHorasMinutos(double horasDecimais) {
    int horas = horasDecimais.floor();
    int minutos = ((horasDecimais - horas) * 60).round();
    if (horas > 0 && minutos > 0) {
      return "$horas h $minutos min";
    } else if (horas > 0) {
      return "$horas h";
    } else {
      return "$minutos min";
    }
  }

  Widget _buildCircularChart(double horasTrabalhadas, double horasRestantes) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            color: Colors.blue,
            value: horasTrabalhadas,
            title: "",
            radius: 30,
          ),
          PieChartSectionData(
            color: Colors.grey[300]!,
            value: horasRestantes,
            title: "",
            radius: 30,
          ),
        ],
      ),
    );
  }
}
