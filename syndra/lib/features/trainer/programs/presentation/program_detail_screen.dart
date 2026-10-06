import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/program.dart';
import '../../../trainee/workout_log/presentation/workout_logger_screen.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Program program;
  const ProgramDetailScreen({super.key, required this.program});

  Future<bool> _isTrainee() async {
    // Trainer sees read-only; trainee sees Start Workout button.
    // We detect by checking if the current user has a linked trainer.
    // (Simple heuristic — could be role-based, but this works.)
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    // Trainer created this program
    return program.trainerId != uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(program.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${program.exercises.length} exercise${program.exercises.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          for (final ex in program.exercises) _ExerciseCard(exercise: ex),
          const SizedBox(height: 32),
          FutureBuilder<bool>(
            future: _isTrainee(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WorkoutLoggerScreen(program: program),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${exercise.sets} sets × ${exercise.reps} reps @ ${exercise.targetWeight} kg',
        ),
      ),
    );
  }
}