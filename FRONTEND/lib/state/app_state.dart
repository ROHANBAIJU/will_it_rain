// lib/state/app_state.dart
// Lightweight global app state using ValueNotifier for cross-screen updates

import 'package:flutter/foundation.dart';

class AppState {
  // Stores the user's chosen location (e.g., "New York, NY")
  static final ValueNotifier<String?> location = ValueNotifier<String?>(null);
}
