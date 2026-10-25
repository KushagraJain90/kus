
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'services/profile_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final user = ProfileService.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: ProfileService.instance.profileChanges(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load your profile.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final document = snapshot.data!;

          if (!document.exists || document.data() == null) {
            return const Center(
              child: Text('Your profile has not been created yet.'),
            );
          }

          final data = document.data()!;
          final name = data['name'] as String? ?? '';
          final degree = data['degree'] as String? ?? '';
          final editUsed = data['profileEditUsed'] == true;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(degree),
                      const SizedBox(height: 12),
                      Text(
                        user.email ?? 'Google account',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: editUsed
                              ? null
                              : () => _editProfile(
                            context,
                            name,
                            degree,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            editUsed
                                ? 'Profile edit already used'
                                : 'Edit profile (one time)',
                          ),
                        ),
                      ),
                      if (editUsed)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Your one permitted profile edit has been used.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Appearance'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.settings_suggest),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (values) {
                          onThemeChanged(values.first);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Sign out'),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editProfile(
      BuildContext context,
      String currentName,
      String currentDegree,
      ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentName);
    final degreeController = TextEditingController(text: currentDegree);
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Edit profile'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name *',
                        ),
                        validator: (value) =>
                        value == null || value.trim().length < 2
                            ? 'Enter a valid name.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: degreeController,
                        decoration: const InputDecoration(
                          labelText: 'Degree / programme *',
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Degree is required.'
                            : null,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setDialogState(() => saving = true);

                      try {
                        await ProfileService.instance
                            .updateProfileOnce(
                          name: nameController.text,
                          degree: degreeController.text,
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated.'),
                            ),
                          );
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not update profile: $error',
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Save changes'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      degreeController.dispose();
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in with Google to access your profile again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await ProfileService.instance.signOut();
    }
  }
}
