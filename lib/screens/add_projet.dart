import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';

import '../services/Firebase/projet_firebase_store.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sunu_projet/screens/homePage.dart';

import '../utils/fonctions.dart';

class CreateProjectPage extends StatefulWidget {
  @override
  _CreateProjectPageState createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _projectTitleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _priority = "Moyenne";
  List<Map<String, String>> _members = [];
  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    super.initState();
    User? currentUser = getCurrentUser();
    if (currentUser != null) {
      _members.add({
        'email': currentUser.email!,
        'role': 'Créateur',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Créer un projet'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _projectTitleController,
                decoration: InputDecoration(
                  labelText: 'Titre du projet',
                  prefixIcon: Icon(Icons.text_fields),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == '') return 'Veuillez saisir le titre du projet';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == '') return 'Veuillez saisir la description du projet';
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Section Date de début
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date de début'),
                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2026));
                          if (date != null) {
                            setState(() {
                              _startDate = date;
                            });
                          }
                        },
                        icon: Icon(Icons.calendar_today),
                      ),
                      Text(convertDateToString(_startDate))
                    ],
                  ),
                  // Section Date de fin
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date de fin'),

                      IconButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime(1950),
                              lastDate: DateTime(2026));
                          if (date != null) {
                            setState(() {
                              _endDate = date;
                            });
                          }
                        },
                        icon: Icon(Icons.calendar_today),
                        

                      ),
                      Text(convertDateToString(_endDate))
                      
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text('Priorité'),
              Column(
                children: ['Basse', 'Moyenne', 'Haute', 'Urgente']
                    .map((priority) => RadioListTile(
                  title: Text(priority),
                  value: priority,
                  groupValue: _priority,
                  onChanged: (value) {
                    setState(() {
                      _priority = value.toString();
                    });
                  },
                ))
                    .toList(),
              ),
              SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      create_projet(
                        _projectTitleController.text,
                        _descriptionController.text,
                        _priority,
                        _startDate,
                        _endDate,
                        _members,
                      );
                      Get.snackbar(
                        'Succès',
                        'Le projet a été créé avec succès!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        borderRadius: 8.0,
                        margin: EdgeInsets.all(16),
                        duration: Duration(seconds: 3),
                      );
                      Get.to(()=>SunuProjetApp() );

                    }
                  },
                  child: Text('Créer le projet', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
