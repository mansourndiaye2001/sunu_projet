
import 'package:flutter/material.dart';

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
    return StreamBuilder(
        stream: Auth().authStateChanges,
        builder: (context , snapshot){
          if(snapshot.connectionState== ConnectionState.waiting){
            return const  CircularProgressIndicator();
          } else if (snapshot.hasData){
            return const MyHomePage();

          }else{
            return const LoginPage();
          }
        }
    );
  }
}
