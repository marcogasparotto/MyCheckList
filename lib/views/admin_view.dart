import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import 'config_view.dart';
import 'login_view.dart';

/// VIEW - Painel do Administrador (UC1 / A1).
/// Consulta, ativacao e desativacao de usuarios.
class AdminView extends StatelessWidget {
  const AdminView({super.key});
  static const rota = '/admin';

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar usuários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed(ConfigView.rota),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthController>().sair();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(LoginView.rota, (_) => false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: admin.alterarBusca,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou e-mail',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Usuario>>(
              stream: admin.usuarios,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = admin.filtrar(snapshot.data ?? []);
                if (usuarios.isEmpty) {
                  return const Center(
                    child: Text('Nenhum usuário encontrado.'),
                  );
                }

                return ListView.separated(
                  itemCount: usuarios.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = usuarios[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: u.ativo
                            ? Colors.green.shade100
                            : Colors.grey.shade300,
                        child: Icon(
                          u.isAdmin
                              ? Icons.admin_panel_settings
                              : Icons.person_outline,
                          color: u.ativo ? Colors.green : Colors.grey,
                        ),
                      ),
                      title: Text(u.nome),
                      subtitle: Text(u.email),
                      trailing: Switch(
                        value: u.ativo,
                        onChanged: (valor) => valor
                            ? admin.ativar(u)
                            : admin.desativar(u),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
