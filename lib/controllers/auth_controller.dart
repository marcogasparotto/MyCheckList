import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/firestore_service.dart';
import '../services/prefs_service.dart';

/// CONTROLLER - Autenticacao e cadastro (UC1, UC2).
class AuthController extends ChangeNotifier {
  AuthController({
    FirebaseAuth? auth,
    FirestoreService? firestore,
    PrefsService? prefs,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirestoreService(),
        _prefs = prefs ?? PrefsService();

  final FirebaseAuth _auth;
  final FirestoreService _firestore;
  final PrefsService _prefs;

  Usuario? _usuario;
  bool _carregando = false;
  String? _erro;

  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get isAdmin => _usuario?.isAdmin ?? false;
  bool get carregando => _carregando;
  String? get erro => _erro;

  void _setCarregando(bool v) {
    _carregando = v;
    notifyListeners();
  }

  void limparErro() {
    _erro = null;
    notifyListeners();
  }

  /// Restaura a sessao ao abrir o app (RNF09).
  Future<void> carregarSessao() async {
    final atual = _auth.currentUser;
    if (atual == null) return;

    _setCarregando(true);
    _usuario = await _firestore.buscarUsuario(atual.uid);

    // Conta desativada pelo Administrador nao mantem a sessao (UC1).
    if (_usuario != null && !_usuario!.ativo) {
      await _auth.signOut();
      _usuario = null;
      _erro = 'Sua conta está desativada. Procure o administrador.';
    }
    _setCarregando(false);
  }

  /// UC1 - Cadastro de novo usuario.
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String confirmacaoSenha,
  }) async {
    _erro = null;

    final validacao = _validarCadastro(nome, email, senha, confirmacaoSenha);
    if (validacao != null) {
      _erro = validacao;
      notifyListeners();
      return false;
    }

    _setCarregando(true);
    try {
      final emailNormalizado = email.trim().toLowerCase();

      // Cria a conta no Auth PRIMEIRO: a partir daqui existe sessao e as
      // regras do Firestore liberam a escrita em `usuarios`. A verificacao
      // de e-mail duplicado e feita pelo proprio Firebase Auth, que devolve
      // o codigo `email-already-in-use`.
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailNormalizado,
        password: senha,
      );

      final novo = Usuario(
        id: cred.user!.uid,
        nome: nome.trim(),
        email: emailNormalizado,
        perfil: Usuario.perfilUsuario,
        ativo: true,
        criadoEm: DateTime.now(),
      );

      await _firestore.criarUsuario(novo);
      _usuario = novo;
      await _prefs.salvarUltimoEmail(emailNormalizado);
      return true;
    } on FirebaseAuthException catch (e) {
      _erro = _traduzirErro(e.code);
      return false;
    } finally {
      _setCarregando(false);
    }
  }

  /// UC2 - Autenticacao.
  Future<bool> entrar({required String email, required String senha}) async {
    _erro = null;

    if (email.trim().isEmpty || senha.isEmpty) {
      _erro = 'Informe e-mail e senha.';
      notifyListeners();
      return false;
    }

    _setCarregando(true);
    try {
      final emailNormalizado = email.trim().toLowerCase();
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailNormalizado,
        password: senha,
      );

      final perfil = await _firestore.buscarUsuario(cred.user!.uid);
      if (perfil == null) {
        await _auth.signOut();
        _erro = 'Cadastro não encontrado.';
        return false;
      }
      if (!perfil.ativo) {
        await _auth.signOut();
        _erro = 'Sua conta está desativada. Procure o administrador.';
        return false;
      }

      _usuario = perfil;
      await _prefs.salvarUltimoEmail(emailNormalizado);
      return true;
    } on FirebaseAuthException catch (e) {
      _erro = _traduzirErro(e.code);
      return false;
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> sair() async {
    await _auth.signOut();
    _usuario = null;
    notifyListeners();
  }

  // ------------------------------------------------------------- VALIDACOES

  String? _validarCadastro(
      String nome,
      String email,
      String senha,
      String confirmacao,
      ) {
    if (nome.trim().length < 3) {
      return 'Informe um nome com pelo menos 3 caracteres.';
    }
    final regexEmail = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!regexEmail.hasMatch(email.trim())) {
      return 'Informe um e-mail válido.';
    }
    if (senha.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (senha != confirmacao) {
      return 'A confirmação de senha não confere.';
    }
    return null;
  }

  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'A senha é muito fraca.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Não foi possível concluir a operação.';
    }
  }
}
