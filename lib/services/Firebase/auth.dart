import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../screens/Login.dart';
import '../../screens/adminPage.dart';
import '../../screens/homePage.dart';
import '../../widgets/notifaction.dart';

class Auth{

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get CurrentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  //LOGIN WITH EMAIL-PASSWORD
  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      if (!userCredential.user!.emailVerified) {
        logout();
        Get.snackbar(
          'Erreur',
          'Vous devez valider votre compte avant de vous connecter.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: Icon(Icons.error, color: Colors.white),
        );
        await userCredential.user!.sendEmailVerification();
        Get.snackbar(
          'Succès',
          'Veuillez valider votre email.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: Icon(Icons.check, color: Colors.white),
        );
      } else {

        var userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
        if (userDoc.exists) {
          int role = userDoc.data()?['role'] ?? 2;
          bool isblocked = userDoc.data()?['isBlocked']?? true;

          if (role == 1) {
            Get.offAll(Admin()); // Page Admin
          } else {
            if(isblocked == false){
              NotificationMessage.notif( Colors.red ,"Vous etes bloque " ,"Erreur");
            }else{
              Get.offAll(SunuProjetApp());
            }
          // Page Utilisateur
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Une erreur est survenue : $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }




Future<void>logout()async{
  await _firebaseAuth.signOut();
  Get.offAll(LoginPage());
}
  Future<void> createUserWithEmailAndPassword(String email , String password, String nom,File file) async{
    UserCredential userCredential = await  _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

    String uid = userCredential.user!.uid;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String filename = '${uid}_$timestamp.jpg';
    await sb.Supabase.instance.client.storage
        .from('images')
        .upload(
      filename,
      file,
      fileOptions: const sb.FileOptions(upsert: true),
    );
    final String imageUrl = sb.Supabase.instance.client.storage
        .from('images')
        .getPublicUrl(filename);
     await userCredential!.user!.sendEmailVerification();
    await FirebaseFirestore.instance.collection("users").doc(uid

    ).set({
      "id":uid,
      "nom":nom,
      "email":email,
      "isBlocked":true,
      "projets":[],
      "role": 2,
      "imageUrl" : imageUrl


    }


    );
    await logout();





}


}