import 'package:flutter/material.dart';
class NotificationMessage{

  static void showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red, // Couleur en fonction du succès ou de l'erreur
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

