import 'package:shared_preferences/shared_preferences.dart';

/// SERVICE - Armazenamento interno do dispositivo (RNF03 / UC7).
/// Guarda apenas configuracoes e preferencias do aplicativo.
class PrefsService {
  static const _kTemaEscuro = 'cfg_tema_escuro';
  static const _kVibracao = 'cfg_vibracao';
  static const _kUltimoEmail = 'cfg_ultimo_email';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<bool> lerTemaEscuro() async =>
      (await _prefs).getBool(_kTemaEscuro) ?? false;

  Future<void> salvarTemaEscuro(bool valor) async =>
      (await _prefs).setBool(_kTemaEscuro, valor);

  Future<bool> lerVibracao() async =>
      (await _prefs).getBool(_kVibracao) ?? true;

  Future<void> salvarVibracao(bool valor) async =>
      (await _prefs).setBool(_kVibracao, valor);

  Future<String> lerUltimoEmail() async =>
      (await _prefs).getString(_kUltimoEmail) ?? '';

  Future<void> salvarUltimoEmail(String email) async =>
      (await _prefs).setString(_kUltimoEmail, email);
}
