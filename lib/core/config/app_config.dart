import 'dart:convert';

class AppConfig {
  const AppConfig._({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    this.publicUrl = 'https://marea-azul.netlify.app/',
    this.environment = 'production',
    this.productionSupabaseUrl = '',
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig._(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      environment: String.fromEnvironment(
        'MAREA_ENV',
        defaultValue: 'production',
      ),
      productionSupabaseUrl: String.fromEnvironment(
        'MAREA_PRODUCTION_SUPABASE_URL',
      ),
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
    String environment = 'production',
    String productionSupabaseUrl = '',
  }) {
    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      publicUrl: publicUrl,
      environment: environment,
      productionSupabaseUrl: productionSupabaseUrl,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String publicUrl;
  final String environment;
  final String productionSupabaseUrl;
  bool get isDevelopment => environment == 'development';
  String get mobileOAuthRedirect =>
      '${isDevelopment ? 'com.marea.app.dev' : 'com.marea.app'}://login-callback';
  String get developmentSessionKey {
    final uri = Uri.parse(supabaseUrl);
    return 'marea-development-${uri.host}-${uri.port}-auth-token';
  }

  bool acceptsDevelopmentAuthCallback(Uri uri) {
    try {
      final callback = Uri.parse(mobileOAuthRedirect);
      final links = Uri.tryParse(publicUrl);
      final mobile =
          uri.scheme == callback.scheme &&
          uri.host == callback.host &&
          (uri.path.isEmpty || uri.path == '/');
      final web =
          links != null &&
          {'http', 'https'}.contains(uri.scheme) &&
          uri.origin == links.origin &&
          (uri.path.isEmpty || uri.path == '/');
      final fragment =
          Uri.tryParse(
            'https://callback.invalid/?${uri.fragment}',
          )?.queryParameters ??
          {};
      final parameters = {...uri.queryParameters, ...fragment};
      return isDevelopment &&
          uri.userInfo.isEmpty &&
          (mobile || web) &&
          [
            'code',
            'access_token',
            'error',
            'error_code',
            'error_description',
          ].any(parameters.containsKey);
    } on FormatException {
      return false;
    }
  }

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

  bool get isValid => validationMessage == null;

  String? get validationMessage {
    final missing = <String>[
      if (supabaseUrl.isEmpty) 'SUPABASE_URL',
      if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
    ];
    if (missing.isNotEmpty) {
      return 'Falta configurar ${missing.join(' y ')} mediante --dart-define.';
    }
    if (!{'production', 'development'}.contains(environment)) {
      return 'El entorno de la aplicación no es válido.';
    }
    if (!isDevelopment) return null;
    final target = _origin(supabaseUrl),
        production = _origin(productionSupabaseUrl);
    if (target == null || production == null) {
      return 'Prepara la configuración de desarrollo con tool/ar-pilot.ps1.';
    }
    if (target.host == production.host) {
      return 'La aplicación de desarrollo requiere un proyecto separado de producción.';
    }
    final bytes = target.host.split('.').map(int.tryParse).toList();
    final privateIPv4 =
        bytes.length == 4 &&
        bytes.every((v) => v != null && v >= 0 && v <= 255) &&
        (bytes[0] == 10 ||
            (bytes[0] == 172 && bytes[1]! >= 16 && bytes[1]! <= 31) ||
            (bytes[0] == 192 && bytes[1] == 168));
    final local =
        privateIPv4 ||
        {'localhost', '127.0.0.1', '::1', '[::1]'}.contains(target.host);
    if (target.scheme != 'https' && !local) {
      return 'El backend de desarrollo requiere HTTPS o una conexión local.';
    }
    if (!_publicDevelopmentKey(supabaseAnonKey)) {
      return 'Desarrollo requiere una clave pública de Supabase; revisa la configuración.';
    }
    final links = _origin(publicUrl);
    if (links == null || links.host == 'marea-azul.netlify.app') {
      return 'Configura los enlaces del entorno de desarrollo.';
    }
    return null;
  }

  static Uri? _origin(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return null;
    }
    return uri;
  }

  static bool _publicDevelopmentKey(String value) {
    if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]{20,}$').hasMatch(value)) {
      return true;
    }
    try {
      final parts = value.split('.');
      if (parts.length != 3 || parts.any((p) => p.isEmpty)) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map && payload['role'] == 'anon';
    } catch (_) {
      return false;
    }
  }
}
