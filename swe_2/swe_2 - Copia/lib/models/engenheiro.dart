class Engenheiro {
  int? id;
  String nome;
  int cargaMaxima;
  double eficiencia;

  Engenheiro({
    this.id,
    required this.nome,
    required this.cargaMaxima,
    required this.eficiencia,
  });

  factory Engenheiro.fromMap(Map<String, dynamic> map) {
    return Engenheiro(
      id: map['id'] ?? 0,
      nome: map['nome'] ?? "Desconhecido",
      cargaMaxima: map['cargamaxima'],
      eficiencia: (map['eficiencia'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'carga_maxima': cargaMaxima,
      'eficiencia': eficiencia,
    };
  }
}
