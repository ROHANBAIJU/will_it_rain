import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_client.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthenticated});

  /// Optional: pass a callback to switch to the app after sign-in/up.
  final VoidCallback? onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = false;
  String authMethod = 'email'; // 'email' | 'phone'

  final _email = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  final _secureStorage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Only email auth implemented for now
    if (authMethod != 'email') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone auth is not implemented yet')),
      );
      return;
    }

    if (isLogin) {
      _login();
    } else {
      _register();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _phone.dispose();
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B0764), // Deep cosmic purple
              Color(0xFF1E1B4B), // Dark indigo
              Color(0xFF0B0B10), // Dark background
            ],
          ),
        ),
        child: Stack(
          children: [
            // Starfield background
            Positioned.fill(
              child: CustomPaint(
                painter: _CosmicStarfieldPainter(),
              ),
            ),
            
            // Content - Fully responsive and scrollable
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and Title Section
                        Container(
                          width: double.infinity,
                          child: Column(
                            children: [
                              // Logo with cosmic styling
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFF4B0082)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.cloud, color: Colors.white, size: 40),
                              ),
                              const SizedBox(height: 16),
                              
                              // Title
                              const Text(
                                'AeroNimbus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'NASA-Grade Weather Intelligence',
                                style: TextStyle(
                                  color: Color(0xFFCEB3FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Earth Observation Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0x3310B981),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0x4D10B981)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.public, color: Color(0xFF6EE7B7), size: 16),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Powered by Earth Observation Data',
                                      style: TextStyle(
                                        color: Color(0xFF6EE7B7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Main Auth Card - Matching the translucent design from images
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Text(
                                      isLogin ? 'Welcome Back' : 'Join AeroNimbus',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isLogin
                                          ? 'Sign in to access your weather dashboard'
                                          : 'Create an account to get started',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Auth method toggle - Matching the design from images
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _authMethodButton(
                                            icon: Icons.mail,
                                            label: 'Email',
                                            active: authMethod == 'email',
                                            onTap: () => setState(() => authMethod = 'email'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _authMethodButton(
                                            icon: Icons.phone,
                                            label: 'Phone',
                                            active: authMethod == 'phone',
                                            onTap: () => setState(() => authMethod = 'phone'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Form Fields
                                    Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          if (!isLogin) _modernField(
                                            label: 'Full Name',
                                            hint: 'Jane Doe',
                                            controller: _name,
                                            icon: Icons.person,
                                            validator: (v) => (v ?? '').isEmpty ? 'Please enter your name' : null,
                                          ),
                                          // Email/Phone Field
                                          if (authMethod == 'email')
                                            _modernField(
                                              label: 'Email Address',
                                              hint: 'you@example.com',
                                              controller: _email,
                                              icon: Icons.mail,
                                              validator: (v) {
                                                if ((v ?? '').isEmpty) return 'Please enter your email';
                                                if (!RegExp(r'.+@.+\..+').hasMatch(v!)) return 'Enter a valid email';
                                                return null;
                                              },
                                              keyboardType: TextInputType.emailAddress,
                                            )
                                          else
                                            _modernField(
                                              label: 'Phone Number',
                                              hint: '+1 (555) 000-0000',
                                              controller: _phone,
                                              icon: Icons.phone,
                                              validator: (v) =>
                                                  (v ?? '').isEmpty ? 'Please enter your phone number' : null,
                                              keyboardType: TextInputType.phone,
                                            ),
                                          
                                          const SizedBox(height: 16),
                                          
                                          // Password Field
                                          _modernField(
                                            label: 'Password',
                                            hint: '••••••••',
                                            controller: _password,
                                            icon: Icons.lock,
                                            obscure: true,
                                            validator: (v) => (v ?? '').isEmpty ? 'Please enter a password' : null,
                                          ),
                                          
                                          if (!isLogin) ...[
                                            const SizedBox(height: 16),
                                            _modernField(
                                              label: 'Confirm Password',
                                              hint: '••••••••',
                                              controller: _confirm,
                                              icon: Icons.lock,
                                              obscure: true,
                                              validator: (v) {
                                                if ((v ?? '').isEmpty) return 'Please confirm your password';
                                                if (v != _password.text) return 'Passwords do not match';
                                                return null;
                                              },
                                            ),
                                          ],
                                          
                                          const SizedBox(height: 24),

                                          // Create Account Button - Matching the purple gradient from images
                                          Container(
                                            width: double.infinity,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF7C3AED), Color(0xFF4B0082)],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton.icon(
                                              onPressed: _loading ? null : _submit,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              icon: const Icon(Icons.arrow_right_alt, color: Colors.white),
                                              label: Text(
                                                isLogin ? 'Sign In' : 'Create Account',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),

                                          if (_loading) ...[
                                            const SizedBox(height: 12),
                                            const Center(child: CircularProgressIndicator()),
                                          ],

                                          const SizedBox(height: 16),
                                          
                                          // Toggle between Sign In/Sign Up
                                          TextButton(
                                            onPressed: () => setState(() => isLogin = !isLogin),
                                            child: Text(
                                              isLogin
                                                  ? "Don't have an account? Sign up"
                                                  : 'Already have an account? Sign in',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Terms and Privacy
                        Text(
                          'By continuing, you agree to AeroNimbus\'s Terms of Service\nand acknowledge our Privacy Policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Small debug control to clear stored token
                        TextButton(
                          onPressed: _clearToken,
                          child: const Text('Logout / Clear stored token', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern UI components matching the design from images
  Widget _authMethodButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: active 
              ? const Color(0xFF7C3AED) 
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active 
                ? const Color(0xFF7C3AED) 
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 20, 
              color: active 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label, 
              style: TextStyle(
                color: active 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscure,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.6),
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
          if (json.containsKey('detail')) message = json['detail'].toString();
          else if (json.containsKey('error')) message = json['error'].toString();
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
          if (json.containsKey('detail')) message = json['detail'].toString();
          else if (json.containsKey('error')) message = json['error'].toString();
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

// Enhanced cosmic starfield painter
class _CosmicStarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Create a more realistic starfield
    final stars = <Offset>[];
    for (int i = 0; i < 150; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 43.0) % size.height;
      stars.add(Offset(x, y));
    }

    // Draw stars with varying sizes
    for (final star in stars) {
      final radius = (star.dx * 0.1 + star.dy * 0.1) % 3.0;
      paint.color = Colors.white.withOpacity(0.6 + (radius / 3.0) * 0.4);
      canvas.drawCircle(star, radius, paint);
    }

    // Add some larger "twinkling" stars
    final twinkleStars = <Offset>[
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.7),
      Offset(size.width * 0.3, size.height * 0.8),
    ];

    for (final star in twinkleStars) {
      paint.color = Colors.white.withOpacity(0.9);
      canvas.drawCircle(star, 2.0, paint);
      paint.color = Colors.white.withOpacity(0.3);
      canvas.drawCircle(star, 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
