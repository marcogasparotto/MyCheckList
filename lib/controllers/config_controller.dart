import 'package:flutter/foundation.dart';

import '../services/device_service.dart';
import '../services/prefs_service.dart';

/// CONTROLLER - Configuracoes do aplicativo (UC7 / RNF03).
///
/// Tambem centraliza o acelerometro (UC8). Varias telas podem reagir a
/// agitacao (a principal mostra vencimentos; a de tarefas limpa o filtro),
/// entao o controller mantem uma pilha: a tela mais recente assume o sensor
/// e, ao sair, o sensor volta para a tela anterior.
class ConfigController extends ChangeNotifier {
  ConfigController({PrefsService? prefs, DeviceService? device})
      : _prefs = prefs ?? PrefsService(),
        _device = device ?? DeviceService();

  final PrefsService _prefs;
  final DeviceService _device;

  bool _temaEscuro = false;
  bool _vibracao = true;
  bool _carregado = false;

  final List<void Function()> _pilhaAgitacao = [];

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

  /// Tela nova assume o acelerometro. Chamar no initState da tela.
  void iniciarMonitoramento(void Function() onAgitar) {
    _pilhaAgitacao.add(onAgitar);
    _reiniciarSensor();
  }

  /// Tela que sai devolve o acelerometro para a anterior. Chamar no dispose.
  void pararMonitoramento() {
    if (_pilhaAgitacao.isNotEmpty) _pilhaAgitacao.removeLast();
    _reiniciarSensor();
  }

  void _reiniciarSensor() {
    _device.cancelar();
    if (_pilhaAgitacao.isNotEmpty) {
      _device.monitorarAgitacao(_pilhaAgitacao.last);
    }
  }

  @override
  void dispose() {
    _pilhaAgitacao.clear();
    _device.cancelar();
    super.dispose();
  }
}