import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Android: encrypted, platform-backed secure storage.
/// Chrome design/testing: RAM only; never persist Bearer token in browser localStorage.
class GateTokenVault {
  GateTokenVault._();
  static final GateTokenVault instance = GateTokenVault._();
  static const _key = 'si_goray_gate_bearer';
  final _secure = const FlutterSecureStorage();
  String? _browserSessionToken;

  Future<void> save(String token) async {
    if (kIsWeb) {
      _browserSessionToken = token;
    } else {
      await _secure.write(key: _key, value: token);
    }
  }

  Future<String?> read() async {
    if (kIsWeb) return _browserSessionToken;
    return _secure.read(key: _key);
  }

  Future<void> clear() async {
    _browserSessionToken = null;
    if (!kIsWeb) await _secure.delete(key: _key);
  }
}
