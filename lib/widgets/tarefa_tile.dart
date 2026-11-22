import 'package:flutter/material.dart';

import '../models/tarefa.dart';

/// WIDGET - Item de tarefa com caixa de selecao (UC5) e prazo (UC4).
class TarefaTile extends StatelessWidget {
  const TarefaTile({
    super.key,
    required this.tarefa,
    required this.onAlternar,
    required this.onEditar,
    required this.onExcluir,
  });

  final Tarefa tarefa;
  final VoidCallback onAlternar;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(tarefa.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Theme.of(context).colorScheme.errorContainer,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onExcluir(),
      child: ListTile(
        leading: Checkbox(
          value: tarefa.concluida,
          onChanged: (_) => onAlternar(),
        ),
        title: Text(
          tarefa.descricao,
          // Tarefa concluida visualmente diferenciada (UC5, passo 4).
          style: TextStyle(
            decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
            color: tarefa.concluida ? Theme.of(context).disabledColor : null,
          ),
        ),
        subtitle: _subtitulo(context),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEditar,
        ),
        onTap: onAlternar,
      ),
    );
  }

  /// Mostra o prazo somente em tarefas pendentes.
  Widget? _subtitulo(BuildContext context) {
    final dias = tarefa.diasParaVencer;
    if (dias == null || tarefa.concluida) return null;

    final cores = Theme.of(context).colorScheme;
    Color cor = cores.onSurfaceVariant;
    if (dias <= 0) {
      cor = cores.error;
    } else if (dias <= 2) {
      cor = cores.tertiary;
    }

    return Text(
      _textoPrazo(dias),
      style: TextStyle(color: cor, fontWeight: dias <= 2 ? FontWeight.w600 : null),
    );
  }
}

String _textoPrazo(int dias) {
  if (dias < 0) {
    final n = -dias;
    return 'Atrasada há $n ${n == 1 ? 'dia' : 'dias'}';
  }
  if (dias == 0) return 'Vence hoje';
  if (dias == 1) return 'Vence amanhã';
  return 'Vence em $dias dias';
}