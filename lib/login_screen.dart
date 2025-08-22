import 'package:fish_farm_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fish_farm_app/screens/registration_screen.dart'; // Import the registration screen
// Import the AuthWrapper for navigation after login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Create an instance of Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to show a message to the user
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Main login function
  void _loginUser() async {
    try {
      // Show loading indicator
      _showSnackBar('Logging in...', isError: false);

      // Attempt to sign in with email and password
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // If successful, show a success message
      _showSnackBar('Login successful!', isError: false);

      // Navigate to the AuthWrapper which will handle routing to the correct dashboard
      // We use pushReplacement to prevent the user from going back to the login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AuthWrapper() as Widget),
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      _showSnackBar(e.message ?? 'An unknown error occurred.', isError: true);
    } catch (e) {
      // Handle other general errors
      _showSnackBar(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loginUser, // Call the new login function
              child: const Text('Login'),
            ),
            const SizedBox(height: 16), // Added a new SizedBox for spacing
            TextButton(
              onPressed: () {
                // Navigate to the registration screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
