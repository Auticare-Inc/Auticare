import 'dart:core';

class AppUser{
  final String email;
  final String caregiverEmail;
  final String caregiverName;
  final String childName;
  final String name;
  final String uid;
  final String caregiverContact;

  AppUser({
    required this.childName,
    required this.email,
    required this.name,
    required this.uid,
    required this.caregiverEmail, 
    required this.caregiverName,
    required this.caregiverContact
  });

    // Convert appuser -> json
  Map<String,dynamic>toJson(){
    return{
      'uid':uid,
      'name':name,
      'email':email,
      'caregiverEmail': caregiverEmail,
      'caregiverName': caregiverName,
      'childName': childName,
      'caregiverContact': caregiverContact
    };
  }

  Map<String,dynamic>fromJson(){
    return {
      'uid': uid,
      'email': email,
      'name':name,
      'caregiverEmail': caregiverEmail,
      'caregiverName': caregiverName,
      'childName': childName,
      'caregiverContact': caregiverContact
    };
  }

  // Factory constructor for creating an AppUser from a map
  factory AppUser.from(Map<String,dynamic>json){
    return AppUser(
      caregiverContact: json['caregiverContact'],
      caregiverEmail: json['caregiverEmail'],
      caregiverName: json['caregiverName'],
      childName: json['childName'],
      email:json['email'],
      uid: json['uid'],
      name: json['name']);
  }
}