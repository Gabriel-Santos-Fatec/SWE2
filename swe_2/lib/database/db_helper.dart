import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/engenheiro.dart';
import '../models/tarefa.dart';

class DBHelper {
  static Database? _database;

  // Retorna a instância do banco de dados, inicializando-o se necessário
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Inicializa o banco de dados e cria as tabelas se necessário
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'projeto.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE Engenheiros (
          Id INTEGER PRIMARY KEY AUTOINCREMENT,
          Nome TEXT NOT NULL,
          CargaMaxima INTEGER NOT NULL,
          Eficiencia REAL NOT NULL
        )
      ''');
        await db.execute('''
        CREATE TABLE Tarefas (
          Id INTEGER PRIMARY KEY AUTOINCREMENT,
          Nome TEXT NOT NULL,
          Prioridade TEXT NOT NULL,
          Tempo INTEGER NOT NULL,
          Status TEXT DEFAULT 'Pendente',
          Inicio TEXT,
          Conclusao TEXT,
          IdEngenheiro INTEGER,
          TempoTrabalhado REAL DEFAULT 0,
          UltimaPausa TEXT,
          UltimoInicio TEXT,
          TempoGastoHoje INTEGER DEFAULT 0,
          TempoGasto INTEGER DEFAULT 0,
          DataUltimaAtualizacao TEXT,
          FOREIGN KEY (IdEngenheiro) REFERENCES Engenheiros(Id) ON DELETE SET NULL
        )
      ''');
      },
    );
  }

  // Insere um engenheiro na tabela Engenheiros
  Future<int> inserirEngenheiro(Engenheiro engenheiro) async {
    final db = await database;
    return await db.insert('Engenheiros', engenheiro.toMap());
  }

  // Insere uma tarefa na tabela Tarefas
  Future<int> inserirTarefa(Tarefa tarefa) async {
    final db = await database;
    return await db.insert('Tarefas', tarefa.toMap());
  }

  // Retorna a lista de engenheiros cadastrados
  Future<List<Engenheiro>> listarEngenheiros() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('Engenheiros');
    return List.generate(maps.length, (i) => Engenheiro.fromMap(maps[i]));
  }

  // Atualiza um engenheiro existente
  Future<void> atualizarEngenheiro(Engenheiro engenheiro) async {
    final db = await database;
    await db.update(
      'Engenheiros',
      engenheiro.toMap(),
      where: 'Id = ?',
      whereArgs: [engenheiro.id],
    );
  }

  // Exclui um engenheiro pelo ID
  Future<void> excluirEngenheiro(int id) async {
    final db = await database;
    await db.delete('Engenheiros', where: 'Id = ?', whereArgs: [id]);
  }

  // Retorna a lista de tarefas cadastradas
  Future<List<Tarefa>> listarTarefas() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('Tarefas');
    return List.generate(maps.length, (i) => Tarefa.fromMap(maps[i]));
  }

  // Inicia uma tarefa sem sobrescrever o primeiro horário de início
  Future<void> iniciarTarefa(int idTarefa) async {
    final db = await database;
    final DateTime agora = DateTime.now();
    final String dataHoje = agora.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> resultado = await db.query(
      'Tarefas',
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );

    if (resultado.isNotEmpty) {
      final tarefa = resultado.first;

      // Se o dia mudou, zera `tempoGastoHoje`
      String? ultimaAtualizacao = tarefa['DataUltimaAtualizacao'];
      if (ultimaAtualizacao == null || ultimaAtualizacao != dataHoje) {
        await db.update(
          'Tarefas',
          {'TempoGastoHoje': 0, 'DataUltimaAtualizacao': dataHoje},
          where: 'Id = ?',
          whereArgs: [idTarefa],
        );
      }

      await db.update(
        'Tarefas',
        {
          'Status': 'Em andamento',
          'Inicio': tarefa['Inicio'] ?? agora.toIso8601String(),
          'UltimoInicio':
              agora.toIso8601String(), // Salva última vez que iniciou
          'UltimaPausa': null,
        },
        where: 'Id = ?',
        whereArgs: [idTarefa],
      );
    }
  }

  // Marca uma tarefa como concluída
  Future<void> concluirTarefa(int idTarefa) async {
    final db = await database;
    final DateTime agora = DateTime.now();
    final String dataHoje = agora.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> resultado = await db.query(
      'Tarefas',
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );

    if (resultado.isNotEmpty) {
      final tarefa = resultado.first;
      DateTime? ultimoInicio =
          tarefa['UltimoInicio'] != null
              ? DateTime.parse(tarefa['UltimoInicio'])
              : null;
      int tempoGastoHoje = tarefa['TempoGastoHoje'] ?? 0;
      int tempoGasto = tarefa['TempoGasto'] ?? 0;

      if (ultimoInicio != null) {
        int minutosGastos = agora.difference(ultimoInicio).inMinutes;
        tempoGastoHoje += minutosGastos;
        tempoGasto += minutosGastos;
      }

      // Se o dia mudou, zera `tempoGastoHoje`
      String? ultimaAtualizacao = tarefa['DataUltimaAtualizacao'];
      if (ultimaAtualizacao == null || ultimaAtualizacao != dataHoje) {
        tempoGastoHoje = 0;
      }

      await db.update(
        'Tarefas',
        {
          'Status': 'Concluída',
          'Conclusao': agora.toIso8601String(),
          'UltimaPausa': agora.toIso8601String(),
          'TempoGastoHoje': tempoGastoHoje,
          'TempoGasto': tempoGasto,
          'DataUltimaAtualizacao': dataHoje,
        },
        where: 'Id = ?',
        whereArgs: [idTarefa],
      );
    }
  }

  // Aloca uma tarefa para um engenheiro específico
  Future<void> alocarTarefa(int idTarefa, int idEngenheiro) async {
    final db = await database;
    await db.update(
      'Tarefas',
      {'IdEngenheiro': idEngenheiro, 'Status': 'Pendente'},
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );
  }

  // Atualiza os dados de uma tarefa
  Future<void> atualizarTarefa(Tarefa tarefa) async {
    final db = await database;
    await db.update(
      'Tarefas',
      tarefa.toMap(),
      where: 'Id = ?',
      whereArgs: [tarefa.id],
    );
  }

  // Pausa uma tarefa e atualiza o tempo trabalhado
  Future<void> pausarTarefaComTempo(int idTarefa) async {
    final db = await database;

    // Busca os dados da tarefa no banco
    final List<Map<String, dynamic>> resultado = await db.query(
      'Tarefas',
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );

    if (resultado.isNotEmpty) {
      final tarefa = resultado.first;

      DateTime? ultimoInicio =
          tarefa['UltimoInicio'] != null
              ? DateTime.parse(tarefa['UltimoInicio'])
              : null;
      DateTime agora = DateTime.now();

      if (ultimoInicio != null) {
        // Calcula o tempo decorrido desde o último início
        double minutosDecorridos =
            agora
                .difference(ultimoInicio)
                .inMinutes
                .toDouble(); // ✅ Convertido para double

        // Recupera valores do banco garantindo que sejam double
        double tempoGastoHoje =
            (tarefa['TempoGastoHoje'] as num?)?.toDouble() ?? 0.0;
        double tempoGastoTotal =
            (tarefa['TempoGasto'] as num?)?.toDouble() ?? 0.0;

        // Atualiza os tempos
        tempoGastoHoje += minutosDecorridos;
        tempoGastoTotal += minutosDecorridos;

        // Atualiza os dados da tarefa no banco
        await db.update(
          'Tarefas',
          {
            'Status': 'Pausada',
            'TempoGastoHoje': tempoGastoHoje, // ✅ Garantido como double
            'TempoGasto': tempoGastoTotal, // ✅ Garantido como double
            'UltimaPausa': agora.toIso8601String(),
            'UltimoInicio': null, // Reseta o último início
          },
          where: 'Id = ?',
          whereArgs: [idTarefa],
        );
      }
    }
  }

  // Exclui uma tarefa pelo ID
  Future<void> excluirTarefa(int id) async {
    final db = await database;
    await db.delete('Tarefas', where: 'Id = ?', whereArgs: [id]);
  }

  // Obtém o total de tempo trabalhado no dia atual
  Future<double> obterTempoTotalTrabalhadoHoje(int idEngenheiro) async {
    final db = await database;
    DateTime hoje = DateTime.now();
    String dataHoje =
        "${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}";

    List<Map<String, dynamic>> resultado = await db.rawQuery(
      '''
    SELECT SUM(TempoTrabalhado) as TotalHoras
    FROM Tarefas
    WHERE IdEngenheiro = ? AND DATE(Inicio) = ?
  ''',
      [idEngenheiro, dataHoje],
    );

    return (resultado.first['TotalHoras'] ?? 0.0).toDouble();
  }

  // Zera o tempo gasto do dia por tarefa
  Future<void> zerarTempoGastoHojePorTarefa(int idTarefa) async {
    final db = await database;
    await db.update(
      'Tarefas',
      {'TempoGastoHoje': 0},
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );
  }
}
