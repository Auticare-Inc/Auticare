import 'package:autismapp/app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../repositories/smsRepo.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => context.goNamed('dashboard'),
            icon: const Icon(
              FontAwesomeIcons.angleLeft,
              size: 14,
            )),
        centerTitle: true,
        title: const Text(
          'Emergency Contact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              contactTile()
            ],
          ),
        ),
      )
    );
  }
}

Widget contactTile() {
  return StreamBuilder(
      stream: FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'autism')
          .collection('caregiverDetails')
          .snapshots(),
      builder: (context, snapshot) {
        if (ConnectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          final data = snapshot.data!.docs;
           return Column(
              children: data.map((doc) {
                final details = doc.data();
              return Padding(
            padding:  EdgeInsets.all(15),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[200],
                        child: Icon(Icons.person),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            details['childName'] ?? 'No child',
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                          ),
                          SizedBox(height: 3),
                          Text('Last known location:Accra'),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details['caregiverName'] ?? 'Null name',
                            style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),
                          ),
                          SizedBox(height: 3),
                          Text(details['caregiverContact'] ?? 'Unknown number')
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 60,
                            width: 90,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.blue[200]),
                            child: Center(
                                child: Icon(
                              Icons.person,
                              size: 24,
                            )),
                          )
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 20,right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: (){
                            Smsrepo.sendSMS(
                              caregiverContact:details['caregiverContact'], 
                              childName:details['childName'],
                              context: context);
                          },
                          child: Container(
                            height: 45,
                            width: 200,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(16)),
                            child: Center(
                                child: Text(
                              'Send SMS',
                              style: TextStyle(color: Colors.white),
                            )),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );            
          }).toList(),
         );
        }
        return Column(
          children: [
            Center(child: Text('No Emergency Contact available',style: TextStyle(color: Colors.blue),)),
          ],
        );
      });
}
