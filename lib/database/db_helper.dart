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

  // Exclui um engenheiro pelo ID e ajusta as tarefas relacionadas
  Future<void> excluirEngenheiro(int id) async {
    final db = await database;

    List<Map<String, dynamic>> tarefas = await db.query(
      'Tarefas',
      where: 'IdEngenheiro = ?',
      whereArgs: [id],
    );

    for (var tarefa in tarefas) {
      // Se a tarefa estiver em andamento, pausa ela
      if (tarefa['Status'] == 'Em andamento' || tarefa['Status'] == 'Pausada') {
        await db.update(
          'Tarefas',
          {'Status': 'Pendente'},
          where: 'Id = ?',
          whereArgs: [tarefa['Id']],
        );
      }

      // Remove o engenheiro da tarefa e zera o tempo gasto hoje
      await db.update(
        'Tarefas',
        {'IdEngenheiro': null, 'TempoGastoHoje': 0},
        where: 'Id = ?',
        whereArgs: [tarefa['Id']],
      );
    }

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
      DateTime? ultimaPausa =
          tarefa['UltimaPausa'] != null
              ? DateTime.parse(tarefa['UltimaPausa'])
              : null;
      int tempoGastoHoje = tarefa['TempoGastoHoje'] ?? 0;
      int tempoGasto = tarefa['TempoGasto'] ?? 0;

      if (ultimoInicio != null) {
        int minutosGastos = agora.difference(ultimoInicio).inMinutes;
        tempoGastoHoje += minutosGastos;
        tempoGasto += minutosGastos;
      }

      // Se houver uma última pausa, soma (agora - última pausa)
      if (ultimaPausa != null) {
        int minutosDesdeUltimaPausa = agora.difference(ultimaPausa).inMinutes;
        tempoGasto += minutosDesdeUltimaPausa;
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
            agora.difference(ultimoInicio).inMinutes.toDouble();

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
            'TempoGastoHoje': tempoGastoHoje,
            'TempoGasto': tempoGastoTotal,
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
    DateTime agora = DateTime.now();

    List<Map<String, dynamic>> resultado = await db.rawQuery(
      '''
    SELECT Id, TempoGastoHoje, UltimoInicio, UltimaPausa, Status
    FROM Tarefas
    WHERE IdEngenheiro = ?
  ''',
      [idEngenheiro],
    );

    double totalMinutos = 0;

    for (var row in resultado) {
      int tempoGastoHoje = row['TempoGastoHoje'] ?? 0;
      DateTime? ultimoInicio =
          row['UltimoInicio'] != null
              ? DateTime.parse(row['UltimoInicio'])
              : null;
      DateTime? ultimaPausa =
          row['UltimaPausa'] != null
              ? DateTime.parse(row['UltimaPausa'])
              : null;
      String status = row['Status'] ?? "";

      if (status == "Em andamento" && ultimoInicio != null) {
        // Se a tarefa ainda está ativa, somamos o tempo desde o último início
        int minutosDecorridos = agora.difference(ultimoInicio).inMinutes;

        // Somamos apenas se a última pausa não ocorreu após o último início
        if (ultimaPausa == null || ultimoInicio.isAfter(ultimaPausa)) {
          tempoGastoHoje += minutosDecorridos;
        }
      }

      totalMinutos += tempoGastoHoje;
    }

    return totalMinutos / 60;
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

  // Obtém os engenheiros que possuem tarefas pendentes, em andamento ou pausadas
  Future<Set<int>> buscarEngenheirosOcupados() async {
    final db = await database;
    List<Map<String, dynamic>> resultados = await db.rawQuery('''
      SELECT DISTINCT IdEngenheiro 
      FROM Tarefas 
      WHERE IdEngenheiro IS NOT NULL AND Status IN ('Pendente', 'Em andamento', 'Pausada')
    ''');

    return resultados
        .where((row) => row['IdEngenheiro'] != null)
        .map((row) => row['IdEngenheiro'] as int)
        .toSet();
  }

  // Remove o engenheiro de uma tarefa sem excluir a tarefa
  Future<void> desvincularEngenheiroDaTarefa(int idTarefa) async {
    final db = await database;
    await db.update(
      'Tarefas',
      {'IdEngenheiro': null},
      where: 'Id = ?',
      whereArgs: [idTarefa],
    );
  }
}
