import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String priority;
  final String status;
  final List<Map<String, dynamic>> members;
  final String createdBy;
  final double progress; // Ajout du champ progress

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.status,
    required this.members,
    required this.createdBy,
    required this.progress, // Ajouter le champ progress au constructeur
  });

  factory Project.fromFirestore(Map<String, dynamic> data) {
    return Project(
      id: data['id'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: data['startDate'].toDate(),
      endDate: data['endDate'].toDate(),
      priority: data['priority'] ?? '',
      status: data['statut'] ?? '',
      members: List<Map<String, dynamic>>.from(data['members'] ?? []),
      createdBy: data['createdBy'] ?? '',
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0, // Ajouter la récupération du champ progress
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'priority': priority,
      'statut': status,
      'members': members,
      'createdBy': createdBy,
      'progress': progress, // Ajouter le champ progress lors de l'enregistrement
    };
  }
}
