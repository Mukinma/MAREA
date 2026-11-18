import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/auth/data/auth_repository.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/shared/widgets/session_feedback.dart';
import 'package:qr/qr.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  List<AuthenticatorFactor> _factors = [];
  bool _loading = false;
  bool _operating = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.supportsAccountSecurity) _loadFactors();
  }

  Future<void> _loadFactors() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final factors = await widget.controller.authenticatorFactors();
      if (!mounted) return;
      setState(() {
        _factors = factors;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_operating || widget.controller.isBusy) return;
    setState(() => _operating = true);
    widget.controller.clearFeedback();
    try {
      await action();
    } finally {
      if (mounted) setState(() => _operating = false);
    }
  }

  Future<void> _enroll() => _run(() async {
    final enrollment = await widget.controller.enrollAuthenticator();
    if (!mounted || enrollment == null) return;
    final added = await showMareaBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) => _AuthenticatorSheet(
        controller: widget.controller,
        enrollment: enrollment,
      ),
    );
    if (!mounted) return;
    if (added == true) {
      await _loadFactors();
    } else {
      widget.controller.clearFeedback();
    }
  });

  Future<void> _remove(AuthenticatorFactor factor) => _run(() async {
    final removed = await showMareaBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) => _AuthenticatorSheet(
        controller: widget.controller,
        remove: factor,
        factors: _factors,
      ),
    );
    if (!mounted) return;
    if (removed == true) {
      await _loadFactors();
    } else {
      widget.controller.clearFeedback();
    }
  });

  Future<void> _closeOthers() => _run(() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.tr('¿Cerrar otras sesiones?')),
        scrollable: true,
        content: Text(
          AppLocalizations.tr(
            'Cerrarás el acceso en los demás dispositivos. La sesión en este dispositivo seguirá abierta.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.tr('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.tr('Cerrar otras sesiones')),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) {
      await widget.controller.signOutOtherSessions();
    }
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final available = widget.controller.supportsAccountSecurity;
      final busy = _operating || _loading || widget.controller.isBusy;
      return ProfilePage(
        title: AppLocalizations.tr('Seguridad y sesiones'),
        fallback: '/settings',
        busy: _loading || widget.controller.isBusy,
        body: SingleChildScrollView(
          child: ProfilePageFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.lg,
              children: [
                if (!available)
                  ProfileFormSection(
                    children: [
                      Text(
                        AppLocalizations.tr(
                          'Los controles de seguridad no están disponibles.',
                        ),
                      ),
                    ],
                  )
                else ...[
                  ProfileFormSection(
                    title: AppLocalizations.tr('Verificación en dos pasos'),
                    icon: Icons.verified_user_outlined,
                    children: [
                      Text(
                        AppLocalizations.tr(
                          'Protege tu cuenta con un código de tu app autenticadora al iniciar sesión.',
                        ),
                      ),
                      if (_loaded) ...[
                        Text(
                          _factors.isEmpty
                              ? AppLocalizations.tr('Desactivada')
                              : AppLocalizations.tr('Activada'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        for (final factor in _factors)
                          ProfileMenuRow(
                            icon: Icons.phonelink_lock_outlined,
                            title: AppLocalizations.tr(factor.name),
                            subtitle: AppLocalizations.tr(
                              'Quitar autenticador',
                            ),
                            onTap: busy ? null : () => _remove(factor),
                          ),
                        if (_factors.length < 2)
                          FilledButton(
                            onPressed: busy ? null : _enroll,
                            child: Text(
                              _factors.isEmpty
                                  ? AppLocalizations.tr('Activar verificación')
                                  : AppLocalizations.tr(
                                      'Agregar autenticador de respaldo',
                                    ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ] else if (!_loading) ...[
                        Text(
                          AppLocalizations.tr(
                            'No pudimos consultar tus autenticadores.',
                          ),
                        ),
                        OutlinedButton(
                          onPressed: busy ? null : _loadFactors,
                          child: Text(AppLocalizations.tr('Reintentar')),
                        ),
                      ],
                    ],
                  ),
                  ProfileFormSection(
                    title: AppLocalizations.tr(
                      'Sesiones en otros dispositivos',
                    ),
                    icon: Icons.devices_outlined,
                    children: [
                      Text(
                        AppLocalizations.tr(
                          'Revoca el acceso de los demás dispositivos donde tengas una sesión abierta.',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : _closeOthers,
                        child: Text(
                          AppLocalizations.tr('Cerrar otras sesiones'),
                        ),
                      ),
                    ],
                  ),
                  if (!_operating)
                    SessionFeedback(controller: widget.controller),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

class MfaChallengeScreen extends StatefulWidget {
  const MfaChallengeScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _code = TextEditingController();
  List<AuthenticatorFactor> _factors = [];
  String? _selected;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.controller.securityCheckFailed) _loadFactors();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadFactors() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final factors = await widget.controller.authenticatorFactors();
      if (!mounted) return;
      setState(() {
        _factors = factors;
        _selected = factors.firstOrNull?.id;
        if (factors.isEmpty) {
          _error = AppLocalizations.tr(
            'No encontramos un autenticador para esta cuenta.',
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.tr(
            'No pudimos consultar tus autenticadores.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retryCheck() async {
    final controller = widget.controller;
    await controller.recheckAppSession();
    if (mounted && controller.needsMfa && !controller.securityCheckFailed) {
      await _loadFactors();
    }
  }

  Future<void> _verify() async {
    final id = _selected;
    if (id == null || _code.text.length != 6 || widget.controller.isBusy) {
      return;
    }
    FocusScope.of(context).unfocus();
    await widget.controller.verifyAuthenticator(id, _code.text);
  }

  Future<void> _support(String email) async {
    try {
      if (await launchUrl(Uri(scheme: 'mailto', path: email))) return;
    } catch (_) {
      // The address can still be copied by selecting it.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Escríbenos a $email.')));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final retrySession = controller.securityCheckFailed;
      final busy = _loading || controller.isBusy;
      final email = controller.legalPolicy.supportEmail?.trim() ?? '';
      return ProfilePage(
        title: AppLocalizations.tr('Verificación en dos pasos'),
        onBack: () {
          if (!busy) controller.signOut();
        },
        busy: busy,
        body: SingleChildScrollView(
          child: ProfilePageFrame(
            child: ProfileFormSection(
              children: [
                if (retrySession) ...[
                  Text(
                    AppLocalizations.tr(
                      'No pudimos comprobar tu sesión. Vuelve a intentarlo.',
                    ),
                  ),
                  FilledButton(
                    onPressed: busy ? null : _retryCheck,
                    child: Text(AppLocalizations.tr('Reintentar')),
                  ),
                ] else ...[
                  Text(
                    AppLocalizations.tr(
                      'Ingresa el código que aparece en tu app autenticadora.',
                    ),
                  ),
                  if (_error case final error?) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : _loadFactors,
                      child: Text(AppLocalizations.tr('Reintentar')),
                    ),
                  ],
                  if (_factors.length > 1)
                    _FactorChoices(
                      factors: _factors,
                      selected: _selected,
                      onSelect: busy
                          ? null
                          : (id) => setState(() => _selected = id),
                    ),
                  if (_selected != null)
                    _AuthenticatorCodeField(
                      controller: _code,
                      enabled: !busy,
                      onChanged: () => setState(() {}),
                      onSubmitted: _verify,
                    ),
                ],
                SessionFeedback(controller: controller),
                if (email.isNotEmpty)
                  TextButton(
                    onPressed: () => _support(email),
                    child: Text(
                      AppLocalizations.tr('Perdí acceso a mi autenticador'),
                    ),
                  ),
                TextButton(
                  onPressed: busy ? null : controller.signOut,
                  child: Text(AppLocalizations.tr('Cerrar sesión')),
                ),
              ],
            ),
          ),
        ),
        action: retrySession || _selected == null
            ? null
            : FilledButton(
                onPressed: busy || _code.text.length != 6 ? null : _verify,
                child: Text(AppLocalizations.tr('Verificar')),
              ),
      );
    },
  );
}

class _AuthenticatorSheet extends StatefulWidget {
  const _AuthenticatorSheet({
    required this.controller,
    this.enrollment,
    this.remove,
    this.factors = const [],
  });

  final AppSessionController controller;
  final AuthenticatorEnrollment? enrollment;
  final AuthenticatorFactor? remove;
  final List<AuthenticatorFactor> factors;

  @override
  State<_AuthenticatorSheet> createState() => _AuthenticatorSheetState();
}

class _AuthenticatorSheetState extends State<_AuthenticatorSheet> {
  final _code = TextEditingController();
  late String? _verificationFactor = widget.remove?.id;
  bool _revealSecret = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.length != 6 || widget.controller.isBusy) return;
    FocusScope.of(context).unfocus();
    final enrollment = widget.enrollment;
    final success = enrollment != null
        ? await widget.controller.verifyAuthenticator(enrollment.id, _code.text)
        : await widget.controller.removeAuthenticator(
            widget.remove!.id,
            _code.text,
            verificationFactorId: _verificationFactor,
          );
    if (mounted && success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final busy = widget.controller.isBusy;
      final enrollment = widget.enrollment;
      return PopScope(
        canPop: !busy,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ProfileSheetContent(
            title: enrollment == null
                ? AppLocalizations.tr('Quitar autenticador')
                : AppLocalizations.tr('Configurar autenticador'),
            children: [
              if (enrollment != null) ...[
                Text(
                  AppLocalizations.tr(
                    'Escanea el QR con tu app autenticadora o agrega la clave manual. Después escribe el código de seis dígitos.',
                  ),
                ),
                Text(
                  AppLocalizations.tr(
                    'Al activar este autenticador se cerrarán las sesiones en otros dispositivos.',
                  ),
                ),
                Center(child: _EnrollmentQr(uri: enrollment.uri)),
                if (_revealSecret)
                  SelectableText(
                    enrollment.secret,
                    textAlign: TextAlign.center,
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _revealSecret = !_revealSecret),
                      child: Text(
                        _revealSecret
                            ? AppLocalizations.tr('Ocultar clave')
                            : AppLocalizations.tr('Mostrar clave manual'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Clipboard.setData(
                        ClipboardData(text: enrollment.secret),
                      ),
                      icon: const Icon(Icons.copy_outlined),
                      label: Text(AppLocalizations.tr('Copiar clave')),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  widget.factors.length == 1
                      ? AppLocalizations.tr(
                          'Al quitar el último autenticador se desactivará la verificación en dos pasos.',
                        )
                      : AppLocalizations.tr(
                          'Confirma la acción con el código de un autenticador activo.',
                        ),
                ),
                if (widget.factors.length > 1)
                  _FactorChoices(
                    factors: widget.factors,
                    selected: _verificationFactor,
                    onSelect: busy
                        ? null
                        : (id) => setState(() => _verificationFactor = id),
                  ),
              ],
              _AuthenticatorCodeField(
                controller: _code,
                enabled: !busy,
                onChanged: () => setState(() {}),
                onSubmitted: _submit,
              ),
              SessionFeedback(controller: widget.controller),
              FilledButton(
                onPressed: busy || _code.text.length != 6 ? null : _submit,
                child: Text(
                  enrollment == null
                      ? AppLocalizations.tr('Confirmar retiro')
                      : AppLocalizations.tr('Verificar y activar'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: Text(AppLocalizations.tr('Cancelar')),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AuthenticatorCodeField extends StatelessWidget {
  const _AuthenticatorCodeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged, onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    onChanged: (_) => onChanged(),
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      labelText: AppLocalizations.tr('Código de autenticación'),
    ),
  );
}

class _FactorChoices extends StatelessWidget {
  const _FactorChoices({
    required this.factors,
    required this.selected,
    required this.onSelect,
  });

  final List<AuthenticatorFactor> factors;
  final String? selected;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final factor in factors)
        ChoiceChip(
          label: Text(AppLocalizations.tr(factor.name)),
          selected: selected == factor.id,
          onSelected: onSelect == null ? null : (_) => onSelect!(factor.id),
        ),
    ],
  );
}

class _EnrollmentQr extends StatelessWidget {
  const _EnrollmentQr({required this.uri});

  final String uri;

  @override
  Widget build(BuildContext context) {
    try {
      final qr = QrImage(
        QrCode.fromData(data: uri, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
      return Semantics(
        image: true,
        label: AppLocalizations.tr('Código QR para configurar tu autenticador'),
        child: CustomPaint(
          size: const Size.square(176),
          painter: _QrPainter(qr),
        ),
      );
    } catch (_) {
      return Text(
        AppLocalizations.tr(
          'Usa la clave manual para configurar el autenticador.',
        ),
      );
    }
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.qr);

  final QrImage qr;

  @override
  void paint(Canvas canvas, Size size) {
    const quietZone = 4;
    final modules = qr.moduleCount;
    final step = size.shortestSide / (modules + quietZone * 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final marks = Path();
    for (var row = 0; row < modules; row++) {
      for (var col = 0; col < modules; col++) {
        if (!qr.isDark(row, col)) continue;
        marks.addRect(
          Rect.fromLTWH(
            (col + quietZone) * step,
            (row + quietZone) * step,
            step,
            step,
          ),
        );
      }
    }
    canvas.drawPath(
      marks,
      Paint()
        ..color = Colors.black
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.qr != qr;
}
