import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/invite_code.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    final data = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Trainer gets a unique invite code at signup.
    if (role == 'trainer') {
      data['inviteCode'] = InviteCode.generate();
    }

    // Trainee has trainerId = null until they link.
    if (role == 'trainee') {
      data['trainerId'] = null;
    }

    await _firestore.collection('users').doc(uid).set(data);
    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Trainer: find the trainee-visible info for a given invite code.
  Future<Map<String, dynamic>?> findTrainerByCode(String code) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'trainer')
        .where('inviteCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return {'uid': snapshot.docs.first.id, ...snapshot.docs.first.data()};
  }

  /// Trainee: link to trainer.
  Future<void> linkTraineeToTrainer({
    required String traineeId,
    required String trainerId,
  }) async {
    await _firestore.collection('users').doc(traineeId).update({
      'trainerId': trainerId,
    });
  }

  /// Trainee: unlink from trainer.
  Future<void> unlinkTrainee(String traineeId) async {
    await _firestore.collection('users').doc(traineeId).update({
      'trainerId': null,
    });
  }
}