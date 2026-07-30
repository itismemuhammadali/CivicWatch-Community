class ApiConfig {
  /// Backend base URL - disabled for standalone testing
  /// Set to a valid backend URL when connecting to real backend
  /// Example: 'http://localhost:8000' or 'https://api.cctv.app'
  static const String baseUrl = 'http://localhost:9999'; // Non-existent URL - forces mock mode

  /// MOCK_MODE flag controls whether the app uses mock data or real backend
  /// Set to `true` to use mock responses (standalone/testing)
  /// Set to `false` to connect to real backend (after Firebase setup)
  ///
  /// When MOCK_MODE is true:
  /// - All API calls return pre-generated mock data
  /// - Network delays are simulated (300ms)
  /// - No backend connection is required
  /// - Perfect for UI development and testing
  ///
  /// When MOCK_MODE is false:
  /// - All API calls go to the real backend (baseUrl)
  /// - Actual network delays apply
  /// - Backend must be running and accessible
  static const bool MOCK_MODE = true;

  /// Firebase configuration flags (for future integration)
  /// Set to true once Firebase is configured
  static const bool USE_FIREBASE = true;

  /// Enable/disable debug logging
  static const bool DEBUG_MODE = true;

  ApiConfig._();

  /// Get current config status as string
  static String getConfigStatus() {
    return '''
API Configuration:
- Base URL: $baseUrl
- Mock Mode: $MOCK_MODE
- Use Firebase: $USE_FIREBASE
- Debug Mode: $DEBUG_MODE
- Status: ${MOCK_MODE ? 'Using Mock Data (Offline Mode)' : 'Connected to Backend'}
''';
  }
}


