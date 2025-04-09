import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../services/Firebase/task_db.dart';
import '../utils/fonctions.dart';
import 'package:sunu_projet/screens/View_tache.dart';
class Add_Tache extends StatefulWidget {
  final String id;
  const Add_Tache({super.key , required this.id});

  @override
  State<Add_Tache> createState() => _Add_TacheState();
}

class _Add_TacheState extends State<Add_Tache> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _taskitleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  DateTime _endDate = DateTime.now();
  String _priority = "Moyenne";
  bool   _isLoading =false;



  @override
  Widget build(BuildContext context) {
  return  Scaffold(
    appBar: AppBar(
      title: Text("Ajouter une Tache"),
    ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _taskitleController,
                decoration: InputDecoration(
                  labelText: 'Titre de la Tache',
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
                      Text('Date de Fin'),
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
                  // Section Date de fin

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
          TextFormField(
         controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email du membre a assigne ',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == '') return 'Veuillez saisir votre Email';
              if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value!)) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },

          ),
              SizedBox(height: 16,),

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      assignTaskToMember(
                      projectId:   widget.id,
                        taskTitle: _taskitleController.text,
                        taskDescription: _descriptionController.text,
                        taskPriority: _priority,
                        taskEndDate: _endDate,
                        memberEmail: _emailController.text

                      );

                    Get.back();





                    }
                  },
                  child: Text('Créer une tache', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
