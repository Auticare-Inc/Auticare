import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/authCubit.dart';
import 'utilities/textField.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final caregiverEmailController = TextEditingController();

    void register(){
      final String email = emailController.text.trim();
      final String pw = passwordController.text;
      final String name = nameController.text;
      final String confirmPw = confirmPasswordController.text;


      //authCubit
      final authCubit = context.read<Authcubit>();
      //ensure fields are filled up
      if (email.isNotEmpty && pw.isNotEmpty && name.isNotEmpty && confirmPw.isNotEmpty){
        if( pw == confirmPw){
          authCubit.register(email, pw, name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text('Passwords don\'t match'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content:Text("Please enter required fields")));
      }

    @override
     void dispose(){
      emailController.dispose();
      passwordController.dispose();
      nameController.dispose();
      confirmPasswordController.dispose;

      super.dispose();
    }

    }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      resizeToAvoidBottomInset: false,
      body:  Stack(
        children:[ 
          Positioned(
            top: -100,
            left: -100,
            child:Container(
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Row(
                children: [
                  Text('Create Account',style: TextStyle(fontSize:28,fontWeight: FontWeight.bold),),
                ],
              ),
               Row(
                children: [
                  const Text('Already have an account?'),
                  GestureDetector(
                    onTap: ()=>context.goNamed('loginPage'),
                    child: const Text(' sign in',style: TextStyle(color: Color.fromARGB(255, 139, 94, 237),fontWeight: FontWeight.bold),))
                ],
              ),
              const SizedBox(height: 45),
              TextFields(hintText:'Name',hintColor: Colors.grey,controller:nameController ,),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Email',hintColor: Colors.grey,controller: emailController,),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Password',hintColor: Colors.grey,controller: passwordController,),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Confirm Password',hintColor: Colors.grey,controller:confirmPasswordController,),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Caregiver email',hintColor:Colors.grey,controller:caregiverEmailController),
              const SizedBox(height: 25,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap:()=>register(),
                    child: Container(
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
                            child: Text('Sign up',style: TextStyle(color: Colors.white),),
                          ),
                          SizedBox(width:5,),
                          Icon(Icons.exit_to_app,color: Colors.white,)
                        ],
                      )),
                    ),
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(bottom:  20,top: 60),
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
          ),
      ]),
    );
  }
}