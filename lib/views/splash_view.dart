import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/config_controller.dart';
import 'admin_view.dart';
import 'home_view.dart';
import 'login_view.dart';

/// VIEW - Tela inicial. Restaura sessao e preferencias (RNF09) e direciona
/// o usuario conforme o perfil autenticado (UC2 / RNF02).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    final auth = context.read<AuthController>();
    final config = context.read<ConfigController>();

    if (!config.carregado) await config.carregar();
    await auth.carregarSessao();

    if (!mounted) return;

    if (!auth.autenticado) {
      Navigator.of(context).pushReplacementNamed(LoginView.rota);
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      auth.isAdmin ? AdminView.rota : HomeView.rota,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checklist_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'MyCheckList',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
