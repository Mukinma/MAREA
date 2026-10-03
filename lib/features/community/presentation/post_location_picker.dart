import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:marea/core/location/device_location_service.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:marea/features/community/models/community_models.dart';

const _defaultCenter = LatLng(19.4326, -99.1332);

class PostLocationSelection {
  const PostLocationSelection({required this.label, required this.coordinates});

  final String label;
  final PostCoordinates coordinates;
}

Future<PostLocationSelection?> showCommunityLocationPicker(
  BuildContext context, {
  PostLocationSelection? initial,
}) => showPostLocationPicker(context, initial: initial);

Future<PostLocationSelection?> showPostLocationPicker(
  BuildContext context, {
  PostLocationSelection? initial,
}) => showModalBottomSheet<PostLocationSelection>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _PostLocationPicker(initial: initial),
);

Future<void> showPostLocationViewer(
  BuildContext context, {
  required String label,
  required PostCoordinates coordinates,
}) => showDialog<void>(
  context: context,
  builder: (_) => _PostLocationViewer(label: label, coordinates: coordinates),
);

class _SearchPlace {
  const _SearchPlace({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _PostLocationPicker extends StatefulWidget {
  const _PostLocationPicker({this.initial});

  final PostLocationSelection? initial;

  @override
  State<_PostLocationPicker> createState() => _PostLocationPickerState();
}

class _PostLocationPickerState extends State<_PostLocationPicker> {
  late final TextEditingController _search;
  late LatLng _point;
  late PostLocationPrecision _precision;
  late String _label;
  final _mapController = MapController();
  List<_SearchPlace> _results = [];
  bool _searching = false;
  bool _locating = false;
  bool _mapReady = false;
  int _searchGeneration = 0;
  int _selectionGeneration = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    final initial = widget.initial;
    _point = initial == null
        ? _defaultCenter
        : LatLng(initial.coordinates.latitude, initial.coordinates.longitude);
    _precision = initial?.coordinates.precision ?? PostLocationPrecision.exact;
    _label = initial?.label ?? '';
  }

  @override
  void dispose() {
    _searchGeneration++;
    _selectionGeneration++;
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _findPlaces() async {
    final generation = ++_searchGeneration;
    final query = _search.text.trim();
    if (query.length < 3) {
      setState(() {
        _results = [];
        _searching = false;
        _message = 'Escribe al menos 3 caracteres para buscar.';
      });
      return;
    }
    setState(() {
      _searching = true;
      _results = [];
      _message = null;
    });
    try {
      final response = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/search', {
              'q': query,
              'format': 'jsonv2',
              'limit': '5',
              'countrycodes': 'mx',
            }),
            headers: const {
              'Accept-Language': 'es-MX',
              'User-Agent': 'MAREA/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw StateError('search_failed');
      final rows = jsonDecode(response.body) as List<dynamic>;
      final results = rows.map((row) {
        final value = Map<String, dynamic>.from(row as Map);
        return _SearchPlace(
          label: value['display_name'] as String,
          point: LatLng(
            double.parse(value['lat'] as String),
            double.parse(value['lon'] as String),
          ),
        );
      }).toList();
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _results = results
            .where((result) => _validPoint(result.point))
            .toList();
        _message = _results.isEmpty
            ? 'No encontramos lugares con ese nombre.'
            : null;
      });
    } catch (_) {
      if (mounted && generation == _searchGeneration) {
        setState(
          () => _message =
              'No pudimos buscar ese lugar. Puedes elegir un punto en el mapa o escribir la dirección al cerrar.',
        );
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _searching = false);
      }
    }
  }

  bool _selectionIsCurrent(int generation) =>
      mounted && generation == _selectionGeneration;

  bool _validPoint(LatLng point) =>
      point.latitude.isFinite &&
      point.longitude.isFinite &&
      point.latitude >= -90 &&
      point.latitude <= 90 &&
      point.longitude >= -180 &&
      point.longitude <= 180;

  String _pointLabel(LatLng point) =>
      'Ubicación seleccionada (${point.latitude.toStringAsFixed(6)}, '
      '${point.longitude.toStringAsFixed(6)})';

  String _boundedLabel(String label) {
    final trimmed = label.trim();
    return trimmed.length > 180 ? trimmed.substring(0, 180) : trimmed;
  }

  void _moveMap(LatLng point) {
    if (mounted && _mapReady) _mapController.move(point, 15);
  }

  Future<void> _useCurrentLocation() async {
    final generation = ++_selectionGeneration;
    ++_searchGeneration;
    setState(() {
      _locating = true;
      _searching = false;
      _results = [];
      _message = null;
    });
    try {
      final position = await const GeolocatorDeviceLocationService().current(
        requestPermission: true,
        isCurrent: () => _selectionIsCurrent(generation),
      );
      if (!_selectionIsCurrent(generation)) return;
      final point = LatLng(position.latitude, position.longitude);
      if (!_validPoint(point)) throw StateError('location_invalid');
      setState(() {
        _point = point;
        _label = _pointLabel(point);
      });
      _moveMap(point);
      final address = await _reverseGeocode(point);
      if (!_selectionIsCurrent(generation)) return;
      if (address != null) setState(() => _label = _boundedLabel(address));
    } catch (error) {
      if (_selectionIsCurrent(generation)) {
        setState(() => _message = _locationErrorMessage(error));
      }
    } finally {
      if (_selectionIsCurrent(generation)) {
        setState(() => _locating = false);
      }
    }
  }

  Future<String?> _reverseGeocode(LatLng point) async {
    try {
      final response = await http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': point.latitude.toString(),
              'lon': point.longitude.toString(),
              'format': 'jsonv2',
              'zoom': '18',
            }),
            headers: const {
              'Accept-Language': 'es-MX',
              'User-Agent': 'MAREA/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final value = jsonDecode(response.body) as Map<String, dynamic>;
      final label = value['display_name'] as String?;
      return label?.trim().isEmpty ?? true ? null : label;
    } catch (_) {
      return null;
    }
  }

  String _locationErrorMessage(Object error) {
    if (error is DeviceLocationFailure) return error.message;
    final code = error is StateError ? error.message.toString() : '';
    final details = error.toString().toLowerCase();
    if (code == 'location_disabled') {
      return 'Activa el servicio de ubicación de tu dispositivo e inténtalo de nuevo.';
    }
    if (code == 'location_denied' ||
        details.contains('permission') ||
        details.contains('denied')) {
      return 'Permite el acceso a tu ubicación en el navegador o en Ajustes del dispositivo.';
    }
    if (details.contains('secure') ||
        details.contains('https') ||
        details.contains('insecure')) {
      return 'En Web, la ubicación requiere HTTPS o abrir la app desde localhost.';
    }
    return 'No pudimos obtener tu ubicación. Revisa el permiso y el GPS, o elige el punto manualmente.';
  }

  PostCoordinates _coordinates() {
    if (_precision == PostLocationPrecision.exact) {
      return PostCoordinates(
        latitude: _point.latitude,
        longitude: _point.longitude,
        precision: _precision,
      );
    }
    return PostCoordinates(
      latitude: double.parse(_point.latitude.toStringAsFixed(2)),
      longitude: double.parse(_point.longitude.toStringAsFixed(2)),
      precision: _precision,
    );
  }

  void _selectPoint(LatLng point, {String? label}) {
    if (!_validPoint(point)) return;
    ++_selectionGeneration;
    ++_searchGeneration;
    setState(() {
      _point = point;
      _label = label == null ? _pointLabel(point) : _boundedLabel(label);
      _results = [];
      _locating = false;
      _searching = false;
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Elegir ubicación',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _findPlaces(),
                    onChanged: (_) {
                      ++_searchGeneration;
                      setState(() {
                        _results = [];
                        _searching = false;
                        _message = null;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Buscar lugar o dirección',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Buscar',
                  onPressed: _findPlaces,
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, index) {
                  final result = _results[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(result.label, maxLines: 2),
                    onTap: () {
                      _selectPoint(result.point, label: result.label);
                      _moveMap(result.point);
                    },
                  );
                },
              ),
            ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        onMapReady: () => _mapReady = true,
                        initialCenter: _point,
                        initialZoom: widget.initial == null ? 5 : 15,
                        onTap: (_, point) => _selectPoint(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.marea.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _point,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Positioned(
                      left: 8,
                      bottom: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white70),
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Text('© OpenStreetMap contributors'),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'post-location-current',
                        onPressed: _locating ? null : _useCurrentLocation,
                        tooltip: 'Usar mi ubicación actual',
                        child: _locating
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _label.isEmpty ? 'Toca el mapa para elegir un punto' : _label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SegmentedButton<PostLocationPrecision>(
                  segments: const [
                    ButtonSegment(
                      value: PostLocationPrecision.exact,
                      label: Text('Exacta'),
                      icon: Icon(Icons.gps_fixed),
                    ),
                    ButtonSegment(
                      value: PostLocationPrecision.approximate,
                      label: Text('Aproximada'),
                      icon: Icon(Icons.location_searching),
                    ),
                  ],
                  selected: {_precision},
                  onSelectionChanged: (value) =>
                      setState(() => _precision = value.first),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _label.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          PostLocationSelection(
                            label:
                                _precision == PostLocationPrecision.approximate
                                ? 'Zona aproximada'
                                : _label,
                            coordinates: _coordinates(),
                          ),
                        ),
                  icon: const Icon(Icons.check),
                  label: const Text('Usar esta ubicación'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostLocationViewer extends StatelessWidget {
  const _PostLocationViewer({required this.label, required this.coordinates});

  final String label;
  final PostCoordinates coordinates;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(coordinates.latitude, coordinates.longitude);
    return AlertDialog(
      title: Text(coordinates.isApproximate ? 'Zona aproximada' : 'Ubicación'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.marea.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('© OpenStreetMap contributors'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
