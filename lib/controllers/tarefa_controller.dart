import 'package:flutter/foundation.dart';

import '../models/tarefa.dart';
import '../services/firestore_service.dart';

/// CONTROLLER - Manutencao de tarefas (UC4), conclusao (UC5) e filtros (UC6).
class TarefaController extends ChangeNotifier {
  TarefaController({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  FiltroTarefa _filtro = FiltroTarefa.todas;
  String? _erro;

  FiltroTarefa get filtro => _filtro;
  String? get erro => _erro;
  bool get filtroAtivo => _filtro != FiltroTarefa.todas;

  Stream<List<Tarefa>> tarefasDaLista(String listaId, String usuarioId) =>
      _firestore.observarTarefas(listaId, usuarioId);

  /// UC6 - aplica o filtro selecionado sobre a lista carregada.
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

  void alterarFiltro(FiltroTarefa novo) {
    _filtro = novo;
    notifyListeners();
  }

  /// UC8 - limpeza do filtro disparada pela agitacao do aparelho.
  void limparFiltro() {
    _filtro = FiltroTarefa.todas;
    notifyListeners();
  }

  Future<bool> adicionar({
    required String listaId,
    required String usuarioId,
    required String descricao,
  }) async {
    if (descricao.trim().isEmpty) {
      _erro = 'Informe a descrição da tarefa.';
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
      ),
    );
    return true;
  }

  Future<bool> editar({
    required String id,
    required String listaId,
    required String usuarioId,
    required String descricao,
  }) async {
    if (descricao.trim().isEmpty) {
      _erro = 'Informe a descrição da tarefa.';
      notifyListeners();
      return false;
    }

    _erro = null;
    await _firestore.atualizarTarefa(id, listaId, usuarioId, {
      'descricao': descricao.trim(),
    });
    return true;
  }

  /// UC5 - alterna entre concluida e pendente.
  Future<void> alternarConclusao(Tarefa tarefa) async {
    final novoStatus = !tarefa.concluida;
    await _firestore.atualizarTarefa(tarefa.id, tarefa.listaId, tarefa.usuarioId, {
      'concluida': novoStatus,
      'concluidaEm': novoStatus ? DateTime.now().millisecondsSinceEpoch : null,
    });
  }

  Future<void> excluir(Tarefa tarefa) =>
      _firestore.excluirTarefa(tarefa.id, tarefa.listaId, tarefa.usuarioId);
}
