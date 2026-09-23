import 'dart:async';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/legal/legal_policy.dart';
import 'package:marea/features/legal/legal_repository.dart';
import 'package:marea/features/profile/data/profile_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    LegalRepository? legalRepository,
    this.mediaRepository,
    this.communityRepository,
  }) : _auth = authRepository,
       _profiles = profileRepository,
       _legal = legalRepository;
  final CommunityRepository? communityRepository;
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final LegalRepository? _legal;
  final ProfileMediaRepository? mediaRepository;
  StreamSubscription<AuthUser?>? _subscription;
  AuthStatus _status = AuthStatus.initializing;
  Profile? _profile;
  bool _busy = false,
      _refreshing = false,
      _disposed = false,
      _recovering = false,
      _needsLegal = false;
  int _generation = 0;
  int _profileRevision = 0;
  AppFailure? _failure;
  String? _success;
  Timer? _successTimer;
  int _successRevision = 0;
  LegalPolicy _policy = const LegalPolicy.unavailable();
  String? _legalError;
  final Map<String, DateTime> _emailCooldowns = {};
  AuthStatus get status => _status;
  Profile? get profile => _profile;
  bool get isBusy => _busy;
  bool get isRecovering => _recovering;
  bool get needsLegalAcceptance => _needsLegal;
  bool get needsOnboarding =>
      _profile?.onboardingStatus == OnboardingStatus.pending;
  AppFailure? get failure => _failure;
  String? get successMessage => _success;
  String? get email => _auth.currentUser?.email;
  LegalPolicy get legalPolicy => _policy;
  String? get legalError => _legalError;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    _subscription ??= _auth.authStateChanges.listen((user) {
      if (user == null) {
        _unauthenticated();
        return;
      }
      if (user.recovery) _recovering = true;
      if (!_busy) unawaited(_loadAuthenticated());
    });
    await reloadLegal();
    if (_auth.currentUser == null) {
      _unauthenticated();
    } else {
      await _loadAuthenticated();
    }
  }

  Future<void> reloadLegal() async {
    try {
      _policy = await _legal?.loadPolicy() ?? const LegalPolicy.unavailable();
      _legalError = null;
      if (_auth.currentUser != null && _policy.hasDocuments) {
        _needsLegal = !(await _legal!.hasAccepted(_policy));
      }
    } catch (_) {
      _policy = const LegalPolicy.unavailable();
      _legalError =
          'No pudimos cargar los documentos. Puedes reintentar; no crearemos una cuenta sin ellos.';
    }
    _notify();
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    if (_busy || _disposed) return null;
    _busy = true;
    _failure = null;
    _successTimer?.cancel();
    _successTimer = null;
    ++_successRevision;
    _success = null;
    _notify();
    try {
      return await action();
    } catch (error) {
      _failure = error is AppFailure ? error : AppFailureMapper.from(error);
      return null;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async =>
      await _run(() async {
        _recovering = false;
        await _auth.signIn(email: email.trim(), password: password);
        await _loadAuthenticated();
        return true;
      }) ??
      false;
  Future<SignUpOutcome?> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    LegalConsent? consent,
  }) => _run(() async {
    if (!_policy.canRegister) {
      throw const AppFailure(
        'El registro aún no está disponible. Faltan los documentos legales publicados de MAREA.',
      );
    }
    if (consent == null ||
        consent.termsVersion != _policy.terms!.version ||
        consent.privacyVersion != _policy.privacy!.version) {
      throw const AppFailure(
        'Acepta los términos vigentes y confirma que tienes 18 años o más.',
      );
    }
    if (!await _profiles.isUsernameAvailable(username)) {
      throw const AppFailure('Este nombre de usuario ya está ocupado.');
    }
    final outcome = await _auth.signUp(
      fullName: fullName.trim(),
      username: username,
      email: email.trim(),
      password: password,
      consent: consent,
    );
    if (outcome == SignUpOutcome.authenticated) {
      await _loadAuthenticated();
      _showSuccess('¡Tu lugar en MAREA está listo!');
    } else {
      _emailCooldowns['false:${email.trim().toLowerCase()}'] = DateTime.now()
          .add(const Duration(seconds: 60));
    }
    return outcome;
  });
  Future<bool> isUsernameAvailable(String username) =>
      _profiles.isUsernameAvailable(username);
  Future<bool> updateProfile(ProfileUpdateInput input) async =>
      await _run(() async {
        final before = _profile;
        if (before == null) {
          throw const AppFailure(
            'No pudimos cargar tu perfil. Vuelve a intentarlo.',
          );
        }
        final error = ProfilePreferences.websiteError(input.website);
        if (error != null) throw AppFailure(error);
        if (input.username != before.username &&
            !await _profiles.isUsernameAvailable(input.username)) {
          throw const AppFailure('Este nombre de usuario ya está ocupado.');
        }
        final generation = _generation;
        ++_profileRevision;
        final updated = await _profiles.updateCurrentProfile(input);
        if (generation != _generation || _auth.currentUser == null) {
          return false;
        }
        _profile = updated;
        _showSuccess('Perfil actualizado.');
        return true;
      }) ??
      false;
  Future<bool> finishOnboarding({
    required bool skip,
    required List<String> interests,
    required List<String> goals,
  }) async {
    final current = _profile;
    if (current == null) return false;
    return updateProfile(
      current
          .copyWith(
            interests: skip ? current.interests : interests,
            goals: skip ? current.goals : goals,
            onboardingStatus: skip
                ? OnboardingStatus.skipped
                : OnboardingStatus.completed,
          )
          .updateInput,
    );
  }

  Future<bool> acceptLegal(LegalConsent consent) async =>
      await _run(() async {
        if (_legal == null) {
          throw const AppFailure(
            'No se pudieron cargar los documentos legales.',
          );
        }
        await _legal.accept(consent);
        _needsLegal = false;
        return true;
      }) ??
      false;
  Future<bool> signOut() async =>
      await _run(() async {
        ++_generation;
        await _auth.signOut();
        _unauthenticated();
        return true;
      }) ??
      false;
  Future<bool> deleteAccount() async =>
      await _run(() async {
        ++_generation;
        await _auth.deleteAccount();
        _unauthenticated();
        return true;
      }) ??
      false;
  int emailCooldown(String email, {required bool recovery}) {
    final until = _emailCooldowns['$recovery:${email.trim().toLowerCase()}'];
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(0, 60);
  }

  Future<bool> sendCode(String email, {required bool recovery}) async =>
      await _run(() async {
        if (emailCooldown(email, recovery: recovery) > 0) {
          throw const AppFailure(
            'Espera un momento antes de solicitar otro código.',
          );
        }
        final destination = email.trim();
        if (recovery) {
          await _auth.requestRecovery(destination);
        } else {
          await _auth.resendConfirmation(destination);
        }
        _emailCooldowns['$recovery:${destination.toLowerCase()}'] =
            DateTime.now().add(const Duration(seconds: 60));
        return true;
      }) ??
      false;
  Future<bool> verifyCode(
    String email,
    String code, {
    required bool recovery,
  }) async =>
      await _run(() async {
        _recovering = recovery;
        try {
          await _auth.verifyCode(email: email, code: code, recovery: recovery);
        } catch (_) {
          _recovering = false;
          rethrow;
        }
        await _loadAuthenticated();
        return true;
      }) ??
      false;
  Future<bool> changePassword(
    String password, {
    String? currentPassword,
    String? nonce,
  }) async =>
      await _run(() async {
        if (!_recovering &&
            (currentPassword == null || currentPassword.isEmpty)) {
          throw const AppFailure('Escribe tu contraseña actual.');
        }
        await _auth.changePassword(
          password,
          currentPassword: currentPassword,
          nonce: nonce,
        );
        _recovering = false;
        _showSuccess('Contraseña actualizada.');
        return true;
      }) ??
      false;
  Future<bool> changeEmail(String newEmail, String currentPassword) async =>
      await _run(() async {
        await _auth.changeEmail(newEmail, currentPassword);
        _showSuccess(
          'Revisa tu correo actual y el nuevo para confirmar el cambio. Tu correo no cambia hasta completarlo.',
        );
        return true;
      }) ??
      false;
  Future<bool> requestReauthentication() async =>
      await _run(() async {
        await _auth.requestReauthentication();
        _showSuccess('Revisa tu correo para obtener el código de seguridad.');
        return true;
      }) ??
      false;
  void clearFeedback() {
    _failure = null;
    _successTimer?.cancel();
    _successTimer = null;
    ++_successRevision;
    _success = null;
    _notify();
  }

  void _showSuccess(String message) {
    _successTimer?.cancel();
    final revision = ++_successRevision;
    _success = message;
    _successTimer = Timer(const Duration(seconds: 3), () {
      if (_disposed || revision != _successRevision) return;
      _success = null;
      _successTimer = null;
      _notify();
    });
  }

  Future<void> refresh() async {
    if (_busy || _refreshing || _disposed) return;
    _refreshing = true;
    try {
      await reloadLegal();
      await refreshProfile();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> refreshProfile() async {
    if (_status != AuthStatus.authenticated) return;
    final generation = _generation;
    final profileRevision = _profileRevision;
    try {
      final next = await _profiles.getCurrentProfile();
      if (generation != _generation ||
          profileRevision != _profileRevision ||
          _auth.currentUser == null) {
        return;
      }
      _profile = next;
      _failure = null;
    } catch (error) {
      if (generation == _generation) {
        final failure = error is AppFailure
            ? error
            : AppFailureMapper.from(error);
        _failure = failure;
        if (failure.kind == AppFailureKind.invalidSession) {
          await _clearInvalidSession(failure);
          return;
        }
      }
    }
    _notify();
  }

  Future<void> _loadAuthenticated() async {
    if (_auth.currentUser == null) {
      _unauthenticated();
      return;
    }
    final generation = ++_generation;
    try {
      final next = await _profiles.getCurrentProfile();
      final needsLegal = _policy.hasDocuments && _legal != null
          ? !await _legal.hasAccepted(_policy)
          : false;
      if (generation != _generation || _disposed || _auth.currentUser == null) {
        return;
      }
      _profile = next;
      _needsLegal = needsLegal;
      _failure = null;
    } catch (error) {
      if (generation != _generation || _disposed) return;
      _profile = null;
      final failure = error is AppFailure
          ? error
          : AppFailureMapper.from(error);
      _failure = failure;
      if (failure.kind == AppFailureKind.invalidSession) {
        await _clearInvalidSession(failure);
        return;
      }
    }
    _status = AuthStatus.authenticated;
    _notify();
  }

  Future<void> _clearInvalidSession(AppFailure failure) async {
    _failure = failure;
    try {
      await _auth.clearLocalSession();
    } catch (_) {
      // The in-memory session must still be invalidated even if local
      // persistence cannot be cleared by the platform SDK.
    }
    _unauthenticated();
  }

  void _unauthenticated() {
    ++_generation;
    _status = AuthStatus.unauthenticated;
    _profile = null;
    _recovering = false;
    _needsLegal = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _successTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
