import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/firestore_service.dart';

/// CONTROLLER - Gerenciamento de contas pelo Administrador (UC1 / A1).
class AdminController extends ChangeNotifier {
  AdminController({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  final FirestoreService _firestore;

  String _busca = '';
  String get busca => _busca;

  Stream<List<Usuario>> get usuarios => _firestore.observarUsuarios();

  void alterarBusca(String valor) {
    _busca = valor.trim().toLowerCase();
    notifyListeners();
  }

  List<Usuario> filtrar(List<Usuario> lista) {
    if (_busca.isEmpty) return lista;
    return lista
        .where((u) =>
            u.nome.toLowerCase().contains(_busca) ||
            u.email.toLowerCase().contains(_busca))
        .toList();
  }

  Future<void> ativar(Usuario usuario) =>
      _firestore.alterarStatusUsuario(usuario.id, true);

  Future<void> desativar(Usuario usuario) =>
      _firestore.alterarStatusUsuario(usuario.id, false);
}
