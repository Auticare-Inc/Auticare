// import 'package:flutter/material.dart';
// import '../../../models/place.dart';
// import '../../GeofenceUtils.dart/geoService.dart';
// import 'appColors.dart';
// import 'textfield.dart';
// import 'timeSelector.dart';

// class AddPlaceSheet extends StatefulWidget {
//   final List<String>? details;
//   final Place? place;
//   final Function(Place)? onPlaceAdded;
//   final Map<String, dynamic>? prefilledPlaceData;
//   final bool enableGeofencing; // New parameter

//   const AddPlaceSheet({
//     Key? key,
//     this.place,
//     this.onPlaceAdded,
//     this.details,
//     this.prefilledPlaceData,
//     this.enableGeofencing = true, // Default to true
//   }) : super(key: key);

//   @override
//   _AddPlaceSheetState createState() => _AddPlaceSheetState();
// }

// class _AddPlaceSheetState extends State<AddPlaceSheet> {
//   late var _nameController = TextEditingController();
//   late var _addressController = TextEditingController();
//   TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);
//   TimeOfDay _endTime = TimeOfDay(hour: 17, minute: 0);
//   bool _createGeofence = true; // New state variable
//   final EnhancedGeofencingService _geofencingService = EnhancedGeofencingService();

//   // Store coordinates from prefilled data
//   double _latitude = 0.0;
//   double _longitude = 0.0;

//   @override
//   void initState() {
//     super.initState();
    
//     // Initialize controllers with prefilled data or existing place data
//     _nameController = TextEditingController(
//       text: widget.prefilledPlaceData?['name'] ?? widget.place?.name ?? '',
//     );
//     _addressController = TextEditingController(
//       text: widget.prefilledPlaceData?['address'] ?? widget.place?.address ?? '',
//     );

//     // Set coordinates from prefilled data or existing place
//     if (widget.prefilledPlaceData != null) {
//       _latitude = widget.prefilledPlaceData!['latitude']?.toDouble() ?? 0.0;
//       _longitude = widget.prefilledPlaceData!['longitude']?.toDouble() ?? 0.0;
//       print('Prefilled coordinates: $_latitude, $_longitude'); // Debug log
//     } else if (widget.place != null) {
//       _latitude = widget.place!.latitude;
//       _longitude = widget.place!.longitude;
//       _startTime = widget.place!.startTime;
//       _endTime = widget.place!.endTime;
//     }

//     // Debug log to verify coordinates
//     print('Initialized with coordinates: $_latitude, $_longitude');
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }

//   Future<void> _selectTime(BuildContext context, bool isStartTime) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: isStartTime ? _startTime : _endTime,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(primary: AppColors.primary),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStartTime) {
//           _startTime = picked;
//         } else {
//           _endTime = picked;
//         }
//       });
//     }
//   }

//   Future<void> _savePlace() async {
//     if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please fill in all required fields'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Check if we have valid coordinates
//     if (_latitude == 0.0 && _longitude == 0.0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Invalid location coordinates. Please search for a place first.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     final place = Place(
//       id: widget.place?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
//       name: _nameController.text,
//       address: _addressController.text,
//       latitude: _latitude,  // Use the stored coordinates
//       longitude: _longitude, // Use the stored coordinates
//       startTime: _startTime,
//       endTime: _endTime,
//     );

//     // Debug log to verify place coordinates
//     print('Saving place with coordinates: ${place.latitude}, ${place.longitude}');

//     // Call the original callback
//     widget.onPlaceAdded!(place);

//     // Create geofence if enabled and we have valid coordinates
//     if (widget.enableGeofencing && _createGeofence && _latitude != 0.0 && _longitude != 0.0) {
//       try {
//         await _geofencingService.createGeofenceFromPlace(place);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Place and geofence created successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } catch (e) {
//         print('Geofence creation error: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Place created, but geofence setup failed: $e'),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     } else if (widget.enableGeofencing && _createGeofence && (_latitude == 0.0 || _longitude == 0.0)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Place created, but geofence requires valid coordinates'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//     }

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(
//         bottom: MediaQuery.of(context).viewInsets.bottom,
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.cardBackground,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _buildHeader(),
//               SizedBox(height: 24),
//               CustomTextField(
//                 controller: _nameController,
//                 label: 'Place Name',
//                 hint: 'Enter place name',
//                 icon: Icons.location_on,
//               ),
//               SizedBox(height: 16),
//               CustomTextField(
//                 controller: _addressController,
//                 label: 'Address',
//                 hint: 'Enter address',
//                 icon: Icons.place,
//               ),
//               // Debug: Show coordinates if available
//               if (_latitude != 0.0 && _longitude != 0.0) ...[
//                 SizedBox(height: 8),
//                 Container(
//                   padding: EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.check_circle, color: Colors.green, size: 16),
//                       SizedBox(width: 8),
//                       Text(
//                         'Location: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
//                         style: TextStyle(fontSize: 12, color: Colors.green),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//               SizedBox(height: 24),
//               _buildTimeSection(),
//               if (widget.enableGeofencing) ...[
//                 SizedBox(height: 24),
//                 _buildGeofenceSection(),
//               ],
//               SizedBox(height: 32),
//               _buildSaveButton(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Text(
//           widget.place == null ? 'Add Place' : 'Edit Place',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         Spacer(),
//         IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: Icon(Icons.close, color: AppColors.textSecondary),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimeSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Active Hours',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: TimeSelector(
//                 label: 'Start Time',
//                 time: _startTime,
//                 onTap: () => _selectTime(context, true),
//               ),
//             ),
//             SizedBox(width: 16),
//             Expanded(
//               child: TimeSelector(
//                 label: 'End Time',
//                 time: _endTime,
//                 onTap: () => _selectTime(context, false),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildGeofenceSection() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.primary.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.primary.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.location_searching, color: AppColors.primary),
//               SizedBox(width: 8),
//               Text(
//                 'Geofencing',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
//           Text(
//             'Create a geofence to get notifications when you arrive at this location during the scheduled time (±1 minute).',
//             style: TextStyle(
//               fontSize: 14,
//               color: AppColors.textSecondary,
//             ),
//           ),
//           SizedBox(height: 16),
//           Row(
//             children: [
//               Switch(
//                 value: _createGeofence,
//                 onChanged: (value) {
//                   setState(() {
//                     _createGeofence = value;
//                   });
//                 },
//                 activeColor: AppColors.primary,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Enable geofencing for this place',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//           if (_createGeofence) ...[
//             SizedBox(height: 12),
//             Container(
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: (_latitude != 0.0 && _longitude != 0.0) 
//                     ? Colors.blue.withOpacity(0.1) 
//                     : Colors.orange.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     (_latitude != 0.0 && _longitude != 0.0) ? Icons.info : Icons.warning,
//                     color: (_latitude != 0.0 && _longitude != 0.0) ? Colors.blue : Colors.orange,
//                     size: 16,
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       (_latitude != 0.0 && _longitude != 0.0)
//                           ? 'Geofence will be active for 24 hours'
//                           : 'Valid coordinates required for geofencing',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: (_latitude != 0.0 && _longitude != 0.0) ? Colors.blue : Colors.orange,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildSaveButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         onPressed: _savePlace,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//         ),
//         child: Text(
//           widget.place == null ? 'Add Place' : 'Update Place',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../../models/place.dart';
import '../../GeofenceUtils.dart/geoService.dart';
import 'appColors.dart';
import 'textfield.dart';
import 'timeSelector.dart';

class AddPlaceSheet extends StatefulWidget {
  final List<String>? details;
  final Place? place;
  final Function(Place)? onPlaceAdded;
  final Map<String, dynamic>? prefilledPlaceData;
  final bool enableGeofencing;
  final Function()? onGeofenceUpdated; // New callback for notifying map page

  const AddPlaceSheet({
    Key? key,
    this.place,
    this.onPlaceAdded,
    this.details,
    this.prefilledPlaceData,
    this.enableGeofencing = true,
    this.onGeofenceUpdated,
  }) : super(key: key);

  @override
  _AddPlaceSheetState createState() => _AddPlaceSheetState();
}

class _AddPlaceSheetState extends State<AddPlaceSheet> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _createGeofence = true;
  final EnhancedGeofencingService _geofencingService = EnhancedGeofencingService();
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.prefilledPlaceData?['name'] ?? widget.place?.name ?? '',
    );
    _addressController = TextEditingController(
      text: widget.prefilledPlaceData?['address'] ?? widget.place?.address ?? '',
    );

    if (widget.prefilledPlaceData != null) {
      _latitude = widget.prefilledPlaceData!['latitude']?.toDouble() ?? 0.0;
      _longitude = widget.prefilledPlaceData!['longitude']?.toDouble() ?? 0.0;
      print('Prefilled coordinates: $_latitude, $_longitude');
    } else if (widget.place != null) {
      _latitude = widget.place!.latitude;
      _longitude = widget.place!.longitude;
      _startTime = widget.place!.startTime;
      _endTime = widget.place!.endTime;
    }

    print('Initialized with coordinates: $_latitude, $_longitude');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _savePlace() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid location coordinates. Please search for a place first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final place = Place(
      id: widget.place?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      address: _addressController.text,
      latitude: _latitude,
      longitude: _longitude,
      startTime: _startTime,
      endTime: _endTime,
    );

    print('Saving place: ${place.name}, lat: ${place.latitude}, lng: ${place.longitude}');

    widget.onPlaceAdded?.call(place);

    if (widget.enableGeofencing && _createGeofence) {
      try {
        await _geofencingService.createGeofenceFromPlace(place);
        widget.onGeofenceUpdated?.call(); // Notify map page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place and geofence created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Geofence creation error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Place created, but geofence setup failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'Place Name',
                hint: 'Enter place name',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'Enter address',
                icon: Icons.place,
              ),
              if (_latitude != 0.0 && _longitude != 0.0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Location: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _buildTimeSection(),
              if (widget.enableGeofencing) ...[
                const SizedBox(height: 24),
                _buildGeofenceSection(),
              ],
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          widget.place == null ? 'Add Place' : 'Edit Place',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Hours',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TimeSelector(
                label: 'Start Time',
                time: _startTime,
                onTap: () => _selectTime(context, true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TimeSelector(
                label: 'End Time',
                time: _endTime,
                onTap: () => _selectTime(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeofenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_searching, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Geofencing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a geofence to get notifications when you arrive at this location during the scheduled time (±1 minute).',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: _createGeofence,
                onChanged: (value) {
                  setState(() {
                    _createGeofence = value;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Enable geofencing for this place',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (_createGeofence) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_latitude != 0.0 && _longitude != 0.0)
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    (_latitude != 0.0 && _longitude != 0.0) ? Icons.info : Icons.warning,
                    color: (_latitude != 0.0 && _longitude != 0.0) ? Colors.blue : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (_latitude != 0.0 && _longitude != 0.0)
                          ? 'Geofence will be active for 24 hours'
                          : 'Valid coordinates required for geofencing',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_latitude != 0.0 && _longitude != 0.0) ? Colors.blue : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _savePlace,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          widget.place == null ? 'Add Place' : 'Update Place',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}