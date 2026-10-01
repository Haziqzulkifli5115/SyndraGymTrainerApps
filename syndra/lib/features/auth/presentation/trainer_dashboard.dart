import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_repository.dart';
import '../data/user_provider.dart';
import '../../../core/utils/invite_code.dart';
import '../../trainer/programs/data/program.dart';
import '../../trainer/programs/data/program_repository.dart';
import '../../trainer/programs/presentation/program_builder_screen.dart';

class TrainerDashboard extends ConsumerWidget {
  const TrainerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Dashboard'),
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

          // Backfill: trainer from before the invite-code feature.
          if (data['inviteCode'] == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final newCode = InviteCode.generate();
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .update({'inviteCode': newCode});
            });
          }

          final name = data['name'] ?? 'Coach';
          final code = data['inviteCode'] ?? '—';
          final traineesAsync = ref.watch(trainerTraineesProvider);
          final trainerId = FirebaseAuth.instance.currentUser!.uid;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Share this code with your trainees so they can link to you.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // Invite code card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'YOUR INVITE CODE',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        code,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Trainees section
              Row(
                children: [
                  const Icon(Icons.people_outline),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Trainees',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  traineesAsync.maybeWhen(
                    data: (list) => Text(
                      '${list.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              traineesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading trainees: $e'),
                ),
                data: (trainees) {
                  if (trainees.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No trainees linked yet. Share your code above.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return Column(
                    children: trainees
                        .map((t) => _TraineeCard(trainee: t))
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // Programs section
              Row(
                children: [
                  const Icon(Icons.fitness_center),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Programs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProgramBuilderScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ref.watch(programsProvider(trainerId)).when(
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
                            'No programs yet. Tap "New" to create one.',
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
            ],
          );
        },
      ),
    );
  }
}

class _TraineeCard extends StatelessWidget {
  final Map<String, dynamic> trainee;
  const _TraineeCard({required this.trainee});

  @override
  Widget build(BuildContext context) {
    final name = trainee['name'] ?? 'Unnamed';
    final email = trainee['email'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            name.toString().isNotEmpty
                ? name.toString()[0].toUpperCase()
                : '?',
          ),
        ),
        title: Text(name),
        subtitle: Text(email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trainee profile: $name (coming soon)')),
          );
        },
      ),
    );
  }
}

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
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete program?'),
                content: Text('Delete "${program.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ProgramRepository().deleteProgram(program.id);
            }
          },
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Program details: ${program.name}')),
          );
        },
      ),
    );
  }
}

/// Streams the trainer's programs.
final programsProvider =
    StreamProvider.family<List<Program>, String>((ref, trainerId) {
  return ProgramRepository().streamTrainerPrograms(trainerId);
});