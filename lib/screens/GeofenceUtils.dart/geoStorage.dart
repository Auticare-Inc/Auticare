import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'geoModels.dart';


class StorageService {
  static const String _geofencesKey = 'saved_geofences';

  static Future<List<Geofence>> getGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_geofencesKey);
    
    if (jsonString == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Geofence.fromJson(json)).toList();
  }

  static Future<void> saveGeofences(List<Geofence> geofences) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = geofences.map((g) => g.toJson()).toList();
    await prefs.setString(_geofencesKey, jsonEncode(jsonList));
  }

  static Future<void> clearGeofences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_geofencesKey);
  }
}