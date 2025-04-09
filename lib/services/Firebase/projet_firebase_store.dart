
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> create_projet(String titre, String description, String priorite, DateTime start_date, DateTime end_date, List<Map<String, String>> members) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return;
    }

    DocumentReference projectRef = await FirebaseFirestore.instance
        .collection('projects').add({
      'title': titre,
      'description': description,
      'startDate': Timestamp.fromDate(start_date),
      'endDate': Timestamp.fromDate(end_date),
      'priority': priorite,
      'createdBy': user.uid,
      'statut': 'En attente',
      'members': members,
      'progress': 0.0, // Initialiser la progression à 0
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'projets': FieldValue.arrayUnion([projectRef.id]),
        });

    print("Projet créé avec succès : ${projectRef.id}");
  } catch (e) {
    print("Erreur lors de la création du projet : $e");
  }
}


Stream<List<Map<String, dynamic>>> getUserProjects() {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .map((projectsSnapshot) {
      List<Map<String, dynamic>> userProjects = [];
      for (var doc in projectsSnapshot.docs) {
        Map<String, dynamic> projectData = doc.data() as Map<String, dynamic>;

        if (projectData.containsKey('members') && projectData['members'] is List) {
          List membres = projectData['members'];

          bool isUserMember = membres.any((membre) {
            if (membre is Map<String, dynamic>) {
              return membre['email'] == user.email;
            }
            return false;
          });

          if (isUserMember) {
            projectData['id'] = doc.id;

            if (projectData.containsKey('statut') && projectData['statut'] == 'En attente') {
              userProjects.add(projectData);
            }
          }
        }
      }

      return userProjects;
    });
  } catch (e) {
    print("Erreur lors de la récupération des projets : $e");
    return Stream.value([]);
  }
}


Stream<List<Map<String, dynamic>>> getUserProjects_byStatut(String statut) {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print("Utilisateur non connecté");
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('projects')
      .snapshots()
      .map((QuerySnapshot projectsSnapshot) {
    List<Map<String, dynamic>> userProjects = [];
    for (var doc in projectsSnapshot.docs) {
      Map<String, dynamic> projectData = doc.data() as Map<String, dynamic>;

      if (projectData.containsKey('members') && projectData['members'] is List) {
        List membres = projectData['members'];

        bool isUserMember = membres.any((membre) {
          if (membre is Map<String, dynamic>) {
            return membre['email'] == user.email;
          }
          return false;
        });

        if (isUserMember) {
          projectData['id'] = doc.id;

          // Si le statut correspond à celui demandé
          if (projectData.containsKey('statut') && projectData['statut'] == statut) {
            // Si la progression n'existe pas encore, initialiser à 0
            if (!projectData.containsKey('progress')) {
              projectData['progress'] = 0;
            }
            userProjects.add(projectData);
          }
        }
      }
    }
    return userProjects;
  });
}

// Fonction pour récupérer les membres d'un projet
Stream<List<Map<String, dynamic>>> getProjectMembersStream(String projectId) {
  final controller = StreamController<List<Map<String, dynamic>>>();

  void fetchData() async {
    try {
      FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .snapshots()
          .listen((projectSnapshot) {
        if (!projectSnapshot.exists) {
          print("Projet non trouvé");
          controller.add([]);
          return;
        }

        Map<String, dynamic> projectData = projectSnapshot.data() as Map<String, dynamic>;

        if (!projectData.containsKey('members')) {
          print("Aucun membre trouvé dans le projet");
          controller.add([]);
          return;
        }

        List<dynamic> members = projectData['members'];
        _processMemberDetails(members, controller);
      }, onError: (error) {
        print("Erreur lors de l'écoute du projet : $error");
        controller.addError(error);
      });
    } catch (e) {
      print("Erreur lors de l'initialisation du stream de membres : $e");
      controller.addError(e);
    }
  }
  fetchData();
  return controller.stream;
}

void _processMemberDetails(List<dynamic> members, StreamController<List<Map<String, dynamic>>> controller) async {
  try {
    List<Map<String, dynamic>> memberDetails = [];

    if (members.isEmpty) {
      controller.add([]);
      return;
    }

    for (var member in members) {
      if (member is Map<String, dynamic>) {
        String email = member['email'] ?? '';
        String role = member['role'] ?? '';

        FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .snapshots()
            .listen((userSnapshot) {
          if (userSnapshot.docs.isNotEmpty) {
            DocumentSnapshot userDoc = userSnapshot.docs.first;
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            String name = userData['nom'] ?? 'Nom inconnu';
            String imageUrl = userData['imageUrl'] ?? '';

            int existingIndex = memberDetails.indexWhere((m) => m['email'] == email);
            if (existingIndex >= 0) {
              memberDetails[existingIndex] = {
                'name': name,
                'email': email,
                'role': role,
                'imageUrl': imageUrl
              };
            } else {
              memberDetails.add({
                'name': name,
                'email': email,
                'role': role,
                'imageUrl': imageUrl
              });
            }
            controller.add(List.from(memberDetails));
          }
        }, onError: (error) {
          print("Erreur lors de la récupération des détails de l'utilisateur : $error");
        });
      }
    }
  } catch (e) {
    print("Erreur lors du traitement des détails des membres : $e");
    controller.addError(e);
  }
}

// Fonction pour ajouter un membre à un projet
Future<bool> addProjectMember({
  required String projectId,
  required String email,
  required BuildContext context,
  String customRole = "Membre",
}) async {
  try {
    if (!_isValidEmail(email)) {
      _showSnackBar(context, "L'adresse email n'est pas valide", Colors.red);
      return false;
    }

    DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectSnapshot.exists) {
      _showSnackBar(context, "Le projet n'existe pas", Colors.red);
      return false;
    }

    Map<String, dynamic> projectData = projectSnapshot.data() as Map<String, dynamic>;
    List<dynamic> members = projectData['members'] ?? [];

    bool isMemberAlready = members.any((member) {
      if (member is Map<String, dynamic>) {
        return member['email'] == email;
      }
      return false;
    });

    if (isMemberAlready) {
      _showSnackBar(context, "Ce membre fait déjà partie du projet", Colors.orange);
      return false;
    }

    // Vérifie d'abord si l'utilisateur existe dans la collection 'users'
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      _showSnackBar(
        context,
        "L'utilisateur n'existe pas dans le système, impossible de l'ajouter.",
        Colors.red,
      );
      return false;
    }

    // Ajouter le membre uniquement si l'utilisateur existe
    members.add({
      'email': email,
      'role': customRole,
    });

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({'members': members});

    _showSnackBar(context, "Membre ajouté avec succès !", Colors.green);
    return true;
  } catch (e) {
    print("Erreur lors de l'ajout du membre : $e");
    _showSnackBar(context, "Erreur lors de l'ajout du membre: $e", Colors.red);
    return false;
  }
}



void _showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: Duration(seconds: 3),
    ),
  );
}

bool _isValidEmail(String email) {
  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegExp.hasMatch(email);
}
Future<void> changerStatutProjet(String projectId, String newStatut) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return;
    }

    DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectSnapshot.exists) {
      print("Le projet n'existe pas");
      return;
    }

    Map<String, dynamic> projectData = projectSnapshot.data() as Map<String, dynamic>;

    if (projectData['createdBy'] != user.uid) {
      Get.snackbar(
        "Erreur",
        "Vous n'êtes pas le créateur du projet",
        duration: Duration(seconds: 10),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(10),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
      return;
    }

    // Si le nouveau statut est "Terminé", définir directement la progression à 100%
    if (newStatut == "Terminé" || newStatut == "Terminée") {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'statut': newStatut,
        'progress': 100,
        'completedAt': FieldValue.serverTimestamp()
      });

      Get.snackbar(
        "Succès",
        "Projet marqué comme terminé avec succès",
        duration: Duration(seconds: 10),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(10),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    }
    // Si le nouveau statut est "Annulé", conserver la progression actuelle
    else if (newStatut == "Annulé") {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'statut': newStatut,
        'canceledAt': FieldValue.serverTimestamp()
      });

      Get.snackbar(
        "Information",
        "Le projet a été annulé",
        duration: Duration(seconds: 10),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade300,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(10),
        icon: Icon(Icons.cancel, color: Colors.white),
      );
    }
    // Pour les autres statuts, mettre à jour uniquement le statut
    else {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'statut': newStatut,
      });

      // Recalculer la progression après changement de statut
      await updateProjectProgress(projectId);

      Get.snackbar(
        "Succès",
        "Modification du statut avec succès",
        duration: Duration(seconds: 10),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        borderRadius: 10,
        margin: EdgeInsets.all(10),
        icon: Icon(Icons.check_circle, color: Colors.white),
      );
    }
  } catch (e) {
    print("Erreur lors de la mise à jour du statut du projet : $e");
    Get.snackbar(
      "Erreur",
      "Erreur lors de la mise à jour du statut du projet : $e",
      duration: Duration(seconds: 10),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      borderRadius: 10,
      margin: EdgeInsets.all(10),
      icon: Icon(Icons.error, color: Colors.white),
    );
  }
}

//calcule et mettre à jour la progression d'un projet
Future<void> updateProjectProgress(String projectId) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return;
    }

    DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .get();

    if (!projectSnapshot.exists) {
      print("Le projet n'existe pas");
      return;
    }

    Map<String, dynamic> projectData = projectSnapshot.data() as Map<String, dynamic>;

    // Récupérer toutes les tâches du projet depuis la collection 'tasks'
    QuerySnapshot tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('projectId', isEqualTo: projectId)
        .get();

    int totalTasks = tasksSnapshot.docs.length;

    // Si aucune tâche, la progression est à 0%
    if (totalTasks == 0) {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'progress': 0,
        'statut': 'En attente'
      });
      print("Aucune tâche trouvée, progression mise à 0");
      return;
    }

    // Compter les tâches terminées et les tâches en cours
    int completedTasks = 0;
    int inProgressTasks = 0;

    // Calculer la progression globale en utilisant la moyenne des progressions des tâches
    double totalProgress = 0;

    for (var doc in tasksSnapshot.docs) {
      Map<String, dynamic> taskData = doc.data() as Map<String, dynamic>;
      String taskStatus = taskData['statut'] ?? '';
      double taskProgress = (taskData['progress'] as num?)?.toDouble() ?? 0.0;

      // Accumuler la progression totale
      totalProgress += taskProgress;

      if (taskStatus == 'Terminée' || taskProgress == 100) {
        completedTasks++;
      } else if (taskStatus == 'En cours' || taskProgress > 0) {
        inProgressTasks++;
      }
    }

    // Calculer le pourcentage de progression moyen
    double progressPercentage = totalProgress / totalTasks;
    int progress = progressPercentage.round();


    String newStatus;

    Timestamp endDateTimestamp = projectData['endDate'];
    DateTime endDate = endDateTimestamp.toDate();
    DateTime now = DateTime.now();

    if (now.isAfter(endDate)) {
      // La date de fin est dépassée
      newStatus = 'Terminé';
    } else if (completedTasks == totalTasks) {
      // Toutes les tâches sont terminées
      newStatus = 'Terminé';
      progress = 100;
    } else if (inProgressTasks > 0) {
      // Au moins une tâche est en cours
      newStatus = 'En cours';
    } else {
      // Aucune tâche en cours, mais pas toutes terminées
      newStatus = 'En attente';
    }

    // Mettre à jour le projet
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .update({
      'progress': progress,
      'statut': newStatus
    });

    print("Progression du projet mise à jour : $progress%, Statut : $newStatus");

  } catch (e) {
    print("Erreur lors de la mise à jour de la progression du projet : $e");
  }
}

// Fonction pour obtenir un flux des projets avec leurs progressions
Stream<List<Map<String, dynamic>>> getUserProjectsWithProgress() {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('projects')
        .snapshots()
        .asyncMap((projectsSnapshot) async {
      List<Map<String, dynamic>> userProjects = [];

      for (var doc in projectsSnapshot.docs) {
        Map<String, dynamic> projectData = doc.data() as Map<String, dynamic>;

        if (projectData.containsKey('members') && projectData['members'] is List) {
          List membres = projectData['members'];

          bool isUserMember = membres.any((membre) {
            if (membre is Map<String, dynamic>) {
              return membre['email'] == user.email;
            }
            return false;
          });

          if (isUserMember) {
            projectData['id'] = doc.id;

            // Vérifier si une mise à jour de la progression est nécessaire
            if (!projectData.containsKey('progress')) {
              await updateProjectProgress(doc.id);

              // Récupérer les données mises à jour
              DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
                  .collection('projects')
                  .doc(doc.id)
                  .get();

              if (updatedDoc.exists) {
                projectData = updatedDoc.data() as Map<String, dynamic>;
                projectData['id'] = doc.id;
              }
            }

            userProjects.add(projectData);
          }
        }
      }

      return userProjects;
    });
  } catch (e) {
    print("Erreur lors de la récupération des projets avec progression : $e");
    return Stream.value([]);
  }
}

// Fonction à appeler chaque fois qu'une tâche est modifiée ou créée
Future<void> onTaskChanged(String projectId, String taskId, String newStatus) async {
  try {
    // Mettre à jour le statut de la tâche
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': newStatus,
      'lastUpdated': FieldValue.serverTimestamp()
    });

    // Recalculer la progression du projet
    await updateProjectProgress(projectId);

  } catch (e) {
    print("Erreur lors de la mise à jour de la tâche : $e");
  }
}

// Fonction pour créer une tâche dans un projet
Future<void> createTask(String projectId, String title, String description, DateTime dueDate, String assignedTo) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Utilisateur non connecté");
      return;
    }

    DocumentReference taskRef = await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .add({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedTo': assignedTo,
      'createdBy': user.uid,
      'status': 'En attente',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("Tâche créée avec succès : ${taskRef.id}");

    // Mettre à jour la progression du projet
    await updateProjectProgress(projectId);

  } catch (e) {
    print("Erreur lors de la création de la tâche : $e");
  }
}

// Fonction pour vérifier et mettre à jour le statut des projets basé sur la date de fin
Future<void> checkProjectDeadlines() async {
  try {
    DateTime now = DateTime.now();

    // Récupérer tous les projets dont la date de fin est dépassée mais pas encore marqués terminés
    QuerySnapshot projectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('endDate', isLessThan: Timestamp.fromDate(now))
        .where('statut', isNotEqualTo: 'Terminé')
        .get();

    for (var doc in projectsSnapshot.docs) {
      String projectId = doc.id;

      // Mettre à jour le statut du projet à "Terminé" et la progression à 100%
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .update({
        'statut': 'Terminé',
        'progress': 100,
        'completedAt': Timestamp.fromDate(now)
      });

      print("Projet $projectId marqué comme terminé car la date de fin est dépassée");
    }
  } catch (e) {
    print("Erreur lors de la vérification des dates limites des projets : $e");
  }
}

// Fonction pour créer un écouteur qui vérifie régulièrement les dates limites des projets
Timer? deadlineCheckTimer;

void startDeadlineChecker() {
  // Arrêter l'ancien timer s'il existe
  deadlineCheckTimer?.cancel();

  // Créer un nouveau timer qui s'exécute toutes les heures
  deadlineCheckTimer = Timer.periodic(Duration(hours: 1), (timer) {
    checkProjectDeadlines();
  });

  // Exécuter immédiatement une première vérification
  checkProjectDeadlines();
}

// Appeler cette fonction au démarrage de l'application
void initializeProjectProgressManagement() {
  startDeadlineChecker();
}