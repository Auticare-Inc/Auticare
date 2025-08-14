import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/place.dart';
import 'GeofenceUtils.dart/placesProvider.dart';
import 'utilities/placesPageUtils/addPlaceSheet.dart';
import 'utilities/placesPageUtils/appColors.dart';
import 'utilities/placesPageUtils/placeCard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesScreen extends StatefulWidget {
  final Function()? onGeofenceUpdated;

  const PlacesScreen({Key? key, this.onGeofenceUpdated}) : super(key: key);

  @override
  _PlacesScreenState createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  Future<List<Map<String, dynamic>>> fetchPlaceFromGoogle(String query) async {
    const apiKey =
        'AIzaSyBXXpFr0y3eIptseTiNnxVO4kgrqhB24Bk'; // Replace with your actual API key
    final encodedQuery = Uri.encodeComponent(query);
    final url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$encodedQuery&key=$apiKey';

    try {
      print('Making API call to: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'REQUEST_DENIED') {
          print('API Error: ${data['error_message']}');
          throw Exception('API key issue: ${data['error_message']}');
        }
        if (data['status'] == 'OVER_QUERY_LIMIT') {
          print('API Error: Over query limit');
          throw Exception('API query limit exceeded');
        }
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final places =
              List<Map<String, dynamic>>.from(data['results'].map((place) {
            final geometry = place['geometry'];
            final location = geometry?['location'];
            return {
              'name': place['name'] ?? 'Unknown Place',
              'address': place['formatted_address'] ?? '',
              'placeId': place['place_id'] ?? '',
              'latitude': location?['lat']?.toDouble() ?? 0.0,
              'longitude': location?['lng']?.toDouble() ?? 0.0,
              'rating': place['rating']?.toDouble() ?? 0.0,
              'types': place['types'] ?? [],
            };
          }));
          print('Found ${places.length} places with coordinates');
          return places;
        } else {
          print('No results found or status not OK: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching places: $e');
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // No need to load places here; PlacesProvider handles it
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
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
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await fetchPlaceFromGoogle(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _addPlace() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlaceSheet(
        onPlaceAdded: (place) {
          Provider.of<PlacesProvider>(context, listen: false).addPlace(place);
          widget.onGeofenceUpdated?.call();
        },
        onGeofenceUpdated: widget.onGeofenceUpdated,
      ),
    );
  }

  void _addPlaceWithPrefilledData(Map<String, dynamic> placeData) {
    print(
        'Passing to AddPlaceSheet: lat=${placeData['latitude']}, lng=${placeData['longitude']}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPlaceSheet(
        prefilledPlaceData: placeData,
        onPlaceAdded: (place) {
          Provider.of<PlacesProvider>(context, listen: false).addPlace(place);
          widget.onGeofenceUpdated?.call();
        },
        onGeofenceUpdated: widget.onGeofenceUpdated,
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
          Provider.of<PlacesProvider>(context, listen: false)
              .updatePlace(updatedPlace);
          widget.onGeofenceUpdated?.call();
        },
        onGeofenceUpdated: widget.onGeofenceUpdated,
      ),
    );
  }

  void _deletePlace(String placeId) {
    Provider.of<PlacesProvider>(context, listen: false).removePlace(placeId);
    widget.onGeofenceUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlacesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFE8F4FD),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(provider.places.length),
                _buildSearchBar(),
                Expanded(
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildPlacesList(provider.places),
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
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int placeCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goNamed('dashboard'),
            icon: const Icon(
              FontAwesomeIcons.angleLeft,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          const Center(
            child: const Text(
              'Places',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$placeCount',
              style: const TextStyle(
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
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: updateSearchResults,
        decoration: InputDecoration(
          hintText: 'Search for places...',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _isSearching = false;
                      _searchResults.clear();
                      _isLoading = false;
                      _errorMessage = null;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Searching places...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          updateSearchResults(_searchController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(56, 83, 106, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No places found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          child: Material(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchResults.clear();
                                  _isLoading = false;
                                  _errorMessage = null;
                                });
                                _searchController.clear();
                                _addPlaceWithPrefilledData(place);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            90, 111, 129, 1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color.fromRGBO(51, 77, 100, 1),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place['name'] ?? 'Unknown Place',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (place['address'] != null &&
                                              place['address'].isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                place['address'],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          if (place['rating'] != null &&
                                              place['rating'] > 0)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    place['rating'].toString(),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (place['latitude'] != 0.0 &&
                                              place['longitude'] != 0.0)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Coords: ${place['latitude'].toStringAsFixed(4)}, ${place['longitude'].toStringAsFixed(4)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
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

  Widget _buildPlacesList(List<Place> places) {
    if (places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 40,
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
      padding: const EdgeInsets.only(top: 24, bottom: 100),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return PlaceCard(
          place: place,
          onEdit: () => _editPlace(place),
          onDelete: () => _deletePlace(place.id),
        );
      },
    );
  }
}
