import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';
import '../controllers/lista_controller.dart';
import '../models/lista.dart';
import '../widgets/lista_card.dart';
import 'config_view.dart';
import 'login_view.dart';
import 'tarefas_view.dart';

/// VIEW - Tela principal: listas do usuario com progresso (UC3, UC6).
class HomeView extends StatelessWidget {
  const HomeView({super.key});
  static const rota = '/home';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final listaCtrl = context.read<ListaController>();
    final usuario = auth.usuario;

    if (usuario == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas listas'),
        actions: [
          IconButton(
            tooltip: 'Configurações',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(ConfigView.rota),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthController>().sair();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginView.rota,
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova lista'),
      ),
      body: StreamBuilder<List<Lista>>(
        stream: listaCtrl.listasDoUsuario(usuario.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _Mensagem(
              icone: Icons.cloud_off,
              titulo: 'Não foi possível carregar suas listas',
              texto: 'Verifique sua conexão e tente novamente.',
            );
          }

          final listas = snapshot.data ?? [];
          if (listas.isEmpty) {
            return const _Mensagem(
              icone: Icons.checklist_rtl,
              titulo: 'Nenhuma lista ainda',
              texto: 'Toque em "Nova lista" para começar.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: listas.length,
            itemBuilder: (context, i) {
              final lista = listas[i];
              return ListaCard(
                lista: lista,
                onAbrir: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TarefasView(lista: lista),
                  ),
                ),
                onEditar: () => _abrirFormulario(context, lista: lista),
                onExcluir: () => _confirmarExclusao(context, lista),
              );
            },
          );
        },
      ),
    );
  }

  /// UC3 - abre o formulario de criacao / edicao de lista.
  /// Os controllers ficam dentro de _FormularioLista, que os descarta quando
  /// o formulario sai da tela. Descarta-los aqui, logo apos o await, quebrava
  /// a animacao de saida da folha.
  Future<void> _abrirFormulario(BuildContext context, {Lista? lista}) async {
    final ctrl = context.read<ListaController>();
    final config = context.read<ConfigController>();
    final usuarioId = context.read<AuthController>().usuario!.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormularioLista(
        lista: lista,
        ctrl: ctrl,
        config: config,
        usuarioId: usuarioId,
      ),
    );
  }

  /// UC3 - exclui a lista depois de confirmar. Falhas sao mostradas ao usuario.
  Future<void> _confirmarExclusao(BuildContext context, Lista lista) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir lista'),
        content: Text(
          'Excluir "${lista.nome}" e todas as suas tarefas?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    try {
      await context.read<ListaController>().excluir(lista.id);
    } catch (e, s) {
      debugPrint('Erro ao excluir lista: $e\n$s');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a lista.')),
      );
    }
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({
    required this.icone,
    required this.titulo,
    required this.texto,
  });

  final IconData icone;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario de lista. Dono dos controllers: cria no initState e descarta no
/// dispose, so depois que a folha sai da arvore.
class _FormularioLista extends StatefulWidget {
  const _FormularioLista({
    required this.ctrl,
    required this.config,
    required this.usuarioId,
    this.lista,
  });

  final Lista? lista;
  final ListaController ctrl;
  final ConfigController config;
  final String usuarioId;

  @override
  State<_FormularioLista> createState() => _FormularioListaState();
}

class _FormularioListaState extends State<_FormularioLista> {
  late final TextEditingController _nome;
  late final TextEditingController _descricao;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Erro exibido dentro da folha. Um SnackBar ficaria escondido atras dela.
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.lista?.nome ?? '');
    _descricao = TextEditingController(text: widget.lista?.descricao ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _erro = null);
    final lista = widget.lista;

    try {
      final ok = lista == null
          ? await widget.ctrl.criar(
              usuarioId: widget.usuarioId,
              nome: _nome.text,
              descricao: _descricao.text,
            )
          : await widget.ctrl.editar(
              id: lista.id,
              nome: _nome.text,
              descricao: _descricao.text,
            );

      if (!mounted) return;
      if (!ok) {
        setState(() => _erro = 'Não foi possível salvar a lista.');
        return;
      }

      await widget.config.feedbackTatil(duracaoMs: 40);
      if (mounted) Navigator.of(context).pop();
    } catch (e, s) {
      debugPrint('Erro ao salvar lista: $e\n$s');
      if (mounted) {
        setState(() => _erro = 'Não foi possível salvar a lista.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.lista == null ? 'Nova lista' : 'Editar lista',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome da lista'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Informe o nome da lista'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricao,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvar,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}