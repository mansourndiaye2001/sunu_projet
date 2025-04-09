import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/adminPage.dart';
import 'Firebase/auth.dart';
import 'package:sunu_projet/screens/homePage.dart';
import 'package:sunu_projet/screens/Login.dart';

class Redirect_Page extends StatefulWidget {
  const Redirect_Page({super.key});

  @override
  State<Redirect_Page> createState() => _Redirect_PageState();
}

class _Redirect_PageState extends State<Redirect_Page> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {

          return const LoginPage();
        }

        User user = snapshot.data!;


        if (!user.emailVerified) {
          return const LoginPage();
        }


        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (roleSnapshot.hasData && roleSnapshot.data != null) {
              int role = roleSnapshot.data?.get('role') ?? 2;


              if (role == 1) {
                return Admin();
              } else {
                return SunuProjetApp();
              }
            }

            return const Center(child: Text('Erreur de chargement du rôle.'));
          },
        );
      },
    );
  }
}
