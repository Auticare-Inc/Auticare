import 'dart:core';

class AppUser{
  final String email;
  final String name;
  final String uid;

  AppUser({
    required this.email,
    required this.name,
    required this.uid
  });

    // Convert appuser -> json
  Map<String,dynamic>toJson(){
    return{
      'uid':uid,
      'name':name,
      'email':email
    };
  }

  Map<String,dynamic>fromJson(){
    return {
      'uid': uid,
      'email': email,
      'name':name
    };
  }

  // Factory constructor for creating an AppUser from a map
  factory AppUser.from(Map<String,dynamic>json){
    return AppUser(
      email:json['email'],
      uid: json['uid'],
      name: json['name']);
  }
}