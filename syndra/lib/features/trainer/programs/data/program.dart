import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double targetWeight;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.targetWeight,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'targetWeight': targetWeight,
      };

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
        name: m['name'] as String? ?? '',
        sets: (m['sets'] as num?)?.toInt() ?? 0,
        reps: (m['reps'] as num?)?.toInt() ?? 0,
        targetWeight: (m['targetWeight'] as num?)?.toDouble() ?? 0,
      );
}

class Program {
  final String id;
  final String trainerId;
  final String name;
  final List<Exercise> exercises;
  final DateTime? createdAt;

  const Program({
    required this.id,
    required this.trainerId,
    required this.name,
    required this.exercises,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'trainerId': trainerId,
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Program.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Program(
      id: doc.id,
      trainerId: m['trainerId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      exercises: (m['exercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}