import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/admin_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/config_controller.dart';
import 'controllers/lista_controller.dart';
import 'controllers/tarefa_controller.dart';
import 'firebase_options.dart';
import 'views/admin_view.dart';
import 'views/cadastro_view.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';
import 'views/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyCheckListApp());
}

/// Raiz do aplicativo. Registra os Controllers (camada C do MVC - RNF06).
class MyCheckListApp extends StatelessWidget {
  const MyCheckListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConfigController()..carregar()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ListaController()),
        ChangeNotifierProvider(create: (_) => TarefaController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: Consumer<ConfigController>(
        builder: (context, config, _) {
          return MaterialApp(
            title: 'MyCheckList',
            debugShowCheckedModeBanner: false,
            theme: _tema(Brightness.light),
            darkTheme: _tema(Brightness.dark),
            themeMode: config.temaEscuro ? ThemeMode.dark : ThemeMode.light,
            home: const SplashView(),
            routes: {
              LoginView.rota: (_) => const LoginView(),
              CadastroView.rota: (_) => const CadastroView(),
              HomeView.rota: (_) => const HomeView(),
              AdminView.rota: (_) => const AdminView(),
            },
          );
        },
      ),
    );
  }

  ThemeData _tema(Brightness brilho) {
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2E6BE6),
      brightness: brilho,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }
}
