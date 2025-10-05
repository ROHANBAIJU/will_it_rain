import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_client.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthenticated});

  /// Optional: pass a callback to switch to the app after sign-in/up.
  final VoidCallback? onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true; // Start with login view

  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  final _secureStorage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (isLogin) {
      _login();
    } else {
      _register();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    
    try {
      // Initialize Google Sign-In with ONLY scopes - no clientId needed for web
      // The clientId is automatically picked up from the meta tag in index.html
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'openid',
        ],
      );

      // Sign out first to ensure clean state
      await googleSignIn.signOut();

      // Attempt to sign in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() => _googleLoading = false);
        }
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // For web, we primarily use accessToken since idToken is not reliably available
      final String? token = googleAuth.accessToken ?? googleAuth.idToken;
      
      if (token == null) {
        throw Exception('Failed to get authentication token from Google');
      }

      print('Google Sign-In successful!');
      print('Email: ${googleUser.email}');
      print('Name: ${googleUser.displayName}');
      print('Token type: ${googleAuth.idToken != null ? "ID Token" : "Access Token"}');

      // Send to backend for verification and account creation/login
      print('📤 Sending to backend: /auth/google');
      final res = await ApiClient.instance.post(
        '/auth/google',
        body: {
          'id_token': token,
          'email': googleUser.email,
          'name': googleUser.displayName ?? googleUser.email.split('@')[0],
        },
      );

      print('📥 Backend response: ${res.statusCode}');
      print('📥 Response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final accessToken = data['access_token'] as String?;
        
        print('✅ Got access token from backend: ${accessToken?.substring(0, 20)}...');
        
        if (accessToken != null) {
          await _saveToken(accessToken);
          print('✅ Token saved to secure storage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Google!'),
                backgroundColor: Color(0xFF34A853),
              ),
            );
            print('✅ Calling onAuthenticated callback...');
            print('✅ Callback is ${widget.onAuthenticated == null ? "NULL" : "NOT NULL"}');
            widget.onAuthenticated?.call();
            print('✅ Callback executed!');
          }
          return;
        } else {
          print('❌ No access_token in response data');
        }
      }

      // Handle error
      String message = 'Google Sign-In failed';
      try {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) {
          message = json['detail']?.toString() ?? json['error']?.toString() ?? json['message']?.toString() ?? message;
        }
      } catch (_) {}
      
      print('❌ Error: $message');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      
      // Check if it's the People API error
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('people api') || errorMsg.contains('403') || errorMsg.contains('permission_denied')) {
        if (mounted) {
          _showPeopleApiSetupDialog();
        }
      } else if (errorMsg.contains('popup_closed')) {
        // User closed the popup - this is expected, don't show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in cancelled'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (errorMsg.contains('clientid') || errorMsg.contains('client_id')) {
        if (mounted) {
          _showGoogleSignInSetupDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Google Sign-In error: ${e.toString()}'),
              backgroundColor: const Color(0xFFEA4335),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _googleLoading = false);
      }
    }
  }

  void _showPeopleApiSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable People API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The Google People API needs to be enabled for your project.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Please follow these steps:'),
              const SizedBox(height: 12),
              const Text('1. Go to Google Cloud Console'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const SelectableText(
                  'https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=606020632465',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFF7C6BAD),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('2. Click "Enable API"'),
              const Text('3. Wait a few minutes for it to activate'),
              const Text('4. Try signing in again'),
              const SizedBox(height: 16),
              const Text(
                'Or use Email authentication instead.',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showGoogleSignInSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Sign-In Setup Required'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To use Google Sign-In, you need to:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Go to Google Cloud Console'),
              Text('2. Create OAuth 2.0 Client ID'),
              Text('3. Add authorized JavaScript origins:'),
              Text('   • http://localhost:63064', style: TextStyle(fontFamily: 'monospace')),
              Text('4. Copy the Client ID'),
              Text('5. Update web/index.html with your Client ID'),
              SizedBox(height: 16),
              Text(
                'For now, please use Email authentication.',
                style: TextStyle(
                  color: Color(0xFF7C6BAD),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could open a URL to Google Cloud Console
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C6BAD),
            ),
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F3FF), // Light lavender background
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  maxWidth: 600, // Prevent content from stretching too wide
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 360 ? 16 : (MediaQuery.of(context).size.width < 500 ? 24 : 32),
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        // Logo and Title Section
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 360;
                            return Column(
                              children: [
                                // Logo with friendly styling
                                Container(
                                  width: isSmallScreen ? 64 : 80,
                                  height: isSmallScreen ? 64 : 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7C6BAD), Color(0xFF9B8AC4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C6BAD).withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.cloud,
                                    color: Colors.white,
                                    size: isSmallScreen ? 32 : 40,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12 : 16),

                                // Title
                                Text(
                                  'AeroNimbus',
                                  style: TextStyle(
                                    color: const Color(0xFF2D2D2D),
                                    fontSize: isSmallScreen ? 24 : 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'NASA-Grade Weather Intelligence',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF7C6BAD),
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Earth Observation Badge
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8E4F3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFD4CDED)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.public, color: Color(0xFF7C6BAD), size: 16),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Powered by Earth Observation Data',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFF7C6BAD),
                                            fontSize: isSmallScreen ? 11 : 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Main Auth Card - Clean white design
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 440),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              MediaQuery.of(context).size.width < 360 ? 20 : 28,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmallScreen = constraints.maxWidth < 360;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isLogin ? 'Welcome Back' : 'Join AeroNimbus',
                                          style: TextStyle(
                                            color: const Color(0xFF2D2D2D),
                                            fontSize: isSmallScreen ? 22 : 26,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(height: isSmallScreen ? 4 : 8),
                                        Text(
                                          isLogin
                                              ? 'Sign in to access your weather dashboard'
                                              : 'Create your account and get started',
                                          style: TextStyle(
                                            color: const Color(0xFF666666),
                                            fontSize: isSmallScreen ? 13 : 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 28),

                                // Google Sign-In Button - Primary CTA
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _googleLoading ? null : _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF2D2D2D),
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: Color(0xFFE5E5E5),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _googleLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C6BAD)),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Google "G" logo with colors
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFF4285F4),
                                                      Color(0xFFEA4335),
                                                      Color(0xFFFBBC05),
                                                      Color(0xFF34A853),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Center(
                                                  child: Text(
                                                    'G',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                isLogin ? 'Sign in with Google' : 'Sign up with Google',
                                                style: const TextStyle(
                                                  color: Color(0xFF2D2D2D),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // OR Divider
                                Row(
                                  children: const [
                                    Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Email Auth Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      if (!isLogin)
                                        _modernField(
                                          label: 'Full Name',
                                          hint: 'Jane Doe',
                                          controller: _name,
                                          icon: Icons.person_outline,
                                          validator: (v) => (v ?? '').isEmpty ? 'Please enter your name' : null,
                                        ),
                                      
                                      _modernField(
                                        label: 'Email Address',
                                        hint: 'you@example.com',
                                        controller: _email,
                                        icon: Icons.mail_outline,
                                        validator: (v) {
                                          if ((v ?? '').isEmpty) return 'Please enter your email';
                                          if (!RegExp(r'.+@.+\..+').hasMatch(v!)) return 'Enter a valid email';
                                          return null;
                                        },
                                        keyboardType: TextInputType.emailAddress,
                                      ),

                                      const SizedBox(height: 16),

                                      _modernField(
                                        label: 'Password',
                                        hint: '••••••••',
                                        controller: _password,
                                        icon: Icons.lock_outline,
                                        obscure: true,
                                        validator: (v) {
                                          if ((v ?? '').isEmpty) return 'Please enter a password';
                                          if (v!.length < 6) return 'Password must be at least 6 characters';
                                          return null;
                                        },
                                      ),

                                      if (!isLogin) ...[
                                        const SizedBox(height: 16),
                                        _modernField(
                                          label: 'Confirm Password',
                                          hint: '••••••••',
                                          controller: _confirm,
                                          icon: Icons.lock_outline,
                                          obscure: true,
                                          validator: (v) {
                                            if ((v ?? '').isEmpty) return 'Please confirm your password';
                                            if (v != _password.text) return 'Passwords do not match';
                                            return null;
                                          },
                                        ),
                                      ],

                                      if (isLogin) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Password reset coming soon!'),
                                                  backgroundColor: Color(0xFF7C6BAD),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: Color(0xFF7C6BAD),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 24),

                                      // Email Sign In/Up Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: _loading ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF7C6BAD),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shadowColor: const Color(0xFF7C6BAD).withOpacity(0.3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      isLogin ? 'Sign In with Email' : 'Create Account',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.arrow_forward, size: 20),
                                                  ],
                                                ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Toggle between Sign In/Sign Up
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isLogin
                                                ? "Don't have an account?"
                                                : 'Already have an account?',
                                            style: const TextStyle(
                                              color: Color(0xFF666666),
                                              fontSize: 14,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              isLogin = !isLogin;
                                              _formKey.currentState?.reset();
                                            }),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                            ),
                                            child: Text(
                                              isLogin ? 'Sign up' : 'Sign in',
                                              style: const TextStyle(
                                                color: Color(0xFF7C6BAD),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                  ],
                                ),
                              ),
                            ),

                        const SizedBox(height: 24),
                        
                        // Terms and Privacy
                        const Text(
                          'By continuing, you agree to AeroNimbus\'s Terms of Service\nand acknowledge our Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Small debug control to clear stored token
                        TextButton(
                          onPressed: _clearToken,
                          child: const Text('Logout / Clear stored token', style: TextStyle(color: Color(0xFF7C6BAD))),
                        ),
                      ], // Column children
                    ), // Padding
                  ), // ConstrainedBox
                ), // SingleChildScrollView
              ), // Center
            ), // SafeArea
          ), // Container
        ), // body
      ); // Scaffold
  }

  // Modern text field with beautiful styling
  Widget _modernField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2D2D2D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: const Color(0xFF2D2D2D).withOpacity(0.4),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF7C6BAD),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  // Backend configuration (change for device or production)
  String get _backendBase => 'https://will-it-rain-3ogz.onrender.com';

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final body = jsonEncode({
        'email': _email.text.trim(),
        'password': _password.text,
        'name': _name.text.trim(),
      });

    // Debug: print outgoing request (visible in console for web)
    // ignore: avoid_print
    print('POST $_backendBase/auth/register -> $body');

    final res = await ApiClient.instance.post('/auth/register', body: {'email': _email.text.trim(), 'password': _password.text, 'name': _name.text.trim()});

      // Debug: print response status and body
      // ignore: avoid_print
      print('RESPONSE ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null) {
          await _saveToken(token);
          widget.onAuthenticated?.call();
          return;
        }
      }

      // Try to parse a helpful error message from the backend JSON
      String message = 'Registration failed';
      try {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) {
          if (json.containsKey('detail')) {
            message = json['detail'].toString();
          } else if (json.containsKey('error')) message = json['error'].toString();
          else if (json.containsKey('message')) message = json['message'].toString();
          else message = json.toString();
        } else {
          message = json.toString();
        }
      } catch (_) {
        if (res.body.isNotEmpty) message = res.body;
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // Surface unexpected errors
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final body = jsonEncode({'email': _email.text.trim(), 'password': _password.text});

    // Debug
    // ignore: avoid_print
    print('POST $_backendBase/auth/login -> $body');

    final res = await ApiClient.instance.post('/auth/login', body: {'email': _email.text.trim(), 'password': _password.text});

      // Debug: print response
      // ignore: avoid_print
      print('RESPONSE ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['access_token'] as String?;
        if (token != null) {
          await _saveToken(token);
          widget.onAuthenticated?.call();
          return;
        }
      }

      String message = 'Login failed';
      try {
        final json = jsonDecode(res.body);
        if (json is Map<String, dynamic>) {
          if (json.containsKey('detail')) {
            message = json['detail'].toString();
          } else if (json.containsKey('error')) message = json['error'].toString();
          else if (json.containsKey('message')) message = json['message'].toString();
          else message = json.toString();
        } else {
          message = json.toString();
        }
      } catch (_) {
        if (res.body.isNotEmpty) message = res.body;
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      await _secureStorage.write(key: 'access_token', value: token);
    } catch (e) {
      // ignore - best-effort
    }
  }

  Future<void> _clearToken() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token cleared')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing token: $e')));
    }
  }

}

// Starfield painter removed for clean light theme
