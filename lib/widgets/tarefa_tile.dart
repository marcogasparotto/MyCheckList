import 'package:flutter/material.dart';

import '../models/tarefa.dart';

/// WIDGET - Item de tarefa com caixa de selecao (UC5).
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
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEditar,
        ),
        onTap: onAlternar,
      ),
    );
  }
}