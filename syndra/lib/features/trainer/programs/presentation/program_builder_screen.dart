import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/program.dart';
import '../data/program_repository.dart';

class ProgramBuilderScreen extends StatefulWidget {
  const ProgramBuilderScreen({super.key});

  @override
  State<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends State<ProgramBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final _repo = ProgramRepository();
  final _exercises = <ExerciseDraft>[];
  bool _saving = false;

  void _addExercise() => setState(() => _exercises.add(ExerciseDraft()));

  void _removeExercise(int index) => setState(() => _exercises.removeAt(index));

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnack('Enter a program name');
      return;
    }
    if (_exercises.isEmpty) {
      _showSnack('Add at least one exercise');
      return;
    }

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final exercises = _exercises
          .map((d) => d.toExercise())
          .whereType<Exercise>()
          .toList();

      await _repo.createProgram(Program(
        id: '',
        trainerId: uid,
        name: name,
        exercises: exercises,
      ));

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Program saved');
    } catch (e) {
      _showSnack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Program'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Program name',
              hintText: 'e.g. Push Day A',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text(
                'Exercises',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No exercises yet. Tap "Add" to start.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          for (int i = 0; i < _exercises.length; i++)
            _ExerciseRow(
              key: ValueKey(i),
              draft: _exercises[i],
              index: i,
              onRemove: () => _removeExercise(i),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class ExerciseDraft {
  final nameCtrl = TextEditingController();
  final setsCtrl = TextEditingController(text: '3');
  final repsCtrl = TextEditingController(text: '8');
  final weightCtrl = TextEditingController(text: '0');

  Exercise? toExercise() {
    if (nameCtrl.text.trim().isEmpty) return null;
    return Exercise(
      name: nameCtrl.text.trim(),
      sets: int.tryParse(setsCtrl.text) ?? 3,
      reps: int.tryParse(repsCtrl.text) ?? 8,
      targetWeight: double.tryParse(weightCtrl.text) ?? 0,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    setsCtrl.dispose();
    repsCtrl.dispose();
    weightCtrl.dispose();
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseDraft draft;
  final int index;
  final VoidCallback onRemove;

  const _ExerciseRow({
    super.key,
    required this.draft,
    required this.index,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Exercise ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            TextField(
              controller: draft.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Bench Press',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: draft.setsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: draft.repsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: draft.weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'kg',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}