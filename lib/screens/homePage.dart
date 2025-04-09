import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sunu_projet/services/Firebase/auth.dart';
import '../services/Firebase/projet_firebase_store.dart';
import 'ProjectList.dart';
import 'add_projet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SunuProjetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      theme: ThemeData(
        primaryColor: Colors.blue,
        fontFamily: 'Roboto',
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  String searchQuery = '';
  String searchType = 'statut'; // Par défaut, recherche par statut
  DateTime? selectedDate;
  final TextEditingController searchController = TextEditingController();

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Déconnexion",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Voulez-vous vraiment vous déconnecter ?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Annuler", style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Auth().logout();
              Navigator.pop(context);
            },
            child: Text("Déconnexion", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        searchQuery = DateFormat('dd/MM/yyyy').format(picked);
        searchController.text = searchQuery;
      });
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Rechercher un projet...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
        suffixIcon: searchType == 'date'
            ? IconButton(
          icon: Icon(Icons.calendar_today, color: Colors.white),
          onPressed: () => _selectDate(context),
        )
            : null,
      ),
      style: TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => setState(() {
        searchQuery = query;
      }),
    );
  }

  List<Widget> _buildSearchActions() {
    return [
      PopupMenuButton<String>(
        icon: Icon(Icons.filter_list),
        onSelected: (String value) {
          setState(() {
            searchType = value;
            searchQuery = '';
            searchController.clear();
            selectedDate = null;
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'statut',
            child: Text('Rechercher par statut'),
          ),
          PopupMenuItem<String>(
            value: 'membre',
            child: Text('Rechercher par membre'),
          ),
          PopupMenuItem<String>(
            value: 'date',
            child: Text('Rechercher par date'),
          ),
        ],
      ),
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          setState(() {
            isSearching = false;
            searchQuery = '';
            searchController.clear();
            selectedDate = null;
          });
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: isSearching ? _buildSearchField() : Text(
            'SunuProjet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blueAccent,
          actions: isSearching
              ? _buildSearchActions()
              : [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, size: 30),
              onPressed: () => _logout(context),
              tooltip: 'Déconnexion',
            ),
          ],
          bottom: TabBar(
            labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: 'En attente'),
              Tab(icon: Icon(Icons.work), text: 'En cours'),
              Tab(icon: Icon(Icons.check_circle), text: 'Terminé'),
              Tab(icon: Icon(Icons.cancel), text: 'Annulé'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            isSearching
                ? ProjectListWithSearch(statut: "En attente", searchQuery: searchQuery, searchType: searchType, selectedDate: selectedDate)
                : ProjectList(statut: "En attente"),
            isSearching
                ? ProjectListWithSearch(statut: "En cours", searchQuery: searchQuery, searchType: searchType, selectedDate: selectedDate)
                : ProjectList(statut: "En cours"),
            isSearching
                ? ProjectListWithSearch(statut: "Terminé", searchQuery: searchQuery, searchType: searchType, selectedDate: selectedDate)
                : ProjectList(statut: "Terminé"),
            isSearching
                ? ProjectListWithSearch(statut: "Annulé", searchQuery: searchQuery, searchType: searchType, selectedDate: selectedDate)
                : ProjectList(statut: "Annulé"),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Get.to(() => CreateProjectPage());
          },
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class ProjectListWithSearch extends StatelessWidget {
  final String statut;
  final String searchQuery;
  final String searchType;
  final DateTime? selectedDate;

  const ProjectListWithSearch({
    Key? key,
    required this.statut,
    required this.searchQuery,
    required this.searchType,
    this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getUserProjects_byStatut(statut),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucun projet trouvé'));
        }

        List<Map<String, dynamic>> projects = snapshot.data!;
        List<Map<String, dynamic>> filteredProjects = _filterProjects(projects);

        if (filteredProjects.isEmpty) {
          return Center(child: Text('Aucun résultat trouvé pour votre recherche'));
        }

        return ListView.builder(
          itemCount: filteredProjects.length,
          padding: EdgeInsets.all(10),
          itemBuilder: (context, index) {
            final project = filteredProjects[index];
            return _buildProjectCard(context, project);
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterProjects(List<Map<String, dynamic>> projects) {
    if (searchQuery.isEmpty) {
      return projects;
    }

    switch (searchType) {
      case 'statut':
        return projects.where((project) {
          return project['statut'].toString().toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();

      case 'membre':
        return projects.where((project) {
          if (project['members'] is List) {
            List members = project['members'];
            return members.any((member) {
              if (member is Map<String, dynamic> && member.containsKey('email')) {
                return member['email'].toString().toLowerCase().contains(searchQuery.toLowerCase());
              }
              return false;
            });
          }
          return false;
        }).toList();

      case 'date':
        return projects.where((project) {
          if (selectedDate != null) {
            if (project.containsKey('startDate') && project['startDate'] is Timestamp) {
              DateTime startDate = (project['startDate'] as Timestamp).toDate();
              DateTime compareDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
              DateTime startOfDay = DateTime(startDate.year, startDate.month, startDate.day);

              if (startOfDay.isAtSameMomentAs(compareDate)) {
                return true;
              }
            }

            if (project.containsKey('endDate') && project['endDate'] is Timestamp) {
              DateTime endDate = (project['endDate'] as Timestamp).toDate();
              DateTime compareDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
              DateTime endOfDay = DateTime(endDate.year, endDate.month, endDate.day);

              if (endOfDay.isAtSameMomentAs(compareDate)) {
                return true;
              }
            }
          }
          return false;
        }).toList();

      default:
        return projects;
    }
  }

  Widget _buildProjectCard(BuildContext context, Map<String, dynamic> project) {
    String title = project['title'] ?? 'Sans titre';
    String description = project['description'] ?? 'Aucune description';
    double progress = (project['progress'] as num?)?.toDouble() ?? 0.0;
    String priority = project['priority'] ?? 'Normal';

    // Formatage des dates
    String startDate = 'Non définie';
    String endDate = 'Non définie';

    if (project.containsKey('startDate') && project['startDate'] is Timestamp) {
      startDate = DateFormat('dd/MM/yyyy').format((project['startDate'] as Timestamp).toDate());
    }

    if (project.containsKey('endDate') && project['endDate'] is Timestamp) {
      endDate = DateFormat('dd/MM/yyyy').format((project['endDate'] as Timestamp).toDate());
    }

    Color priorityColor;
    switch (priority.toLowerCase()) {
      case 'haute':
        priorityColor = Colors.red;
        break;
      case 'moyenne':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          // Navigation vers les détails du projet (à implémenter selon votre architecture)
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Début: $startDate', style: TextStyle(fontSize: 12)),
                  Text('Fin: $endDate', style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 30 ? Colors.red :
                  progress < 70 ? Colors.orange : Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('Progression: ${progress.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              _buildMembersSection(project),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersSection(Map<String, dynamic> project) {
    if (!project.containsKey('members') || project['members'] is! List || (project['members'] as List).isEmpty) {
      return SizedBox.shrink();
    }

    List members = project['members'] as List;

    return Container(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length > 3 ? 4 : members.length,
        itemBuilder: (context, index) {
          if (index < 3) {
            var member = members[index];
            String email = '';
            String role = '';

            if (member is Map<String, dynamic>) {
              email = member['email'] ?? '';
              role = member['role'] ?? '';
            }

            return Tooltip(
              message: '$email ($role)',
              child: Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    email.isNotEmpty ? email[0].toUpperCase() : '?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          } else {
            return Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+${members.length - 3}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}