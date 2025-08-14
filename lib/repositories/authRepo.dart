import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/appUser.dart';

abstract class AuthRepo{
  Future<AppUser?>loginInWithEmailPassword(String email, String password);
  Future<AppUser?>registerInWithEmailPassword(String email,String password,String name,String caregiverEmail,String caregiverName,String childName,String caregiverContact);
  Future<void>logout();
  Future<AppUser?>getCurrentUser();
  Future<bool> doesUserProfileExist(String uid) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.exists && doc.data()!.containsKey('email'); // Adjust based on your schema
}
} 