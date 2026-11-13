import 'dart:convert';
import 'package:http/http.dart' as http;

class GateAuthApi {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static Future<String> requestOtp(String email) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/gate/auth/request-otp'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'no_hp_email': email.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Respons server tidak valid.',
      );
    }

    final message = data['message'];
    final serverMessage = message is String
        ? message
        : 'Terjadi kesalahan pada server.';

    if (response.statusCode == 202) {
      return serverMessage;
    }

    throw Exception(serverMessage);
  }
}
