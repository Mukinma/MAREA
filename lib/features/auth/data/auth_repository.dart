import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SignUpOutcome { authenticated, confirmationRequired }

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.recovery = false,
  });

  final String id;
  final String? email;
  final bool recovery;
}

abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Stream<AuthUser?> get authStateChanges;

  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    UserType userType = UserType.general,
    LegalConsent? consent,
  });

  Future<void> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> clearLocalSession();
  Future<void> deleteAccount();
  Future<void> resendConfirmation(String email);
  Future<void> requestRecovery(String email);
  Future<void> verifyCode({
    required String email,
    required String code,
    required bool recovery,
  });
  Future<void> changePassword(
    String password, {
    String? currentPassword,
    String? nonce,
  });
  Future<void> changeEmail(String email, String currentPassword);
  Future<void> requestReauthentication();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges => _client.auth.onAuthStateChange.map(
    (state) => state.session == null
        ? null
        : AuthUser(
            id: state.session!.user.id,
            email: state.session!.user.email,
            recovery: state.event == AuthChangeEvent.passwordRecovery,
          ),
  );

  @override
  Future<SignUpOutcome> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    UserType userType = UserType.general,
    LegalConsent? consent,
  }) async {
    try {
      if (consent == null) {
        throw const AppFailure(
          'Debes aceptar los términos y confirmar que tienes 18 años o más.',
        );
      }
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName.trim(),
          'username': username,
          'user_type': userType.databaseValue,
          'registration_flow': 'minimal-v1',
          ...consent.toMetadata(),
        },
      );
      // Supabase masks repeated signups for confirmed accounts with a fake
      // user whose identities are empty. No confirmation email is sent.
      if (response.session == null &&
          response.user?.identities?.isEmpty == true) {
        throw const AppFailure(
          'No pudimos completar este registro. Si ya tienes una cuenta, inicia sesión o recupera tu contraseña',
          kind: AppFailureKind.emailAlreadyUsed,
        );
      }
      return response.session == null
          ? SignUpOutcome.confirmationRequired
          : SignUpOutcome.authenticated;
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (error) {
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<void> clearLocalSession() =>
      _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> deleteAccount() async {
    try {
      final response = await _client.functions.invoke(
        'delete-account',
        method: HttpMethod.post,
      );
      if (response.status < 200 || response.status >= 300) {
        throw const AppFailure(
          'No pudimos eliminar tu cuenta. Inténtalo nuevamente.',
        );
      }
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw AppFailureMapper.from(error);
    }
  }

  static AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }

  @override
  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  @override
  Future<void> requestRecovery(String email) =>
      _client.auth.resetPasswordForEmail(email.trim());
  @override
  Future<void> verifyCode({
    required String email,
    required String code,
    required bool recovery,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: recovery ? OtpType.recovery : OtpType.email,
    );
  }

  @override
  Future<void> changePassword(
    String password, {
    String? currentPassword,
    String? nonce,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(
        password: password,
        currentPassword: currentPassword,
        nonce: nonce?.isEmpty == true ? null : nonce,
      ),
    );
  }

  @override
  Future<void> changeEmail(String email, String currentPassword) async {
    final currentEmail = _client.auth.currentUser?.email;
    if (currentEmail == null) {
      throw const AppFailure('Inicia sesión nuevamente.');
    }
    await _client.auth.signInWithPassword(
      email: currentEmail,
      password: currentPassword,
    );
    await _client.auth.updateUser(UserAttributes(email: email.trim()));
  }

  @override
  Future<void> requestReauthentication() => _client.auth.reauthenticate();
}
