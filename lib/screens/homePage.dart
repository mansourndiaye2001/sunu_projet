
import 'package:flutter/material.dart';

import '../services/Firebase/auth.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text("Bienvue"),
        actions: [
          IconButton(
              onPressed: (){
                Auth().logout();
              },
              icon: Icon(Icons.exit_to_app))
        ],
      ),
    );
  }
}
