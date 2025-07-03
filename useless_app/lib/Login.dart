import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth.dart';

class LoginDialog extends StatefulWidget {
  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String? _error;
  bool _loading = false;
  final Auth _auth = Auth();

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: _email.trim(),
          password: _password,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('invalid-credential')) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                'Wrong credentials',
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'Please check that your credentials are correct.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          );
        }
      } else if (msg.contains('invalid-email')) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text(
                'Invalid email',
                style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
              ),
              content: const Text(
                'The email you entered is not valid.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _error = msg.replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? 'Login' : 'Register',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => _email = v,
                        validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFFD700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        obscureText: true,
                        onChanged: (v) => _password = v,
                        validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 characters',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 16),
                      _loading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC5A700),
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(40),
                              ),
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {
                                  _submit();
                                }
                              },
                              child: Text(_isLogin ? 'Login' : 'Register'),
                            ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _error = null;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? "Don't have an account? Sign up"
                              : "Already have an account? Login",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
