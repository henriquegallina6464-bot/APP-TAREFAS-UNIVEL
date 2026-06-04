import 'package:flutter/material.dart';
import 'database.dart';     

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repositorio});

  final TarefaRepositorio? repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Tarefas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: TelaTarefas(repositorio: repositorio ?? BancoDados.instancia),
    );
  }
}

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key, required this.repositorio});

  final TarefaRepositorio repositorio;

  @override
  State<TelaTarefas> createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _buscaIdController = TextEditingController();

  List<Tarefa> _tarefas = [];
  Tarefa? _tarefaEncontrada;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _buscaIdController.dispose();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    final tarefas = await widget.repositorio.listarTarefas();

    setState(() {
      _tarefas = tarefas;
      _carregando = false;
    });
  }

  Future<void> _criarTarefa() async {
    final titulo = _tituloController.text.trim();
    final descricao = _descricaoController.text.trim();

    if (titulo.isEmpty || descricao.isEmpty) {
      _mostrarMensagem('Informe titulo e descricao.');
      return;
    }

    await widget.repositorio.criarTarefa(
      Tarefa(titulo: titulo, descricao: descricao),
    );

    _tituloController.clear();
    _descricaoController.clear();
    _mostrarMensagem('Tarefa criada com sucesso.');
    await _carregarTarefas();
  }

  Future<void> _buscarPorId() async {
    final id = int.tryParse(_buscaIdController.text.trim());

    if (id == null) {
      _mostrarMensagem('Informe um ID valido.');
      return;
    }

    final tarefa = await widget.repositorio.buscarTarefaPorId(id);

    setState(() {
      _tarefaEncontrada = tarefa;
    });

    if (tarefa == null) {
      _mostrarMensagem('Nenhuma tarefa encontrada com esse ID.');
    }
  }

  Future<void> _atualizarStatus(Tarefa tarefa, bool concluida) async {
    await widget.repositorio.atualizarTarefa(
      tarefa.copyWith(concluida: concluida),
    );
    await _carregarTarefas();

    if (_tarefaEncontrada?.id == tarefa.id) {
      await _buscarPorId();
    }
  }

  Future<void> _editarTarefa(Tarefa tarefa) async {
    final tituloController = TextEditingController(text: tarefa.titulo);
    final descricaoController = TextEditingController(text: tarefa.descricao);
    bool concluida = tarefa.concluida;

    final tarefaEditada = await showDialog<Tarefa>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar tarefa #${tarefa.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Titulo'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descricaoController,
                      decoration: const InputDecoration(labelText: 'Descricao'),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Concluida'),
                      value: concluida,
                      onChanged: (value) {
                        setDialogState(() {
                          concluida = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    final titulo = tituloController.text.trim();
                    final descricao = descricaoController.text.trim();

                    if (titulo.isEmpty || descricao.isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      tarefa.copyWith(
                        titulo: titulo,
                        descricao: descricao,
                        concluida: concluida,
                      ),
                    );
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();
    descricaoController.dispose();

    if (tarefaEditada == null) {
      return;
    }

    await widget.repositorio.atualizarTarefa(tarefaEditada);
    _mostrarMensagem('Tarefa atualizada com sucesso.');
    await _carregarTarefas();

    if (_tarefaEncontrada?.id == tarefa.id) {
      await _buscarPorId();
    }
  }

  Future<void> _deletarTarefa(int id) async {
    await widget.repositorio.deletarTarefa(id);

    if (_tarefaEncontrada?.id == id) {
      setState(() {
        _tarefaEncontrada = null;
      });
    }

    _mostrarMensagem('Tarefa removida.');
    await _carregarTarefas();
  }

  void _limparBusca() {
    _buscaIdController.clear();
    setState(() {
      _tarefaEncontrada = null;
    });
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Lista de Tarefas'),
      ),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _carregarTarefas,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _FormularioCriacao(
                      tituloController: _tituloController,
                      descricaoController: _descricaoController,
                      onSalvar: _criarTarefa,
                    ),
                    const SizedBox(height: 20),
                    _BuscaPorId(
                      controller: _buscaIdController,
                      tarefa: _tarefaEncontrada,
                      onBuscar: _buscarPorId,
                      onLimpar: _limparBusca,
                      onEditar: _editarTarefa,
                      onDeletar: (tarefa) => _deletarTarefa(tarefa.id!),
                      onStatusChanged: _atualizarStatus,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Todas as tarefas (${_tarefas.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_tarefas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Nenhuma tarefa cadastrada.'),
                        ),
                      )
                    else
                      ..._tarefas.map(
                        (tarefa) => _TarefaTile(
                          tarefa: tarefa,
                          onEditar: () => _editarTarefa(tarefa),
                          onDeletar: () => _deletarTarefa(tarefa.id!),
                          onStatusChanged: (concluida) {
                            _atualizarStatus(tarefa, concluida);
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FormularioCriacao extends StatelessWidget {
  const _FormularioCriacao({
    required this.tituloController,
    required this.descricaoController,
    required this.onSalvar,
  });

  final TextEditingController tituloController;
  final TextEditingController descricaoController;
  final VoidCallback onSalvar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Criar tarefa',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Titulo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Descricao',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSalvar,
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuscaPorId extends StatelessWidget {
  const _BuscaPorId({
    required this.controller,
    required this.tarefa,
    required this.onBuscar,
    required this.onLimpar,
    required this.onEditar,
    required this.onDeletar,
    required this.onStatusChanged,
  });

  final TextEditingController controller;
  final Tarefa? tarefa;
  final VoidCallback onBuscar;
  final VoidCallback onLimpar;
  final ValueChanged<Tarefa> onEditar;
  final ValueChanged<Tarefa> onDeletar;
  final void Function(Tarefa tarefa, bool concluida) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Buscar por ID',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'ID da tarefa',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onBuscar,
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                ),
                IconButton.outlined(
                  onPressed: onLimpar,
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar',
                ),
              ],
            ),
            if (tarefa != null) ...[
              const SizedBox(height: 12),
              _TarefaTile(
                tarefa: tarefa!,
                onEditar: () => onEditar(tarefa!),
                onDeletar: () => onDeletar(tarefa!),
                onStatusChanged: (concluida) {
                  onStatusChanged(tarefa!, concluida);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarefaTile extends StatelessWidget {
  const _TarefaTile({
    required this.tarefa,
    required this.onEditar,
    required this.onDeletar,
    required this.onStatusChanged,
  });

  final Tarefa  tarefa;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: tarefa.concluida,
          onChanged: (value) => onStatusChanged(value ?? false),
        ),
        title: Text(
          '#${tarefa.id} - ${tarefa.titulo}',
          style: TextStyle(
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(tarefa.descricao),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onEditar,
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDeletar,
              icon: const Icon(Icons.delete),
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }
}
