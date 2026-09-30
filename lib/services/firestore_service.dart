import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lista.dart';
import '../models/tarefa.dart';
import '../models/usuario.dart';

/// SERVICE - Persistencia externa em nuvem (RNF04).
/// Encapsula todo o acesso ao Cloud Firestore; os Controllers nao conhecem
/// a API do Firebase diretamente.
class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _db.collection('usuarios');
  CollectionReference<Map<String, dynamic>> get _listas =>
      _db.collection('listas');
  CollectionReference<Map<String, dynamic>> get _tarefas =>
      _db.collection('tarefas');

  // ---------------------------------------------------------------- USUARIOS

  Future<void> criarUsuario(Usuario usuario) async {
    await _usuarios.doc(usuario.id).set(usuario.toMap());
  }

  Future<Usuario?> buscarUsuario(String uid) async {
    final doc = await _usuarios.doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.id, doc.data()!);
  }

  Future<bool> emailJaCadastrado(String email) async {
    final snap = await _usuarios
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// UC1 - consulta de usuarios pelo Administrador.
  Stream<List<Usuario>> observarUsuarios() {
    return _usuarios.orderBy('nome').snapshots().map(
          (snap) => snap.docs
              .map((d) => Usuario.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// UC1 - ativar / desativar conta.
  Future<void> alterarStatusUsuario(String uid, bool ativo) async {
    await _usuarios.doc(uid).update({'ativo': ativo});
  }

  // ------------------------------------------------------------------ LISTAS

  /// RNF07 - somente as listas do proprio usuario.
  Stream<List<Lista>> observarListas(String usuarioId) {
    return _listas
        .where('usuarioId', isEqualTo: usuarioId)
        .snapshots()
        .map((snap) {
      final listas =
          snap.docs.map((d) => Lista.fromMap(d.id, d.data())).toList();
      listas.sort((a, b) => b.criadaEm.compareTo(a.criadaEm));
      return listas;
    });
  }

  Future<String> criarLista(Lista lista) async {
    final ref = await _listas.add(lista.toMap());
    return ref.id;
  }

  Future<void> atualizarLista(String id, Map<String, dynamic> dados) async {
    await _listas.doc(id).update(dados);
  }

  /// Exclui a lista e, em lote, todas as tarefas vinculadas a ela.
  Future<void> excluirLista(String id) async {
    final tarefas = await _tarefas.where('listaId', isEqualTo: id).get();
    final lote = _db.batch();
    for (final doc in tarefas.docs) {
      lote.delete(doc.reference);
    }
    lote.delete(_listas.doc(id));
    await lote.commit();
  }

  // ----------------------------------------------------------------- TAREFAS

  Stream<List<Tarefa>> observarTarefas(String listaId) {
    return _tarefas
        .where('listaId', isEqualTo: listaId)
        .snapshots()
        .map((snap) {
      final tarefas =
          snap.docs.map((d) => Tarefa.fromMap(d.id, d.data())).toList();
      tarefas.sort((a, b) => a.criadaEm.compareTo(b.criadaEm));
      return tarefas;
    });
  }

  Future<String> criarTarefa(Tarefa tarefa) async {
    final ref = await _tarefas.add(tarefa.toMap());
    await _recalcularContadores(tarefa.listaId);
    return ref.id;
  }

  Future<void> atualizarTarefa(
    String id,
    String listaId,
    Map<String, dynamic> dados,
  ) async {
    await _tarefas.doc(id).update(dados);
    await _recalcularContadores(listaId);
  }

  Future<void> excluirTarefa(String id, String listaId) async {
    await _tarefas.doc(id).delete();
    await _recalcularContadores(listaId);
  }

  /// Mantem os agregados da lista atualizados para a tela principal (UC6).
  Future<void> _recalcularContadores(String listaId) async {
    final snap = await _tarefas.where('listaId', isEqualTo: listaId).get();
    final total = snap.docs.length;
    final concluidas =
        snap.docs.where((d) => (d.data()['concluida'] ?? false) == true).length;

    await _listas.doc(listaId).update({
      'totalTarefas': total,
      'totalConcluidas': concluidas,
    });
  }
}