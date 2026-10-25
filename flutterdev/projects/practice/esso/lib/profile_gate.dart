
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_setup_page.dart';
import 'sign_in_page.dart';
import 'services/profile_service.dart';

class ProfileGate extends StatelessWidget {
  const ProfileGate({
    super.key,
    required this.authenticatedHome,
  });

  final Widget authenticatedHome;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: ProfileService.instance.authChanges,
      initialData: ProfileService.instance.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            !authSnapshot.hasData) {
          return const _GateLoading();
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const SignInPage();
        }

        return StreamBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          key: ValueKey(user.uid),
          stream: ProfileService.instance.profileChanges(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _GateError(
                message: 'Could not load your profile. '
                    'Check your internet connection and database rules.',
                authenticatedHome: authenticatedHome,
              );
            }

            if (!profileSnapshot.hasData) {
              return const _GateLoading();
            }

            final document = profileSnapshot.data!;

            if (!document.exists) {
              return const ProfileSetupPage();
            }

            final data = document.data();

            if (data == null ||
                data['name'] is! String ||
                (data['name'] as String).trim().isEmpty ||
                data['degree'] is! String ||
                (data['degree'] as String).trim().isEmpty) {
              return const ProfileSetupPage();
            }

            return authenticatedHome;
          },
        );
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


class _GateError extends StatelessWidget {
  const _GateError({
    required this.message,
    required this.authenticatedHome,
  });

  final String message;
  final Widget authenticatedHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => ProfileGate(
                        authenticatedHome: authenticatedHome,
                      ),
                    ),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
