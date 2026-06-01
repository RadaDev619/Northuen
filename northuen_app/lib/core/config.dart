class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://northuen-backend-814824894845.asia-south1.run.app',
  );
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const geoapifyApiKey = String.fromEnvironment(
    'GEOAPIFY_API_KEY',
    defaultValue: '',
  );
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasSupabaseRealtime =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  static bool get hasGoogleMaps => googleMapsApiKey.isNotEmpty;
  static bool get hasGeoapify => geoapifyApiKey.isNotEmpty;
  static String get geoapifyTileUrl {
    if (!hasGeoapify) return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    return 'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=$geoapifyApiKey';
  }
}
