// ignore_for_file: library_private_types_in_public_api

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

    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Obtenção de dados
  Future<void> _carregarDados() async {
    List<Engenheiro> engenheiros = await _dbHelper.listarEngenheiros();
    List<Tarefa> tarefas = await _dbHelper.listarTarefas();
    Map<int, double> horasTrabalhadas = {};
    Map<int, List<Tarefa>> tarefasEngenheiro = {};

    for (var engenheiro in engenheiros) {
      double horas = _calcularTempoTrabalhadoHoje(engenheiro, tarefas);
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

  // Calcula a soma de `tempoGastoHoje` das tarefas do engenheiro.
  double _calcularTempoTrabalhadoHoje(
    Engenheiro engenheiro,
    List<Tarefa> tarefas,
  ) {
    double totalMinutos = 0;

    for (var tarefa in tarefas.where((t) => t.idEngenheiro == engenheiro.id)) {
      double minutosGastosHoje = tarefa.tempoGastoHoje.toDouble();

      if (tarefa.status == "Em andamento" &&
          tarefa.ultimoInicio != null &&
          (tarefa.ultimaPausa == null ||
              tarefa.ultimoInicio!.isAfter(tarefa.ultimaPausa!))) {
        int minutosDecorridos =
            DateTime.now().difference(tarefa.ultimoInicio!).inMinutes;
        minutosGastosHoje += minutosDecorridos;
      }

      totalMinutos += minutosGastosHoje;
    }

    return totalMinutos / 60; // Converte minutos para horas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Progresso dos Engenheiros")),
      body:
          _engenheiros.isEmpty
              ? Container(
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
                child: Center(child: Text("Nenhum engenheiro encontrado")),
              )
              : Container(
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
                  itemCount: _engenheiros.length,
                  itemBuilder: (context, index) {
                    return _construirCardEngenheiro(_engenheiros[index]);
                  },
                ),
              ),
    );
  }

  Widget _construirCardEngenheiro(Engenheiro engenheiro) {
    double horasTrabalhadas = _horasTrabalhadas[engenheiro.id!] ?? 0;
    double horasRestantes = engenheiro.cargaMaxima - horasTrabalhadas;
    if (horasRestantes < 0) horasRestantes = 0;

    return Card(
      margin: EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              engenheiro.nome,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _construirGraficoCircular(horasTrabalhadas, horasRestantes),
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
                        "trabalhados\nhoje",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                )
                : Text(
                  "Faltam ${_formatarHorasMinutos(horasRestantes)} para atingir o limite diário",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
            SizedBox(height: 10),
            Divider(),
            Text(
              "Tarefas atribuídas:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            _construirListaTarefas(engenheiro),
          ],
        ),
      ),
    );
  }

  Widget _construirListaTarefas(Engenheiro engenheiro) {
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _construirLinhaInfo(tarefa.nome, true),
                _construirLinhaInfo("Status: ${tarefa.status}", false),
                _construirLinhaInfo(
                  "Tempo da Tarefa: ${_formatarHorasMinutos(tarefa.tempo.toDouble())}",
                  false,
                ),
                _construirLinhaInfo(
                  "Estimado com eficiência: ${_formatarHorasMinutos(tempoEstimado)}",
                  false,
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _construirLinhaInfo(String texto, bool negrito) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: !negrito ? Colors.white : Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 14,
                fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
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

  Widget _construirGraficoCircular(
    double horasTrabalhadas,
    double horasRestantes,
  ) {
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
