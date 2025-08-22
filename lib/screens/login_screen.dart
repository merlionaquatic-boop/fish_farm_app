import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fish_farm_app/screens/registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPhoneLogin = false; // To toggle between email/phone login
  String? _verificationId; // Stores the ID received after sending OTP

  @override
  void dispose() {
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

  // --- Email/Password Login Function ---
  void _loginWithEmailPassword() async {
    try {
      _showSnackBar('Logging in with email...', isError: false);
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _showSnackBar('Login successful!', isError: false);
      _navigateToAuthWrapper();
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'An unknown error occurred.', isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  // --- Phone Number Login Functions ---
  void _sendOtp() async {
    try {
      _showSnackBar('Sending OTP...', isError: false);
      await _auth.verifyPhoneNumber(
        phoneNumber: _phoneController.text,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // AUTO-LOGIN: This callback is invoked automatically if the phone number
          // can be verified instantly (e.g., Android instant verification).
          await _auth.signInWithCredential(credential);
          _showSnackBar(
            'Phone verification successful (auto)!',
            isError: false,
          );
          _navigateToAuthWrapper();
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar(
            e.message ?? 'Phone verification failed.',
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          // OTP SENT: Store the verification ID to use when the user enters the code.
          setState(() {
            _verificationId = verificationId;
          });
          _showSnackBar('OTP sent to ${_phoneController.text}', isError: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout: If OTP is not auto-retrieved within a specific time.
          setState(() {
            _verificationId = verificationId;
          });
          _showSnackBar('OTP auto-retrieval timed out.', isError: true);
        },
        timeout: const Duration(seconds: 60), // OTP timeout
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

  void _verifyOtpAndLogin() async {
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
      await _auth.signInWithCredential(credential);
      _showSnackBar('Login successful with phone!', isError: false);
      _navigateToAuthWrapper();
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? 'OTP verification failed.', isError: true);
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  void _navigateToAuthWrapper() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => AuthWrapper()));
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
            // Toggle between Email/Password and Phone Login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isPhoneLogin = false;
                      _verificationId = null; // Reset OTP state
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Email/Password',
                    style: TextStyle(
                      color: _isPhoneLogin ? Colors.grey : Colors.blue,
                      fontWeight: _isPhoneLogin
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                ),
                const Text(' | '),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isPhoneLogin = true;
                      _verificationId = null; // Reset OTP state
                      _otpController.clear();
                    });
                  },
                  child: Text(
                    'Phone Number',
                    style: TextStyle(
                      color: _isPhoneLogin ? Colors.blue : Colors.grey,
                      fontWeight: _isPhoneLogin
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Email/Password Input Fields
            if (!_isPhoneLogin) ...[
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
                onPressed: _loginWithEmailPassword,
                child: const Text('Login'),
              ),
            ],

            // Phone Number & OTP Input Fields
            if (_isPhoneLogin) ...[
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
                onPressed: _sendOtp,
                child: const Text('Send OTP'),
              ),
              if (_verificationId != null) ...[
                // Only show OTP field if OTP has been sent
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
                  onPressed: _verifyOtpAndLogin,
                  child: const Text('Verify OTP & Login'),
                ),
              ],
            ],

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Implement your authentication wrapper logic here
    return Scaffold(body: Center(child: Text('AuthWrapper Screen')));
  }
}
