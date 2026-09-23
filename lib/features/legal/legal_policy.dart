class LegalDocument {
  const LegalDocument({
    required this.version,
    required this.title,
    required this.body,
  });
  final String version;
  final String title;
  final String body;
  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    version: json['version'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
  );
}

class LegalPolicy {
  const LegalPolicy({
    required this.signupEnabled,
    this.terms,
    this.privacy,
    this.supportEmail,
  });
  const LegalPolicy.unavailable()
    : signupEnabled = false,
      terms = null,
      privacy = null,
      supportEmail = null;
  final bool signupEnabled;
  final LegalDocument? terms;
  final LegalDocument? privacy;
  final String? supportEmail;
  bool get hasDocuments =>
      terms != null &&
      privacy != null &&
      terms!.body.trim().isNotEmpty &&
      privacy!.body.trim().isNotEmpty;
  bool get canRegister => signupEnabled && hasDocuments;
  factory LegalPolicy.fromJson(Map<String, dynamic> json) => LegalPolicy(
    signupEnabled: json['signup_enabled'] == true,
    terms: json['terms'] is Map<String, dynamic>
        ? LegalDocument.fromJson(json['terms'] as Map<String, dynamic>)
        : null,
    privacy: json['privacy'] is Map<String, dynamic>
        ? LegalDocument.fromJson(json['privacy'] as Map<String, dynamic>)
        : null,
    supportEmail: json['support_email'] as String?,
  );
}

class LegalConsent {
  LegalConsent({
    required this.termsVersion,
    required this.privacyVersion,
    required bool acceptedTerms,
    required bool adultConfirmed,
  }) {
    if (!acceptedTerms ||
        !adultConfirmed ||
        termsVersion.isEmpty ||
        privacyVersion.isEmpty) {
      throw ArgumentError('Consent and adult declaration required');
    }
  }
  final String termsVersion;
  final String privacyVersion;
  Map<String, dynamic> toMetadata() => {
    'terms_version': termsVersion,
    'privacy_version': privacyVersion,
    'adult_confirmed': true,
    'accepted_terms': true,
  };
}
