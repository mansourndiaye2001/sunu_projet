import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunu_projet/models/Projet.dart';
import 'package:sunu_projet/utils/fonctions.dart';
import 'package:sunu_projet/screens/ViewProjet.dart';
import '../services/Firebase/projet_firebase_store.dart';

class ProjectList extends StatefulWidget {
  final String statut;
  const ProjectList({super.key, required this.statut});

  @override
  State<ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Projets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getUserProjects_byStatut(widget.statut),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur : ${snapshot.error}'));
            }

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              List<Map<String, dynamic>> data = snapshot.data!;
              List<Project> projects = data.map((e) => Project.fromFirestore(e)).toList();

              return ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  var project = projects[index];

                  // Conversion sécurisée
                  double progress = (data[index]['progress'] as num?)?.toDouble() ?? 0.0;

                  // Couleur basée sur la progression
                  Color progressColor;
                  if (progress >= 100) {
                    progressColor = Colors.green;
                  } else if (progress >= 50) {
                    progressColor = Colors.blue;
                  } else if (progress >= 25) {
                    progressColor = Colors.orange;
                  } else {
                    progressColor = Colors.red;
                  }

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // Navigation vers l'aperçu du projet
                        Get.to(() => ProjectOverview(project: project));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre et priorité
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    project.title,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: project.priority == 'Urgente'
                                        ? Colors.red.shade100
                                        : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    project.priority,
                                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8),

                            // Description
                            Text(
                              project.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: 12),

                            // Barre de progression
                            LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.grey.shade300,
                              color: progressColor,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),

                            SizedBox(height: 6),

                            // Pourcentage et bouton de rafraîchissement
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$progress% terminé',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: progressColor),
                                ),
                                IconButton(
                                  icon: Icon(Icons.refresh, size: 18),
                                  onPressed: () {
                                    updateProjectProgress(project.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mise à jour de la progression en cours...'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            SizedBox(height: 6),

                            // Date et membres
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Date
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                    SizedBox(width: 4),
                                    Text(
                                      project.endDate != null
                                          ? convertDateToString(project.endDate)
                                          : "Échéance: 12/08/2025",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),

                                // Membres du projet
                                StreamBuilder<List<Map<String, dynamic>>>(
                                  stream: getProjectMembersStream(project.id),
                                  builder: (context, membersSnapshot) {
                                    if (membersSnapshot.hasData && membersSnapshot.data!.isNotEmpty) {
                                      return Container(
                                        height: 28,
                                        width: membersSnapshot.data!.length > 3 ? 80 : membersSnapshot.data!.length * 20,
                                        child: Stack(
                                          children: [
                                            for (int i = 0; i < (membersSnapshot.data!.length > 3 ? 3 : membersSnapshot.data!.length); i++)
                                              Positioned(
                                                left: i * 16.0,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.white,
                                                  radius: 14,
                                                  child: CircleAvatar(
                                                    backgroundImage: membersSnapshot.data![i]['imageUrl'] != null && membersSnapshot.data![i]['imageUrl'].isNotEmpty
                                                        ? NetworkImage(membersSnapshot.data![i]['imageUrl'])
                                                        : null,
                                                    backgroundColor: Colors.blueAccent,
                                                    radius: 12,
                                                    child: membersSnapshot.data![i]['imageUrl'] == null || membersSnapshot.data![i]['imageUrl'].isEmpty
                                                        ? Text(
                                                      membersSnapshot.data![i]['name'][0].toUpperCase(),
                                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                                    )
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                            if (membersSnapshot.data!.length > 3)
                                              Positioned(
                                                left: 3 * 16.0,
                                                child: CircleAvatar(
                                                  backgroundColor: Colors.grey,
                                                  radius: 12,
                                                  child: Text(
                                                    "+${membersSnapshot.data!.length - 3}",
                                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }
                                    return CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 12,
                                      child: Icon(Icons.person, size: 16, color: Colors.white),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'Aucun projet trouvé',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Rejoignez un projet ou créez-en un nouveau',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}