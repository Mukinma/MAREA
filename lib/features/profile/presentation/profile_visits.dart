import 'package:flutter/material.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/ar_markers/models/ar_marker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/tours/models/business_ar_target.dart';
import 'package:marea/features/tours/models/tour_models.dart';
import 'package:marea/shared/widgets/marea_panel.dart';

typedef _Visit = ({
  String title,
  String route,
  String? location,
  PostCoordinates? coordinates,
});

class ProfileVisits extends StatefulWidget {
  const ProfileVisits({
    required this.controller,
    required this.profileId,
    required this.onOpen,
    this.onManage,
    super.key,
  });

  final AppSessionController controller;
  final String profileId;
  final Future<void> Function(String route) onOpen;
  final VoidCallback? onManage;

  @override
  State<ProfileVisits> createState() => _ProfileVisitsState();
}

class _ProfileVisitsState extends State<ProfileVisits> {
  late Future<List<TourRecord>>? _tours = _loadTours();
  late Future<List<ArMarker>>? _markers = _loadMarkers();

  Future<List<TourRecord>>? _loadTours() =>
      widget.controller.tourRepository?.publicList(widget.profileId);

  Future<List<ArMarker>>? _loadMarkers() {
    final viewer = widget.controller.profile?.id;
    return viewer == null
        ? null
        : widget.controller.markerPublicationRepository?.publicForOwner(
            viewer,
            widget.profileId,
          );
  }

  Future<void> _choose(String label, List<_Visit> visits) async {
    if (visits.length == 1) {
      await _visit(visits.single.route);
      return;
    }
    final route = await showMareaBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(label, style: Theme.of(context).textTheme.titleLarge),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visits.length,
                itemBuilder: (context, index) {
                  final visit = visits[index];
                  return ListTile(
                    title: Text(visit.title),
                    subtitle: visit.location == null
                        ? null
                        : Text(visit.location!),
                    trailing: _mapButton(context, visit),
                    onTap: () => Navigator.pop(context, visit.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted && route != null) await _visit(route);
  }

  Future<void> _visit(String route) async {
    await widget.onOpen(route);
    if (!mounted) return;
    setState(() {
      _tours = _loadTours();
      _markers = _loadMarkers();
    });
  }

  Widget? _mapButton(BuildContext context, _Visit visit) {
    final coordinates = visit.coordinates;
    if (coordinates == null) return null;
    return IconButton(
      tooltip: AppLocalizations.tr('Ver en mapa'),
      icon: const Icon(Icons.place_outlined),
      onPressed: () => showPostLocationViewer(
        context,
        label: visit.location ?? visit.title,
        coordinates: coordinates,
      ),
    );
  }

  _Visit _tourVisit(TourRecord tour, {BusinessARTarget? target}) {
    final location = tour.space['location_label'];
    final latitude = tour.space['latitude'];
    final longitude = tour.space['longitude'];
    final coordinates = latitude is num && longitude is num
        ? PostCoordinates(
            latitude: latitude.toDouble(),
            longitude: longitude.toDouble(),
            precision: tour.space['location_precision'] == 'approximate'
                ? PostLocationPrecision.approximate
                : PostLocationPrecision.exact,
          )
        : null;
    return (
      title: target?.point.name ?? tour.title,
      route: target == null
          ? '/tours/${Uri.encodeComponent(tour.id)}'
          : Uri(
              path: '/tours/${tour.id}/business-ar',
              queryParameters: {
                'owner': tour.ownerId,
                'point': target.point.id,
              },
            ).toString(),
      location: location is String && location.trim().isNotEmpty
          ? location
          : target == null
          ? null
          : tour.title,
      coordinates: coordinates?.isValid == true ? coordinates : null,
    );
  }

  _Visit _markerVisit(ArMarker marker) => (
    title: marker.name,
    route: '/ar-markers/${Uri.encodeComponent(marker.id)}/visit',
    location: null,
    coordinates: null,
  );

  Widget _entry(String label, IconData icon, List<_Visit> visits) {
    final single = visits.length == 1 ? visits.single : null;
    final mapAction = single == null ? null : _mapButton(context, single);
    return ListTile(
      minVerticalPadding: 8,
      leading: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.brandNavy, size: 20),
        ),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: single == null ? null : Text(single.title),
      trailing: mapAction == null
          ? const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mapAction,
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
      onTap: () => _choose(label, visits),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<TourRecord>>(
    future: _tours,
    builder: (context, tourState) => FutureBuilder<List<ArMarker>>(
      future: _markers,
      builder: (context, markerState) {
        final loading =
            tourState.connectionState == ConnectionState.waiting ||
            markerState.connectionState == ConnectionState.waiting;
        final tours = (tourState.data ?? const <TourRecord>[])
            .where(
              (tour) =>
                  tour.ownerId == widget.profileId &&
                  tour.state == 'published' &&
                  tour.publicRevisionId != null,
            )
            .toList();
        final targets = BusinessARTarget.fromPublicTours(
          tours,
          widget.profileId,
        );
        final markers = (markerState.data ?? const <ArMarker>[]).where(
          (marker) => marker.ownerId == widget.profileId && marker.isPublic,
        );
        final rows = [
          if (tours.isNotEmpty)
            _entry(
              AppLocalizations.tr('Explorar en 360°'),
              Icons.panorama_photosphere_outlined,
              tours.map(_tourVisit).toList(),
            ),
          if (targets.isNotEmpty)
            _entry(
              AppLocalizations.tr('Explorar con cámara'),
              Icons.view_in_ar_outlined,
              [
                for (final target in targets)
                  _tourVisit(target.tour, target: target),
              ],
            ),
          if (markers.isNotEmpty)
            _entry(
              AppLocalizations.tr('Escanear marcador'),
              Icons.image_search_outlined,
              markers.map(_markerVisit).toList(),
            ),
          if (tourState.hasError)
            TextButton(
              onPressed: () => setState(() => _tours = _loadTours()),
              child: Text(AppLocalizations.tr('Reintentar recorridos')),
            ),
          if (markerState.hasError)
            TextButton(
              onPressed: () => setState(() => _markers = _loadMarkers()),
              child: Text(AppLocalizations.tr('Reintentar marcadores')),
            ),
        ];
        final manage = widget.onManage;
        if (rows.isEmpty && !loading && manage == null) {
          return const SizedBox.shrink();
        }
        final isOwnerEmpty = rows.isEmpty && !loading && manage != null;
        if (isOwnerEmpty) {
          rows.add(
            ListTile(
              leading: const Icon(
                Icons.view_in_ar_outlined,
                color: AppColors.brandNavy,
              ),
              title: Text(AppLocalizations.tr('Gestionar experiencias')),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
              minTileHeight: 52,
              onTap: manage,
            ),
          );
        }
        return Padding(
          key: const Key('profile-experiences-section'),
          padding: const EdgeInsets.only(top: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rows.isNotEmpty) ...[
                ProfileSectionHeading(
                  title: AppLocalizations.tr('Experiencias'),
                  trailing: manage == null || isOwnerEmpty
                      ? null
                      : Tooltip(
                          message: AppLocalizations.tr(
                            'Gestionar experiencias',
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: manage,
                            child: Text(AppLocalizations.tr('Gestionar')),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < rows.length; index++) ...[
                        if (index > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        rows[index],
                      ],
                    ],
                  ),
                ),
              ],
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: LinearProgressIndicator(
                    semanticsLabel: AppLocalizations.tr(
                      'Cargando experiencias',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
