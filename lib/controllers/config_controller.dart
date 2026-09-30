import 'package:flutter/foundation.dart';

import '../services/device_service.dart';
import '../services/prefs_service.dart';

/// CONTROLLER - Configuracoes do aplicativo (UC7 / RNF03).
///
/// Tambem centraliza o monitoramento do acelerometro (UC8): a tela de
/// tarefas pede para ligar/desligar, e este controller mantem uma unica
/// instancia do DeviceService para todo o app.
class ConfigController extends ChangeNotifier {
  ConfigController({PrefsService? prefs, DeviceService? device})
      : _prefs = prefs ?? PrefsService(),
        _device = device ?? DeviceService();

  final PrefsService _prefs;
  final DeviceService _device;

  bool _temaEscuro = false;
  bool _vibracao = true;
  bool _carregado = false;

  bool get temaEscuro => _temaEscuro;
  bool get vibracao => _vibracao;
  bool get carregado => _carregado;

  /// Le as preferencias do armazenamento interno na inicializacao.
  Future<void> carregar() async {
    _temaEscuro = await _prefs.lerTemaEscuro();
    _vibracao = await _prefs.lerVibracao();
    _carregado = true;
    notifyListeners();
  }

  Future<void> alterarTema(bool valor) async {
    _temaEscuro = valor;
    notifyListeners();
    await _prefs.salvarTemaEscuro(valor);
  }

  Future<void> alterarVibracao(bool valor) async {
    _vibracao = valor;
    notifyListeners();
    await _prefs.salvarVibracao(valor);
    if (valor) {
      await _device.vibrar(habilitada: true, duracaoMs: 40);
    }
  }

  /// Ponto unico de vibracao do app, ja respeitando a preferencia.
  Future<void> feedbackTatil({int duracaoMs = 60}) {
    return _device.vibrar(habilitada: _vibracao, duracaoMs: duracaoMs);
  }

  // ------------------------------------------------------------- UC8 / UC5

  /// Liga o monitoramento do acelerometro. Deve ser chamado quando a tela
  /// de tarefas entra em cena.
  void iniciarMonitoramento(void Function() onAgitar) {
    _device.monitorarAgitacao(onAgitar);
  }

  /// Desliga o monitoramento. Deve ser chamado no dispose da tela, para
  /// que a inscricao no sensor nao sobreviva a ela.
  void pararMonitoramento() {
    _device.cancelar();
  }

  @override
  void dispose() {
    _device.cancelar();
    super.dispose();
  }
}
