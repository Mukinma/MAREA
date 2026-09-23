class AppConfig {
  const AppConfig._({required this.supabaseUrl, required this.supabaseAnonKey});

  factory AppConfig.fromEnvironment() {
    return const AppConfig._(
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  factory AppConfig.fromValues({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    return AppConfig._(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;

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
