import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../trainer/programs/data/program.dart';
import '../data/workout_log.dart';
import '../data/workout_log_repository.dart';

class WorkoutLoggerScreen extends StatefulWidget {
  final Program program;
  const WorkoutLoggerScreen({super.key, required this.program});

  @override
  State<WorkoutLoggerScreen> createState() => _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends State<WorkoutLoggerScreen> {
  final _repo = WorkoutLogRepository();
  final _authRepo = AuthRepository();
  late final List<_ExerciseLogDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.program.exercises
        .map((ex) => _ExerciseLogDraft.fromExercise(ex))
        .toList();
  }

  double get _totalVolume =>
      _drafts.fold(0, (sum, d) => sum + d.volume);

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final profile = await _authRepo.getUserProfile(uid);
      final trainerId = profile?['trainerId'] as String?;

      if (trainerId == null) {
        _snack('No trainer linked.');
        return;
      }

      final exercisesLogged = _drafts
          .map((d) => d.toExerciseLog())
          .where((e) => e.sets.isNotEmpty)
          .toList();

      if (exercisesLogged.isEmpty) {
        _snack('Log at least one set.');
        return;
      }

      final totalVolume = exercisesLogged.fold<double>(
          0, (sum, e) => sum + e.exerciseVolume);

      await _repo.submitLog(WorkoutLog(
        id: '',
        traineeId: uid,
        trainerId: trainerId,
        programId: widget.program.id,
        programName: widget.program.name,
        date: DateTime.now(),
        status: 'pending',
        exercisesLogged: exercisesLogged,
        totalVolume: totalVolume,
      ));

      if (!mounted) return;
      _snack('Workout submitted for review');
      Navigator.of(context).pop();
    } catch (e) {
      _snack('Submit failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade50,
            child: Text(
              'Total volume: ${_totalVolume.toStringAsFixed(0)} kg',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (int i = 0; i < _drafts.length; i++)
                  _ExerciseLogCard(
                    draft: _drafts[i],
                    onChanged: () => setState(() {}),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseLogDraft {
  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final List<_SetDraft> sets;

  _ExerciseLogDraft({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.sets,
  });

  factory _ExerciseLogDraft.fromExercise(Exercise ex) {
    return _ExerciseLogDraft(
      name: ex.name,
      targetSets: ex.sets,
      targetReps: ex.reps,
      targetWeight: ex.targetWeight,
      sets: List.generate(
        ex.sets,
        (_) => _SetDraft(
          weight: ex.targetWeight.toStringAsFixed(0),
          reps: ex.reps.toString(),
        ),
      ),
    );
  }

  double get volume => sets.fold(
        0,
        (sum, s) =>
            sum +
            ((double.tryParse(s.weightCtrl.text) ?? 0) *
                (int.tryParse(s.repsCtrl.text) ?? 0)),
      );

  ExerciseLog toExerciseLog() {
    return ExerciseLog(
      name: name,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      sets: sets.map((s) => s.toSetEntry()).toList(),
    );
  }

  void dispose() {
    for (final s in sets) {
      s.dispose();
    }
  }
}

class _SetDraft {
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;
  final TextEditingController rpeCtrl;


  _SetDraft({String weight = '0', String reps = '0'})
      : weightCtrl = TextEditingController(text: weight),
        repsCtrl = TextEditingController(text: reps),
        rpeCtrl = TextEditingController(text: '7');

  SetEntry toSetEntry() => SetEntry(
        weight: double.tryParse(weightCtrl.text) ?? 0,
        reps: int.tryParse(repsCtrl.text) ?? 0,
        rpe: int.tryParse(rpeCtrl.text) ?? 0,
      );

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
    rpeCtrl.dispose();
  }
}

class _ExerciseLogCard extends StatelessWidget {
  final _ExerciseLogDraft draft;
  final VoidCallback onChanged;

  const _ExerciseLogCard({required this.draft, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              draft.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: ${draft.targetSets} × ${draft.targetReps} @ ${draft.targetWeight.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('Set',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('kg',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('reps',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text('RPE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (int i = 0; i < draft.sets.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: draft.sets[i].weightCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => onChanged(),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: draft.sets[i].repsCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => onChanged(),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: draft.sets[i].rpeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}