import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import '../data/user_provider.dart';
import 'link_trainer_screen.dart';

import '../../trainer/programs/data/program.dart';
import '../../trainer/programs/presentation/program_detail_screen.dart';

import '../../trainee/workout_log/data/workout_log.dart';
import '../../trainee/workout_log/data/workout_log_repository.dart';

class TraineeDashboard extends ConsumerWidget {
  const TraineeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainee Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthRepository().signOut(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Profile not found'));
          }
          final name = data['name'] ?? 'Athlete';
          final trainerId = data['trainerId'] as String?;
          final isLinked = trainerId != null;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // ---------- Linked / not-linked banner ----------
              if (!isLinked)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'Not linked to a trainer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your trainer's invite code to see your programs.",
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LinkTrainerScreen(),
                            ),
                          ),
                          child: const Text('Enter code'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Colors.green.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(child: Text('Linked to your trainer')),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ---------- Programs ----------
              const Row(
                children: [
                  Icon(Icons.fitness_center),
                  SizedBox(width: 8),
                  Text(
                    'Your Programs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (!isLinked)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Link to a trainer to see your programs.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ref.watch(traineeTrainerProgramsProvider).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Error loading programs: $e'),
                      data: (programs) {
                        if (programs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              "Your trainer hasn't created any programs yet.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }
                        return Column(
                          children: programs
                              .map((p) => _ProgramCard(program: p))
                              .toList(),
                        );
                      },
                    ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ---------- Recent logs ----------
              const Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text(
                    'Your Recent Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ref.watch(myLogsProvider(uid)).when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error loading logs: $e'),
                    data: (logs) {
                      if (logs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No workouts logged yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return Column(
                        children: logs.map((log) {
                          final color = log.status == 'approved'
                              ? Colors.green
                              : log.status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading:
                                  Icon(Icons.fitness_center, color: color),
                              title: Text(log.programName),
                              subtitle: Text(
                                '${log.date.day}/${log.date.month} · '
                                '${log.status.toUpperCase()}'
                                '${log.trainerComment != null ? ' — "${log.trainerComment}"' : ''}',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ---------- Helpers ----------

class _ProgramCard extends StatelessWidget {
  final Program program;
  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.list_alt),
        title: Text(program.name),
        subtitle: Text(
          '${program.exercises.length} exercise${program.exercises.length == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProgramDetailScreen(program: program),
          ),
        ),
      ),
    );
  }
}

/// Streams this trainee's workout logs.
final myLogsProvider =
    StreamProvider.family<List<WorkoutLog>, String>((ref, traineeId) {
  return WorkoutLogRepository().streamTraineeLogs(traineeId);
});