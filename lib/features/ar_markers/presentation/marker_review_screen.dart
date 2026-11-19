import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/models/profile.dart';

import '../data/marker_repository.dart';
import '../models/ar_marker.dart';

class MarkerReviewScreen extends StatefulWidget {
  const MarkerReviewScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<MarkerReviewScreen> createState() => _MarkerReviewScreenState();
}

class _MarkerReviewScreenState extends State<MarkerReviewScreen> {
  late final String? _account = widget.controller.profile?.id;
  MarkerPublicationRepository? get _repository =>
      widget.controller.markerPublicationRepository;
  bool get _authorized =>
      _account != null &&
      widget.controller.profile?.id == _account &&
      widget.controller.profile?.role == ProfileRole.admin &&
      _repository != null;

  final _items = <ArMarker>[];
  final _busy = <String>{};
  bool _loading = false;
  bool _more = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    if (!_authorized) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository!.reviewQueue(
        _account!,
        offset: append ? _items.length : 0,
      );
      if (!mounted || !_authorized || generation != _generation) return;
      setState(() {
        if (!append) _items.clear();
        _items.addAll(page);
        _more = page.length == 30;
      });
    } catch (error) {
      if (mounted && _authorized && generation == _generation) {
        setState(() => _error = communityError(error));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _review(ArMarker marker, {required bool approve}) async {
    if (!_authorized || _busy.contains(marker.id)) return;
    final reason = approve
        ? null
        : await askCommunityText(
            context,
            title: 'Solicitar cambios',
            label: 'Motivo de la revisión',
            maxLength: 500,
          );
    if (!mounted || !_authorized || (!approve && reason == null)) return;
    setState(() => _busy.add(marker.id));
    try {
      await _repository!.review(
        _account!,
        marker,
        approve: approve,
        reason: reason,
      );
      if (mounted && _authorized) {
        widget.controller.markersChanged();
        await _load();
      }
    } catch (error) {
      if (mounted && _authorized) {
        await _load();
        if (mounted && _authorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error.toString().contains('marker_review_changed')
                    ? AppLocalizations.tr(
                        'El marcador cambió. Revisa su versión actual.',
                      )
                    : communityError(error),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy.remove(marker.id));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.tr('Marcadores RA'))),
      body: !_authorized
          ? CommunityNotice(
              message: AppLocalizations.tr(
                'Esta sección está reservada para administradores.',
              ),
            )
          : CommunityPage(
              title: AppLocalizations.tr('Pendientes de revisión'),
              onRefresh: _load,
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_error case final error?)
                  CommunityNotice(message: error, onRetry: _load),
                if (!_loading && _items.isEmpty && _error == null)
                  Text(AppLocalizations.tr('No hay marcadores pendientes.')),
                for (final marker in _items)
                  _MarkerSubmission(
                    key: ValueKey((marker.id, marker.updatedAt)),
                    marker: marker,
                    loadImage: () =>
                        _repository!.loadReviewImage(_account!, marker),
                    disabled: _busy.contains(marker.id) || _loading,
                    approve: () => _review(marker, approve: true),
                    requestChanges: () => _review(marker, approve: false),
                  ),
                if (_more && !_loading)
                  TextButton(
                    onPressed: () => _load(append: true),
                    child: Text(AppLocalizations.tr('Cargar más marcadores')),
                  ),
              ],
            ),
    ),
  );
}

class _MarkerSubmission extends StatefulWidget {
  const _MarkerSubmission({
    required this.marker,
    required this.loadImage,
    required this.disabled,
    required this.approve,
    required this.requestChanges,
    super.key,
  });

  final ArMarker marker;
  final Future<Uint8List> Function() loadImage;
  final bool disabled;
  final VoidCallback approve, requestChanges;

  @override
  State<_MarkerSubmission> createState() => _MarkerSubmissionState();
}

class _MarkerSubmissionState extends State<_MarkerSubmission> {
  late Future<Uint8List> _image = widget.loadImage();

  @override
  Widget build(BuildContext context) {
    final marker = widget.marker;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(marker.name, style: Theme.of(context).textTheme.titleLarge),
            if (marker.description.trim().isNotEmpty) Text(marker.description),
            if (marker.menuUrl case final url?) SelectableText(url),
            const SizedBox(height: 12),
            FutureBuilder<Uint8List>(
              future: _image,
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (snapshot.connectionState != ConnectionState.done)
                    const LinearProgressIndicator()
                  else if (snapshot.hasError)
                    CommunityNotice(
                      message: AppLocalizations.tr(
                        'No pudimos abrir la imagen del marcador.',
                      ),
                      onRetry: () =>
                          setState(() => _image = widget.loadImage()),
                    )
                  else
                    Image.memory(
                      snapshot.data!,
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (marker.hasPreciseLocation)
                        TextButton.icon(
                          onPressed: () => showPostLocationViewer(
                            context,
                            label: marker.name,
                            coordinates: PostCoordinates(
                              latitude: marker.latitude!,
                              longitude: marker.longitude!,
                              precision: PostLocationPrecision.exact,
                            ),
                          ),
                          icon: const Icon(Icons.place_outlined),
                          label: Text(AppLocalizations.tr('Ver en mapa')),
                        ),
                      OutlinedButton(
                        onPressed: widget.disabled
                            ? null
                            : widget.requestChanges,
                        child: Text(AppLocalizations.tr('Solicitar cambios')),
                      ),
                      FilledButton(
                        onPressed:
                            widget.disabled ||
                                !snapshot.hasData ||
                                !marker.isTested ||
                                !marker.hasPreciseLocation
                            ? null
                            : widget.approve,
                        child: Text(AppLocalizations.tr('Aprobar y publicar')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
