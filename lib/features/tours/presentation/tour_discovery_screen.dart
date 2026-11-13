import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
class TourDiscoveryScreen extends StatefulWidget {
  const TourDiscoveryScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<TourDiscoveryScreen> createState() => _TourDiscoveryScreenState();
}

class _TourDiscoveryScreenState extends State<TourDiscoveryScreen> {
  late Future<List<TourRecord>> _items = widget.controller.tourRepository!
      .list();
  bool _locating = false;
  String? _error;
  Future<void> _nearby() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await const GeolocatorDeviceLocationService().current(
        requestPermission: true,
        isCurrent: () => mounted,
      );
      if (mounted) {
        setState(
          () => _items = widget.controller.tourRepository!.list(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              (AppLocalizations.of(context) ?? AppLocalizationsEs())
                  .errorUbicacion,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return Scaffold(
    appBar: AppBar(
      leading: const TourBackButton(fallback: '/map'),
      title: Text(core_l10n.AppLocalizations.tr(l10n.explorarLocales)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(core_l10n.AppLocalizations.tr(l10n.conoceEspacios360)),
        FilledButton.icon(
          onPressed: _locating ? null : _nearby,
          icon: const Icon(Icons.near_me_outlined),
          label: Text(
            _locating ? core_l10n.AppLocalizations.tr(l10n.buscandoUbicacion) : core_l10n.AppLocalizations.tr(l10n.descubrirCerca),
          ),
        ),
        if (_error != null) TourNotice(_error!),
        TourNotice(core_l10n.AppLocalizations.tr(l10n.ubicacionAproximada)),
        FutureBuilder<List<TourRecord>>(
          future: _items,
          builder: (c, s) {
            if (s.hasError) {
              return TourNotice(
                tourError(s.error!, l10n: l10n),
                onRetry: () => setState(
                  () => _items = widget.controller.tourRepository!.list(),
                ),
              );
            }
            if (!s.hasData) return const LinearProgressIndicator();
            if (s.data!.isEmpty) {
              return TourNotice(core_l10n.AppLocalizations.tr(l10n.sinRecorridosDisponibles));
            }
            return Column(
              children: [
                for (final t in s.data!)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.panorama_photosphere_outlined),
                      title: Text(t.title),
                      subtitle: Text(
                        t.space['location_label'] as String? ?? '',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/tours/${t.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
  }
}
