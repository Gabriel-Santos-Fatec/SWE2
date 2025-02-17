class Tarefa {
  int? id;
  String nome;
  String prioridade;
  int tempo;
  String status;
  DateTime? inicio;
  DateTime? conclusao;
  int? idEngenheiro;
  double? tempoTrabalhado;
  DateTime? ultimaPausa;
  DateTime? ultimoInicio;
  int tempoGasto;
  int tempoGastoHoje;

  Tarefa({
    this.id,
    required this.nome,
    required this.prioridade,
    required this.tempo,
    this.status = "Pendente",
    this.inicio,
    this.conclusao,
    this.idEngenheiro,
    this.tempoTrabalhado = 0.0,
    this.ultimaPausa,
    this.ultimoInicio,
    this.tempoGastoHoje = 0,
    this.tempoGasto = 0,
  });

  // Converte um `Map<String, dynamic>` (dados do banco) para um objeto `Tarefa`
  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['Id'],
      nome: map['Nome'],
      prioridade: map['Prioridade'],
      tempo: map['Tempo'],
      status: map['Status'] ?? "Pendente",
      inicio: map['Inicio'] != null ? DateTime.parse(map['Inicio']) : null,
      conclusao:
          map['Conclusao'] != null ? DateTime.parse(map['Conclusao']) : null,
      idEngenheiro: map['IdEngenheiro'],
      tempoTrabalhado:
          map['TempoTrabalhado'] != null
              ? map['TempoTrabalhado'].toDouble()
              : 0.0,
      ultimaPausa:
          map['UltimaPausa'] != null
              ? DateTime.parse(map['UltimaPausa'])
              : null,
      ultimoInicio:
          map['UltimoInicio'] != null
              ? DateTime.parse(map['UltimoInicio'])
              : null,
      tempoGastoHoje: map['TempoGastoHoje'] ?? 0,
      tempoGasto: map['TempoGasto'] ?? 0,
    );
  }

  // Converte um objeto `Tarefa` para um `Map<String, dynamic>` (para salvar no banco)
  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Nome': nome,
      'Prioridade': prioridade,
      'Tempo': tempo,
      'Status': status,
      'Inicio': inicio?.toIso8601String(),
      'Conclusao': conclusao?.toIso8601String(),
      'IdEngenheiro': idEngenheiro,
      'TempoTrabalhado': tempoTrabalhado,
      'UltimaPausa': ultimaPausa?.toIso8601String(),
      'UltimoInicio': ultimoInicio?.toIso8601String(),
      'TempoGastoHoje': tempoGastoHoje,
      'TempoGasto': tempoGasto,
    };
  }
}
