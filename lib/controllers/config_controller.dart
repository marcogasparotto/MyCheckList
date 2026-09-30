import 'package:flutter/foundation.dart';

import '../services/device_service.dart';
import '../services/prefs_service.dart';

/// CONTROLLER - Configuracoes do aplicativo (UC7 / RNF03).
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
}
