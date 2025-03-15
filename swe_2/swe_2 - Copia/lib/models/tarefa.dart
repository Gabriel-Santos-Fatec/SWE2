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
  DateTime? dataUltimaAtualizacao;
  String? tempoEstimado;
  int? diasNecessarios;

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
    this.dataUltimaAtualizacao,
    this.tempoEstimado,
    this.diasNecessarios,
  });

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'],
      nome: map['nome'],
      prioridade: map['prioridade'],
      tempo: map['tempo'],
      status: map['status'] ?? "Pendente",
      inicio:
          map['inicio'] != null
              ? DateTime.parse(map['inicio']).toLocal()
              : null,
      conclusao:
          map['conclusao'] != null
              ? DateTime.parse(map['conclusao']).toLocal()
              : null,
      idEngenheiro: map['idengenheiro'],
      tempoTrabalhado: map['tempotrabalhado']?.toDouble(),
      ultimaPausa:
          map['ultimapausa'] != null
              ? DateTime.parse(map['ultimapausa']).toLocal()
              : null,
      ultimoInicio:
          map['ultimoinicio'] != null
              ? DateTime.parse(map['ultimoinicio']).toLocal()
              : null,
      tempoGastoHoje: map['tempogastohoje'] ?? 0,
      tempoGasto: map['tempogasto'] ?? 0,
      dataUltimaAtualizacao:
          map['dataultimaatualizacao'] != null
              ? DateTime.parse(map['dataultimaatualizacao']).toLocal()
              : null,
      tempoEstimado: map['tempoestimado'],
      diasNecessarios: map['diasnecessarios'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'prioridade': prioridade,
      'tempo': tempo,
      'status': status,
      'inicio': inicio?.toIso8601String(),
      'conclusao': conclusao?.toIso8601String(),
      'idengenheiro': idEngenheiro,
      'tempotrabalhado': tempoTrabalhado,
      'ultimapausa': ultimaPausa?.toIso8601String(),
      'ultimoinicio': ultimoInicio?.toIso8601String(),
      'tempogastohoje': tempoGastoHoje,
      'tempogasto': tempoGasto,
      'dataultimaatualizacao': dataUltimaAtualizacao?.toIso8601String(),
      'tempoestimado': tempoEstimado,
      'diasnecessarios': diasNecessarios,
    };
  }
}
