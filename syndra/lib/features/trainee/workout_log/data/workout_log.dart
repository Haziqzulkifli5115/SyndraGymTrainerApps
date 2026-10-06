import 'package:cloud_firestore/cloud_firestore.dart';

class SetEntry {
  final double weight;
  final int reps;
  final int rpe;
  final bool completed;

  const SetEntry({
    required this.weight,
    required this.reps,
    required this.rpe,
    this.completed = true,
  });

  Map<String, dynamic> toMap() => {
        'weight': weight,
        'reps': reps,
        'rpe': rpe,
        'completed': completed,
      };

  factory SetEntry.fromMap(Map<String, dynamic> m) => SetEntry(
        weight: (m['weight'] as num?)?.toDouble() ?? 0,
        reps: (m['reps'] as num?)?.toInt() ?? 0,
        rpe: (m['rpe'] as num?)?.toInt() ?? 0,
        completed: m['completed'] as bool? ?? true,
      );
}

class ExerciseLog {
  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final List<SetEntry> sets;

  const ExerciseLog({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.sets,
  });

  double get exerciseVolume =>
      sets.fold(0, (acc, s) => acc + (s.weight * s.reps));

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  factory ExerciseLog.fromMap(Map<String, dynamic> m) => ExerciseLog(
        name: m['name'] as String? ?? '',
        targetSets: (m['targetSets'] as num?)?.toInt() ?? 0,
        targetReps: (m['targetReps'] as num?)?.toInt() ?? 0,
        targetWeight: (m['targetWeight'] as num?)?.toDouble() ?? 0,
        sets: (m['sets'] as List<dynamic>? ?? [])
            .map((e) => SetEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

class WorkoutLog {
  final String id;
  final String traineeId;
  final String trainerId;
  final String programId;
  final String programName;
  final DateTime date;
  final String status; // 'pending' | 'approved' | 'rejected'
  final List<ExerciseLog> exercisesLogged;
  final double totalVolume;
  final String? trainerComment;
  final DateTime? createdAt;

  const WorkoutLog({
    required this.id,
    required this.traineeId,
    required this.trainerId,
    required this.programId,
    required this.programName,
    required this.date,
    required this.status,
    required this.exercisesLogged,
    required this.totalVolume,
    this.trainerComment,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'traineeId': traineeId,
        'trainerId': trainerId,
        'programId': programId,
        'programName': programName,
        'date': Timestamp.fromDate(date),
        'status': status,
        'exercisesLogged': exercisesLogged.map((e) => e.toMap()).toList(),
        'totalVolume': totalVolume,
        'trainerComment': trainerComment,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory WorkoutLog.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return WorkoutLog(
      id: doc.id,
      traineeId: m['traineeId'] as String? ?? '',
      trainerId: m['trainerId'] as String? ?? '',
      programId: m['programId'] as String? ?? '',
      programName: m['programName'] as String? ?? '',
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: m['status'] as String? ?? 'pending',
      exercisesLogged: (m['exercisesLogged'] as List<dynamic>? ?? [])
          .map((e) => ExerciseLog.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalVolume: (m['totalVolume'] as num?)?.toDouble() ?? 0,
      trainerComment: m['trainerComment'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}