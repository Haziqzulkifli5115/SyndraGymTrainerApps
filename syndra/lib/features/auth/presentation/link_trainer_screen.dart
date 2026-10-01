import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';

class LinkTrainerScreen extends StatefulWidget {
  const LinkTrainerScreen({super.key});

  @override
  State<LinkTrainerScreen> createState() => _LinkTrainerScreenState();
}

class _LinkTrainerScreenState extends State<LinkTrainerScreen> {
  final _codeCtrl = TextEditingController();
  final _repo = AuthRepository();
  bool _loading = false;

  Future<void> _link() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final trainer = await _repo.findTrainerByCode(code);
      if (trainer == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No trainer found with that code')),
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _repo.linkTraineeToTrainer(
        traineeId: uid,
        trainerId: trainer['uid'] as String,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Linked to ${trainer['name']}')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link to Trainer')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the invite code your trainer shared with you.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'SYN-XXXXX',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _link,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Link'),
            ),
          ],
        ),
      ),
    );
  }
}