import 'package:marea/features/legal/legal_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class LegalRepository {
  Future<LegalPolicy> loadPolicy();
  Future<bool> hasAccepted(LegalPolicy policy);
  Future<void> accept(LegalConsent consent);
}

class SupabaseLegalRepository implements LegalRepository {
  SupabaseLegalRepository(this.client);
  final SupabaseClient client;
  @override
  Future<LegalPolicy> loadPolicy() async => LegalPolicy.fromJson(
    Map<String, dynamic>.from(await client.rpc('registration_policy')),
  );
  @override
  Future<bool> hasAccepted(LegalPolicy policy) async {
    if (!policy.hasDocuments) return true;
    final rows = await client
        .from('legal_acceptances')
        .select('id')
        .eq('user_id', client.auth.currentUser!.id)
        .eq('terms_version', policy.terms!.version)
        .eq('privacy_version', policy.privacy!.version)
        .limit(1);
    return rows.isNotEmpty;
  }

  @override
  Future<void> accept(LegalConsent consent) async {
    await client.rpc(
      'accept_current_legal',
      params: {
        'terms': consent.termsVersion,
        'privacy': consent.privacyVersion,
        'adult': true,
      },
    );
  }
}
