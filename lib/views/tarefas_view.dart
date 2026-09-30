import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/tarefa_controller.dart';
import '../models/lista.dart';
import '../models/tarefa.dart';
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
  final TextEditingController _novaTarefa = TextEditingController();

  // Guardados no initState para serem usados com seguranca depois de awaits.
  late final ConfigController _config;
  late final TarefaController _tarefaCtrl;
  late final AuthController _auth;

  bool _dialogoAberto = false;

  @override
  void initState() {
    super.initState();
    // Captura os controllers UMA vez, antes de qualquer await. Usar
    // context.read depois de um await pode tocar num Provider ja destruido.
    _config = context.read<ConfigController>();
    _tarefaCtrl = context.read<TarefaController>();
    _auth = context.read<AuthController>();

    _config.iniciarMonitoramento(_aoAgitar);
  }

  @override
  void dispose() {
    // Cancela a inscricao no acelerometro ANTES de a tela sair da arvore.
    _config.pararMonitoramento();
    _novaTarefa.dispose();
    super.dispose();
  }

  /// UC8 - agitacao identificada: vibra, pede confirmacao e limpa o filtro.
  Future<void> _aoAgitar() async {
    if (!mounted || _dialogoAberto) return;
    if (!_tarefaCtrl.filtroAtivo) return;

    await _config.feedbackTatil(duracaoMs: 120);
    if (!mounted) return;

    _dialogoAberto = true;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.vibration),
        title: const Text('Movimento identificado'),
        content: const Text('Deseja limpar o filtro aplicado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Limpar filtro'),
          ),
        ],
      ),
    );
    _dialogoAberto = false;

    if (confirmado == true && mounted) {
      _tarefaCtrl.limparFiltro();
      await _config.feedbackTatil(duracaoMs: 40);
    }
  }

  /// UC4 - adiciona tarefa.
  Future<void> _adicionar() async {
    final usuarioId = _auth.usuario?.id;
    if (usuarioId == null) return;

    final ok = await _tarefaCtrl.adicionar(
      listaId: widget.lista.id,
      usuarioId: usuarioId,
      descricao: _novaTarefa.text,
    );

    if (!mounted) return;

    if (ok) {
      _novaTarefa.clear();
      FocusScope.of(context).unfocus();
      await _config.feedbackTatil(duracaoMs: 40);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tarefaCtrl.erro ?? 'Informe a descrição.')),
      );
    }
  }

  /// UC4 - edita a descricao de uma tarefa existente.
  Future<void> _editar(Tarefa tarefa) async {
    final campo = TextEditingController(text: tarefa.descricao);

    final novo = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Editar tarefa'),
        content: TextField(
          controller: campo,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(campo.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    campo.dispose();

    if (novo != null && novo.trim().isNotEmpty && mounted) {
      await _tarefaCtrl.editar(
        id: tarefa.id,
        listaId: tarefa.listaId,
        descricao: novo,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarefaCtrl = context.watch<TarefaController>();

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
              stream: tarefaCtrl.tarefasDaLista(
                widget.lista.id,
                _auth.usuario?.id ?? '',
              ),
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
                          await _config.feedbackTatil(duracaoMs: 60);
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
