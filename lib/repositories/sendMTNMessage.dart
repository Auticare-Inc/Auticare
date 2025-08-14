import 'mtnSMSHelper.dart';

class SendMtnMessage{

  static Future<void>smsReop({
    required String message,
    required String caregiverContact
  })async{
  final auth = ChenosisAuth(
  consumerKey: 'NKGRqVwfDbqSp5QVLwoDKb83n0cjAGPG',
  consumerSecret: 'bFctQpG9k7iJhpj6',
);

// replace with the exact SMS endpoint URL of the Chenosis product you subscribed to
final sms = ChenosisSms(
  auth: auth,
  smsEndpoint: 'https://api.chenosis.io/<provider>/<product>/v1/messages',
);

// simple shape (works if your product uses from/to/message)
await sms.sendSms(
  from: 'MyApp',
  to: caregiverContact,
  message: message,
);

// if your product expects a different JSON schema, override the body:
// await sms.sendSms(
//   bodyOverride: {
//     "senderAddress": "tel:+2332XXXXXXX",
//     "message": "hello!",
//     "recipientAddress": ["tel:+2335YYYYYYY"]
//   },
// );
  }

}