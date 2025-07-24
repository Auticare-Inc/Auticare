import '../models/appUser.dart';

abstract class AuthRepo{
  Future<AppUser?>loginInWithEmailPassword(String email, String password);
  Future<AppUser?>registerInWithEmailPassword(String email,String password,String name,String caregiverEmail,String caregiverName,String childName);
  Future<void>logout();
  Future<AppUser?>getCurrentUser();
} 