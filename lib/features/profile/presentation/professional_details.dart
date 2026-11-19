import 'package:flutter/material.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalDetails extends StatelessWidget {
  const ProfessionalDetails({required this.profile, super.key});
  final CommunityProfile profile;

  Uri? _link(String? value) =>
      value == null ||
          value.trim().isEmpty ||
          ProfilePreferences.websiteError(value) != null
      ? null
      : Uri.tryParse(value.trim());

  bool get _hasHours =>
      profile.userType == UserType.business && profile.businessHours.isNotEmpty;
  bool get _available =>
      profile.userType == UserType.creator && profile.openToCollaboration;

  bool get hasContent =>
      _hasHours ||
      _available ||
      _link(profile.website) != null ||
      _link(profile.contactUrl) != null;

  @override
  Widget build(BuildContext context) {
    final website = _link(profile.website);
    final contact = _link(profile.contactUrl);
    final rows = <Widget>[
      if (website != null)
        _linkRow(context, website, 'Sitio web', Icons.link_rounded),
      if (contact != null && contact != website)
        _linkRow(context, contact, 'Contactar', Icons.mail_outline_rounded),
      if (_hasHours)
        ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          minTileHeight: 48,
          iconColor: AppColors.brandNavy,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(AppLocalizations.tr('Horarios'), style: _rowStyle),
          leading: const Icon(Icons.schedule_outlined, size: 19),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                AppLocalizations.tr('Hora local del negocio'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            for (final entry in ProfilePreferences.weekdays.entries)
              if (profile.businessHours.containsKey(entry.key))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(child: Text(AppLocalizations.tr(entry.value))),
                      Flexible(
                        child: Text(
                          profile.businessHours[entry.key] ??
                              AppLocalizations.tr('Cerrado'),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      if (_available)
        ListTile(
          minTileHeight: 48,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.handshake_outlined, size: 19),
          title: Text(
            AppLocalizations.tr('Disponible para colaborar'),
            style: _rowStyle,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const Divider(height: 1, indent: 16, endIndent: 16),
          row,
        ],
      ],
    );
  }

  static const _rowStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.brandNavy,
  );

  ListTile _linkRow(
    BuildContext context,
    Uri uri,
    String label,
    IconData icon,
  ) => ListTile(
    minTileHeight: 48,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Icon(icon, size: 19, color: AppColors.brandNavy),
    title: Text(AppLocalizations.tr(label), style: _rowStyle),
    trailing: const Icon(
      Icons.north_east_rounded,
      size: 16,
      color: AppColors.textSecondary,
    ),
    onTap: () => runCommunityAction(context, () async {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('link unavailable');
      }
    }),
  );
}
