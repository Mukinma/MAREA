import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';

class TourDiscoveryScreen extends StatefulWidget {
  const TourDiscoveryScreen({
    required this.controller,
    this.locationService = const GeolocatorDeviceLocationService(),
    super.key,
  });
  final AppSessionController controller;
  final DeviceLocationService locationService;
  @override
  State<TourDiscoveryScreen> createState() => _TourDiscoveryScreenState();
}

class _TourDiscoveryScreenState extends State<TourDiscoveryScreen> {
  late Future<List<TourRecord>> _items = _fetch();
  bool _locating = false;
  String? _error;
  DevicePosition? _position;
  int _locationGeneration = 0;
  late final _account = widget.controller.profile?.id;
  bool get _current => mounted && widget.controller.profile?.id == _account;

  Future<List<TourRecord>> _fetch() {
    final items = widget.controller.tourRepository!.list(
      latitude: _position?.latitude,
      longitude: _position?.longitude,
    );
    // A nearby query can fail before the next frame attaches FutureBuilder.
    // Keep the original future so its error remains visible in that builder.
    items.ignore();
    return items;
  }

  void _reload() {
    setState(() {
      _error = null;
      _items = _fetch();
    });
  }

  double? _distance(TourRecord tour) {
    final position = _position;
    final latitude = tour.space['latitude'];
    final longitude = tour.space['longitude'];
    if (position == null ||
        latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return const Distance().as(
      LengthUnit.Meter,
      LatLng(position.latitude, position.longitude),
      LatLng(latitude.toDouble(), longitude.toDouble()),
    );
  }

  String _locationLabel(TourRecord tour) {
    final place = tour.space['location_label'] as String? ?? '';
    final distance = _distance(tour);
    if (distance == null) return place;
    final text = distance < 1000
        ? '${distance.round()} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
    return [
      place,
      'A $text aproximadamente',
    ].where((s) => s.isNotEmpty).join('\n');
  }

  Future<void> _nearby() async {
    if (_locating) return;
    final generation = ++_locationGeneration;
    bool current() => _current && generation == _locationGeneration;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await widget.locationService.current(
        requestPermission: true,
        isCurrent: current,
      );
      if (current()) {
        setState(() {
          _position = position;
          _items = _fetch();
        });
      }
    } catch (e) {
      if (current() &&
          !(e is DeviceLocationFailure &&
              e.kind == DeviceLocationFailureKind.cancelled)) {
        setState(
          () => _error = e is DeviceLocationFailure
              ? e.message
              : 'No pudimos obtener tu ubicación. Puedes explorar la lista de locales.',
        );
      }
    } finally {
      if (current()) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const TourBackButton(fallback: '/map'),
      title: const Text('Explorar locales'),
      actions: [
        IconButton(
          tooltip: 'Ver mapa',
          icon: const Icon(Icons.map_outlined),
          onPressed: () {
            _locationGeneration++;
            setState(() => _locating = false);
            context.push('/map?experiences=1');
          },
        ),
        if (_position != null)
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value != 'all') return;
              _locationGeneration++;
              setState(() {
                _locating = false;
                _position = null;
                _error = null;
                _items = _fetch();
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('Ver todos los locales')),
            ],
          ),
      ],
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
            _locating
                ? 'Buscando tu ubicación…'
                : _position == null
                ? 'Descubrir cerca de mí'
                : 'Actualizar cerca de mí',
          ),
        ),
        if (_error != null) TourNotice(_error!),
        if (_position != null)
          const Text(
            'Cerca de ti · distancias aproximadas. Abre un local para explorar sus imágenes.',
          ),
        FutureBuilder<List<TourRecord>>(
          future: _items,
          builder: (c, s) {
            if (s.hasError) {
              return TourNotice(tourError(s.error!), onRetry: _reload);
            }
            if (!s.hasData) return const LinearProgressIndicator();
            if (s.data!.isEmpty) {
              return const TourNotice(
                'Todavía no hay recorridos disponibles aquí.',
              );
            }
            final tours = [...s.data!];
            if (_position != null) {
              tours.sort((a, b) {
                final first = _distance(a), second = _distance(b);
                if (first == null) return second == null ? 0 : 1;
                return second == null ? -1 : first.compareTo(second);
              });
            }
            return Column(
              children: [
                for (final t in tours)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.panorama_photosphere_outlined),
                      title: Text(t.title),
                      subtitle: Text(_locationLabel(t)),
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
