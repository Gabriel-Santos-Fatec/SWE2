import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/tarefa.dart';
import '../widgets/card_widget.dart';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TarefasScreenState createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _tempoController = TextEditingController();
  String _prioridadeSelecionada = "Alta";
  final DBHelper _dbHelper = DBHelper();
  List<Tarefa> _tarefas = [];

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  void _carregarTarefas() async {
    List<Tarefa> lista = await _dbHelper.listarTarefas();
    setState(() {
      _tarefas = lista;
    });
  }

  void _salvarTarefa({Tarefa? tarefa}) async {
    String nome = _nomeController.text.trim();
    int tempo = int.tryParse(_tempoController.text) ?? 0;
    if (nome.isEmpty || tempo <= 0) return;

    if (tarefa == null) {
      await _dbHelper.inserirTarefa(
        Tarefa(nome: nome, prioridade: _prioridadeSelecionada, tempo: tempo),
      );
    } else {
      tarefa.nome = nome;
      tarefa.tempo = tempo;
      tarefa.prioridade = _prioridadeSelecionada;
      await _dbHelper.atualizarTarefa(tarefa);
    }

    _carregarTarefas();
    _limparCampos();
  }

  void _editarTarefa(Tarefa tarefa) {
    _nomeController.text = tarefa.nome;
    _tempoController.text = tarefa.tempo.toString();
    _prioridadeSelecionada = tarefa.prioridade;

    _mostrarDialogoCadastro(tarefa);
  }

  void _excluirTarefa(int id) async {
    bool confirmar = await _confirmarExclusao();
    if (confirmar) {
      await _dbHelper.excluirTarefa(id);
      _carregarTarefas();
    }
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
                  child: Text("Excluir"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _limparCampos() {
    _nomeController.clear();
    _tempoController.clear();
    _prioridadeSelecionada = "Alta";
  }

  void _mostrarDialogoCadastro([Tarefa? tarefa]) {
    String prioridadeTemp = tarefa?.prioridade ?? _prioridadeSelecionada;
    bool boolErro = false;
    String mensagemErro = "";

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
                    "Tempo (horas)",
                    Icons.timer,
                    true,
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Prioridade:",
                        style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                      ),
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
                      textAlign: TextAlign.center,
                      mensagemErro,
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
                    int? tempo = int.tryParse(_tempoController.text);

                    if (nome.isEmpty || tempo == null || tempo < 1) {
                      setStateDialog(() {
                        boolErro = true;
                        mensagemErro =
                            nome.isEmpty
                                ? "Insira o nome da tarefa."
                                : (tempo == null)
                                ? "Insira o tempo necessário."
                                : (tempo < 1)
                                ? "O tempo deve ser maior que 0."
                                : "";
                      });
                    } else {
                      _prioridadeSelecionada = prioridadeTemp;
                      _salvarTarefa(tarefa: tarefa);
                      Navigator.of(context).pop();
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
                              subtitle2: "Tempo: ${tarefa.tempo}h",
                              subtitle3: "Status: ${tarefa.status}",
                              icon: Icons.task,
                              onEdit: () => _editarTarefa(tarefa),
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
        child: Icon(Icons.add, color: Colors.blue),
      ),
    );
  }
}
