import 'package:autismapp/app.dart';
import 'package:autismapp/screens/GeofenceUtils.dart/geoService.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'cubits/authCubit.dart';
import 'firebase_options.dart';
import 'repositories/firebaseAuthRepo.dart';
import 'screens/GeofenceUtils.dart/placesProvider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.requestPermission();
  final authRepo = FirebaseAuthRepo();
    // Initialize geofencing service
  try {
    await EnhancedGeofencingService().initialize();
    print('Geofencing service initialized successfully');
  } catch (e) {
    print('Failed to initialize geofencing service: $e');
  }

    // Set the background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(
    // MultiBlocProvider(
    //   providers:[
    //     BlocProvider(create:(context)=>Authcubit(repo: authRepo)..checkAuth())
    //   ],
    // child: const MainApp())
    ChangeNotifierProvider(
      create: (context) => PlacesProvider(),
      child: MainApp(),
    ),
  );
}
