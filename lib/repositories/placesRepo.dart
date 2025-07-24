import 'dart:convert';

import 'package:http/http.dart' as http;

class Placesrepo {
    static Future<void> getPlaces({required dynamic query}) async {

    final apiKey = ' AIzaSyBXXpFr0y3eIptseTiNnxVO4kgrqhB24Bk'; 
    final encodedQuery = Uri.encodeComponent(query);
    final url =
      'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$encodedQuery&inputtype=textquery&fields=name,formatted_address,geometry&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>;
    } else {
      throw Exception('Failed to load results');
    }
  }
}
