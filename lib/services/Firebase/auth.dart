import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Auth{

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get CurrentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  //LOGIN WITH EMAIL-PASSWORD
Future<void> loginWithEmailAndPassword (String email , String password ) async{
  await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
}
Future<void>logout()async{
  await _firebaseAuth.signOut();
}
  Future<void> createUserWithEmailAndPassword(String email , String password, String nom) async{
    UserCredential userCredential = await  _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    String uid = userCredential.user!.uid;
    await FirebaseFirestore.instance.collection("user").doc(

    ).set({
      "id":uid,
      "nom":nom,
      "email":email,
      "status":'Actif',
      "projets":[]

    }


    );





}


}