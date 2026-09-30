import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';

/// VIEW - Configuracoes do aplicativo (UC7).
/// As preferencias sao gravadas no armazenamento interno (RNF03).
class ConfigView extends StatelessWidget {
  const ConfigView({super.key});
  static const rota = '/configuracoes';

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final usuario = context.watch<AuthController>().usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        children: [
          if (usuario != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(usuario.nome),
              subtitle: Text(usuario.email),
              trailing: Chip(
                label: Text(usuario.isAdmin ? 'Administrador' : 'Usuário'),
              ),
            ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tema escuro'),
            subtitle: const Text('Alterna a aparência do aplicativo'),
            value: config.temaEscuro,
            onChanged: config.alterarTema,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibração'),
            subtitle: const Text('Retorno tátil ao concluir tarefas'),
            value: config.vibracao,
            onChanged: config.alterarVibracao,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('MyCheckList'),
            subtitle: Text('Versão 1.0.0'),
          ),
        ],
      ),
    );
  }
}
