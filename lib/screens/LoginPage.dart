import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/authCubit.dart';
import 'utilities/textField.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key,});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    void login(){
      final String email = emailController.text;
      final String pw = passwordController.text;

      //auth cubit
      final authCubit = context.read<Authcubit>();

      //ensure that email and password fields are not empty
      if(email.isNotEmpty && pw.isNotEmpty){
        //login
        authCubit.login(email, pw);

        //display error if some fields are empty
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content:Text('Please enter email and password')));
      }

      @override
      void dispose(){
        emailController.dispose();
        passwordController.dispose();
        super.dispose();
      }
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            left: -100,
            top: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 210, 192, 250),
                    Color.fromARGB(255, 224, 211, 251),
                    Color(0xFFF9F9F9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              ),
            )),
           Padding(
            padding: const EdgeInsets.only(left: 25,right: 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Admin Login',style:TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
                  ],
                ),
                Row(
                children: [
                const Text('Are you a caregiver?'),
                  GestureDetector(
                  onTap: ()=>context.goNamed('caregiverLogin'),
                  child: const Text(' login',style: TextStyle(color: Color.fromARGB(255, 139, 94, 237),fontWeight: FontWeight.bold),))
                ],
              ),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Email',hintColor: Colors.grey,controller: emailController,),
              const SizedBox(height: 25),
              TextFields(hintText: 'Password',hintColor: Colors.grey,controller: passwordController,),
              const SizedBox(height:25,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 105,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 174, 141, 247),
                      borderRadius: BorderRadius.circular(25)
                    ),
                    child: const Center(child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Login',style: TextStyle(color: Colors.white),),
                        ),
                        SizedBox(width:5,),
                        Icon(Icons.exit_to_app,color: Colors.white,)
                      ],
                    )),
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 85),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('CareConnect',style: TextStyle(fontWeight: FontWeight.bold,fontSize:17)),
                    Text(' The smart way to care')
                  ],
                ),
              )
              ],
            ),
          )
        ],
      ),
    );
  }
}