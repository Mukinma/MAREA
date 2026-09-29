import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/models/profile.dart';

class ProfessionalDetails extends StatelessWidget {
  const ProfessionalDetails({
    required this.profile,
    this.showContact = true,
    super.key,
  });
  final CommunityProfile profile;
  final bool showContact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (profile.userType == UserType.creator && profile.openToCollaboration)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Disponible para colaborar',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      if (showContact &&
          profile.contactUrl != null &&
          ProfilePreferences.websiteError(profile.contactUrl) == null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: () => runCommunityAction(context, () async {
              if (!await launchUrl(
                Uri.parse(profile.contactUrl!),
                mode: LaunchMode.externalApplication,
              )) {
                throw StateError('link unavailable');
              }
            }),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Contactar'),
          ),
        ),
      if (profile.userType == UserType.business && profile.location != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: profile.locationLatitude == null
              ? Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Flexible(child: Text(profile.location!)),
                  ],
                )
              : TextButton.icon(
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(profile.location!),
                  onPressed: () => showPostLocationViewer(
                    context,
                    label: profile.location!,
                    coordinates: PostCoordinates(
                      latitude: profile.locationLatitude!,
                      longitude: profile.locationLongitude!,
                      precision: PostLocationPrecision.values.byName(
                        profile.locationPrecision ?? 'exact',
                      ),
                    ),
                  ),
                ),
        ),
      if (profile.userType == UserType.business &&
          profile.businessHours.isNotEmpty)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          title: const Text(
            'Horarios',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          leading: const Icon(Icons.schedule_outlined, size: 20),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hora local del negocio',
                style: TextStyle(fontSize: 12),
              ),
            ),
            for (final entry in ProfilePreferences.weekdays.entries)
              if (profile.businessHours.containsKey(entry.key))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(entry.value)),
                      Text(profile.businessHours[entry.key] ?? 'Cerrado'),
                    ],
                  ),
                ),
          ],
        ),
    ],
  );
}
