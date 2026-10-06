import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trainer/programs/data/program.dart';
import '../../trainer/programs/data/program_repository.dart';

/// Streams the current Firebase Auth user (null when signed out).
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Streams the user's Firestore profile document (contains `role`).
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.data());
});

/// Streams the list of trainees linked to the current trainer.
final trainerTraineesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(const []);

  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'trainee')
      .where('trainerId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
});

/// Streams the programs of the trainee's linked trainer.
final traineeTrainerProgramsProvider =
    StreamProvider<List<Program>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final trainerId = profile?['trainerId'] as String?;
  if (trainerId == null) return Stream.value(const []);

  return ProgramRepository().streamTrainerPrograms(trainerId);
});