import 'package:flutter_test/flutter_test.dart';

import 'package:app_tarefas/database.dart';
import 'package:app_tarefas/main.dart';

void main() {
  testWidgets('exibe tela inicial da lista de tarefas', (tester) async {
    await tester.pumpWidget(MyApp(repositorio: RepositorioFake()));
    await tester.pump();

    expect(find.text('Lista de Tarefas'), findsOneWidget);
    expect(find.text('Criar tarefa'), findsOneWidget);
    expect(find.text('Buscar por ID'), findsOneWidget);
  });
}

class RepositorioFake implements TarefaRepositorio {
  final List<Tarefa> _tarefas = [];

  @override
  Future<int> criarTarefa(Tarefa tarefa) async {
    _tarefas.add(tarefa.copyWith(id: _tarefas.length + 1));
    return _tarefas.length;
  }

  @override
  Future<List<Tarefa>> listarTarefas() async {
    return _tarefas;
  }

  @override
  Future<Tarefa?> buscarTarefaPorId(int id) async {
    return _tarefas.where((tarefa) => tarefa.id == id).firstOrNull;
  }

  @override
  Future<int> atualizarTarefa(Tarefa tarefa) async {
    final index = _tarefas.indexWhere((item) => item.id == tarefa.id);
    if (index == -1) {
      return 0;
    }

    _tarefas[index] = tarefa;
    return 1;
  }

  @override
  Future<int> deletarTarefa(int id) async {
    final quantidadeAntes = _tarefas.length;
    _tarefas.removeWhere((tarefa) => tarefa.id == id);
    return quantidadeAntes - _tarefas.length;
  }
}
