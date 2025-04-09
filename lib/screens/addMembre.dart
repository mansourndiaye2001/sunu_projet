import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:sunu_projet/screens/projet_membres_details.dart';
import 'package:sunu_projet/services/Firebase/projet_firebase_store.dart';
import 'package:sunu_projet/controllers/ProjetController.dart';

class AddProjectMemberScreen extends StatefulWidget {
  final String id;
  const AddProjectMemberScreen({super.key , required this.id});
  @override
  _AddProjectMemberScreenState createState() => _AddProjectMemberScreenState();
}

class _AddProjectMemberScreenState extends State<AddProjectMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = "Membre";
  bool _isLoading = false;

  final List<String> _availableRoles = ["Membre", "Admin"];


  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });


      try {
        bool success = await addProjectMember(
          projectId: widget.id ,
          email: _emailController.text.trim(),
          context: context,
          customRole: _selectedRole,
        );
        Get.back();



      } catch (e) {
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter un membre"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section d'en-tête avec nom du projet
              Card(
                margin: EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Projet: ${""}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Ajoutez de nouveaux membres à ce projet en saisissant leur adresse email.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Champ email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Adresse email",
                  hintText: "Entrez l'adresse email du membre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Veuillez saisir une adresse email";
                  }
                  // Vérification de base de l'email
                  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(value)) {
                    return "Veuillez saisir une adresse email valide";
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Sélection du rôle
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: "Rôle",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: Icon(Icons.badge),
                ),
                items: _availableRoles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),

              SizedBox(height: 24),

              // Bouton d'ajout
              ElevatedButton(
                onPressed: _isLoading ? null : _addMember,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Ajouter le membre",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              SizedBox(height: 16),

              // Notes informatives
              Card(
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notes:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• Si l'utilisateur existe déjà, il sera ajouté directement au projet.",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        "• Si l'utilisateur n'existe pas, une invitation lui sera envoyée par email.",
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        "• Par défaut, les nouveaux membres ont le rôle \"Membre\".",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}