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

  /// Mantido para uso futuro. No fluxo de cadastro o proprio Firebase Auth
  /// ja barra e-mail repetido (codigo `email-already-in-use`), por isso
  /// esta consulta nao e usada antes da conta existir.
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
  /// A consulta tambem filtra por usuarioId, pelo mesmo motivo de
  /// observarTarefas: sem esse filtro as regras negam com `permission-denied`.
  Future<void> excluirLista(String id, String usuarioId) async {
    final tarefas = await _tarefas
        .where('listaId', isEqualTo: id)
        .where('usuarioId', isEqualTo: usuarioId)
        .get();
    final lote = _db.batch();
    for (final doc in tarefas.docs) {
      lote.delete(doc.reference);
    }
    lote.delete(_listas.doc(id));
    await lote.commit();
  }

  // ----------------------------------------------------------------- TAREFAS

  /// RNF07 - o filtro por usuarioId repete a condicao da regra do Firestore.
  /// Sem ele, a consulta e negada por `permission-denied`, porque o Firestore
  /// nao consegue provar sozinho que os documentos pertencem ao usuario.
  Stream<List<Tarefa>> observarTarefas(String listaId, String usuarioId) {
    return _tarefas
        .where('listaId', isEqualTo: listaId)
        .where('usuarioId', isEqualTo: usuarioId)
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
    await _recalcularContadores(tarefa.listaId, tarefa.usuarioId);
    return ref.id;
  }

  Future<void> atualizarTarefa(
      String id,
      String listaId,
      String usuarioId,
      Map<String, dynamic> dados,
      ) async {
    await _tarefas.doc(id).update(dados);
    await _recalcularContadores(listaId, usuarioId);
  }

  Future<void> excluirTarefa(String id, String listaId, String usuarioId) async {
    await _tarefas.doc(id).delete();
    await _recalcularContadores(listaId, usuarioId);
  }

  /// Mantem os agregados da lista atualizados para a tela principal (UC6).
  /// A consulta filtra por usuarioId para passar pelas regras (RNF07).
  Future<void> _recalcularContadores(String listaId, String usuarioId) async {
    final snap = await _tarefas
        .where('listaId', isEqualTo: listaId)
        .where('usuarioId', isEqualTo: usuarioId)
        .get();
    final total = snap.docs.length;
    final concluidas =
        snap.docs.where((d) => (d.data()['concluida'] ?? false) == true).length;

    await _listas.doc(listaId).update({
      'totalTarefas': total,
      'totalConcluidas': concluidas,
    });
  }
}
