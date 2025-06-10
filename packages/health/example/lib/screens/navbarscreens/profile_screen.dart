import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For image upload
import 'package:cloud_firestore/cloud_firestore.dart'; // For username storage

class ProfileScreen extends StatefulWidget {
  final String username, email, photoUrl;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.photoUrl,
  });
  @override State<ProfileScreen> createState() => _ProfileScreenState();
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
  String _currentUsername = '';
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _currentUsername = widget.username;
    _currentPhotoUrl = widget.photoUrl;
    _usernameController.text = _currentUsername;
    _emailController.text = widget.email;
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
        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'username': newUsername,
        });

        setState(() {
          _currentUsername = newUsername;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Upload to Firebase Storage
        final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
        await ref.putFile(imageFile);
        final url = await ref.getDownloadURL();

        // Update in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': url,
        });

        setState(() {
          _currentPhotoUrl = url;
          _pickedImage = imageFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_rememberMe) await prefs.clear();
    await _auth.signOut();
    if (_isGoogle) await GoogleSignIn().signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final imageFile = File(file.path);
        await _updateProfilePicture(imageFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Widget _avatar() {
    ImageProvider? img;
    if (_isGoogle && _currentPhotoUrl?.isNotEmpty == true) {
      img = NetworkImage(_currentPhotoUrl!) as ImageProvider;
    } else if (_pickedImage != null) {
      img = FileImage(_pickedImage!) as ImageProvider;
    } else if (_currentPhotoUrl?.isNotEmpty == true) {
      img = NetworkImage(_currentPhotoUrl!) as ImageProvider;
    }

    return GestureDetector(
      onTap: _isGoogle ? null : _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            backgroundImage: img,
            child: img == null
                ? Text(
              _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
            )
                : null,
          ),
          if (!_isGoogle)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: TextStyle(fontSize: 16)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _metricCard(String label, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.3),
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text("${(percent * 100).toInt()}%", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEditProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isGoogle ? null : _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _pickedImage != null
                      ? FileImage(_pickedImage!) as ImageProvider
                      : (_currentPhotoUrl?.isNotEmpty == true
                      ? NetworkImage(_currentPhotoUrl!) as ImageProvider
                      : null),
                  child: _pickedImage == null && (_currentPhotoUrl?.isEmpty ?? true)
                      ? Text(
                    _currentUsername.isNotEmpty ? _currentUsername[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black54),
                  )
                      : null,
                ),
                if (!_isGoogle)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 20, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
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
              Navigator.pop(context);
            },
            child: Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                _avatar(),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentUsername, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Health & Academic Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _metricCard("Stress Level", 0.55, Colors.redAccent),
                        _metricCard("GPA Score", 0.76, Colors.teal),
                        _metricCard("Physical Activity", 0.9, Colors.orange),
                        _metricCard("Social Hours", 0.65, Colors.purple),
                        _metricCard("Sleep Cycle", 0.8, Colors.indigo),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            child: Column(
              children: [
                _menuItem(Icons.edit, "Edit Profile", () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text("Edit Profile")),
                      body: _buildEditProfile(),
                    ),
                  ));
                }),
                const Divider(height: 1),
                _menuItem(Icons.settings, "Settings", () {
                  // Navigate to settings page
                }),
                const Divider(height: 1),
                _menuItem(Icons.credit_card, "Billing Details", () {
                  // Navigate to billing details
                }),
                const Divider(height: 1),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 50),
              ),
              child: const Text("Logout", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }
}