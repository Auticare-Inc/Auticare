import 'package:autismapp/cubits/authState.dart';
import 'package:bloc/bloc.dart';

import '../models/appUser.dart';
import '../repositories/authRepo.dart';

class Authcubit extends Cubit<AuthState> {
  final AuthRepo repo;
  AppUser? _currentUser;
  Authcubit({required this.repo}):super(AuthInitial());
  
//check if user is already authenticated
  void checkAuth()async{
    final AppUser? user = await repo.getCurrentUser();
    if(user!=null){
      _currentUser = user;
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  
  //get current user
  AppUser? get currentUser => _currentUser;

  //login with email and password
  Future<void>login(String email, String pw)async{

    try{
     emit(Authloading());
      final user = await repo.loginInWithEmailPassword(email,pw);
      if(user!=null){
        _currentUser = user;
        emit(Authenticated(user));
      }else{
        emit(Unauthenticated());
      }
    }
    catch(e){
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  //register with email,password and name 
  Future<void>register(String email, String pw,String name)async{
    try{
      emit(Authloading());
      final user = await repo.registerInWithEmailPassword(email,pw,name);
      if(user!=null){
        _currentUser = user;
        emit(Authenticated(user));
      }else{
        emit(Unauthenticated());
      }
    }
    catch(e){
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  // logout
  Future<void>logout()async{
    await repo.logout();
    emit(Unauthenticated());
  }
}