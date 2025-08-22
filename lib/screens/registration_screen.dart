import 'package:fish_farm_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPhoneRegistration =
      false; // To toggle between email/phone registration
  String? _verificationId; // Stores the ID received after sending OTP

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- Email/Password Registration Function ---
  void _registerWithEmailPassword() async {
    try {
      _showSnackBar('Registering with email...', isError: false);

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      String? uid = userCredential.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'role': 'farmer',
          'farmId': null,
          'createdAt': Timestamp.now(),
        });
        _showSnackBar('Registration successful!', isError: false);
        _navigateToAuthWrapper();
      } else {
        _showSnackBar(
          'Registration failed: User UID not found.',
          isError: true,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'An unknown error occurred.', isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  // --- Phone Number Registration Functions ---
  void _sendOtpForRegistration() async {
    try {
      _showSnackBar('Sending OTP...', isError: false);
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // AUTO-REGISTER/LOGIN: This callback is invoked automatically if the phone number
          // can be verified instantly.
          UserCredential userCredential = await _auth.signInWithCredential(
            credential,
          );
          if (userCredential.user != null) {
            await _storePhoneUserData(
              userCredential.user!.uid,
              _phoneController.text,
            );
            _showSnackBar(
              'Phone registration successful (auto)!',
              isError: false,
            );
            _navigateToAuthWrapper();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar(
            e.message ?? 'Phone verification failed.',
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });
          _showSnackBar('OTP sent to ${_phoneController.text}', isError: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
          _showSnackBar('OTP auto-retrieval timed out.', isError: true);
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        e.message ?? 'An error occurred sending OTP.',
        isError: true,
      );
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _verifyOtpAndRegister() async {
    if (_verificationId == null) {
      _showSnackBar('Please send OTP first.', isError: true);
      return;
    }
    try {
      _showSnackBar('Verifying OTP...', isError: false);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text,
      );
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      if (userCredential.user != null) {
        await _storePhoneUserData(
          userCredential.user!.uid,
          _phoneController.text,
        );
        _showSnackBar('Registration successful with phone!', isError: false);
        _navigateToAuthWrapper();
      } else {
        _showSnackBar('Registration failed: User not created.', isError: true);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'OTP verification failed.', isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _storePhoneUserData(String uid, String phoneNumber) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text,
      'phoneNumber': phoneNumber,
      'email': null, // Email is null if registered by phone
      'role': 'farmer',
      'farmId': null,
      'createdAt': Timestamp.now(),
    });
  }

  void _navigateToAuthWrapper() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Toggle between Email/Password and Phone Registration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isPhoneRegistration = false;
                      _verificationId = null;
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Email/Password',
                    style: TextStyle(
                      color: _isPhoneRegistration ? Colors.grey : Colors.blue,
                      fontWeight: _isPhoneRegistration
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
                const Text(' | '),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isPhoneRegistration = true;
                      _verificationId = null;
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      color: _isPhoneRegistration ? Colors.blue : Colors.grey,
                      fontWeight: _isPhoneRegistration
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email/Password Registration Fields
            if (!_isPhoneRegistration) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
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
                onPressed: _registerWithEmailPassword,
                child: const Text('Register'),
              ),
            ],

            // Phone Number & OTP Registration Fields
            if (_isPhoneRegistration) ...[
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g., +919876543210)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendOtpForRegistration,
                child: const Text('Send OTP'),
              ),
              if (_verificationId != null) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  decoration: const InputDecoration(
                    labelText: 'Enter OTP',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _verifyOtpAndRegister,
                  child: const Text('Verify OTP & Register'),
                ),
              ],
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
