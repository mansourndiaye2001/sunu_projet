import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunu_projet/services/Firebase/projet_firebase_store.dart';
import 'package:sunu_projet/screens/addMembre.dart';

class ProjectMembersScreen extends StatelessWidget {
  final String idPoject;
  const ProjectMembersScreen({super.key, required this.idPoject});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('projects').doc(idPoject).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return SizedBox();
          }
          final projectData = snapshot.data!;
          final projectCreatorId = projectData['createdBy'];

          if (currentUserId == projectCreatorId) {
            return FloatingActionButton(
              onPressed: () {
                Get.to(() => AddProjectMemberScreen(id: idPoject));
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
            );
          }

          return SizedBox();
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getProjectMembersStream(idPoject),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    "Erreur lors du chargement des membres",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "${snapshot.error}",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.data == null) {
            return Center(child: Text("Aucune donnée disponible"));
          }

          List<Map<String, dynamic>> members = snapshot.data!;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Aucun membre trouvé",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Les membres ajoutés au projet apparaîtront ici",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: members.length,
            itemBuilder: (context, index) {
              var member = members[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: member['imageUrl'] != null
                      ? CircleAvatar(
                    backgroundImage: NetworkImage(member['imageUrl']),
                    radius: 30,
                  )
                      : CircleAvatar(
                    child: Icon(Icons.person),
                    radius: 30,
                  ),
                  title: Text(
                    member['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        member['email'],
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                  trailing: _buildRoleBadge(member['role']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fonction pour générer une couleur d'avatar basée sur le nom
  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.deepPurple,
      Colors.lightBlue,
    ];

    // Générer un index basé sur le nom
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (role) {
      case 'Créateur':
        badgeColor = Colors.orange;
        badgeIcon = Icons.star;
        badgeText = "Créateur";
        break;
      case 'Admin':
        badgeColor = Colors.blue;
        badgeIcon = Icons.admin_panel_settings;
        badgeText = "Admin";
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.person;
        badgeText = "Membre";
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        border: Border.all(color: badgeColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 16, color: badgeColor),
          SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
