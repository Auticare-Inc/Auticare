import 'dart:convert';

import 'package:http/http.dart' as http;

class ChildStateRepo {
  static Future<Map<String,dynamic>> fetchLatestPrediction() async {
    // Define full URI directly
    Uri uri = Uri.parse('https://231acb80c8d9.ngrok-free.app/last_prediction/');

    try {
      // Send GET request
      final response = await http.get(uri);

      // Optional: log or check status
    if (response.statusCode == 200) {
    final Map<String,dynamic> data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Failed load');
  }
    } catch (e) {
      print("prediction error: $e");
      rethrow;
    }
  }
}
