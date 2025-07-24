import 'dart:core';

class AppUser{
  final String email;
  final String caregiverEmail;
  final String caregiverName;
  final String childName;
  final String name;
  final String uid;

  AppUser({
    required this.childName,
    required this.email,
    required this.name,
    required this.uid,
    required this.caregiverEmail, 
    required this.caregiverName
  });

    // Convert appuser -> json
  Map<String,dynamic>toJson(){
    return{
      'uid':uid,
      'name':name,
      'email':email,
      'caregiverEmail': caregiverEmail,
      'caregiverName': caregiverName,
      'childName': childName
    };
  }

  Map<String,dynamic>fromJson(){
    return {
      'uid': uid,
      'email': email,
      'name':name,
      'caregiverEmail': caregiverEmail,
      'caregiverName': caregiverName,
      'childName': childName
    };
  }

  // Factory constructor for creating an AppUser from a map
  factory AppUser.from(Map<String,dynamic>json){
    return AppUser(
      caregiverEmail: json['caregiverEmail'],
      caregiverName: json['caregiverName'],
      childName: json['childName'],
      email:json['email'],
      uid: json['uid'],
      name: json['name']);
  }
}