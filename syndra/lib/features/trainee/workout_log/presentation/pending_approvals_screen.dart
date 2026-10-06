import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/workout_log.dart';
import '../data/workout_log_repository.dart';


class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final pendingAsync = ref.watch(_pendingProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approvals')),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Text('No pending logs. All caught up!'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return _LogApprovalCard(log: log);
            },
          );
        },
      ),
    );
  }
}

final _pendingProvider =
    StreamProvider.family<List<WorkoutLog>, String>((ref, trainerId) {
  return WorkoutLogRepository().streamPendingLogsForTrainer(trainerId);
});

class _LogApprovalCard extends ConsumerStatefulWidget {
  final WorkoutLog log;
  const _LogApprovalCard({required this.log});

  @override
  ConsumerState<_LogApprovalCard> createState() => _LogApprovalCardState();
}

class _LogApprovalCardState extends ConsumerState<_LogApprovalCard> {
  final _commentCtrl = TextEditingController();
  bool _busy = false;

  Future<void> _decide({required bool approve}) async {
    setState(() => _busy = true);
    try {
      final repo = WorkoutLogRepository();
      final comment =
          _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim();
      if (approve) {
        await repo.approveLog(widget.log.id, comment: comment);
      } else {
        await repo.rejectLog(widget.log.id, comment: comment);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? 'Approved' : 'Rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.programName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${log.date.day}/${log.date.month}/${log.date.year} — Volume: ${log.totalVolume.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final ex in log.exercisesLogged)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ex.sets
                          .map((s) =>
                              '${s.weight.toStringAsFixed(0)}kg×${s.reps} @RPE${s.rpe}')
                          .join('  •  '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _decide(approve: false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _decide(approve: true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
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