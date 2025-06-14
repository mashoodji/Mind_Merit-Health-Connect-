import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:health_example/screens/navbarscreens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_example/utils/colors1.dart';

import '../feature_screen/gpa_screen.dart';
import '../feature_screen/stress_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  bool _isGoogle = false, _rememberMe = false;
  File? _pickedImage;
  final _picker = ImagePicker();
  int _selectedTab = 3;
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  String _currentUsername = 'Loading...';
  String _currentEmail = 'Loading...';
  String? _currentPhotoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPrefs();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _currentUsername = doc.data()?['username'] ?? user.displayName ?? 'No username';
            _currentEmail = user.email ?? 'No email';
            _currentPhotoUrl = doc.data()?['photoUrl'] ?? user.photoURL;
            _usernameController.text = _currentUsername;
            _emailController.text = _currentEmail;
            _isLoading = false;
          });
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            'username': user.displayName ?? 'New User',
            'email': user.email,
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
          _loadUserData();
        }
      }
    } catch (e) {
      setState(() {
        _currentUsername = 'Error loading data';
        _currentEmail = 'Error loading data';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      _isGoogle = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    });
  }

  Future<void> _updateUsername(String newUsername) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await _loadUserData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() => _isLoading = true);
        final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
        await ref.putFile(imageFile);
        final url = await ref.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _loadUserData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await _updateProfilePicture(File(file.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Widget _avatar() {
    ImageProvider? img;
    if (_currentPhotoUrl?.isNotEmpty == true) {
      img = NetworkImage(_currentPhotoUrl!);
    } else if (_pickedImage != null) {
      img = FileImage(_pickedImage!);
    }

    return GestureDetector(
      onTap: _isGoogle ? null : _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.cardBackground,
            backgroundImage: img,
            child: img == null
                ? Text(
              _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.iconSecondary),
            )
                : null,
          ),
          if (!_isGoogle)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: AppColors.accentBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 18, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconPrimary),
      title: Text(title, style: const TextStyle(fontSize: 16, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconInactive),
      onTap: onTap,
    );
  }

  Widget _buildEditProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _avatar(),
          const SizedBox(height: 24),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            enabled: false,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (_usernameController.text.trim().isNotEmpty) {
                await _updateUsername(_usernameController.text.trim());
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: AppColors.textLight,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFromApp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'More from App',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ),
        _menuItem(Icons.school, "GPA Predictor", () {
          Navigator.push(context,
              MaterialPageRoute(builder:
                  (context) => const
                  GPAScreen(sleepHours: 0, activityMinutes: 0, socialHours: 0, averageStudyHours: 0,)));

        }),
        const Divider(height: 1, color: AppColors.divider),
        _menuItem(Icons.self_improvement, "Stress Analyzer", () {
          Navigator.push(context,
              MaterialPageRoute(builder:
                  (context) => const
              StressScreen(sleepHours: 0, activityMinutes: 0, socialHours: 0,)));
        }),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentUsername, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_currentEmail, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: AppColors.cardBackground,
            child: Column(
              children: [
                _menuItem(Icons.edit, "Edit Profile", () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text("Edit Profile"),
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textLight,
                        leading: const BackButton(color: Colors.white),
                      ),
                      body: _buildEditProfile(),
                    ),
                  ));
                }),
                const Divider(height: 1, color: AppColors.divider),
                _menuItem(Icons.settings, "Settings", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
                const Divider(height: 1, color: AppColors.divider),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildMoreFromApp(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: _buildContent(),
    );
  }
}
