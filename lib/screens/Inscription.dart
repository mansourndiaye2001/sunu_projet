import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sunu_projet/screens/Login.dart';
import '../services/Firebase/auth.dart';
import 'package:sunu_projet/widgets/notifaction.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _nomController = TextEditingController();
  TextEditingController _password_ConfirmController = TextEditingController();
  final _forkey = GlobalKey<FormState>();
  bool _isLoading = false;
  File ?file;
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Inscription", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _forkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Rejoignez SunuProjet pour gérer vos projets",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              /*
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green
                      
                ),
                child: file==null ? null:
                    Image.file(file!)
                
                
              ),
                 */

               Center(
                 child: CircleAvatar(
                   backgroundImage: file==null ? null : FileImage(file!),
                   radius: 50,
                 ),
               ),


              IconButton(onPressed: ()async{
                XFile? xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                if(xFile != null){
                  setState(() {
                    file = File(xFile.path);
                  });
                }
              }, icon: Icon(Icons.camera_alt)),


              SizedBox(height: 20,),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: "Nom complet",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == '') return 'Veuillez saisir votre Nom Complet ';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Adresse Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == '') return 'Veuillez saisir votre Email';
                  if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                      .hasMatch(value!)) {
                    return 'Veuillez entrer un email valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Mot de Passe",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == '') return 'Veuillez saisir votre Mot de Pass  ';
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _password_ConfirmController,
                decoration: InputDecoration(
                  labelText: "Confirmer le Mot de Passe",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: Icon(Icons.visibility_off),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == '') return 'Veuillez Confirmer  votre Mot de Pass ';
                  if (_passwordController.text != value) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: _isLoading ? null : () async {
                    if (_forkey.currentState!.validate()) {
                      if (_passwordController.text != _password_ConfirmController.text) {
                        NotificationMessage.showSnackBar(context,"Les mots de pass ne se correspondent pas!!",isSuccess: false);

                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        await Auth().createUserWithEmailAndPassword(
                          _emailController.text,
                          _passwordController.text,
                          _nomController.text,
                          file!
                        );

                        // Message de succès
                        NotificationMessage.showSnackBar(
                            context,
                            "Inscription réussie ! Veuillez vérifier votre email pour valider votre compte.",
                            isSuccess: true
                        );

                        // Redirection vers la page de connexion après inscription
                        Get.off(() => LoginPage());
                      } on FirebaseAuthException catch (e) {
                        // Message d'erreur approprié
                        NotificationMessage.showSnackBar(
                            context,
                            "Erreur : ${e.message}",
                            isSuccess: false
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }


                    }
                  },
                  child: _isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Text(
                    "S'inscrire",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Vous avez déjà un compte? "),
                    GestureDetector(
                      onTap: () {
                       Get.to(()=>LoginPage());
                      },
                      child: Text(
                        "Se connecter",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
