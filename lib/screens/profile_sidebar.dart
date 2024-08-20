import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackexp/provider/login_state_provider.dart';
import 'package:trackexp/services/auth.dart';

class ProfileSidebar extends StatelessWidget {
  const ProfileSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<LoginStateProvider>(context).user;

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            if (user != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${user.displayName}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    user.email ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text("Delete Account"),
              onTap: () async {
                final confirmation = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone. Your account will be deleted in 30 days.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmation ?? false) {
                  final authProvider =
                      Provider.of<LoginStateProvider>(context, listen: false);
                  final customUser = authProvider.user;

                  if (customUser != null) {
                    // Use AuthService to schedule account deletion
                    final authService = AuthService();
                    await authService.scheduleAccountDeletion(customUser);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Your account will be deleted in 30 days unless you log in before then.')),
                    );
                    authProvider.logOut();
                    Navigator.pushReplacementNamed(context, '/');
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text("Fetch Backups"),
              onTap: () {
                // Implement fetch backups logic here
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Provider.of<LoginStateProvider>(context, listen: false)
                    .logOut();
                Navigator.pop(context, '/'); // Close the drawer
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}
