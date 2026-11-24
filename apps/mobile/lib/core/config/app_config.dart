// Public compile-time configuration only; never load the backend environment.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static SupabaseConfiguration? get supabase =>
      SupabaseConfiguration.parse(supabaseUrl, supabasePublishableKey);
}

class SupabaseConfiguration {
  const SupabaseConfiguration._(this.url, this.publishableKey);

  final String url;
  final String publishableKey;

  static SupabaseConfiguration? parse(String url, String key) {
    if (url.isEmpty && key.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        !key.startsWith('sb_publishable_') ||
        key.length <= 'sb_publishable_'.length ||
        key.contains(RegExp(r'\s'))) {
      throw const FormatException(
        'Provide an HTTPS Supabase project URL and a publishable key.',
      );
    }
    return SupabaseConfiguration._(uri.origin, key);
  }
}
