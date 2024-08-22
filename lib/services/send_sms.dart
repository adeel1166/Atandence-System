import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';

class SmsService {
  static Future<bool> message(List<String> recipient, String msgText, BuildContext context) async {

    try {
      await sendSMS(
          message: msgText, recipients: recipient, sendDirect: true
      );
      return true; // message send successfully

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Some error occurred sending message. Make sure SMS permission is granted'))
      );
    }

    return false; // message not sent
  }
}
