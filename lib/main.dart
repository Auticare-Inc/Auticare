import 'package:autismapp/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/authCubit.dart';
import 'firebase_options.dart';
import 'repositories/firebaseAuthRepo.dart';

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final authRepo = FirebaseAuthRepo();

  //request firebase notifications
  await FirebaseMessaging.instance.requestPermission();
  // Subscribe after Firebase init
  await FirebaseMessaging.instance.subscribeToTopic("user123");
  
  runApp(
    MultiBlocProvider(
      providers:[
        BlocProvider(create:(context)=>Authcubit(repo: authRepo)..checkAuth())
      ],
    child: const MainApp())
  );
}
