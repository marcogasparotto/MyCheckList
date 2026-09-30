import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/tarefa_controller.dart';
import '../models/lista.dart';
import '../models/tarefa.dart';
import '../services/device_service.dart';
import '../widgets/tarefa_tile.dart';

/// VIEW - Tarefas de uma lista (UC4, UC5, UC6) com interacao por
/// acelerometro para limpar o filtro (UC8).
class TarefasView extends StatefulWidget {
  const TarefasView({super.key, required this.lista});

  final Lista lista;

  @override
  State<TarefasView> createState() => _TarefasViewState();
}

class _TarefasViewState extends State<TarefasView> {
  final DeviceService _device = DeviceService();
  final TextEditingController _novaTarefa = TextEditingController();
  bool _dialogoAberto = false;

  @override
  void initState() {
    super.initState();
    _device.monitorarAgitacao(_aoAgitar);
  }

  @override
  void dispose() {
    _device.cancelar();
    _novaTarefa.dispose();
    super.dispose();
  }

  /// UC8 - agitacao identificada: vibra, pede confirmacao e limpa o filtro.
  Future<void> _aoAgitar() async {
    final tarefaCtrl = context.read<TarefaController>();
    final config = context.read<ConfigController>();

    if (_dialogoAberto || !mounted) return;
    if (!tarefaCtrl.filtroAtivo) return;

    await config.feedbackTatil(duracaoMs: 120);
    if (!mounted) return;

    _dialogoAberto = true;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.vibration),
        title: const Text('Movimento identificado'),
        content: const Text('Deseja limpar o filtro aplicado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Limpar filtro'),
          ),
        ],
      ),
    );
    _dialogoAberto = false;

    if (confirmado == true) {
      tarefaCtrl.limparFiltro();
      await config.feedbackTatil(duracaoMs: 40);
    }
  }

  /// UC4 - adiciona tarefa.
  Future<void> _adicionar() async {
    final ctrl = context.read<TarefaController>();
    final config = context.read<ConfigController>();
    final usuarioId = context.read<AuthController>().usuario!.id;

    final ok = await ctrl.adicionar(
      listaId: widget.lista.id,
      usuarioId: usuarioId,
      descricao: _novaTarefa.text,
    );

    if (!mounted) return;

    if (ok) {
      _novaTarefa.clear();
      FocusScope.of(context).unfocus();
      await config.feedbackTatil(duracaoMs: 40);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.erro ?? 'Informe a descrição.')),
      );
    }
  }

  /// UC4 - edita a descricao de uma tarefa existente.
  Future<void> _editar(Tarefa tarefa) async {
    final campo = TextEditingController(text: tarefa.descricao);
    final ctrl = context.read<TarefaController>();

    final novo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar tarefa'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(campo.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    campo.dispose();

    if (novo != null && novo.trim().isNotEmpty) {
      await ctrl.editar(
        id: tarefa.id,
        listaId: tarefa.listaId,
        descricao: novo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarefaCtrl = context.watch<TarefaController>();
    final config = context.read<ConfigController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lista.nome),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: FiltroTarefa.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: tarefaCtrl.filtro == f,
                    onSelected: (_) => tarefaCtrl.alterarFiltro(f),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (tarefaCtrl.filtroAtivo)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.vibration, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtro "${tarefaCtrl.filtro.label}" ativo — '
                      'agite o aparelho para limpar.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Tarefa>>(
              stream: tarefaCtrl.tarefasDaLista(widget.lista.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todas = snapshot.data ?? [];
                final tarefas = tarefaCtrl.aplicarFiltro(todas);

                if (tarefas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        todas.isEmpty
                            ? 'Nenhuma tarefa nesta lista.\nAdicione a primeira abaixo.'
                            : 'Nenhuma tarefa no filtro "${tarefaCtrl.filtro.label}".',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tarefas.length,
                  itemBuilder: (context, i) {
                    final tarefa = tarefas[i];
                    return TarefaTile(
                      tarefa: tarefa,
                      onAlternar: () async {
                        await tarefaCtrl.alternarConclusao(tarefa);
                        // UC5 - vibracao indica a conclusao.
                        if (!tarefa.concluida) {
                          await config.feedbackTatil(duracaoMs: 60);
                        }
                      },
                      onEditar: () => _editar(tarefa),
                      onExcluir: () => tarefaCtrl.excluir(tarefa),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _novaTarefa,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _adicionar(),
                      decoration: const InputDecoration(
                        hintText: 'Nova tarefa',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _adicionar,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
