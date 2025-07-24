import 'package:autismapp/app.dart';
import 'package:autismapp/models/FirestoreDatabase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageCaregiversPage extends StatefulWidget {
  const ManageCaregiversPage({super.key});

  @override
  State<ManageCaregiversPage> createState() => _ManageCaregiversPageState();
}

class _ManageCaregiversPageState extends State<ManageCaregiversPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController childnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();

  String? selectedRelationship;


  void addCaregiver() {
    if (nameController.text.isNotEmpty &&
        childnameController.text.isNotEmpty&&
        emailController.text.isNotEmpty &&
        contactController.text.isNotEmpty &&
        relationshipController.text.isNotEmpty) {
      Firestoredatabase.createCaregiverDetails(
         childName: childnameController.text,
          caregiverContact: contactController.text,
          caregiverType: relationshipController.text,
          caregiverEmail: emailController.text,
          caregiverName: nameController.text);
      // Clear form
      nameController.clear();
      emailController.clear();
      contactController.clear();
      relationshipController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caregiver added successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.goNamed('dashboard'),
        ),
        title: Text(
          'Manage Caregivers',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Caregivers Section
              Text(
                'Current Caregivers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // Caregivers List
              // ...caregivers
              //     .map((caregiver) => _buildCaregiverItem(caregiver))
              //     .toList(),
              _buildCaregiverItem(),

              SizedBox(height: 24),

              // Add New Caregiver Section
              Text(
                'Add New Caregiver',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // Form Fields
              _buildTextField(
                controller: nameController,
                hintText: 'Caregiver Name',
              ),
              SizedBox(height: 12),
              _buildTextField(
                controller: childnameController,
                hintText: 'Child Name',
              ),

              SizedBox(height: 12),

              _buildTextField(
                controller: emailController,
                hintText: 'Email',
              ),
              SizedBox(height: 12),

              // Relationship Dropdown
              _buildTextField(
                  controller: relationshipController, hintText: 'Relationship'),
              SizedBox(height: 12),

              _buildTextField(
                controller: contactController,
                hintText: 'Contact Info',
              ),
              SizedBox(height: 24),

              // Add Caregiver Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: addCaregiver,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    'Add Caregiver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverItem() {
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

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(Icons.person,
                        color: Colors.grey.shade600, size: 24)
                      ),
                      SizedBox(width: 12),

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(details['caregiverName'] ?? 'No name'),
                            Text(details['caregiverType'] ?? 'Type'),
                          ],
                        ),
                      ),

                      // Edit
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Edit Caregiver'),
                              content: Text(
                                  'Delete details for ${details['caregiverName'] ?? ''}'),
                              actions: [
                                TextButton(
                                  onPressed: (){
                                    Firestoredatabase.deleteCaregiver(caregiverEmail: details['caregiverEmail']);
                                    Navigator.pop(context);
                                  },
                                  child: Text('Delete',style: TextStyle(color: Colors.red),),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.edit, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          }
          return Center(child: Text('No caregiver available'));
        });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
