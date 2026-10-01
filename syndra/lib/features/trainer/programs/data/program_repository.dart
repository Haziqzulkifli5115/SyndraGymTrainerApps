import 'package:cloud_firestore/cloud_firestore.dart';
import 'program.dart';

class ProgramRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createProgram(Program program) async {
    final ref = await _firestore.collection('programs').add(program.toMap());
    return ref.id;
  }

  /// Stream all programs for a trainer, sorted newest-first in Dart.
  Stream<List<Program>> streamTrainerPrograms(String trainerId) {
    return _firestore
        .collection('programs')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Program.fromDoc).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad); // newest first
      });
      return list;
    });
  }

  Future<void> deleteProgram(String programId) async {
    await _firestore.collection('programs').doc(programId).delete();
  }
}