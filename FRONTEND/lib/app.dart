
// lib/app.dart
// AeroNimbus – App root & navigation
// -------------------------------------------------------------
// This file wires up:
// 1) Global theme
// 2) Auth gate (starts at AuthPage, goes to MainTabs after login)
// 3) Main tabbed UI (Dashboard, Alerts, Compare, Best Days, Map, Settings)
// 4) Optional /transparency route
//
// Notes:
// - We rely on your existing screen files under lib/screens/*.dart
// - AuthPage must call onAuthenticated() to pass the gate
// -------------------------------------------------------------

import 'package:flutter/material.dart';

// Screens (already in your project per your confirmation)
import 'screens/auth.dart';
import 'screens/dashboard.dart';
import 'screens/alerts.dart';
import 'screens/compare.dart';
import 'screens/best_days.dart';
import 'screens/map.dart';
import 'screens/settings.dart';
import 'screens/transparency.dart';
import 'theme/aeronimbus_theme.dart';
import 'state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/plan_ahead.dart';
/// Public entry used by main.dart -> runApp(const AeroNimbusApp());
class AeroNimbusApp extends StatelessWidget {
  const AeroNimbusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroNimbus',
      debugShowCheckedModeBanner: false,
      theme: AeroNimbusTheme.dark(),

      // IMPORTANT: Start behind an auth gate so the app opens on AuthPage.
      home: const _AuthGate(),

      // Optional route for the standalone transparency screen.
      routes: {
        '/transparency': (_) => const TransparencyPage(),
      },
    );
  }
}

// ---------------------------------------------------------------------
// Auth Gate
// ---------------------------------------------------------------------
// Shows AuthPage first. After successful sign-in/up, we push MainTabs.
// This matches your original requirement “start at login, then dashboard”.

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _authed = false;

  @override
  Widget build(BuildContext context) {
    if (!_authed) {
      // Your existing AuthPage from lib/screens/auth.dart
      return AuthPage(
        onAuthenticated: () {
          setState(() => _authed = true);
        },
      );
    }

    // After auth -> tabbed application
    return const MainTabs();
  }
}

// ---------------------------------------------------------------------
// MainTabs – the main app scaffold with Drawer navigation (Dashboard, Alerts, Compare, Best Days, Map, Settings)
// ---------------------------------------------------------------------

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _selectedIndex = 0; // Track current page index
  String currentLocation = 'New York, NY';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // List of pages for navigation
  late final List<Widget> _pages;
  late final List<_DrawerItem> _drawerItems;

  @override
  void initState() {
    super.initState();
    _pages =  [
      DashboardPage(),
      PlanAheadWidget(),
      AlertsPage(),
      ComparePage(),
      BestDaysPage(),
      MapPage(),
      SettingsPage(),
    ];

    // Load saved location; if missing, prompt user after first frame
    _loadOrPromptLocation();
    
    _drawerItems = const [
      _DrawerItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      _DrawerItem(icon: Icons.settings_outlined, label: 'Plan Ahead'),
      _DrawerItem(icon: Icons.health_and_safety_outlined, label: 'Health Alerts'),
      _DrawerItem(icon: Icons.bar_chart, label: 'Compare'),
      _DrawerItem(icon: Icons.star_border, label: 'Best Days'),
      _DrawerItem(icon: Icons.public, label: 'Map'),
      _DrawerItem(icon: Icons.settings_outlined, label: 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      // Custom drawer implementation
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Subtle background gradient (gold + cyan + indigo haze)
          const _BackgroundGradient(),

          // Foreground content with SafeArea - improved layout structure
          SafeArea(
            child: Column(
              children: [
                // Simplified header with drawer menu button and location search
                _SimpleHeader(
                  currentLocation: currentLocation,
                  onLocationChanged: (v) => setState(() => currentLocation = v),
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),

                // Current page content
                Expanded(
                  child: _pages[_selectedIndex],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadOrPromptLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_location');
    if (saved != null && saved.isNotEmpty) {
      setState(() => currentLocation = saved);
      AppState.location.value = saved;
      return;
    }
    // Prompt after first frame to ensure scaffold is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationDialog();
    });
  }

  Future<void> _showLocationDialog() async {
    final controller = TextEditingController(text: currentLocation);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your city or ZIP code'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g., New York, NY',
                ),
                autofocus: true,
                onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_location', result);
      setState(() => currentLocation = result);
      AppState.location.value = result;
    }
  }

  // Custom drawer widget
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0B0B10), // Dark background matching theme
      child: Column(
        children: [
          // Drawer header with app branding
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B0764), // Deep purple
                  Color(0xFF1E1B4B), // Dark indigo
                  Color(0xFF0B0B10), // Dark background
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4B0082)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Icon(Icons.cloud, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 8),
                    // App title and subtitle
                    const Text(
                      'AeroNimbus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'NASA-Grade Weather Intelligence',
                      style: TextStyle(
                        color: Color(0xFFCEB3FF),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Live data badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x4D10B981)),
                      ),
                      child: const Text(
                        'Live Data',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Navigation menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _drawerItems.length,
              itemBuilder: (context, index) {
                final item = _drawerItems[index];
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x1AFACC15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: const Color(0x4DFACC15)) : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item.icon,
                      color: isSelected ? const Color(0xFFFACC15) : Colors.white70,
                      size: 22,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFFACC15) : Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.of(context).pop(); // Close drawer
                    },
                  ),
                );
              },
            ),
          ),
          
          // Footer in drawer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.10)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white60, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Powered by NASA Earth Observation Data',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Visual pieces (background, top bar, footer, tabs, badges)
// ---------------------------------------------------------------------

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base cosmic gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B0764), // Deep purple
                Color(0xFF1E1B4B), // Dark indigo
                Color(0xFF0B0B10), // Dark background
              ],
            ),
          ),
        ),
        // Starfield overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _StarfieldPainter(),
            ),
          ),
        ),
        // Subtle cosmic haze
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x33FACC15).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x3306B6D4).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Simplified header with menu button and location search
class _SimpleHeader extends StatelessWidget {
  final String currentLocation;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onMenuPressed;

  const _SimpleHeader({
    required this.currentLocation,
    required this.onLocationChanged,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x33000000), // black/20
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 600;
          
          if (isSmallScreen) {
            // Stack vertically on small screens to prevent overflow
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row with menu and branding
                Row(
                  children: [
                    IconButton(
                      onPressed: onMenuPressed,
                      icon: const Icon(Icons.menu, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.cloud, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 6),
                    const Flexible(
                      child: Text(
                        'AeroNimbus',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field on second row
                SizedBox(
                  width: double.infinity,
                  child: _SearchField(
                    initialText: currentLocation,
                    onChanged: onLocationChanged,
                  ),
                ),
              ],
            );
          } else {
            // Horizontal layout for larger screens
            return Row(
              children: [
                // Menu button to open drawer
                IconButton(
                  onPressed: onMenuPressed,
                  icon: const Icon(Icons.menu, color: Colors.white),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                
                // App branding (simplified)
                const Icon(Icons.cloud, color: Color(0xFF7C3AED), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'AeroNimbus',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                
                const Spacer(),
                
                // Location search (constrained width)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (screenWidth * 0.4).clamp(200.0, 350.0),
                      minWidth: 180.0,
                    ),
                    child: _SearchField(
                      initialText: currentLocation,
                      onChanged: onLocationChanged,
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.initialText,
    required this.onChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        _ctrl.text != widget.initialText) {
      _ctrl.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white70,
      decoration: InputDecoration(
        hintText: 'Search location...',
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// Data class for drawer navigation items
class _DrawerItem {
  final IconData icon;
  final String label;
  
  const _DrawerItem({required this.icon, required this.label});
}


// Starfield painter for cosmic background
class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create a grid of stars
    final stars = <Offset>[];
    for (int i = 0; i < 100; i++) {
      final x = (i * 37.0) % size.width;
      final y = (i * 43.0) % size.height;
      stars.add(Offset(x, y));
    }

    // Draw stars
    for (final star in stars) {
      final radius = (star.dx * 0.1 + star.dy * 0.1) % 2.0;
      canvas.drawCircle(star, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------
// Minimal fallback AuthScreen (not used when your AuthPage is present)
// ---------------------------------------------------------------------
// Kept here only as reference. Your real `AuthPage` from lib/screens/auth.dart
// will be shown by _AuthGate. You can delete the below if not needed.
// ---------------------------------------------------------------------

/*
class AuthScreen extends StatelessWidget {
  final VoidCallback onAuthenticated;
  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B0082), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              color: Colors.black.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.satellite_alt,
                        color: Colors.white, size: 36),
                    const SizedBox(height: 10),
                    const Text('AeroNimbus',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18)),
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: 'Email or phone',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0x1AFFFFFF),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0x1AFFFFFF),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onAuthenticated,
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
*/
