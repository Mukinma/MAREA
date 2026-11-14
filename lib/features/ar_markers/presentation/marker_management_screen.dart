import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';

import '../data/marker_repository.dart';
import '../models/ar_marker.dart';

enum _MarkerAction { edit, scan, delete }

class MarkerManagementScreen extends StatefulWidget {
  const MarkerManagementScreen({
    required this.controller,
    required this.repository,
    super.key,
  });

  final AppSessionController controller;
  final MarkerRepository repository;

  @override
  State<MarkerManagementScreen> createState() => _MarkerManagementScreenState();
}

class _MarkerManagementScreenState extends State<MarkerManagementScreen> {
  String? _owner;
  String? _error;
  bool _loading = false;
  int _generation = 0;
  List<ArMarker> _items = [];
  final _deleting = <String>{};
  final _images = <String, Future<Uint8List>>{};

  @override
  void initState() {
    super.initState();
    _owner = widget.controller.profile?.id;
    widget.controller.addListener(_accountChanged);
    _reload();
  }

  bool _current(String owner, int generation) =>
      mounted &&
      _owner == owner &&
      widget.controller.profile?.id == owner &&
      generation == _generation;

  void _accountChanged() {
    final owner = widget.controller.profile?.id;
    if (_owner == owner) return;
    setState(() {
      _owner = owner;
      _items = [];
      _images.clear();
      _deleting.clear();
      _error = null;
    });
    _reload();
  }

  Future<void> _reload() async {
    final owner = _owner;
    final generation = ++_generation;
    if (owner == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _images.clear();
    });
    try {
      final markers = await widget.repository.listOwned(owner);
      if (!_current(owner, generation)) return;
      setState(() {
        _items = markers.where((marker) => marker.ownerId == owner).toList();
      });
    } catch (error) {
      if (_current(owner, generation)) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (_current(owner, generation)) setState(() => _loading = false);
    }
  }

  Future<void> _open(String path) async {
    final owner = _owner;
    if (owner == null || widget.controller.profile?.id != owner) return;
    await context.push(path);
    if (mounted && widget.controller.profile?.id == owner) await _reload();
  }

  Future<void> _action(ArMarker marker, _MarkerAction action) async {
    final owner = _owner;
    if (owner == null ||
        marker.ownerId != owner ||
        widget.controller.profile?.id != owner ||
        _deleting.contains(marker.id)) {
      return;
    }
    final id = Uri.encodeComponent(marker.id);
    if (action == _MarkerAction.edit) return _open('/ar-markers/$id/edit');
    if (action == _MarkerAction.scan) return _open('/ar-markers/$id/scan');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar marcador'),
        content: Text('Se eliminará «${marker.name}» de tus marcadores.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true ||
        !mounted ||
        widget.controller.profile?.id != owner) {
      return;
    }
    final generation = _generation;
    setState(() => _deleting.add(marker.id));
    try {
      await widget.repository.delete(owner, marker.id);
      if (_current(owner, generation)) {
        widget.controller.markersChanged();
        await _reload();
      }
    } catch (error) {
      if (_current(owner, generation)) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted && _owner == owner) {
        setState(() => _deleting.remove(marker.id));
      }
    }
  }

  String _message(Object error) => error is StateError
      ? error.message.toString()
      : AppFailureMapper.from(error).message;

  @override
  void dispose() {
    _generation++;
    widget.controller.removeListener(_accountChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tus marcadores')),
    body: _owner == null
        ? const Center(child: Text('Inicia sesión para ver tus marcadores.'))
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _loading
                          ? null
                          : () => _open('/ar-markers/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir marcador'),
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(_error!, semanticsLabel: _error),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _items.isEmpty ? 1 : _items.length,
                        itemBuilder: (context, index) {
                          if (_items.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _loading
                                    ? 'Cargando marcadores…'
                                    : 'Añade una imagen para crear tu primer marcador.',
                              ),
                            );
                          }
                          final marker = _items[index];
                          return Card(
                            key: ValueKey('${marker.ownerId}:${marker.id}'),
                            child: ListTile(
                              leading: SizedBox(
                                width: 56,
                                height: 56,
                                child: FutureBuilder<Uint8List>(
                                  future: _images.putIfAbsent(
                                    marker.id,
                                    () => widget.repository.loadImage(
                                      marker.ownerId,
                                      marker,
                                    ),
                                  ),
                                  builder: (context, snapshot) =>
                                      snapshot.hasData
                                      ? Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          cacheWidth: 112,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_not_supported_outlined,
                                          ),
                                        )
                                      : const Icon(Icons.image_outlined),
                                ),
                              ),
                              title: Text(marker.name),
                              subtitle: Text(
                                '${marker.isTested ? 'Reconocimiento probado' : 'Pendiente de probar en RA'}\n'
                                '${marker.isLocal ? 'Guardado en este dispositivo' : 'Guardado en tu cuenta'}',
                              ),
                              trailing: PopupMenuButton<_MarkerAction>(
                                tooltip: 'Opciones de ${marker.name}',
                                enabled: !_deleting.contains(marker.id),
                                onSelected: (action) => _action(marker, action),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: _MarkerAction.edit,
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: _MarkerAction.scan,
                                    child: Text('Probar RA'),
                                  ),
                                  PopupMenuItem(
                                    value: _MarkerAction.delete,
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}
