import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotification {
  static Future<bool> triggerPushNotification({
    required String title,
    required String body,
  }) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      
      if (token == null) {
        print("No FCM token available");
        return false;
      }

      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendNotificationAlert');

      final result = await callable.call({
        'title': title,
        'body': body,
        'token': token,
      });

      print("Notification sent successfully: ${result.data}");
      return true;
    } on FirebaseFunctionsException catch (e) {
      print("Firebase Functions error: ${e.code} - ${e.message}");
      return false;
    } catch (e) {
      print("Notification error: $e");
      return false;
    }
  }
}