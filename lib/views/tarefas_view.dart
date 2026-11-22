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
  final TextEditingController _novoPrazo = TextEditingController();

  // Guardados no initState para serem usados com seguranca depois de awaits.
  late final ConfigController _config;
  late final TarefaController _tarefaCtrl;
  late final AuthController _auth;

  // Stream criado UMA vez. Se fosse criado no build, cada reconstrucao
  // abriria uma nova consulta no Firestore.
  late final Stream<List<Tarefa>> _tarefasStream;

  bool _dialogoAberto = false;

  @override
  void initState() {
    super.initState();
    _config = context.read<ConfigController>();
    _tarefaCtrl = context.read<TarefaController>();
    _auth = context.read<AuthController>();

    _tarefasStream = _tarefaCtrl.tarefasDaLista(
      widget.lista.id,
      _auth.usuario?.id ?? '',
    );

    _config.iniciarMonitoramento(_aoAgitar);
  }

  @override
  void dispose() {
    // Devolve o acelerometro para a tela principal.
    _config.pararMonitoramento();
    _novaTarefa.dispose();
    _novoPrazo.dispose();
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

  /// UC4 - adiciona tarefa. O prazo em dias e opcional.
  Future<void> _adicionar() async {
    final usuarioId = _auth.usuario?.id;
    if (usuarioId == null) return;

    final ok = await _tarefaCtrl.adicionar(
      listaId: widget.lista.id,
      usuarioId: usuarioId,
      descricao: _novaTarefa.text,
      prazoDias: int.tryParse(_novoPrazo.text.trim()),
    );

    if (!mounted) return;

    if (ok) {
      _novaTarefa.clear();
      _novoPrazo.clear();
      FocusScope.of(context).unfocus();
      await _config.feedbackTatil(duracaoMs: 40);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tarefaCtrl.erro ?? 'Informe a descrição.')),
      );
    }
  }

  /// UC4 - edita a descricao e o prazo de uma tarefa existente.
  Future<void> _editar(Tarefa tarefa) async {
    final restantes = tarefa.diasParaVencer;

    final edicao = await showDialog<({String descricao, int? dias})>(
      context: context,
      builder: (_) => _DialogoEdicaoTarefa(
        descricaoInicial: tarefa.descricao,
        diasInicial: restantes == null ? null : (restantes < 0 ? 0 : restantes),
      ),
    );

    if (edicao == null || edicao.descricao.trim().isEmpty || !mounted) return;

    try {
      final ok = await _tarefaCtrl.editar(
        id: tarefa.id,
        listaId: tarefa.listaId,
        usuarioId: tarefa.usuarioId,
        descricao: edicao.descricao,
        prazoDias: edicao.dias,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tarefaCtrl.erro ?? 'Não foi possível salvar.')),
        );
      }
    } catch (e, s) {
      debugPrint('Erro ao editar tarefa: $e\n$s');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar a tarefa.')),
      );
    }
  }

  /// UC4 - exclui a tarefa. Falhas do Firestore sao mostradas ao usuario.
  Future<void> _excluir(Tarefa tarefa) async {
    try {
      await _tarefaCtrl.excluir(tarefa);
    } catch (e, s) {
      debugPrint('Erro ao excluir tarefa: $e\n$s');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a tarefa.')),
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
              stream: _tarefasStream,
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
                      onExcluir: () => _excluir(tarefa),
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
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _novoPrazo,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'dias',
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

/// Caixa de edicao da descricao e do prazo. Os controllers ficam no State
/// deste dialogo e so sao descartados quando o dialogo sai da tela.
class _DialogoEdicaoTarefa extends StatefulWidget {
  const _DialogoEdicaoTarefa({
    required this.descricaoInicial,
    this.diasInicial,
  });

  final String descricaoInicial;
  final int? diasInicial;

  @override
  State<_DialogoEdicaoTarefa> createState() => _DialogoEdicaoTarefaState();
}

class _DialogoEdicaoTarefaState extends State<_DialogoEdicaoTarefa> {
  late final TextEditingController _campo;
  late final TextEditingController _dias;

  @override
  void initState() {
    super.initState();
    _campo = TextEditingController(text: widget.descricaoInicial);
    _dias = TextEditingController(text: widget.diasInicial?.toString() ?? '');
  }

  @override
  void dispose() {
    _campo.dispose();
    _dias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarefa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _campo,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Descrição'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dias,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prazo em dias (opcional)',
              helperText: 'Contado a partir de hoje. Vazio = sem prazo.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((
            descricao: _campo.text,
            dias: int.tryParse(_dias.text.trim()),
          )),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}