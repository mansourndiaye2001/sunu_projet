import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

final FirebaseFirestore _db = FirebaseFirestore.instance;
final User? user = FirebaseAuth.instance.currentUser;

Future<void> assignTaskToMember({
  required String projectId,
  required String taskTitle,
  required String taskDescription,
  required DateTime taskEndDate,
  required String taskPriority,
  required String memberEmail,
}) async {
  try {
    DocumentSnapshot projectSnapshot = await _db.collection('projects').doc(projectId).get();
    if (!projectSnapshot.exists) {
      throw Exception("Le projet n'existe pas");
    }

    Map<String, dynamic> projectData = projectSnapshot.data() as Map<String, dynamic>;

    if (projectData['createdBy'] != user?.uid) {
      Get.snackbar(
        'Erreur',
        "Vous n'êtes pas autorisé à assigner une tâche à un membre !",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 8.0,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      );
      return;
    }
    List<Map<String, dynamic>> members = List<Map<String, dynamic>>.from(projectData['members'] ?? []);
    bool memberExists = members.any((member) {
      String memberEmail = member['email']?.trim().toLowerCase() ?? '';
      String emailToCheck = memberEmail.trim().toLowerCase();
      return memberEmail == emailToCheck;
    });

    if (!memberExists) {
      Get.snackbar(
        'Erreur',
        "Le membre avec cet email n'est pas dans le projet",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 8.0,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      );
      return;
    }
    DocumentReference taskRef = await _db.collection('tasks').add({
      'title': taskTitle,
      'description': taskDescription,
      'endDate': Timestamp.fromDate(taskEndDate),
      'statut': 'En attente',
      'priority': taskPriority,
      'progress': 0.0,
      'projectId': projectId,
      'assigned_to': memberEmail,
    });

    Get.snackbar(
      'Succès',
      "La tâche a été assignée avec succès.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      borderRadius: 8.0,
      margin: EdgeInsets.all(16),
      duration: Duration(seconds: 3),
    );

  } catch (e) {
    print('Erreur: $e');
    Get.snackbar(
      'Erreur',
      'Une erreur est survenue lors de l\'assignation de la tâche.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      borderRadius: 8.0,
      margin: EdgeInsets.all(16),
      duration: Duration(seconds: 3),
    );
  }
}

Stream<List<Map<String, dynamic>>> getTasksWithMembers(String projectId) {
  return _db.collection('tasks')
      .where('projectId', isEqualTo: projectId)
      .snapshots()
      .asyncMap((snapshot) async {
    if (snapshot.docs.isEmpty) {
      return []; // Retourne une liste vide plutôt que de lancer une exception
    }

    List<Map<String, dynamic>> tasks = snapshot.docs
        .map((doc) {
      var taskData = doc.data() as Map<String, dynamic>;
      taskData['id'] = doc.id; // Ajout de l'ID du document
      return taskData;
    })
        .toList();

    var querySnapshot = await _db.collection('users').get();
    List<Map<String, dynamic>> users = querySnapshot.docs
        .map((doc) => {
      ...doc.data(),
      'id': doc.id // Ajout de l'ID du document utilisateur
    })
        .toList();

    for (var task in tasks) {
      String? assignedEmail = task['assigned_to'];

      // Gestion sécurisée si l'email est null
      if (assignedEmail == null) {
        task['assigned_to'] = 'Nom Inconnu';
        continue;
      }

      var assignedUser = users.firstWhere(
            (user) => user['email']?.trim().toLowerCase() == assignedEmail.trim().toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      task['projectId'] = projectId;

      // Utilisation de l'opérateur ?? pour gérer les cas où le nom est null
      task['assigned_to'] = assignedUser['nom'] ?? 'Nom Inconnu';
      task['emailToAssign']=assignedUser['email'] ?? 'email Inconnu';
    }

    return tasks;
  });
}





