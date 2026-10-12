class AppConfig {
  const AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.publicUrl = 'https://marea-azul.netlify.app/',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig._(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      publicUrl: String.fromEnvironment(
        'APP_PUBLIC_URL',
        defaultValue: 'https://marea-azul.netlify.app/',
      ),
    );
  }

  factory AppConfig.fromValues({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String publicUrl = 'https://marea-azul.netlify.app/',
  }) {
    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      publicUrl: publicUrl,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String publicUrl;
  Uri postUrl(String id) => _contentUrl('posts', id);
  Uri missionUrl(String id) => _contentUrl('missions', id);

  Uri _contentUrl(String kind, String id) {
    final origin = Uri.parse(publicUrl);
    if (!{'http', 'https'}.contains(origin.scheme) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty) {
      throw StateError('APP_PUBLIC_URL debe ser una URL pública HTTP o HTTPS.');
    }
    return Uri(
      scheme: origin.scheme,
      host: origin.host,
      port: origin.hasPort ? origin.port : null,
      pathSegments: [kind, id],
    );
  }

  bool get isValid => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  String? get validationMessage {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (missing.isEmpty) return null;
    return 'Falta configurar ${missing.join(' y ')} mediante --dart-define.';
  }
}
