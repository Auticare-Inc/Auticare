import 'package:autismapp/app.dart';
import 'package:autismapp/repositories/placesRepo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/place.dart';
import 'utilities/placesPageUtils/addPlaceSheet.dart';
import 'utilities/placesPageUtils/appColors.dart';
import 'utilities/placesPageUtils/placeCard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesScreen extends StatefulWidget {
  @override
  _PlacesScreenState createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String? searchResult;

  Future<List<String>> fetchPlaceFromGoogle(String query) async {
  const apiKey = 'AIzaSyBXXpFr0y3eIptseTiNnxVO4kgrqhB24Bk';
  final url =
      'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['status'] == 'OK' && data['results'].isNotEmpty) {
      return List<String>.from(data['results'].map((place) => place['name']));
    }
  }
  return [];
}
  
  List<Place> _places = [];
  List<String>  _searchResults = [];
  bool _isSearching = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSampleData();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  void _loadSampleData() {
    _places = [];
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void updateSearchResults(String query) async {
    if (query.trim().isEmpty) {
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
    return;
  }

  final results = await fetchPlaceFromGoogle(query);
  setState(() {
    _searchResults = results;
    _isSearching = true; 
  });
}

  void _addPlace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlaceSheet(
        onPlaceAdded: (place) {
          setState(() {
            _places.add(place);
          });
        },
      ),
    );
  }

  void _editPlace(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlaceSheet(
        place: place,
        onPlaceAdded: (updatedPlace) {
          setState(() {
            int index = _places.indexWhere((p) => p.id == place.id);
            if (index != -1) {
              _places[index] = updatedPlace;
            }
          });
        },
      ),
    );
  }

  void _deletePlace(String placeId) {
    setState(() {
      _places.removeWhere((place) => place.id == placeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isSearching ? _buildSearchResults() : _buildPlacesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: _addPlace,
          backgroundColor: AppColors.primary,
          elevation: 8,
          child: Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Text(
            'Places',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_places.length}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value){
          if (value.isNotEmpty) {
            updateSearchResults(value);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search for places...',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                    _isSearching = false;
                    _searchResults.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: EdgeInsets.only(top: 24),
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Material(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _searchController.text = _searchResults[index];
                  updateSearchResults('');
                  context.goNamed('addPlaceSheet',
                  extra:_searchResults[index] );
                },
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _searchResults[index],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No places added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first place to get started',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: 24, bottom: 100),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        final place = _places[index];
        return PlaceCard(
          place: place,
          onEdit: () => _editPlace(place),
          onDelete: () => _deletePlace(place.id),
        );
      },
    );
  }
}
