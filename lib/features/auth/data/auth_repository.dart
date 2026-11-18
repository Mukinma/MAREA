import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Future<void> signInWithGoogle({required String redirectTo});
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

class AuthenticatorFactor {
  const AuthenticatorFactor({required this.id, required this.name});

  final String id, name;
}

class AuthenticatorEnrollment {
  const AuthenticatorEnrollment({
    required this.id,
    required this.uri,
    required this.secret,
  });

  final String id, uri, secret;
}

abstract interface class AuthSecurityRepository {
  Future<void> requireAppSession();
  Future<bool> restoreRecoveryIntent();
  Future<void> rememberRecoveryIntent(bool value);
  Future<List<AuthenticatorFactor>> authenticatorFactors();
  Future<AuthenticatorEnrollment> enrollAuthenticator();
  Future<void> verifyAuthenticator(String id, String code);
  Future<void> removeAuthenticator(String id);
  Future<void> signOutOtherSessions();
}

class SupabaseAuthRepository implements AuthRepository, AuthSecurityRepository {
  SupabaseAuthRepository(
    this._client, {
    this.allowGoogleOAuth = true,
    String googleWebClientId = const String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
    ),
  }) : _googleWebClientId = googleWebClientId.trim();

  static const _googleAccountChannel = MethodChannel('marea/google-sign-in');
  final SupabaseClient _client;
  final bool allowGoogleOAuth;
  final String _googleWebClientId;

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
  Future<void> signInWithGoogle({required String redirectTo}) async {
    if (!allowGoogleOAuth) {
      throw const AppFailure(
        'Este piloto utiliza las cuentas de prueba por correo.',
      );
    }
    try {
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          _googleWebClientId.isNotEmpty &&
          await _signInWithAndroidGoogle()) {
        return;
      }
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: const {'prompt': 'select_account'},
      );
      if (!launched) {
        throw const AppFailure('No pudimos abrir Google. Intenta de nuevo.');
      }
    } on AppFailure {
      rethrow;
    } catch (error) {
      throw AppFailureMapper.from(error);
    }
  }

  Future<bool> _signInWithAndroidGoogle() async {
    final nonce = _client.auth.generateRawNonce();
    final String? token;
    try {
      token = await _googleAccountChannel.invokeMethod<String>(
        'chooseAccount',
        {'serverClientId': _googleWebClientId, 'nonce': nonce},
      );
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (error.code == 'unavailable') return false;
      throw const AppFailure('No pudimos abrir Google. Intenta de nuevo.');
    }
    if (token != null) {
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: token,
        nonce: nonce,
      );
    }
    return true;
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
    final session = _client.auth.currentSession;
    final originalId = _sessionId;
    final user = session?.user;
    final currentEmail = user?.email;
    final key = _client.auth.headers['apikey'];
    if (user == null ||
        currentEmail == null ||
        originalId == null ||
        key == null) {
      throw const AppFailure('Inicia sesión nuevamente.');
    }
    // The temporary password grant stays outside GoTrue's session storage and
    // web broadcast channel, so it cannot replace the verified app session.
    final restUrl = Uri.parse(_client.rest.url);
    final authUrl = restUrl.replace(
      path: restUrl.path.replaceFirst(RegExp(r'/rest/v1/?$'), '/auth/v1/'),
    );
    final response = await http
        .post(
          authUrl.resolve('token?grant_type=password'),
          headers: {'apikey': key, 'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': currentEmail,
            'password': currentPassword,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const AppFailure('La contraseña actual no es correcta.');
    }
    if (response.statusCode == 429) {
      throw const AppFailure('Espera un momento antes de volver a intentarlo.');
    }
    if (response.statusCode != 200) {
      throw const AppFailure('No pudimos comprobar tu contraseña. Reintenta.');
    }
    final temporary = jsonDecode(response.body) as Map<String, dynamic>;
    final token = temporary['access_token'] as String?;
    if (token == null) {
      throw const AppFailure('No pudimos comprobar tu contraseña. Reintenta.');
    }
    final revoked = await http
        .post(
          authUrl.resolve('logout?scope=local'),
          headers: {'apikey': key, 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (revoked.statusCode != 204 ||
        (temporary['user'] as Map?)?['id'] != user.id) {
      throw const AppFailure('No pudimos comprobar tu contraseña. Reintenta.');
    }
    if (_sessionId != originalId) {
      throw const AppFailure('Tu sesión cambió. Vuelve a abrir esta pantalla.');
    }
    await _client.auth.updateUser(UserAttributes(email: email.trim()));
  }

  @override
  Future<void> requestReauthentication() => _client.auth.reauthenticate();

  String? get _sessionId {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return null;
    final payload =
        jsonDecode(
              utf8.decode(
                base64Url.decode(base64Url.normalize(token.split('.')[1])),
              ),
            )
            as Map<String, dynamic>;
    return payload['session_id'] as String?;
  }

  String get _recoveryIntentKey {
    final host = Uri.parse(_client.rest.url).host;
    return 'marea.recovery-session.$host';
  }

  @override
  Future<bool> restoreRecoveryIntent() async {
    final session = _sessionId;
    if (session == null) return false;
    return (await SharedPreferences.getInstance()).getString(
          _recoveryIntentKey,
        ) ==
        session;
  }

  @override
  Future<void> rememberRecoveryIntent(bool value) async {
    final session = _sessionId;
    final preferences = await SharedPreferences.getInstance();
    if (value && session != null && _sessionId == session) {
      await preferences.setString(_recoveryIntentKey, session);
    } else if (preferences.getString(_recoveryIntentKey) == session) {
      await preferences.remove(_recoveryIntentKey);
    }
  }

  @override
  Future<void> requireAppSession() async {
    await _client
        .rpc('require_app_session')
        .timeout(const Duration(seconds: 12));
  }

  @override
  Future<List<AuthenticatorFactor>> authenticatorFactors() async {
    final response = await _client.auth.getUser();
    final factors = response.user?.factors ?? [];
    return [
      for (final factor in factors)
        if (factor.factorType == FactorType.totp &&
            factor.status == FactorStatus.verified)
          AuthenticatorFactor(
            id: factor.id,
            name: factor.friendlyName?.trim().isNotEmpty == true
                ? factor.friendlyName!
                : 'App autenticadora',
          ),
    ];
  }

  @override
  Future<AuthenticatorEnrollment> enrollAuthenticator() async {
    await requireAppSession();
    final current = await _client.auth.getUser();
    final factors = (current.user?.factors ?? [])
        .where((factor) => factor.factorType == FactorType.totp)
        .toList();
    final verified = factors
        .where((factor) => factor.status == FactorStatus.verified)
        .toList();
    if (verified.length >= 2) {
      throw const AppFailure('Ya tienes dos autenticadores activos.');
    }
    // Supabase retains pending enrollments after an interrupted visit.
    for (final factor in factors) {
      if (factor.status == FactorStatus.unverified) {
        await _client.auth.mfa.unenroll(factor.id);
      }
    }
    const primary = 'Autenticador principal';
    final response = await _client.auth.mfa.enroll(
      issuer: 'MAREA',
      friendlyName: verified.any((factor) => factor.friendlyName == primary)
          ? 'Autenticador de respaldo'
          : primary,
    );
    final totp = response.totp!;
    return AuthenticatorEnrollment(
      id: response.id,
      uri: totp.uri,
      secret: totp.secret,
    );
  }

  @override
  Future<void> verifyAuthenticator(String id, String code) async {
    await _client.auth.mfa.challengeAndVerify(factorId: id, code: code);
  }

  @override
  Future<void> removeAuthenticator(String id) async {
    await _client.auth.mfa.unenroll(id);
    await _client.auth.refreshSession();
  }

  @override
  Future<void> signOutOtherSessions() async {
    await requireAppSession();
    await _client.auth.signOut(scope: SignOutScope.others);
    await requireAppSession();
  }
}
