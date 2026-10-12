import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:marea/core/session/app_session_controller.dart';
import '../models/tour_models.dart';
import '../data/tour_progress_store.dart';
import '../data/tour_local_store.dart';
import 'tour_panorama.dart';
import 'tour_widgets.dart';

class TourVisitScreen extends StatefulWidget {
  const TourVisitScreen({
    required this.controller,
    required this.tourId,
    this.preview = false,
    this.pointId,
    this.reviewRecord,
    super.key,
  });
  final AppSessionController controller;
  final String tourId;
  final bool preview;
  final String? pointId;
  final TourRecord? reviewRecord;
  @override
  State<TourVisitScreen> createState() => _TourVisitScreenState();
}

class _TourVisitScreenState extends State<TourVisitScreen> {
  TourRecord? _tour;
  TourProgress? _progress;
  TourProgressStore? _progressStore;
  TourScene? _scene;
  String? _error;
  bool _started = false, _newVersion = false;
  String? _account;
  @override
  void initState() {
    super.initState();
    _account = widget.controller.profile?.id;
    _load();
  }

  bool get _current => mounted && widget.controller.profile?.id == _account;
  Future<void> _load() async {
    try {
      final tour =
          widget.reviewRecord ??
          await widget.controller.tourRepository!.get(
            widget.tourId,
            edit: widget.preview,
          );
      if (!mounted || !_current) return;
      if (tour == null) {
        setState(
          () => _error =
              'Este recorrido no está disponible. Puede estar pausado o haber finalizado.',
        );
        return;
      }
      final progress = widget.preview
          ? TourProgress(revisionId: tour.revisionId)
          : await (_progressStore = TourProgressStore(
              account: _account!,
              tourId: tour.id,
              revisionId: tour.revisionId,
              read: TourLocalStore().read,
              write: TourLocalStore().write,
              sync: (save) {
                if (!_current) throw StateError('La sesión cambió.');
                return widget.controller.tourRepository!.progress(
                  tour.id,
                  tour.revisionId,
                  save: save,
                );
              },
            )).load();
      if (!mounted || !_current) return;
      setState(() {
        _tour = tour;
        _progress = progress;
        _scene =
            tour.document.scene(
              progress.sceneId ?? tour.document.startSceneId ?? '',
            ) ??
            tour.document.scenes.firstOrNull;
        _error = null;
        _newVersion = progress.revisionId != tour.revisionId;
      });
      if (widget.pointId case final id?) {
        final point = tour.document.point(id);
        if (point != null && mounted) {
          setState(() {
            _scene =
                tour.document.scenes
                    .where((s) => s.points.any((p) => p.id == id))
                    .firstOrNull ??
                _scene;
            _started = !_newVersion;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showTourPoint(
                context,
                widget.controller,
                point,
                notice: _newVersion
                    ? 'Este recorrido tiene una versión nueva. Al empezar se reiniciará el progreso anterior.'
                    : null,
              );
            }
          });
        }
      }
    } catch (e) {
      if (_current) setState(() => _error = tourError(e));
    }
  }

  Future<void> _save() async {
    if (widget.preview || _tour == null || !_current) return;
    try {
      await _progressStore!.save(_progress!);
    } catch (e) {
      if (mounted && _current) {
        setState(
          () => _error = e is TourProgressPersistenceException
              ? 'No pudimos guardar el progreso en este dispositivo. Mantén la pantalla abierta e inténtalo de nuevo.'
              : 'Progreso guardado en este dispositivo. Se sincronizará al volver a abrir el recorrido.',
        );
      }
    }
  }

  void _move(String id) {
    final scene = _tour!.document.scene(id);
    if (scene == null) return;
    setState(() {
      if (_newVersion) {
        _progress = TourProgress(revisionId: _tour!.revisionId);
        _newVersion = false;
      }
      _scene = scene;
      _progress!.sceneId = id;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final tour = _tour, scene = _scene;
    return Scaffold(
      appBar: AppBar(
        leading: TourBackButton(
          fallback: tour == null ? '/tours/nearby' : '/people/${tour.ownerId}',
        ),
        title: Text(
          widget.preview
              ? 'Vista previa privada'
              : tour?.title ?? 'Recorrido 360°',
        ),
        actions: [
          if (tour != null && !widget.preview)
            IconButton(
              tooltip: 'Compartir recorrido',
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  uri: Uri.parse(
                    widget.controller.publicUrl,
                  ).resolve('/tours/${tour.id}'),
                ),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: tour == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TourNotice(_error!, onRetry: _load),
            )
          : _started && scene != null
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          scene.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _started = false),
                        child: const Text('Zonas'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TourPanorama(
                    repository: widget.controller.tourRepository!,
                    scene: scene,
                    onPoint: (p) =>
                        showTourPoint(context, widget.controller, p),
                    onConnection: (c) => _move(c['target_scene_id'] as String),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (_error != null) TourNotice(_error!),
                      for (final p in scene.points)
                        ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: const Icon(Icons.info_outline),
                          onTap: () =>
                              showTourPoint(context, widget.controller, p),
                        ),
                      for (final c in scene.connections)
                        ListTile(
                          title: Text(
                            'Ir a ${c['label'] ?? _tour!.document.scene(c['target_scene_id'] as String)?.name ?? 'otra posición'}',
                          ),
                          subtitle: Text(c['instruction'] as String? ?? ''),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => _move(c['target_scene_id'] as String),
                        ),
                      TextButton(
                        onPressed: () => setState(() => _started = false),
                        child: const Text('Finalizar visita'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tour.space['name'] as String? ?? tour.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mira alrededor en 360° y cambia entre posiciones. Puedes conocer cada punto sin usar la cámara ni compartir tu ubicación.',
                ),
                if (_newVersion)
                  const TourNotice(
                    'El recorrido cambió desde tu última visita. Empieza la versión actual.',
                  ),
                FilledButton.icon(
                  onPressed: scene == null
                      ? null
                      : () => setState(() {
                          if (_newVersion) {
                            _progress = TourProgress(
                              revisionId: tour.revisionId,
                            );
                            _newVersion = false;
                          }
                          _started = true;
                        }),
                  icon: const Icon(Icons.panorama_photosphere),
                  label: Text(
                    _progress?.sceneId == null
                        ? 'Empezar visita'
                        : 'Retomar visita',
                  ),
                ),
                if (tour.hasAR)
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/tours/${tour.id}/ar${widget.preview ? '?preview=true' : ''}',
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Recorrer con cámara'),
                  ),
                for (final z in tour.document.zones) ...[
                  const SizedBox(height: 16),
                  Text(
                    z.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(z.data['description'] as String? ?? ''),
                  for (final s in z.scenes)
                    ListTile(
                      title: Text(s.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        _move(s.id);
                        setState(() {
                          if (_newVersion) {
                            _progress = TourProgress(
                              revisionId: tour.revisionId,
                            );
                            _newVersion = false;
                          }
                          _started = true;
                        });
                      },
                    ),
                ],
                TextButton(
                  onPressed: () => context.push('/people/${tour.ownerId}'),
                  child: const Text('Volver al perfil'),
                ),
              ],
            ),
    );
  }
}

Future<bool> showTourPoint(
  BuildContext context,
  AppSessionController controller,
  TourPoint point, {
  String? notice,
}) async {
  final link = point.link;
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                point.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (notice != null) TourNotice(notice),
              Text(point.description),
              if (link != null && link['status'] == 'approved') ...[
                const SizedBox(height: 16),
                Text(link['title'] as String? ?? 'Contenido vinculado'),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(c);
                    if (context.mounted) {
                      final kind = link['kind'];
                      final route = kind == 'showcase'
                          ? 'showcase'
                          : kind == 'post'
                          ? 'posts'
                          : 'missions';
                      await context.push('/$route/${link['id']}');
                    }
                  },
                  child: const Text('Ver contenido'),
                ),
              ] else if (link != null)
                const TourNotice('Este contenido todavía no está disponible.'),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Continuar recorrido'),
              ),
            ],
          ),
        ),
      ) ??
      false;
}
