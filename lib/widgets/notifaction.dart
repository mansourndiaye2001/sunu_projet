import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
class NotificationMessage{

  static void showSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red, // Couleur en fonction du succès ou de l'erreur
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  static void notif(Color color , String message , String type  ){
    Get.snackbar(
      type,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      borderRadius: 8.0,
      margin: EdgeInsets.all(16),
      duration: Duration(seconds: 3),
    );
  }

}

