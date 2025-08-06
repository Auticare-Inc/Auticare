import 'package:autismapp/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Smsrepo {
  static Future<void> sendSMS({
    required BuildContext context,
    required String caregiverContact,
    required String message,
  }) async {
    //final username = 'sandbox';
    final apiKey = 'atsk_046573d2fb204676b2ea202218544ccb2d4baaa7b446e5ef0c669f17829ee27f12517ded';

    final uri = Uri.parse(
        'https://api.sandbox.africastalking.com/version1/messaging');

    final response = await http.post(
      uri,
      headers: {
        'apiKey':apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json'
      },
      body: {
        'username': 'sandbox',
        'to': caregiverContact,
        'message': message
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Message sent successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${response.body}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
