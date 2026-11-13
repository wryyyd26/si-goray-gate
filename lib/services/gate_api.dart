import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Set via --dart-define. localhost is suitable for Chrome on same Windows PC only.
const gateApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

class GateApiError implements Exception {
  const GateApiError(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class GateAuthApi {
  static Future<String> requestOtp(String email) async {
    final response = await _post(
      '/gate/auth/request-otp',
      {'no_hp_email': email.trim()},
    );
    // The Laravel controller returns 202 + {"message": ...}; no success field.
    if (response.statusCode != 202) throw _errorFrom(response);
    return _message(response) ?? 'Permintaan kode OTP diterima server.';
  }

  static Future<String> verifyOtp(String email, String otp) async {
    final response = await _post('/gate/auth/verify-otp', {
      'no_hp_email': email.trim(),
      'kode_otp': otp,
    });
    if (response.statusCode != 200) throw _errorFrom(response);
    final data = _decode(response);
    final token = data['access_token'];
    final tokenType = data['token_type'];
    if (token is! String || token.isEmpty || tokenType != 'Bearer') {
      throw const GateApiError('Token login dari server tidak valid.');
    }
    return token;
  }

  static Future<void> logout(String token) async {
    final response = await _post('/gate/auth/logout', {}, token: token);
    if (response.statusCode != 200) throw _errorFrom(response);
  }
}

enum AccessDecision { granted, denied, uncertain }

class ScanDecision {
  const ScanDecision({required this.decision, required this.message, required this.reason, this.unauthorized = false});
  final AccessDecision decision;
  final String message;
  final String reason;
  final bool unauthorized;
}

class GateScanApi {
  static Future<ScanDecision> scan(String token, String rawQrPayload) async {
    if (rawQrPayload.isEmpty || rawQrPayload.length > 4096) {
      return const ScanDecision(
        decision: AccessDecision.uncertain,
        message: 'QR tidak dapat dikirim karena kosong atau terlalu panjang. Jangan beri akses dulu.',
        reason: 'PAYLOAD_TIDAK_SESUAI',
      );
    }
    try {
      final response = await _post(
        '/gate/scan',
        {'qr_payload': rawQrPayload},
        token: token,
      );
      if (response.statusCode == 401) {
        return const ScanDecision(
          decision: AccessDecision.uncertain,
          message: 'Sesi petugas berakhir. Silakan masuk kembali.',
          reason: 'SESI_BERAKHIR',
          unauthorized: true,
        );
      }
      if (response.statusCode == 403) {
        return ScanDecision(
          decision: AccessDecision.uncertain,
          message: _message(response) ?? 'Petugas tidak memiliki izin memindai. Jangan beri akses dulu.',
          reason: 'AKSES_PETUGAS_DITOLAK',
        );
      }
      if (response.statusCode == 429) {
        return const ScanDecision(
          decision: AccessDecision.uncertain,
          message: 'Terlalu banyak permintaan. Jangan beri akses dulu.',
          reason: 'RATE_LIMIT',
        );
      }
      if (response.statusCode == 200 || response.statusCode == 422) {
        final data = _decode(response);
        final success = data['success'];
        final result = data['hasil'];
        final reason = data['reason'];
        final message = data['message'];
        if (success is! bool || result is! String || reason is! String || message is! String) {
          return const ScanDecision(
            decision: AccessDecision.uncertain,
            message: 'Respons validasi tidak lengkap. Jangan beri akses dulu.',
            reason: 'RESPONS_TIDAK_VALID',
          );
        }
        if (response.statusCode == 200 && success == true && result == 'BERHASIL') {
          return ScanDecision(decision: AccessDecision.granted, message: message, reason: reason);
        }
        if (response.statusCode == 422 && success == false) {
          return ScanDecision(decision: AccessDecision.denied, message: message, reason: reason);
        }
      }
      return const ScanDecision(
        decision: AccessDecision.uncertain,
        message: 'Tidak dapat memastikan status tiket. Jangan beri akses dulu.',
        reason: 'JARINGAN / TIMEOUT',
      );
    } on GateApiError catch (e) {
      return ScanDecision(
        decision: AccessDecision.uncertain,
        message: '${e.message} Jangan beri akses dulu.',
        reason: 'JARINGAN / TIMEOUT',
      );
    }
  }
}

Future<http.Response> _post(String path, Map<String, Object?> data, {String? token}) async {
  try {
    return await http.post(
      Uri.parse('$gateApiBaseUrl$path'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
  } on TimeoutException {
    throw const GateApiError('Koneksi ke Laravel habis waktu.');
  } on http.ClientException {
    throw const GateApiError('Tidak dapat terhubung ke server Laravel atau CORS memblokir permintaan.');
  }
}

Map<String, dynamic> _decode(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) return data;
  } catch (_) {
    // Do not expose raw responses, which could be HTML or contain server internals.
  }
  throw const GateApiError('Format respons Laravel tidak valid.');
}

String? _message(http.Response response) {
  try {
    final value = _decode(response)['message'];
    return value is String ? value : null;
  } on GateApiError {
    return null;
  }
}

GateApiError _errorFrom(http.Response response) {
  if (response.statusCode == 429) {
    return const GateApiError('Terlalu banyak percobaan. Coba lagi nanti.', statusCode: 429);
  }
  if (response.statusCode >= 500) {
    return GateApiError('Layanan Laravel sedang tidak tersedia.', statusCode: response.statusCode);
  }
  return GateApiError(_message(response) ?? 'Permintaan ditolak oleh Laravel.', statusCode: response.statusCode);
}
