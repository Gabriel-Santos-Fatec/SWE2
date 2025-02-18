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
      id: map['Id'],
      nome: map['Nome'],
      cargaMaxima: map['CargaMaxima'],
      eficiencia: map['Eficiencia'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Id': id,
      'Nome': nome,
      'CargaMaxima': cargaMaxima,
      'Eficiencia': eficiencia,
    };
  }
}
