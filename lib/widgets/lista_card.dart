import 'package:flutter/material.dart';

import '../models/lista.dart';

/// WIDGET - Cartao de lista com contadores e progresso (UC6).
class ListaCard extends StatelessWidget {
  const ListaCard({
    super.key,
    required this.lista,
    required this.onAbrir,
    required this.onEditar,
    required this.onExcluir,
  });

  final Lista lista;
  final VoidCallback onAbrir;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lista.nome,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) =>
                        v == 'editar' ? onEditar() : onExcluir(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                    ],
                  ),
                ],
              ),
              if (lista.descricao.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  lista.descricao,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: lista.progresso,
                  minHeight: 8,
                  backgroundColor: cores.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Chip(
                    icone: Icons.list_alt,
                    texto: '${lista.totalTarefas} tarefas',
                  ),
                  _Chip(
                    icone: Icons.check_circle_outline,
                    texto: '${lista.totalConcluidas} concluídas',
                    cor: Colors.green,
                  ),
                  _Chip(
                    icone: Icons.pending_outlined,
                    texto: '${lista.totalPendentes} pendentes',
                    cor: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icone, required this.texto, this.cor});

  final IconData icone;
  final String texto;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final cor0 = cor ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: cor0),
        const SizedBox(width: 4),
        Text(texto, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
