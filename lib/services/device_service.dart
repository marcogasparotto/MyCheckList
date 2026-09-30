import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

/// SERVICE - Recursos fisicos do dispositivo (RNF05).
/// Acelerometro: deteccao de agitacao (UC8).
/// Vibracao: retorno tatil ao usuario (UC5, UC8).
class DeviceService {
  StreamSubscription<AccelerometerEvent>? _sub;

  /// Limite de aceleracao (m/s^2) considerado "agitacao".
  static const double _limiteAgitacao = 22.0;

  /// Intervalo minimo entre duas deteccoes, evita disparos repetidos.
  static const Duration _intervaloMinimo = Duration(seconds: 2);

  DateTime _ultimaDeteccao = DateTime.fromMillisecondsSinceEpoch(0);

  /// Inicia o monitoramento do acelerometro.
  /// [onAgitar] e chamado quando um movimento brusco e identificado.
  void monitorarAgitacao(void Function() onAgitar) {
    cancelar();
    _sub = accelerometerEventStream().listen((event) {
      final forca = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (forca < _limiteAgitacao) return;

      final agora = DateTime.now();
      if (agora.difference(_ultimaDeteccao) < _intervaloMinimo) return;

      _ultimaDeteccao = agora;
      onAgitar();
    });
  }

  void cancelar() {
    _sub?.cancel();
    _sub = null;
  }

  /// Vibra o aparelho, respeitando a preferencia salva pelo usuario (UC7).
  Future<void> vibrar({
    required bool habilitada,
    int duracaoMs = 60,
  }) async {
    if (!habilitada) return;
    final temVibracao = await Vibration.hasVibrator() ?? false;
    if (!temVibracao) return;
    await Vibration.vibrate(duration: duracaoMs);
  }
}
