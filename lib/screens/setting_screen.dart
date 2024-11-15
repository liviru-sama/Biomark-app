import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _toggleSubscription(BuildContext context, bool isSubscribed, String? uid) async {
    if (uid == null) return;

    final confirm = await _showConfirmationDialog(
      context,
      "Change Subscription",
      "Are you sure you want to ${isSubscribed ? "enable" : "disable"} your subscription?",
    );
    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'subscriptionStatus': isSubscribed ? 'on' : 'off',
      });
      Provider.of<AuthProvider>(context, listen: false).updateSubscriptionStatus(isSubscribed ? 'on' : 'off');
    } catch (e) {
      print("Failed to update subscription status: $e");
    }
  }

  Future<void> _deactivateAccount(BuildContext context, String? uid) async {
    if (uid == null) return;

    final confirm = await _showConfirmationDialog(
      context,
      "Deactivate Account",
      "Are you sure you want to deactivate your account? This action cannot be undone.",
    );
    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout(context);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Failed to deactivate account: $e");
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.black,
              child: Text(
                user?.fullName.substring(0, 1) ?? "U",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user?.fullName ?? "User",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              title: 'Change Details',
              icon: Icons.edit,
              color: Colors.lightBlueAccent,
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _buildActionCard(
              context,
              title: 'Change Password',
              icon: Icons.lock,
              color: Colors.lightBlueAccent,
              onPressed: () {
                Navigator.pushNamed(context, '/passwordChange');
              },
            ),
            _buildActionCard(
              context,
              title: 'Change Email',
              icon: Icons.email,
              color: Colors.lightBlueAccent,
              onPressed: () {
                Navigator.pushNamed(context, '/emailChange');
              },
            ),
            const SizedBox(height: 15),
            Card(
              color: Colors.lightBlue[50],
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Subscription',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                value: (user?.subscriptionStatus ?? 'off') == 'on',
                activeColor: Colors.black,
                onChanged: (bool value) {
                  _toggleSubscription(context, value, user?.uid);
                },
                secondary: const Icon(Icons.subscriptions, color: Colors.black),
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              ),
            ),
            const SizedBox(height: 15),
            _buildActionCard(
              context,
              title: 'Deactivate Account',
              icon: Icons.delete_forever,
              color: Colors.redAccent,
              onPressed: () {
                _deactivateAccount(context, user?.uid);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.black54,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/profile');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/settings');
          } else if (index == 3) {
            authProvider.logout(context);
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onPressed}) {
    return Card(
      color: Colors.lightBlue[50],
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        onTap: onPressed,
        contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      ),
    );
  }
}
