/// MODEL - Usuario
/// Representa um usuario do sistema, com separacao de perfis (RNF01, RNF02).
class Usuario {
  final String id; // UID do Firebase Auth
  final String nome;
  final String email;
  final String perfil; // 'admin' ou 'usuario'
  final bool ativo;
  final DateTime? criadoEm;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.perfil = perfilUsuario,
    this.ativo = true,
    this.criadoEm,
  });

  static const String perfilAdmin = 'admin';
  static const String perfilUsuario = 'usuario';

  bool get isAdmin => perfil == perfilAdmin;

  factory Usuario.fromMap(String id, Map<String, dynamic> map) {
    return Usuario(
      id: id,
      nome: (map['nome'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      perfil: (map['perfil'] ?? perfilUsuario) as String,
      ativo: (map['ativo'] ?? true) as bool,
      criadoEm: map['criadoEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['criadoEm'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'perfil': perfil,
      'ativo': ativo,
      'criadoEm': (criadoEm ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  Usuario copyWith({String? nome, String? perfil, bool? ativo}) {
    return Usuario(
      id: id,
      nome: nome ?? this.nome,
      email: email,
      perfil: perfil ?? this.perfil,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm,
    );
  }
}
