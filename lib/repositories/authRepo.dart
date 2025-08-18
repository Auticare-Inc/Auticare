import '../models/appUser.dart';

abstract class AuthRepo{
  Future<AppUser?>loginInWithEmailPassword(String email, String password);
  Future<AppUser?>registerInWithEmailPassword(String name,String email,String password);
  Future<void>logout();
  Future<AppUser?>getCurrentUser();
} 