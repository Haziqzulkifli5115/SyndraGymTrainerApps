import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/user_provider.dart';
import 'link_trainer_screen.dart';
import '../../trainer/programs/data/program.dart';
import '../../trainer/programs/presentation/program_detail_screen.dart';

class TraineeDashboard extends ConsumerWidget {
  const TraineeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

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

              // Not-linked banner
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

              // Programs section
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

              const Text(
                "Today's workout",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming next: log your sets, reps, and weight.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
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