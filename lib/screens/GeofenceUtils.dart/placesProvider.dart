// import 'package:autismapp/screens/GeofenceUtils.dart/geoModels.dart';
// import 'package:flutter/material.dart';
// import '../../models/place.dart';
// import 'geoService.dart';

// class PlacesProvider with ChangeNotifier {
//   final EnhancedGeofencingService _geofencingService = EnhancedGeofencingService();
//   List<Place> _places = [];

//   List<Place> get places => _places;
//   List<Geofence> get geofences => _geofencingService.activeGeofences;
//   bool isUpdatingFromGeofences = false;

//   PlacesProvider() {
//     _geofencingService.onGeofencesUpdated = (geofences) {
//       if(!isUpdatingFromGeofences){
//         _loadPlacesFromGeofences();
//       notifyListeners();
//       }
//     };
//     _loadPlaces();
//   }

//   Future<void> initializeGeofencing() async {
//     await _geofencingService.initialize();
//     await _loadPlaces();
//   }

//   Future<void> _loadPlaces() async {
//     _places = await _geofencingService.getPlaces();
//     print('Provider loaded ${_places.length} places');
//     notifyListeners();
//   }

//   Future<void> _loadPlacesFromGeofences() async {
//     _places = await _geofencingService.getPlaces();
//     notifyListeners();
//   }

//   Future<void> addPlace(Place place) async {
//     isUpdatingFromGeofences = true;
//     _places.add(place);
//     await _geofencingService.createGeofenceFromPlace(place);
//     await _savePlaces();

//     isUpdatingFromGeofences=false;
//     notifyListeners();
//   }

//   Future<void> updatePlace(Place updatedPlace) async {
//     isUpdatingFromGeofences = true;
//     final index = _places.indexWhere((p) => p.id == updatedPlace.id);
//     if (index != -1) {
//       _places[index] = updatedPlace;
//       await _geofencingService.removeGeofencesForPlace(updatedPlace.id);
//       await _geofencingService.createGeofenceFromPlace(updatedPlace);
//       await _savePlaces();
//       isUpdatingFromGeofences = false;
//       notifyListeners();
//     }
//   }

//   Future<void> removePlace(String placeId) async {
//     isUpdatingFromGeofences = true;
//     _places.removeWhere((p) => p.id == placeId);
//     await _geofencingService.removeGeofencesForPlace(placeId);
//     await _savePlaces();
//     isUpdatingFromGeofences = false;
//     notifyListeners();
//   }

//   Future<void> _savePlaces() async {
//     print('Provider saved ${_places.length} places');
//   }
// }

import 'package:autismapp/screens/GeofenceUtils.dart/geoModels.dart';
import 'package:flutter/material.dart';
import '../../models/place.dart';
import 'geoService.dart';

class PlacesProvider with ChangeNotifier {
  final EnhancedGeofencingService _geofencingService = EnhancedGeofencingService();
  List<Place> _places = [];

  List<Place> get places => _places;
  List<Geofence> get geofences => _geofencingService.activeGeofences;

  PlacesProvider() {
    // Remove the callback that causes circular updates
    // _geofencingService.onGeofencesUpdated = (geofences) {
    //   _loadPlacesFromGeofences();
    //   notifyListeners();
    // };
    _loadPlaces();
  }

  Future<void> initializeGeofencing() async {
    await _geofencingService.initialize();
    await _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    _places = await _geofencingService.getPlaces();
    print('Provider loaded ${_places.length} places');
    notifyListeners();
  }

  // Remove this method since it's causing issues
  // Future<void> _loadPlacesFromGeofences() async {
  //   _places = await _geofencingService.getPlaces();
  //   notifyListeners();
  // }

  Future<void> addPlace(Place place) async {
    // Check for duplicates before adding
    final existingPlaceIndex = _places.indexWhere((p) => p.id == place.id);
    
    if (existingPlaceIndex != -1) {
      print('Place ${place.name} already exists');
      return;
    }
    
    _places.add(place);
    await _geofencingService.createGeofenceFromPlace(place);
    await _savePlaces();
    notifyListeners();
  }

  Future<void> updatePlace(Place updatedPlace) async {
    final index = _places.indexWhere((p) => p.id == updatedPlace.id);
    if (index != -1) {
      _places[index] = updatedPlace;
      await _geofencingService.removeGeofencesForPlace(updatedPlace.id);
      await _geofencingService.createGeofenceFromPlace(updatedPlace);
      await _savePlaces();
      notifyListeners();
    }
  }

  Future<void> removePlace(String placeId) async {
    _places.removeWhere((p) => p.id == placeId);
    await _geofencingService.removeGeofencesForPlace(placeId);
    await _savePlaces();
    notifyListeners();
  }

  // Add method to refresh places when needed
  Future<void> refreshPlaces() async {
    await _loadPlaces();
  }

  Future<void> _savePlaces() async {
    print('Provider saved ${_places.length} places');
  }
}