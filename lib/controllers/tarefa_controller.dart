import 'package:flutter/foundation.dart';

import '../models/tarefa.dart';
import '../services/firestore_service.dart';

/// CONTROLLER - Manutencao de tarefas (UC4, UC5), filtro (UC6) e
/// vencimentos (aviso ao agitar na tela principal).
class TarefaController extends ChangeNotifier {
  TarefaController({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  String? _erro;
  String? get erro => _erro;

  FiltroTarefa _filtro = FiltroTarefa.todas;
  FiltroTarefa get filtro => _filtro;
  bool get filtroAtivo => _filtro != FiltroTarefa.todas;

  // ------------------------------------------------------------ FILTRO (UC6)

  void alterarFiltro(FiltroTarefa f) {
    _filtro = f;
    notifyListeners();
  }

  void limparFiltro() {
    _filtro = FiltroTarefa.todas;
    notifyListeners();
  }

  List<Tarefa> aplicarFiltro(List<Tarefa> tarefas) {
    switch (_filtro) {
      case FiltroTarefa.todas:
        return tarefas;
      case FiltroTarefa.pendentes:
        return tarefas.where((t) => !t.concluida).toList();
      case FiltroTarefa.concluidas:
        return tarefas.where((t) => t.concluida).toList();
    }
  }

  // ----------------------------------------------------------------- TAREFAS

  Stream<List<Tarefa>> tarefasDaLista(String listaId, String usuarioId) =>
      _firestore.observarTarefas(listaId, usuarioId);

  /// Converte "dias a partir de hoje" em data limite (meia-noite do dia).
  DateTime _prazoEm(int dias) {
    final hoje = DateTime.now();
    return DateTime(hoje.year, hoje.month, hoje.day + dias);
  }

  /// UC4 - adiciona tarefa. prazoDias e opcional (null = sem prazo).
  Future<bool> adicionar({
    required String listaId,
    required String usuarioId,
    required String descricao,
    int? prazoDias,
  }) async {
    if (descricao.trim().isEmpty) {
      _erro = 'Informe a descrição.';
      notifyListeners();
      return false;
    }
    if (prazoDias != null && prazoDias < 0) {
      _erro = 'O prazo deve ser de 0 dias ou mais.';
      notifyListeners();
      return false;
    }

    _erro = null;
    await _firestore.criarTarefa(
      Tarefa(
        id: '',
        listaId: listaId,
        usuarioId: usuarioId,
        descricao: descricao.trim(),
        criadaEm: DateTime.now(),
        prazo: prazoDias == null ? null : _prazoEm(prazoDias),
      ),
    );
    return true;
  }

  /// UC4 - edita descricao e prazo. prazoDias null remove o prazo.
  Future<bool> editar({
    required String id,
    required String listaId,
    required String usuarioId,
    required String descricao,
    int? prazoDias,
  }) async {
    if (descricao.trim().isEmpty) {
      _erro = 'Informe a descrição.';
      notifyListeners();
      return false;
    }
    if (prazoDias != null && prazoDias < 0) {
      _erro = 'O prazo deve ser de 0 dias ou mais.';
      notifyListeners();
      return false;
    }

    _erro = null;
    await _firestore.atualizarTarefa(id, listaId, usuarioId, {
      'descricao': descricao.trim(),
      'prazo': prazoDias == null
          ? null
          : _prazoEm(prazoDias).millisecondsSinceEpoch,
    });
    return true;
  }

  /// UC5 - marca ou desmarca a tarefa como concluida.
  Future<void> alternarConclusao(Tarefa tarefa) {
    final concluir = !tarefa.concluida;
    return _firestore.atualizarTarefa(
      tarefa.id,
      tarefa.listaId,
      tarefa.usuarioId,
      {
        'concluida': concluir,
        'concluidaEm': concluir ? DateTime.now().millisecondsSinceEpoch : null,
      },
    );
  }

  /// UC4 - exclui a tarefa.
  Future<void> excluir(Tarefa tarefa) =>
      _firestore.excluirTarefa(tarefa.id, tarefa.listaId, tarefa.usuarioId);

  // ------------------------------------------------------------ VENCIMENTOS

  /// Tarefas pendentes com prazo, da mais urgente para a menos urgente.
  Future<List<ProximoVencimento>> proximosVencimentos(
    String usuarioId, {
    int limite = 5,
  }) async {
    final tarefas = await _firestore.buscarTarefasComPrazo(usuarioId);
    final listas = await _firestore.buscarListas(usuarioId);
    final nomes = {for (final l in listas) l.id: l.nome};

    tarefas.sort((a, b) => a.prazo!.compareTo(b.prazo!));

    return tarefas
        .take(limite)
        .map((t) => ProximoVencimento(
              tarefa: t,
              nomeLista: nomes[t.listaId] ?? 'Lista',
            ))
        .toList();
  }
}

/// Tarefa com o nome da lista de origem (usado no aviso de vencimento).
class ProximoVencimento {
  const ProximoVencimento({required this.tarefa, required this.nomeLista});

  final Tarefa tarefa;
  final String nomeLista;
}