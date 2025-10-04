import 'package:flutter/material.dart';
import 'app.dart';
import 'theme/aeronimbus_theme.dart';

void main() {
  runApp(const AeroNimbusRoot());
}

class AeroNimbusRoot extends StatelessWidget {
  const AeroNimbusRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroNimbus',
      debugShowCheckedModeBanner: false,
      theme: AeroNimbusTheme.light(), // Using light purple theme
      home: const AeroNimbusApp(), // contains Auth + tabs wiring
    );
  }
}
