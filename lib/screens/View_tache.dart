import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunu_projet/screens/add_tache.dart';
import 'package:sunu_projet/services/Firebase/commentaire_db.dart';
import '../services/Firebase/task_db.dart';
import '../utils/fonctions.dart';
import 'package:sunu_projet/services/Firebase/projet_firebase_store.dart';

class Tasks extends StatefulWidget {
  final String idPoject;

  const Tasks({super.key, required this.idPoject});

  @override
  State<Tasks> createState() => _TasksState();
}

class _TasksState extends State<Tasks> {
  final TextEditingController _commentController = TextEditingController();
  String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  String projectCreatorId = '';  // Pour stocker l'ID du créateur

  @override
  void initState() {
    super.initState();
    _getProjectCreator();
  }

  // Fonction pour obtenir l'ID du créateur du projet
  Future<void> _getProjectCreator() async {
    try {
      DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance.collection('projects').doc(widget.idPoject).get();
      if (projectSnapshot.exists) {
        setState(() {
          projectCreatorId = projectSnapshot['createdBy']; // On suppose que le champ 'createdBy' contient l'ID du créateur
        });
      }
    } catch (e) {
      print("Erreur lors de la récupération du créateur du projet: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getTasksWithMembers(widget.idPoject),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aucune tâche disponible.'));
          }

          var tasks = snapshot.data!;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];

              String taskName = task['title']?.toString() ?? 'Titre inconnu';
              String memberName = task['assigned_to']?.toString() ?? 'Membre inconnu';
              double progress = (task['progress'] as num?)?.toDouble() ?? 0.0;
              String priority = task['priority']?.toString() ?? 'Priorité';
              String statut = task['statut']?.toString() ?? 'Statut';
              String description = task['description']?.toString() ?? 'Pas de description';
              String id = (task['id'] ?? '').toString();

              bool isAssignedToCurrentUser = task['emailToAssign']?.trim().toLowerCase() == currentUserEmail.trim().toLowerCase();

              DateTime date = DateTime.now();
              if (task['endDate'] != null) {
                try {
                  date = task['endDate'].toDate();
                } catch (e) {
                  print("Erreur de conversion de date: $e");
                }
              }

              double currentProgress = progress;

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              taskName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            convertDateToString(date) ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTag(priority, Colors.orange.shade100),
                          SizedBox(width: 8),
                          _buildTag(statut, Colors.blue.shade100),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Description:",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      SizedBox(height: 8),
                      Text("Progression: ${currentProgress.toStringAsFixed(0)}%", style: TextStyle(fontSize: 14)),

                      if (isAssignedToCurrentUser)
                        Slider(
                          value: currentProgress,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: "${currentProgress.toStringAsFixed(0)}%",
                          activeColor: currentProgress == 100 ? Colors.green : Colors.blue,
                          onChanged: (value) async {
                            setState(() {
                              currentProgress = value;
                            });

                            String newStatut = value == 100 ? 'Terminée' : 'En cours';

                            // S'assurer que la tâche a un projectId
                            await FirebaseFirestore.instance.collection('tasks').doc(id).update({
                              'progress': value,
                              'statut': newStatut,
                              'projectId': widget.idPoject,
                            });

                            print("Tâche mise à jour, statut: $newStatut, progression: $value");

                            // Mettre à jour la progression du projet avec un petit délai
                            // pour assurer que Firestore a bien enregistré les changements
                            await Future.delayed(Duration(milliseconds: 500));
                            await updateProjectProgress(widget.idPoject);
                          },
                        ),
                      SizedBox(height: 8),
                      Text("Assigné à: $memberName", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 12),
                      Divider(),
                      ExpansionTile(
                        title: Text("Commentaires:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: obtenirCommentairesTache(id),
                            builder: (context, commentSnapshot) {
                              if (commentSnapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (!commentSnapshot.hasData || commentSnapshot.data!.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text("Aucun commentaire"),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: commentSnapshot.data!.length,
                                itemBuilder: (context, i) {
                                  var comment = commentSnapshot.data![i];
                                  String userName = comment['nomUtilisateur'] ?? 'Utilisateur inconnu';
                                  String commentText = comment['texte'] ?? '';
                                  String userImageUrl = comment['imageUtilisateur'] ?? '';

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: userImageUrl.isNotEmpty
                                          ? NetworkImage(userImageUrl)
                                          : AssetImage('assets/images/default_avatar.png') as ImageProvider,
                                    ),
                                    title: Text(userName),
                                    subtitle: Text(commentText),
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(height: 8),
                          // Champ d'ajout de commentaire
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              labelText: "Ajouter un commentaire",
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(right: 16), // Décaler le bouton à gauche
                                child: IconButton(
                                  icon: Icon(Icons.send),
                                  onPressed: () {
                                    if (_commentController.text.isNotEmpty) {
                                      ajouterCommentaire(idTache: id, context: context, texteCommentaire: _commentController.text);
                                      _commentController.clear();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: projectCreatorId == FirebaseAuth.instance.currentUser?.uid
          ? FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        onPressed: () {
          Get.to(() => Add_Tache(id: widget.idPoject));
        },
      )
          : SizedBox(),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}