import 'package:flutter/material.dart';
import '../services/Firebase/admin_db.dart';
import '../services/Firebase/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Admin extends StatefulWidget {
  const Admin({Key? key}) : super(key: key);

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  int totalUsers = 0;
  int activeUsers = 0;
  int inactiveUsers = 0;
  int totalProjetEnAttente = 0;
  int totalProjetEnCours = 0;
  int totalProjetTermine = 0;
  int totalProjetAnnule = 0;

  Map<String, int> projectStats = {
    'En attente': 0,
    'En cours': 0,
    'Terminé': 0,
    'Annulé': 0,
  };

  int _currentIndex = 0;
  final List<String> _tabTitles = ['Tableau de bord', 'Utilisateurs'];

  @override
  void initState() {
    super.initState();
    // Les anciennes méthodes ne sont plus nécessaires car nous utilisons maintenant des StreamBuilder
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Déconnexion"),
        content: Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Annuler"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_currentIndex]),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildDashboard(context)
          : _buildUsersList(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
        ],
      ),
    );
  }

  // Widget pour afficher les statistiques du tableau de bord
  Widget _buildDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques des utilisateurs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<int>(
            stream: getUsersCountStream(),
            builder: (context, snapshot) {
              int totalUsers = snapshot.data ?? 0;
              return Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Total',
                      count: totalUsers,
                      color: Colors.blue,
                      icon: Icons.people,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<int>(
                    stream: getUsersBlockedStream(true),
                    builder: (context, snapshot) {
                      int activeUsers = snapshot.data ?? 0;
                      return Expanded(
                        child: _buildStatusCard(
                          title: 'Actifs',
                          count: activeUsers,
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  StreamBuilder<int>(
                    stream: getUsersBlockedStream(false),
                    builder: (context, snapshot) {
                      int inactiveUsers = snapshot.data ?? 0;
                      return Expanded(
                        child: _buildStatusCard(
                          title: 'Inactifs',
                          count: inactiveUsers,
                          color: Colors.red,
                          icon: Icons.cancel,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Statistiques des projets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StreamBuilder<int>(
                stream: getProjetByStatutStream('En attente'),
                builder: (context, snapshot) {
                  int count = snapshot.data ?? 0;
                  return _buildStatusCard(
                    title: 'En attente',
                    count: count,
                    color: Colors.orange,
                    icon: Icons.hourglass_empty,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: getProjetByStatutStream('En cours'),
                builder: (context, snapshot) {
                  int count = snapshot.data ?? 0;
                  return _buildStatusCard(
                    title: 'En cours',
                    count: count,
                    color: Colors.blue,
                    icon: Icons.play_circle,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: getProjetByStatutStream('Terminé'),
                builder: (context, snapshot) {
                  int count = snapshot.data ?? 0;
                  return _buildStatusCard(
                    title: 'Terminé',
                    count: count,
                    color: Colors.green,
                    icon: Icons.check_circle,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: getProjetByStatutStream('Annulé'),
                builder: (context, snapshot) {
                  int count = snapshot.data ?? 0;
                  return _buildStatusCard(
                    title: 'Annulé',
                    count: count,
                    color: Colors.red,
                    icon: Icons.cancel,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Aucun utilisateur trouvé'));
        }

        List<Map<String, dynamic>> users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            bool isBlocked = user['isBlocked'] ?? false;
            String userId = user['id'] ?? '';

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: user['imageUrl'] != null
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(user['imageUrl']),
                  radius: 30,
                )
                    : CircleAvatar(
                  child: Icon(Icons.person),
                  radius: 30,
                ),
                title: Text('${user['nom']}'),
                subtitle: Text(user['email'] ?? 'Email non disponible'),
                trailing: IconButton(
                  icon: Icon(
                    isBlocked ? Icons.block : Icons.lock_open,
                    color: isBlocked ? Colors.red : Colors.green,
                  ),
                  onPressed: () {
                    toggleBlockStatus(userId, isBlocked);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Fichier admin_db.dart - Fonctions de service modifiées pour utiliser des streams

Stream<int> getUsersCountStream() {
  return FirebaseFirestore.instance.collection('users').snapshots().map((snapshot) => snapshot.size);
}

Stream<int> getUsersBlockedStream(bool isBlocked) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isBlocked', isEqualTo: isBlocked)
      .where('role', isEqualTo: 2)
      .snapshots()
      .map((snapshot) => snapshot.size);
}

Stream<int> getProjetByStatutStream(String statut) {
  return FirebaseFirestore.instance
      .collection('projects')
      .where('statut', isEqualTo: statut)
      .snapshots()
      .map((snapshot) => snapshot.size);
}

Stream<List<Map<String, dynamic>>> getUsersStream() {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 2)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      // Ajout de l'ID dans les données pour faciliter l'utilisation
      data['id'] = doc.id;
      return data;
    }).toList();
  });
}

Future<void> toggleBlockStatus(String userId, bool isBlocked) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBlocked': !isBlocked,
    });
  } catch (e) {
    print('Erreur lors de la mise à jour du statut de blocage: $e');
  }
}