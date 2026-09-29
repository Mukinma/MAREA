import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRepository {
  Future<bool> isUsernameAvailable(String username);
  Future<Profile> getCurrentProfile();
  Future<Profile> completeInitialProfile(InitialProfileInput input);
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input);
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppFailure(
        'Tu sesión ya no es válida. Inicia sesión nuevamente.',
      );
    }
    return id;
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final available = await _client.rpc<bool>(
        'is_username_available',
        params: {'candidate': username},
      );
      return available;
    } catch (error) {
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<Profile> getCurrentProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', _currentUserId)
          .single();
      return Profile.fromJson(row);
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<Profile> completeInitialProfile(InitialProfileInput input) async {
    try {
      final error = input.validate();
      if (error != null) throw AppFailure(error);
      final row = await _client.rpc(
        'complete_initial_profile',
        params: input.toJson(),
      );
      return Profile.fromJson(Map<String, dynamic>.from(row as Map));
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<Profile> updateCurrentProfile(ProfileUpdateInput input) async {
    try {
      final row = await _client
          .from('profiles')
          .update(input.toJson())
          .eq('id', _currentUserId)
          .select()
          .single();
      return Profile.fromJson(row);
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw AppFailureMapper.from(error);
    }
  }
}
