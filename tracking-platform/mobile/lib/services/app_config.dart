class AppConfig {
  static const trackingApiBaseUrl = String.fromEnvironment(
    'TRACKING_API_BASE_URL',
    defaultValue: 'http://192.168.1.173:8082',
  );

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyD-sPpMSOn-IVdAIlxfgPUpuNP3NZ1yCR4',
  );

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
