import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/features/community/data/community_reports_repository.dart';
import 'package:marea/features/community/models/report_receipt.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_refresh_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({required this.controller, super.key});

  final AppSessionController controller;

  Future<void> _contact(BuildContext context, String email) async {
    try {
      if (await launchUrl(Uri(scheme: 'mailto', path: email))) return;
    } catch (_) {
      // Copying the address still works if a mail app is unavailable.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.tr('No pudimos abrir tu app de correo.'),
        ),
        action: SnackBarAction(
          label: AppLocalizations.tr('Copiar correo'),
          onPressed: () => Clipboard.setData(ClipboardData(text: email)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final email = controller.legalPolicy.supportEmail?.trim() ?? '';
      return ProfilePage(
        title: AppLocalizations.tr('Ayuda y reportes'),
        fallback: '/settings',
        body: SingleChildScrollView(
          child: ProfilePageFrame(
            child: ProfileMenuSection(
              children: [
                ProfileMenuRow(
                  icon: Icons.mail_outline_rounded,
                  title: AppLocalizations.tr('Contactar a soporte'),
                  subtitle: email.isEmpty
                      ? AppLocalizations.tr('Correo de soporte no disponible')
                      : email,
                  onTap: email.isEmpty ? null : () => _contact(context, email),
                ),
                ProfileMenuRow(
                  icon: Icons.flag_outlined,
                  title: AppLocalizations.tr('Mis reportes'),
                  subtitle: AppLocalizations.tr(
                    'Consulta los reportes que enviaste',
                  ),
                  onTap: () => context.push('/settings/support/reports'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({required this.controller, super.key});

  final AppSessionController controller;

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  final _receipts = <ReportReceipt>[];
  bool _busy = false, _more = false;
  String? _error;
  late final _accountId = widget.controller.profile?.id;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({required bool reset}) async {
    if (_busy) return;
    final repository = widget.controller.communityRepository;
    if (repository is! CommunityReportsRepository) {
      _error = AppLocalizations.tr('Los reportes no están disponibles.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final batch = await (repository as CommunityReportsRepository).myReports(
        offset: reset ? 0 : _receipts.length,
      );
      if (!mounted || widget.controller.profile?.id != _accountId) return;
      setState(() {
        if (reset) _receipts.clear();
        _receipts.addAll(batch);
        _more = batch.length == CommunityReportsRepository.pageSize;
      });
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: AppLocalizations.tr('Mis reportes'),
    fallback: '/settings/support',
    busy: _busy,
    body: MareaRefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ProfilePageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (_receipts.isNotEmpty)
                ProfileMenuSection(
                  children: [
                    for (final receipt in _receipts)
                      ProfileMenuRow(
                        icon: Icons.flag_outlined,
                        title: AppLocalizations.tr(receipt.target.label),
                        subtitle: [
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(receipt.createdAt.toLocal()),
                          receipt.reviewed
                              ? 'Revisado'
                              : AppLocalizations.tr('Recibido'),
                          if (receipt.targetUnavailable)
                            AppLocalizations.tr('Contenido no disponible'),
                        ].join(' · '),
                        onTap: null,
                      ),
                  ],
                ),
              if (_receipts.isEmpty && !_busy && _error == null)
                ProfileFormSection(
                  children: [
                    Text(AppLocalizations.tr('Aún no has enviado reportes.')),
                  ],
                ),
              if (_error case final error?)
                ProfileFormSection(
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _load(reset: _receipts.isEmpty),
                      child: Text(AppLocalizations.tr('Reintentar')),
                    ),
                  ],
                ),
              if (_more && _error == null)
                OutlinedButton(
                  onPressed: _busy ? null : () => _load(reset: false),
                  child: Text(AppLocalizations.tr('Cargar más reportes')),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
