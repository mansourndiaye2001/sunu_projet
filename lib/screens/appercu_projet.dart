import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sunu_projet/models/Projet.dart';
import 'package:sunu_projet/services/Firebase/projet_firebase_store.dart';

class Apercu extends StatefulWidget {
  final Project project;
  const Apercu({super.key, required this.project});

  @override
  State<Apercu> createState() => _ApercuState();
}

class _ApercuState extends State<Apercu> {
  final List<Map<String, dynamic>> statuses = [
    {
      'label': 'En attente',
      'color': Colors.orange,
      'bgColor': Colors.orange.shade100
    },
    {
      'label': 'En cours',
      'color': Colors.blue,
      'bgColor': Colors.blue.shade100
    },
    {
      'label': 'Terminé',
      'color': Colors.green,
      'bgColor': Colors.green.shade100
    },
    {
      'label': 'Annulé',
      'color': Colors.red,
      'bgColor': Colors.red.shade100
    },
  ];

  late final bool isCreator;

  @override
  void initState() {
    super.initState();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    isCreator = widget.project.createdBy == currentUserId;
    print("===> currentUserId: $currentUserId");
    print("===> projectCreatedBy: ${widget.project.createdBy}");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte projet
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.project.title,
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(widget.project.status))
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.priority_high,
                            color: Colors.red, size: 18),
                        SizedBox(width: 4),
                        Text("Priorité: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(widget.project.priority))
                      ],
                    ),
                    SizedBox(height: 8),
                    Text("Description",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text(widget.project.description)),
                    SizedBox(height: 8),
                    Text("Dates",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text(
                                widget.project.startDate.toString(),
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.event, size: 16),
                        Expanded(
                          child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: Text(
                                widget.project.endDate.toString(),
                                overflow: TextOverflow.ellipsis,
                              )),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Carte Avancement
            if(isCreator)
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Avancement du projet",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: widget.project.progress / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                            AlwaysStoppedAnimation(Colors.blue),
                          ),
                          Text("${widget.project.progress}%", style: TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),


              Text(
                "Changer le statut du projet",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: statuses.map((statuts) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statuts['bgColor'],
                        foregroundColor: statuts['color'],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        elevation: 0,
                      ),
                      onPressed: () {
                        changerStatutProjet(
                            widget.project.id, statuts['label']);
                      },
                      child: Text(
                        statuts['label'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ]

        ),
      ),
    );
  }
}
