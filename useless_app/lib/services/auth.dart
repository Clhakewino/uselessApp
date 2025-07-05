import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:useless_app/pigeon/user_details.g.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> createUserWithEmailAndPassword({required String email, required String password, required String username}) async {
    try {
      bool usernameIsTaken = await isUsernameTaken(username);
      if (!usernameIsTaken) {
        final cred = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
        // Salva username su Firestore
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': username,
          'email': email,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to create User: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> saveCounterToFirestore(int counter) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'counter': counter,
      },
      SetOptions(merge: true),
    );
  }

  Future<int?> getCounterFromFirestore() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null && doc.data()!.containsKey('counter')) {
      return doc['counter'] as int;
    }
    return null;
  }

  Future<bool> isUsernameTaken(String proposedUsername) async {
    if (proposedUsername.isEmpty) {
      return false;
    }

    try {
      final query = FirebaseFirestore.instance.collection('users')
          .where('name', isEqualTo: proposedUsername.trim())
          .limit(1);
      final QuerySnapshot querySnapshot = await query.get();
      if (querySnapshot.docs.isNotEmpty) {
        print('Nome utente "$proposedUsername" già in uso.');
        return true;
      } else {
        print('Nome utente "$proposedUsername" disponibile.');
        return false;
      }
    } catch (e) {
      print('Errore durante la verifica del nome utente: $e');
      return true;
    }
  }
}