import 'package:flutter/foundation.dart';

import '../models/lista.dart';
import '../services/firestore_service.dart';

/// CONTROLLER - Manutencao de listas (UC3) e consulta da tela principal (UC6).
class ListaController extends ChangeNotifier {
  ListaController({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  String? _erro;
  String? get erro => _erro;

  /// RNF07 - o stream ja e filtrado pelo usuario autenticado.
  Stream<List<Lista>> listasDoUsuario(String usuarioId) =>
      _firestore.observarListas(usuarioId);

  Future<bool> criar({
    required String usuarioId,
    required String nome,
    String descricao = '',
  }) async {
    if (nome.trim().isEmpty) {
      _erro = 'Informe o nome da lista.';
      notifyListeners();
      return false;
    }

    _erro = null;
    await _firestore.criarLista(
      Lista(
        id: '',
        usuarioId: usuarioId,
        nome: nome.trim(),
        descricao: descricao.trim(),
        criadaEm: DateTime.now(),
      ),
    );
    return true;
  }

  Future<bool> editar({
    required String id,
    required String nome,
    String descricao = '',
  }) async {
    if (nome.trim().isEmpty) {
      _erro = 'Informe o nome da lista.';
      notifyListeners();
      return false;
    }

    _erro = null;
    await _firestore.atualizarLista(id, {
      'nome': nome.trim(),
      'descricao': descricao.trim(),
    });
    return true;
  }

  Future<void> excluir(Lista lista) =>
      _firestore.excluirLista(lista.id, lista.usuarioId);
}
