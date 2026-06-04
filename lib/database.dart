import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Tarefa {
  final int? id;
  final String titulo;
  final String descricao;
  final bool concluida;

  Tarefa({
    this.id,
    required this.titulo,
    required this.descricao,
    this.concluida = false,
  });

  Tarefa copyWith({
    int? id,
    String? titulo,
    String? descricao,
    bool? concluida,
  }) {
    return Tarefa(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      concluida: concluida ?? this.concluida,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'concluida': concluida ? 1 : 0,
    };
  }

  factory Tarefa.fromMap(Map<String, dynamic> map) {
    return Tarefa(
      id: map['id'] as int,
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String,
      concluida: map['concluida'] == 1,
    );
  }
}

abstract class TarefaRepositorio {
  Future<List<Tarefa>> listarTarefas();
  Future<Tarefa?> buscarTarefaPorId(int id);
  Future<void> criarTarefa(Tarefa tarefa);
  Future<void> atualizarTarefa(Tarefa tarefa);
  Future<void> deletarTarefa(int id);
}

class BancoDados implements TarefaRepositorio {
  BancoDados._();

  static final BancoDados instancia = BancoDados._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final caminho = join(await getDatabasesPath(), 'tarefas.db');

    _db = await openDatabase(
      caminho,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tarefas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            descricao TEXT NOT NULL,
            concluida INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    return _db!;
  }

  @override
  Future<List<Tarefa>> listarTarefas() async {
    final db = await database;
    final resultado = await db.query('tarefas', orderBy: 'id DESC');
    return resultado.map((map) => Tarefa.fromMap(map)).toList();
  }

  @override
  Future<Tarefa?> buscarTarefaPorId(int id) async {
    final db = await database;

    final resultado = await db.query(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) return null;

    return Tarefa.fromMap(resultado.first);
  }

  @override
  Future<void> criarTarefa(Tarefa tarefa) async {
    final db = await database;
    await db.insert('tarefas', tarefa.toMap());
  }

  @override
  Future<void> atualizarTarefa(Tarefa tarefa) async {
    final db = await database;

    await db.update(
      'tarefas',
      tarefa.toMap(),
      where: 'id = ?',
      whereArgs: [tarefa.id],
    );
  }

  @override
  Future<void> deletarTarefa(int id) async {
    final db = await database;

    await db.delete(
      'tarefas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}