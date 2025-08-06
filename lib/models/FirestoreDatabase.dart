import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class Firestoredatabase {

  static Future<void>createCaregiverDetails(
    {
    required dynamic? caregiverContact,
    required String? caregiverType,
    required String caregiverEmail,
    required String caregiverName,
    required String? childName,
    
  })async{
    await FirebaseFirestore.instanceFor(app: Firebase.app(),databaseId:'autism')
    .collection('caregiverDetails')
    .doc(caregiverEmail)
    .set({
      'caregiverEmail':caregiverEmail,
      'caregiverContact': caregiverContact,
      'caregiverName': caregiverName,
      'caregiverType': caregiverType,
      'childName': childName
    });
  }


  static Future<void>addCaregiverDetails({
    required String caregiverEmail,
    required int caregiverContact,
    required String caregiverName,
    required String caregiverType,
  })async{
    await FirebaseFirestore.instanceFor(app: Firebase.app(),databaseId:'autism')
    .collection('caregiverDetails')
    .add({
      'caregiverEmail':caregiverEmail,
      'caregiverContact': caregiverContact,
      'caregiverName': caregiverName,
      'caregiverType': caregiverType
    });
  }

  static Future<void>updatecaregiverDetails({
    String? caregiverEmail,
    int? caregiverContact,
    String? caregiverName
  })async{
    await FirebaseFirestore.instanceFor(app: Firebase.app(),databaseId:'autism')
    .collection('caregiverDetails')
    .doc('caregiverEmail')
    .update({
      'caregiverEmail':caregiverEmail,
      'caregiverContact':caregiverContact,
      'caregiverName': caregiverName
    });
  } 

  static Future<Map<dynamic,String>?>getcaregiverDetails({
    required String caregiverEmail
  })async{
   DocumentSnapshot doc = await FirebaseFirestore.instanceFor(app:Firebase.app(),databaseId:'autism')
   .collection('caregiverDetails')
   .doc(caregiverEmail)
   .get();

   if(doc.exists){
    var data = doc.data() as Map<String,dynamic>;
   }
   else return null;
  }

  static Future<Map<String,dynamic>?>getParentDetails()async{
   final user = FirebaseAuth.instanceFor(app:Firebase.app()).currentUser;
   if(user==null) return null;
   final String parentID = user!.uid;
   final doc = await FirebaseFirestore.instanceFor(app:Firebase.app(),databaseId:'autism')
   .collection('users')
   .doc(parentID)
   .get();

   if(doc.exists){
    return doc.data() as Map<String,dynamic>;
   }
   else return null;
  }

  static Future<void>deleteCaregiver({required String caregiverEmail})async{
    await FirebaseFirestore.instanceFor(app: Firebase.app(),databaseId:'autism')
    .collection('caregiverDetails')
    .doc(caregiverEmail)
    .delete();
  }
}