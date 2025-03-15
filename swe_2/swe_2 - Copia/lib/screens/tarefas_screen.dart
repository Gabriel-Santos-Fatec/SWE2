import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tarefa.dart';
import '../widgets/card_widget.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  _TarefasScreenState createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _tempoController = TextEditingController();
  String _prioridadeSelecionada = "Alta";

  List<Tarefa> _tarefas = [];
  final String apiUrl = "http://10.0.2.2:4000/tarefas";

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  // Carrega a lista de tarefas da API
  Future<void> _carregarTarefas() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _tarefas =
              data.map((e) {
                Tarefa tarefa = Tarefa.fromMap(e);
                tarefa.tempo =
                    (tarefa.tempo / 60).round(); // Converter minutos para horas
                return tarefa;
              }).toList();
        });
      } else {
        print("Erro ao carregar tarefas: ${response.statusCode}");
      }
    } catch (e) {
      print("Erro ao buscar tarefas: $e");
    }
  }

  // Salva ou atualiza uma tarefa na API
  Future<void> _salvarTarefa({Tarefa? tarefa}) async {
    String nome = _nomeController.text.trim();
    int tempoHoras = int.tryParse(_tempoController.text) ?? 0;
    if (nome.isEmpty || tempoHoras <= 0) return;

    int tempoMinutos = tempoHoras * 60; // Converter horas para minutos

    try {
      final body = jsonEncode({
        "nome": nome,
        "prioridade": _prioridadeSelecionada,
        "tempo": tempoMinutos,
        "status": "Pendente",
      });

      if (tarefa == null) {
        await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      } else {
        await http.put(
          Uri.parse("$apiUrl/${tarefa.id}"),
          headers: {"Content-Type": "application/json"},
          body: body,
        );
      }
      _carregarTarefas();
    } catch (e) {
      print("Erro ao salvar tarefa: $e");
    }

    _limparCampos();
    Navigator.of(context).pop();
  }

  // Exclui uma tarefa via API
  Future<void> _excluirTarefa(int id) async {
    bool confirmar = await _confirmarExclusao();
    if (confirmar) {
      try {
        final response = await http.delete(Uri.parse("$apiUrl/$id"));

        if (response.statusCode == 200) {
          _carregarTarefas();
        } else {
          print("Erro ao excluir tarefa: ${response.body}");
        }
      } catch (e) {
        print("Erro ao excluir tarefa: $e");
      }
    }
  }

  // Limpa os campos do formulário
  void _limparCampos() {
    _nomeController.clear();
    _tempoController.clear();
    _prioridadeSelecionada = "Alta";
  }

  // Exibe o modal para cadastrar ou editar tarefa
  void _mostrarDialogoCadastro([Tarefa? tarefa]) {
    String prioridadeTemp = tarefa?.prioridade ?? _prioridadeSelecionada;
    bool boolErro = false;
    String mensagemErro = "";

    if (tarefa != null) {
      _nomeController.text = tarefa.nome;
      _tempoController.text = (tarefa.tempo).toString();
      _prioridadeSelecionada = tarefa.prioridade;
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
                tarefa == null ? "Adicionar Tarefa" : "Editar Tarefa",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    _nomeController,
                    "Nome da Tarefa",
                    Icons.task,
                  ),
                  SizedBox(height: 10),
                  _buildTextField(
                    _tempoController,
                    "Tempo (h)",
                    Icons.timer,
                    true,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Prioridade:", style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: prioridadeTemp,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateDialog(() {
                              prioridadeTemp = newValue;
                            });
                          }
                        },
                        items:
                            ["Alta", "Média", "Baixa"].map((String prioridade) {
                              return DropdownMenuItem<String>(
                                value: prioridade,
                                child: Text(prioridade),
                              );
                            }).toList(),
                      ),
                    ],
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
                  child: Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    String nome = _nomeController.text.trim();
                    int? tempo = int.tryParse(_tempoController.text);

                    if (nome.isEmpty || tempo == null || tempo < 1) {
                      setStateDialog(() {
                        boolErro = true;
                        mensagemErro =
                            nome.isEmpty
                                ? "Insira o nome."
                                : "O tempo deve ser maior que 0.";
                      });
                    } else {
                      _prioridadeSelecionada = prioridadeTemp;
                      _salvarTarefa(tarefa: tarefa);
                    }
                  },
                  child: Text("Salvar"),
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
              title: Text("Excluir Tarefa"),
              content: Text("Tem certeza que deseja excluir esta tarefa?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Cancelar"),
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
                "Tarefas",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child:
                    _tarefas.isEmpty
                        ? Center(
                          child: Text(
                            "Nenhuma tarefa cadastrada",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        )
                        : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _tarefas.length,
                          itemBuilder: (context, index) {
                            Tarefa tarefa = _tarefas[index];
                            return CardWidget(
                              title: tarefa.nome,
                              subtitle1: "Prioridade: ${tarefa.prioridade}",
                              subtitle2: "Tempo: ${tarefa.tempo} h",
                              subtitle3: "Status: ${tarefa.status}",
                              icon: Icons.task,
                              onEdit: () => _mostrarDialogoCadastro(tarefa),
                              onDelete: () => _excluirTarefa(tarefa.id!),
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
