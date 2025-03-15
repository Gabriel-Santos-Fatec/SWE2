// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

class ProgressoEngenheirosScreen extends StatefulWidget {
  const ProgressoEngenheirosScreen({super.key});

  @override
  _ProgressoEngenheirosScreenState createState() =>
      _ProgressoEngenheirosScreenState();
}

class _ProgressoEngenheirosScreenState
    extends State<ProgressoEngenheirosScreen> {
  final String apiUrl = "http://10.0.2.2:4000";
  List<Map<String, dynamic>> _engenheiros = [];
  Map<int, double> _horasTrabalhadas = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarDados();

    // Atualiza os dados a cada minuto
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Obtenção de dados da API
  Future<void> _carregarDados() async {
    try {
      final responseEngenheiros = await http.get(
        Uri.parse("$apiUrl/engenheiros"),
      );
      final responseTarefas = await http.get(Uri.parse("$apiUrl/tarefas"));

      if (responseEngenheiros.statusCode == 200 &&
          responseTarefas.statusCode == 200) {
        List<dynamic> engenheiros = jsonDecode(responseEngenheiros.body);
        List<dynamic> tarefas = jsonDecode(responseTarefas.body);

        Map<int, double> horasTrabalhadas = {};

        for (var engenheiro in engenheiros) {
          int idEngenheiro = engenheiro["id"];
          double horas = _calcularTempoTrabalhadoHoje(engenheiro, tarefas);
          horasTrabalhadas[idEngenheiro] = horas;
        }

        setState(() {
          _engenheiros = List<Map<String, dynamic>>.from(engenheiros);
          _horasTrabalhadas = horasTrabalhadas;
        });
      }
    } catch (error) {
      print("Erro ao carregar dados: $error");
    }
  }

  // Calcula `tempogastohoje`
  double _calcularTempoTrabalhadoHoje(
    Map<String, dynamic> engenheiro,
    List<dynamic> tarefas,
  ) {
    double tempoGastoHoje = (engenheiro["tempogastohoje"] ?? 0).toDouble();
    DateTime agora = DateTime.now();

    // Verifica tarefas em andamento para somar tempo decorrido
    for (var tarefa in tarefas.where(
      (t) =>
          t["idengenheiro"] == engenheiro["id"] &&
          t["status"] == "Em andamento",
    )) {
      if (tarefa["ultimoinicio"] != null) {
        DateTime ultimoInicio = DateTime.parse(tarefa["ultimoinicio"]);

        // Apenas considera tarefas iniciadas no mesmo dia
        if (ultimoInicio.day == agora.day &&
            ultimoInicio.month == agora.month &&
            ultimoInicio.year == agora.year) {
          int minutosDecorridos = agora.difference(ultimoInicio).inMinutes;
          tempoGastoHoje += minutosDecorridos;
        }
      }
    }

    return tempoGastoHoje / 60.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Progresso dos Engenheiros")),
      body:
          _engenheiros.isEmpty
              ? _buildSemEngenheiros()
              : _buildListaEngenheiros(),
    );
  }

  // Layout quando não há engenheiros cadastrados
  Widget _buildSemEngenheiros() {
    return Container(
      decoration: _buildGradiente(),
      child: const Center(
        child: Text(
          "Nenhum engenheiro encontrado",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Lista de engenheiros
  Widget _buildListaEngenheiros() {
    return Container(
      decoration: _buildGradiente(),
      child: ListView.builder(
        itemCount: _engenheiros.length,
        itemBuilder: (context, index) {
          return _construirCardEngenheiro(_engenheiros[index]);
        },
      ),
    );
  }

  // Card de cada engenheiro
  Widget _construirCardEngenheiro(Map<String, dynamic> engenheiro) {
    int idEngenheiro = engenheiro["id"];
    double horasTrabalhadas = _horasTrabalhadas[idEngenheiro] ?? 0;
    double horasRestantes = engenheiro["cargamaxima"] - horasTrabalhadas;
    if (horasRestantes < 0) horasRestantes = 0;

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              engenheiro["nome"],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
                        style: const TextStyle(
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
            const SizedBox(height: 10),
            horasRestantes == 0
                ? const Text(
                  "O engenheiro atingiu o limite diário",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                )
                : Text(
                  "Faltam ${_formatarHorasMinutos(horasRestantes)} para atingir o limite diário",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Formata horas decimais para "X h Y min"
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

  // Constrói o gráfico circular (sem exibir valores)
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
            radius: 30,
            title: "",
          ),
          PieChartSectionData(
            color: Colors.grey[300]!,
            value: horasRestantes,
            radius: 30,
            title: "",
          ),
        ],
      ),
    );
  }

  // Define o gradiente de fundo
  BoxDecoration _buildGradiente() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade700,
          Colors.blue.shade400,
          Colors.blue.shade300,
        ],
      ),
    );
  }
}
