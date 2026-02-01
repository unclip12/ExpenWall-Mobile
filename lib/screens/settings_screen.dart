import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            }
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
