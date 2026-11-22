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

  /// Data limite (meia-noite do dia). Opcional.
  final DateTime? prazo;

  const Tarefa({
    required this.id,
    required this.listaId,
    required this.usuarioId,
    required this.descricao,
    this.concluida = false,
    required this.criadaEm,
    this.concluidaEm,
    this.prazo,
  });

  /// Dias ate o vencimento: 0 = vence hoje, negativo = atrasada.
  /// Null quando a tarefa nao tem prazo.
  int? get diasParaVencer {
    final p = prazo;
    if (p == null) return null;
    final hoje = DateTime.now();
    // Compara so as datas, em UTC, para o horario de verao nao alterar o resultado.
    final dataPrazo = DateTime.utc(p.year, p.month, p.day);
    final dataHoje = DateTime.utc(hoje.year, hoje.month, hoje.day);
    return dataPrazo.difference(dataHoje).inDays;
  }

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
      prazo: map['prazo'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['prazo'] as int)
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
      'prazo': prazo?.millisecondsSinceEpoch,
    };
  }

  Tarefa copyWith({
    String? descricao,
    bool? concluida,
    DateTime? concluidaEm,
    DateTime? prazo,
  }) {
    return Tarefa(
      id: id,
      listaId: listaId,
      usuarioId: usuarioId,
      descricao: descricao ?? this.descricao,
      concluida: concluida ?? this.concluida,
      criadaEm: criadaEm,
      concluidaEm: concluida == true ? (concluidaEm ?? DateTime.now()) : null,
      prazo: prazo ?? this.prazo,
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