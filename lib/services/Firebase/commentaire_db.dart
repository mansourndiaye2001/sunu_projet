import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<bool> ajouterCommentaire({
    required String idTache,
    required String texteCommentaire,
    required BuildContext context,
  }) async {
    try {
      final User? utilisateurActuel = FirebaseAuth.instance.currentUser;
      if (utilisateurActuel == null) {
        _afficherSnackBar(context, "Vous devez être connecté pour commenter", Colors.red);
        return false;
      }


      if (texteCommentaire.trim().isEmpty) {
        _afficherSnackBar(context, "Le commentaire ne peut pas être vide", Colors.orange);
        return false;
      }

      DocumentSnapshot instantUtilisateur = await _db
          .collection('users')
          .doc(utilisateurActuel!.uid)
          .get();

      Map<String, dynamic> donneesUtilisateur = instantUtilisateur.data() as Map<String, dynamic>;

      await _db.collection('commentaires_taches').add({
        'idTache': idTache,
        'idUtilisateur': utilisateurActuel!.uid,
        'nomUtilisateur': donneesUtilisateur['nom'] ?? 'Utilisateur',
        'emailUtilisateur': utilisateurActuel!.email,
        'imageUtilisateur': donneesUtilisateur['imageUrl'] ?? '',
        'texte': texteCommentaire.trim(),
        'horodatage': FieldValue.serverTimestamp(),

      });

      _afficherSnackBar(context, "Commentaire ajouté avec succès", Colors.green);
      return true;
    } catch (e) {
      print("Erreur lors de l'ajout du commentaire : $e");
      _afficherSnackBar(context, "Erreur lors de l'ajout du commentaire", Colors.red);
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> obtenirCommentairesTache(String idTache) {
    return _db
        .collection('commentaires_taches')
        .where('idTache', isEqualTo: idTache)
        .orderBy('horodatage', descending: true)
        .snapshots()
        .map((instantInstantane) => instantInstantane.docs
        .map((doc) => {
      'id': doc.id,
      ...doc.data(),
    })
        .toList());
  }

  void _afficherSnackBar(BuildContext context, String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: couleur,
        duration: Duration(seconds: 3),
      ),
    );
  }
