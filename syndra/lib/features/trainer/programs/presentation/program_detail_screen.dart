import 'package:flutter/material.dart';

import '../data/program.dart';

class ProgramDetailScreen extends StatelessWidget {
  final Program program;
  const ProgramDetailScreen({super.key, required this.program});

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
