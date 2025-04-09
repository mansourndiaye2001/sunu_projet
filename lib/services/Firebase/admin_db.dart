
import 'package:cloud_firestore/cloud_firestore.dart';

Future<int> getTotalUsers() async {
try {

QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
return snapshot.size;
} catch (e) {
print('Erreur lors de la récupération des utilisateurs: $e');
return 0;
}
}
Future<int> getTotalProjetByStatut(String statut) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('statut', isEqualTo: statut)
        .get();
    return snapshot.size;
  } catch (e) {
    print('Erreur lors de la récupération des projets: $e');
    return 0;
  }
}
Future<int> getTotalUserisblocked(bool isblocked) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('isBlocked', isEqualTo: isblocked)
      .where('role',isEqualTo: 2)


        .get();
    return snapshot.size;
  } catch (e) {
    print('Erreur lors de la récupération : $e');
    return 0;
  }
}

Stream<List<Map<String, dynamic>>> getUsersStream() {
  try {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 2)
        .snapshots()
        .map((snapshot) {

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  } catch (e) {
    print('Erreur lors de la récupération des utilisateurs en stream: $e');
    return Stream.value([]);
  }
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



