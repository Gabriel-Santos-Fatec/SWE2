// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/engenheiro.dart';
import '../widgets/card_widget.dart';

class EngenheirosScreen extends StatefulWidget {
  const EngenheirosScreen({super.key});

  @override
  _EngenheirosScreenState createState() => _EngenheirosScreenState();
}

class _EngenheirosScreenState extends State<EngenheirosScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _eficienciaController = TextEditingController();
  final TextEditingController _cargaMaximaController = TextEditingController();

  List<Engenheiro> _engenheiros = [];
  final String apiUrl = "http://10.0.2.2:4000/engenheiros";

  @override
  void initState() {
    super.initState();
    _carregarEngenheiros();
  }

  // Carrega a lista de engenheiros
  Future<void> _carregarEngenheiros() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _engenheiros =
              data.map((e) {
                return Engenheiro.fromMap(e);
              }).toList();
        });
      } else {
        print("Erro ao carregar engenheiros: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao buscar engenheiros: $e");
    }
  }

  // Salva um engenheiro novo ou atualiza um existente
  Future<void> _salvarEngenheiro({Engenheiro? engenheiro}) async {
    String nome = _nomeController.text.trim();
    int cargaMaxima = int.tryParse(_cargaMaximaController.text) ?? 8;
    if (cargaMaxima < 1) cargaMaxima = 1;

    double eficiencia = double.tryParse(_eficienciaController.text) ?? 0;
    eficiencia = eficiencia == 0 ? 1.0 : 1 + (eficiencia / 100);

    if (nome.isEmpty) return;

    try {
      final body = jsonEncode({
        "nome": nome,
        "cargaMaxima": cargaMaxima,
        "eficiencia": eficiencia,
      });

      if (engenheiro == null) {
        // Cria novo engenheiro
        await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } else {
        // Atualiza engenheiro existente
        await http.put(
          Uri.parse("$apiUrl/${engenheiro.id}"),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      }
      _carregarEngenheiros();
    } catch (e) {
      print("Erro ao salvar engenheiro: $e");
    }

    _limparCampos();
    Navigator.of(context).pop();
  }

  // Exclui um engenheiro via API
  Future<void> _excluirEngenheiro(int id) async {
    bool confirmar = await _confirmarExclusao();
    if (confirmar) {
      try {
        final response = await http.delete(Uri.parse("$apiUrl/$id"));

        if (response.statusCode == 200) {
          _carregarEngenheiros();
        } else {
          print("Erro ao excluir engenheiro: ${response.body}");
        }
      } catch (e) {
        print("Erro ao excluir engenheiro: $e");
      }
    }
  }

  // Limpa os campos do formulário
  void _limparCampos() {
    _nomeController.clear();
    _cargaMaximaController.clear();
    _eficienciaController.clear();
  }

  // Exibe o modal para cadastrar ou editar engenheiro
  void _mostrarDialogoCadastro([Engenheiro? engenheiro]) {
    bool boolErro = false;
    String mensagemErro = "";

    if (engenheiro != null) {
      _nomeController.text = engenheiro.nome;
      _cargaMaximaController.text = engenheiro.cargaMaxima.toString();
      _eficienciaController.text = ((engenheiro.eficiencia - 1) * 100)
          .toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                engenheiro == null
                    ? "Adicionar Engenheiro"
                    : "Editar Engenheiro",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_nomeController, "Nome", Icons.person),
                  SizedBox(height: 10),
                  _buildTextField(
                    _cargaMaximaController,
                    "Carga Máxima (h/dia)",
                    Icons.schedule,
                    true,
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    _eficienciaController,
                    "Eficiência (%)",
                    Icons.speed,
                    true,
                  ),
                  SizedBox(height: 10),
                  Visibility(
                    visible: boolErro,
                    child: Text(
                      mensagemErro,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _limparCampos();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    String nome = _nomeController.text.trim();
                    int? cargaMaxima = int.tryParse(
                      _cargaMaximaController.text,
                    );

                    if (nome.isEmpty ||
                        cargaMaxima == null ||
                        cargaMaxima < 1 ||
                        cargaMaxima > 8) {
                      setStateDialog(() {
                        boolErro = true;
                        mensagemErro =
                            nome.isEmpty
                                ? "Insira o nome."
                                : (cargaMaxima == null)
                                ? "Insira a carga horária."
                                : (cargaMaxima < 1 || cargaMaxima > 8)
                                ? "A carga máxima deve estar\nentre 1 e 8 horas."
                                : "";
                      });
                    } else {
                      _salvarEngenheiro(engenheiro: engenheiro);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text("Salvar", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmarExclusao() async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Excluir Engenheiro"),
              content: Text("Tem certeza que deseja excluir este engenheiro?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("Excluir", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Constrói um campo de entrada de texto
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, [
    bool isNumber = false,
  ]) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                "Engenheiros",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child:
                    _engenheiros.isEmpty
                        ? Center(
                          child: Text(
                            "Nenhum engenheiro cadastrado",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _engenheiros.length,
                          itemBuilder: (context, index) {
                            Engenheiro eng = _engenheiros[index];
                            return CardWidget(
                              title: eng.nome,
                              subtitle1: "Carga: ${eng.cargaMaxima}h/dia",
                              subtitle2:
                                  "Eficiência: ${((eng.eficiencia - 1) * 100).toStringAsFixed(0)}%",
                              subtitle3: "",
                              icon: Icons.engineering,
                              onEdit: () => _mostrarDialogoCadastro(eng),
                              onDelete: () => _excluirEngenheiro(eng.id!),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoCadastro(),
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: Colors.blueAccent),
      ),
    );
  }
}
