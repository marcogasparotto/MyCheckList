/// MODEL - Tarefa
/// Representa uma tarefa pertencente a uma lista (UC4, UC5).
class Tarefa {
  final String id;
  final String listaId;
  final String usuarioId;
  final String descricao;
  final bool concluida;
  final DateTime criadaEm;
  final DateTime? concluidaEm;

  const Tarefa({
    required this.id,
    required this.listaId,
    required this.usuarioId,
    required this.descricao,
    this.concluida = false,
    required this.criadaEm,
    this.concluidaEm,
  });

  factory Tarefa.fromMap(String id, Map<String, dynamic> map) {
    return Tarefa(
      id: id,
      listaId: (map['listaId'] ?? '') as String,
      usuarioId: (map['usuarioId'] ?? '') as String,
      descricao: (map['descricao'] ?? '') as String,
      concluida: (map['concluida'] ?? false) as bool,
      criadaEm: map['criadaEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['criadaEm'] as int)
          : DateTime.now(),
      concluidaEm: map['concluidaEm'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['concluidaEm'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listaId': listaId,
      'usuarioId': usuarioId,
      'descricao': descricao,
      'concluida': concluida,
      'criadaEm': criadaEm.millisecondsSinceEpoch,
      'concluidaEm': concluidaEm?.millisecondsSinceEpoch,
    };
  }

  Tarefa copyWith({String? descricao, bool? concluida, DateTime? concluidaEm}) {
    return Tarefa(
      id: id,
      listaId: listaId,
      usuarioId: usuarioId,
      descricao: descricao ?? this.descricao,
      concluida: concluida ?? this.concluida,
      criadaEm: criadaEm,
      concluidaEm: concluida == true ? (concluidaEm ?? DateTime.now()) : null,
    );
  }
}

/// Filtro de tarefas (UC6).
enum FiltroTarefa { todas, pendentes, concluidas }

extension FiltroTarefaLabel on FiltroTarefa {
  String get label {
    switch (this) {
      case FiltroTarefa.todas:
        return 'Todas';
      case FiltroTarefa.pendentes:
        return 'Pendentes';
      case FiltroTarefa.concluidas:
        return 'Concluídas';
    }
  }
}
