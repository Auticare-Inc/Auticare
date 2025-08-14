import 'dart:io';

import 'package:autismapp/cubits/authCubit.dart';
import 'package:autismapp/repositories/firebaseAuthRepo.dart';
import 'package:autismapp/screens/GeofenceUtils.dart/geoManagementPage.dart';
import 'package:autismapp/screens/dashboard.dart';
import 'package:autismapp/screens/emergencyContacts.dart';
import 'package:autismapp/screens/healthMonitoring.dart';
import 'package:autismapp/screens/manageCaregivers.dart';
import 'package:autismapp/screens/onBoardingPage.dart';
import 'package:autismapp/screens/placesPage.dart';
import 'package:autismapp/screens/resultsPage.dart';
import 'package:autismapp/screens/utilities/placesPageUtils/addPlaceSheet.dart';
import 'package:autismapp/services/navigationService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'repositories/authRepo.dart';
import 'screens/CaregiverLogin.dart';
import 'screens/LoginPage.dart';
import 'screens/SignupPage.dart';
import 'screens/mapScreen.dart';
import 'services/notificationServices.dart';


class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState(){
    super.initState();
//    NotificationService.init(context);
  _initializeNotifications();
  }

    Future<void> _initializeNotifications() async {
    await NotificationService.initialize();
    
    // Subscribe to topics if needed
    await NotificationService.subscribeToTopic('general');
    
    // Get and save token to your backend
    String? token = await NotificationService.getToken();
    if (token != null) {
      // Send token to your backend server
      _sendTokenToServer(token);
    }
  }

    void _sendTokenToServer(String token) async {
    // Call your cloud function to save the token
    // Example API call to your backend
    await FirebaseAuth.instance.authStateChanges().first;
    try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }
    
    // Save directly to Firestore
    await FirebaseFirestore.instance
        .collection('user_tokens')
        .doc(user.uid)
        .set({
      'fcmToken': token,
      'userId': user.uid,
      'lastUpdated': FieldValue.serverTimestamp(),
      'isActive': true,
      'deviceInfo': {
        'platform': Platform.operatingSystem,
        'timestamp': DateTime.now().toIso8601String(),
      }
    }, SetOptions(merge: true));
    
    print('Token saved to Firestore successfully');
    
  } catch (e) {
    print('Error saving token to Firestore: $e');
  }
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = FirebaseAuthRepo();
    final GoRouter router =
      GoRouter(
        navigatorKey: NavigationService.navigatorKey,
        initialLocation: '/',
        routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'onboardingPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: OnboardingPage());
        },
      ),
      GoRoute(
        path: '/signupPage',
        name: 'signupPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(
            child: BlocProvider(
              create: (_)=>Authcubit(repo:authRepo)..checkAuth(),
              child: SignupPage()));
        },
      ),
      GoRoute(
        path: '/loginPage',
        name: 'loginPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(
            child: BlocProvider(
              create: (_)=>Authcubit(repo: authRepo)..checkAuth(),
              child: LoginPage()));
        },
      ),
      GoRoute(
        path: '/caregiverLogin',
        name: 'caregiverLogin',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: CaregiverLogin());
        },
      ),
      GoRoute(
        path: '/mapScreen',
        name: 'mapScreen',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(child: GeofencingMapsPage());
        },
      ),
      GoRoute(
        path: '/hrhrvPage',
        name: 'hrhrvPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: HRHRVMonitorPage());
        },
      ),
      GoRoute(
        path: '/placesSearchPage',
        name: 'placesSearchPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(
            child: PlacesScreen());
        },
      ), 
      GoRoute(
        path: '/resultsPage',
        name: 'resultsPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(
            child: ResultsPage());
        }),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return  MaterialPage(
            child: HealthPage());
        }),
      GoRoute(
        path: '/geoManagement',
        name: 'geoManagement',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(child: GeofenceManagementPage());
        },
      ),
      GoRoute(
        path: '/emergencyPage',
        name: 'emergencyPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(child: EmergencyPage());
        },
      ),
      GoRoute(
        path: '/manageCaregiversPage',
        name: 'manageCaregiversPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage(child: ManageCaregiversPage());
        },
       )
    ]);
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      }
}