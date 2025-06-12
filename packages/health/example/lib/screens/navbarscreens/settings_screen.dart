import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/colors1.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../home_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  final int selectedIndex = 3;
  ThemeMode _themeMode = ThemeMode.system;
  final _auth = FirebaseAuth.instance;

  void _onItemTapped(int idx) {
    if (idx != selectedIndex) {
      final pages = [HomeScreen(), ProfileScreen(), NotificationsScreen(), SettingsScreen()];
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => pages[idx]));
    }
  }

  Future<void> _changePassword() async {
    final currentUser = _auth.currentUser;
    if (currentUser?.email == null) return;
    final email = currentUser!.email!;
    await showDialog(context: context, builder: (BuildContext ctx) {
      final oldPwdCtr = TextEditingController();
      final newPwdCtr = TextEditingController();
      return AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Change Password", style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPwdCtr,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextField(
              controller: newPwdCtr,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: AppColors.accentRed)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonPrimary),
            child: const Text("Save", style: TextStyle(color: AppColors.textLight)),
            onPressed: () async {
              try {
                final cred = EmailAuthProvider.credential(email: email, password: oldPwdCtr.text);
                await currentUser.reauthenticateWithCredential(cred);
                await currentUser.updatePassword(newPwdCtr.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password updated successfully")),
                );
                Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: ${e.toString()}")),
                );
              }
            },
          ),
        ],
      );
    });
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: AppColors.accentPurple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: AppColors.textLight)),
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
            else Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(Icons.tune, "Preferences"),
          _settingsCard([
            SwitchListTile(
              activeColor: AppColors.primary,
              title: const Text("Enable Notifications", style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text("Receive alerts and updates", style: TextStyle(color: AppColors.textSecondary)),
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            ListTile(
              leading: const Icon(Icons.color_lens, color: AppColors.iconPrimary),
              title: const Text("App Theme", style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text(_themeMode.name.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary)),
              onTap: () {
                showDialog(context: context, builder: (_) => SimpleDialog(
                  title: const Text("Select Theme", style: TextStyle(color: AppColors.textPrimary)),
                  children: [
                    SimpleDialogOption(
                      child: const Text("Light"),
                      onPressed: () => setState(() { _themeMode = ThemeMode.light; Navigator.pop(context); }),
                    ),
                    SimpleDialogOption(
                      child: const Text("Dark"),
                      onPressed: () => setState(() { _themeMode = ThemeMode.dark; Navigator.pop(context); }),
                    ),
                    SimpleDialogOption(
                      child: const Text("System Default"),
                      onPressed: () => setState(() { _themeMode = ThemeMode.system; Navigator.pop(context); }),
                    ),
                  ],
                ));
              },
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(Icons.lock, "Security"),
          _settingsCard([
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.iconPrimary),
              title: const Text("Change Password", style: TextStyle(color: AppColors.textPrimary)),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.iconPrimary),
              title: const Text("Privacy & Security", style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _showInfoDialog("Privacy & Security", '''
We prioritize your data privacy and use end-to-end encryption for all user interactions. 
Your personal information is never shared with third parties without your consent. 
Security features include password encryption, secure login, and regular vulnerability assessments.'''),
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader(Icons.info_outline, "App Info"),
          _settingsCard([
            ListTile(
              leading: const Icon(Icons.description, color: AppColors.iconPrimary),
              title: const Text("Terms & Conditions", style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _showInfoDialog("Terms & Conditions", '''
By using this app, you agree to our guidelines on fair usage, academic integrity, and privacy. 
Unauthorized use, copying of content, or tampering with data is prohibited. 
We reserve the right to suspend accounts violating these terms.'''),
            ),
            ListTile(
              leading: const Icon(Icons.policy, color: AppColors.iconPrimary),
              title: const Text("Privacy Policy", style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _showInfoDialog("Privacy Policy", '''
We collect minimal data necessary for account management and performance tracking. 
This includes email, login activity, and academic analytics. 
You can request data deletion or export by contacting support.'''),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.iconPrimary),
              title: const Text("Help & Support", style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => _showInfoDialog("Help & Support", '''
Need assistance? Contact our support team at:
📧 support@studentapp.com
☎️ +1 800 123 4567
We’re available Mon–Fri, 9 AM to 6 PM.'''),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: AppColors.iconPrimary),
              title: const Text("About App", style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: "Student Prediction App",
                applicationVersion: "1.0.0",
                applicationIcon: const Icon(Icons.school, color: AppColors.primary),
                children: const [
                  Text(
                    "This app helps parents and teachers monitor academic performance, "
                        "predict student outcomes, and improve communication for better results.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.textLight),
              label: const Text("Logout", style: TextStyle(color: AppColors.textLight)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        ],
      ),
      // bottomNavigationBar: BottomNavBar(currentIndex: selectedIndex, onTap: _onItemTapped),
    );
  }

  Widget _sectionHeader(IconData icon, String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    ),
  );

  Widget _settingsCard(List<Widget> items) => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: AppColors.cardBackground,
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: items.map((widget) => widget).toList(),
    ),
  );
}
