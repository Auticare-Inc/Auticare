import 'package:autismapp/screens/healthMonitoring.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/CaregiverLogin.dart';
import 'screens/LoginPage.dart';
import 'screens/SignupPage.dart';
import 'screens/mapScreen.dart';


class MainApp extends StatelessWidget {

  

  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
      
    final GoRouter router =
      GoRouter(initialLocation: '/hrhrvPage', 
        routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'Signuppage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: SignupPage());
        },
      ),
      GoRoute(
        path: '/loginPage',
        name: 'loginPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: LoginPage());
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
          return const MaterialPage(child: MapsPage());
        },
      ),
      GoRoute(
        path: '/hrhrvPage',
        name: 'hrhrvPage',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return const MaterialPage(child: HRHRVMonitorPage());
        },
      ),
    ]);
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      }
  }