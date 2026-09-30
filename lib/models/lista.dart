/// MODEL - Lista
/// Representa uma lista pertencente a um usuario (UC3).
class Lista {
  final String id;
  final String usuarioId;
  final String nome;
  final String descricao;
  final DateTime criadaEm;

  // Contadores agregados (mantidos pelo Controller para a tela principal - UC6)
  final int totalTarefas;
  final int totalConcluidas;

  const Lista({
    required this.id,
    required this.usuarioId,
    required this.nome,
    this.descricao = '',
    required this.criadaEm,
    this.totalTarefas = 0,
    this.totalConcluidas = 0,
  });

  int get totalPendentes => totalTarefas - totalConcluidas;

  double get progresso => totalTarefas == 0 ? 0 : totalConcluidas / totalTarefas;

  factory Lista.fromMap(String id, Map<String, dynamic> map) {
    return Lista(
      id: id,
      usuarioId: (map['usuarioId'] ?? '') as String,
      nome: (map['nome'] ?? '') as String,
      descricao: (map['descricao'] ?? '') as String,
      criadaEm: map['criadaEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['criadaEm'] as int)
          : DateTime.now(),
      totalTarefas: (map['totalTarefas'] ?? 0) as int,
      totalConcluidas: (map['totalConcluidas'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'nome': nome,
      'descricao': descricao,
      'criadaEm': criadaEm.millisecondsSinceEpoch,
      'totalTarefas': totalTarefas,
      'totalConcluidas': totalConcluidas,
    };
  }

  Lista copyWith({
    String? nome,
    String? descricao,
    int? totalTarefas,
    int? totalConcluidas,
  }) {
    return Lista(
      id: id,
      usuarioId: usuarioId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      criadaEm: criadaEm,
      totalTarefas: totalTarefas ?? this.totalTarefas,
      totalConcluidas: totalConcluidas ?? this.totalConcluidas,
    );
  }
}
