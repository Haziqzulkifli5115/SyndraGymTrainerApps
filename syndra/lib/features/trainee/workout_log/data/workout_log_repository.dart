import 'package:cloud_firestore/cloud_firestore.dart';

import 'workout_log.dart';

class WorkoutLogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> submitLog(WorkoutLog log) async {
    final ref = await _firestore.collection('workoutLogs').add(log.toMap());
    return ref.id;
  }

  /// Trainee's own logs, newest first (sorted client-side).
  Stream<List<WorkoutLog>> streamTraineeLogs(String traineeId) {
    return _firestore
        .collection('workoutLogs')
        .where('traineeId', isEqualTo: traineeId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(WorkoutLog.fromDoc).toList();
          list.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return list;
        });
  }

  /// Trainer's pending logs from all their trainees, newest first.
  Stream<List<WorkoutLog>> streamPendingLogsForTrainer(String trainerId) {
    return _firestore
        .collection('workoutLogs')
        .where('trainerId', isEqualTo: trainerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(WorkoutLog.fromDoc).toList();
          list.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return list;
        });
  }

  /// All logs belonging to a trainer (any status).
  Stream<List<WorkoutLog>> streamAllLogsForTrainer(String trainerId) {
    return _firestore
        .collection('workoutLogs')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(WorkoutLog.fromDoc).toList();
          list.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return list;
        });
  }

  Future<void> approveLog(String logId, {String? comment}) async {
    await _firestore.collection('workoutLogs').doc(logId).update({
      'status': 'approved',
      'trainerComment': comment,
    });
  }

  Future<void> rejectLog(String logId, {String? comment}) async {
    await _firestore.collection('workoutLogs').doc(logId).update({
      'status': 'rejected',
      'trainerComment': comment,
    });
  }
}
