import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/appUser.dart';
import 'authRepo.dart';


class FirebaseAuthRepo implements AuthRepo{
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  @override
  Future<AppUser?> loginInWithEmailPassword(String email, String password)async{
    try{
      //attempt sign in
      UserCredential userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password);

        //create user
      AppUser user = AppUser(
        uid: userCredential.user!.uid, 
        name:'', 
        email: email);

        //return user
        return user;
    }
    //catch error
    catch(e){
      throw Exception('login Failed:$e');
    }
  }

  @override
  Future<AppUser?> registerInWithEmailPassword(String name, String email, String password)async{
    try{
      //attempt sign up
    UserCredential userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password);

      //create user

    AppUser user = AppUser(
      uid: userCredential.user!.uid, 
      name: name, 
      email: email);

      // Save user details
      await firebaseFirestore
      .collection('users')
      .doc(user.uid)
      .set(user.toJson());


      return user;

    } catch(e){
      throw Exception('Registration Failed: $e');
    }

  }

  @override
  Future<AppUser?> getCurrentUser()async{
  final firebaseUser = FirebaseAuth.instance.currentUser;

  // No user exists
  if(firebaseUser==null){
    return null;
  } 

  // user exists
  return AppUser(
    uid: firebaseUser.uid, 
    name: '', 
    email: firebaseUser.email!
    );
  }

  @override
  Future<void> logout()async{
    FirebaseAuth.instance.signOut();
  }
}