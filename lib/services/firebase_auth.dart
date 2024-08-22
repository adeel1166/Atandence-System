
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth {

  void signin(String pin, BuildContext context, void Function() then) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'user_$pin@school.com', password: pin,
      );
    } on FirebaseAuthException catch(e) {

      then(); // used for button widget

      if(e.code == 'invalid-email') {
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text('Pin format not correct!'),
              );
            }
        );
        return null;
      }

      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message.toString()),
            );
          }
      );
    }
  }
}
