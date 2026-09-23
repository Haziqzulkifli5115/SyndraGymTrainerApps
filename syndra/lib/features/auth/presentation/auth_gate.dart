import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_provider.dart';
import 'login_screen.dart';
import 'trainer_dashboard.dart';
import 'trainee_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
      data: (user) {
        // Not signed in → Login
        if (user == null) return const LoginScreen();

        // Signed in → wait for profile, then route by role
        final profile = ref.watch(userProfileProvider);
        return profile.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) =>
              Scaffold(body: Center(child: Text('Profile error: $e'))),
          data: (data) {
            if (data == null) {
              // Profile doc missing — sign them out to recover
              return const Scaffold(
                body: Center(child: Text('Profile not found.')),
              );
            }
            final role = data['role'] as String?;
            if (role == 'trainer') return const TrainerDashboard();
            if (role == 'trainee') return const TraineeDashboard();
            return const Scaffold(body: Center(child: Text('Unknown role')));
          },
        );
      },
    );
  }
}
