import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';

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
              'No pudimos obtener tu ubicación. Puedes explorar la lista de locales.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const TourBackButton(fallback: '/map'),
      title: const Text('Explorar locales'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Conoce espacios en 360° y descubre sus paradas con cámara cuando estés ahí.',
        ),
        FilledButton.icon(
          onPressed: _locating ? null : _nearby,
          icon: const Icon(Icons.near_me_outlined),
          label: Text(
            _locating ? 'Buscando tu ubicación…' : 'Descubrir cerca de mí',
          ),
        ),
        if (_error != null) TourNotice(_error!),
        const TourNotice(
          'La ubicación y dirección del local son aproximadas. Dentro, usa las fotografías e indicaciones de cada parada.',
        ),
        FutureBuilder<List<TourRecord>>(
          future: _items,
          builder: (c, s) {
            if (s.hasError) {
              return TourNotice(
                tourError(s.error!),
                onRetry: () => setState(
                  () => _items = widget.controller.tourRepository!.list(),
                ),
              );
            }
            if (!s.hasData) return const LinearProgressIndicator();
            if (s.data!.isEmpty) {
              return const TourNotice(
                'Todavía no hay recorridos disponibles aquí.',
              );
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
