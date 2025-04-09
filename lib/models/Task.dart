import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime endDate;
  final String status;
  final double progress;
  final String priority;
  final String statut;
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    required this.status,
    required this.progress,
    required this.priority,
    required this.statut
  });

  factory Task.fromFirestore(Map<String, dynamic> data) {
    return Task(
      id: data['id'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      endDate: data['endDate'].toDate(),
      priority: data['priority'] ?? '',
      status: data['statut'] ?? '',
      progress: data['progress']?? '', statut: ''
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'end_date': Timestamp.fromDate(endDate),
      'priority': priority,
      'status': status,
      'progress': progress,
      'id':id

    };
  }


}
