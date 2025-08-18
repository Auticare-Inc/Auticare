import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'utilities/textField.dart';

class CaregiverLogin extends StatelessWidget {
  const CaregiverLogin({super.key});
  @override
  Widget build(BuildContext context) {
    final caregiverEmailController = TextEditingController();
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
                    Text('Caregiver Login',style:TextStyle(fontSize: 28,fontWeight: FontWeight.bold),),
                  ],
                ),
                Row(
                children: [
                const Text('Want to have an admin account?'),
                  GestureDetector(
                  onTap: ()=>context.goNamed('Signuppage'),
                  child: const Text(' sign up',style: TextStyle(color: Color.fromARGB(255, 139, 94, 237),fontWeight: FontWeight.bold),))
                ],
              ),
              const SizedBox(height: 25,),
              TextFields(hintText: 'Enter assigned email',hintColor: Colors.grey,controller:caregiverEmailController),
              const SizedBox(height: 25),
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
          )
        ],
      ),
    );
  }
}