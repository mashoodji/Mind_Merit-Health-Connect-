import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:health_example/screens/auth/login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('saved_username') ?? '';
      _emailController.text = prefs.getString('saved_email') ?? '';
      _passwordController.text = prefs.getString('saved_password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveCredentials(
      String username, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.clear();
    }
  }

  Future<void> _signUp() async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("All fields are required!");
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "username": username,
        "email": email,
        "created_at": DateTime.now(),
      });

      if (_rememberMe) {
        await _saveCredentials(username, email, password);
      }

      _showSnackBar("Account created successfully!", success: true);
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "username": user.displayName ?? "",
          "email": user.email ?? "",
          "photo_url": user.photoURL ?? "",
          "created_at": DateTime.now(),
        }, SetOptions(merge: true));

        if (_rememberMe) {
          await _saveCredentials(user.displayName ?? "", user.email ?? "", "");
        }
      }

      _showSnackBar("Google Sign-In Successful!", success: true);
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    } catch (e) {
      _showSnackBar("Google Sign-In failed: ${e.toString()}");
    }
  }

  void _showSnackBar(String message, {bool success = false}) {
    final snackBar = SnackBar(
      content: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: success ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _navigateToLogin() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Center(
                child:
                    Lottie.asset('assets/animations/signup.json', height: 450),
              ),
              SizedBox(height: 0),
              Text(
                "Register",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 5),
              Text(
                "Create an account to get started.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 15),

              SizedBox(height: 15),
              // User_Name Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "User-Name",
                  prefixIcon: Icon(Icons.person, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your User-Name" : null,
              ),

              SizedBox(height: 15),
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: Icon(Icons.email, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your email" : null,
              ),
              SizedBox(height: 15),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _obscureText ? Colors.grey : Colors.blueAccent,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter password" : null,
              ),
              // SizedBox(height: 10),
              //
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text("Remember Me", style: TextStyle(fontSize: 14)),
              //     Switch(
              //       value: _rememberMe,
              //       onChanged: (value) {
              //         setState(() {
              //           _rememberMe = value;
              //         });
              //       },
              //       activeColor: Colors.blueAccent,
              //     ),
              //   ],
              // ),
              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

              SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon:
                      Image.asset('assets/images/google_icon.png', height: 24),
                  label: Text("Sign Up with Google",
                      style: TextStyle(fontSize: 16, color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account?"),
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text("Sign In",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hintText, IconData icon, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
