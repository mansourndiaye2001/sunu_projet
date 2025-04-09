import 'package:flutter/material.dart';

import 'package:sunu_projet/models/Projet.dart';
import 'package:sunu_projet/screens/View_tache.dart';
import 'package:sunu_projet/screens/appercu_projet.dart';
import 'package:sunu_projet/screens/appercu_projet.dart';

import 'package:sunu_projet/screens/projet_membres_details.dart';


class ProjectOverview extends StatefulWidget {
  @override
  final Project project;

  const ProjectOverview({super.key, required this.project});
  _ProjectOverviewState createState() => _ProjectOverviewState();
}

class _ProjectOverviewState extends State<ProjectOverview> {
  Project get project =>widget.project;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Nombre d'onglets
      child: Scaffold(
        appBar: AppBar(
          title:Center(
           child: Text(project.title),
          ),
          actions: [
            IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(icon: Icon(Icons.visibility), text: "Aperçu"),
              Tab(icon: Icon(Icons.people), text: "Membres"),
              Tab(icon: Icon(Icons.list), text: "Tâches"),
              Tab(icon: Icon(Icons.folder), text: "Fichiers"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
           Apercu(project: project,),
            ProjectMembersScreen(idPoject: widget.project.id),
            Tasks(idPoject: widget.project.id,),
            Text("data"),
          ],
        ),
      ),
    );
  }
}

