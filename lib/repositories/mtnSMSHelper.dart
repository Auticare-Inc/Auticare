// chenosis_sms.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Lightweight Chenosis OAuth client (client_credentials flow).
class ChenosisAuth {
 ChenosisAuth({
    required this.consumerKey,
    required this.consumerSecret,
    this.tokenUrl = 'https://api.chenosis.io/oauth/client_credential/accesstoken',
  });

  final String consumerKey;
  final String consumerSecret;
  final String tokenUrl;

  String? _cachedToken;
  DateTime? _expiresAt;

  /// Get (and cache) an access token.
  Future<String> getAccessToken() async {
    // Reuse token if still valid (with 30s safety buffer).
    if (_cachedToken != null &&
        _expiresAt != null &&
        DateTime.now().isBefore(_expiresAt!.subtract(const Duration(seconds: 30)))) {
      return _cachedToken!;
    }

    final basic = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));
    final uri = Uri.parse('$tokenUrl?grant_type=client_credentials');

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Basic $basic',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: 'grant_type=client_credentials',
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Chenosis token error ${res.statusCode}: ${res.body}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    _cachedToken = json['access_token'] as String;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 3600;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    return _cachedToken!;
  }
}

/// Simple SMS sender. Different Chenosis SMS products may use slightly
/// different request bodies—use [bodyOverride] when needed.
class ChenosisSms {
  ChenosisSms({
    required this.auth,
    required this.smsEndpoint,
  });

  /// OAuth helper
  final ChenosisAuth auth;

  /// The full HTTPS URL of the Chenosis SMS POST endpoint for your product.
  /// e.g. something like:
  ///   https://api.chenosis.io/<provider>/<product>/v1/messages
  final String smsEndpoint;

  /// Sends an SMS.
  ///
  /// Many SMS products accept a JSON body like:
  ///   { "from": "MyApp", "to": "+233XXXXXXXXX", "message": "Hello" }
  ///
  /// If your product expects a different schema, supply [bodyOverride].
  Future<http.Response> sendSms({
    String? from,
    String? to,
    String? message,
    Map<String, dynamic>? bodyOverride,
    Map<String, String>? extraHeaders,
  }) async {
    final token = await auth.getAccessToken();

    // Default, common body; replaced completely if bodyOverride is provided.
    final body = bodyOverride ??
        <String, dynamic>{
          if (from != null) 'from': from,
          if (to != null) 'to': to,
          if (message != null) 'message': message,
        };

    final res = await http.post(
      Uri.parse(smsEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (extraHeaders != null) ...extraHeaders,
      },
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Bubble up a helpful error.
      throw Exception('Chenosis SMS error ${res.statusCode}: ${res.body}');
    }
    return res;
  }
}
