import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';
import 'tour_visit_screen.dart';

class TourManagementScreen extends StatefulWidget {
  const TourManagementScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<TourManagementScreen> createState() => _TourManagementScreenState();
}

class _TourManagementScreenState extends State<TourManagementScreen> {
  late Future<List<TourRecord>> _items = _load();
  Future<List<TourRecord>> _load() async =>
      await widget.controller.tourRepository?.list(
        owner: widget.controller.profile?.id,
      ) ??
      [];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const TourBackButton(fallback: '/profile'),
      title: const Text('Tus recorridos'),
    ),
    body: FutureBuilder<List<TourRecord>>(
      future: _items,
      builder: (c, s) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Muestra tu local en 360°',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Captura desde varias posiciones y conecta sus panoramas. Añade AR a los puntos que quieras reconocer en el local.',
          ),
          const SizedBox(height: 16),
          if (widget.controller.profile?.userType != null &&
              widget.controller.profile!.userType != UserType.general)
            FilledButton.icon(
              onPressed: () async {
                await context.push('/tours/new');
                if (mounted) setState(() => _items = _load());
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear recorrido'),
            ),
          OutlinedButton(
            onPressed: () => context.push('/tours/requests'),
            child: const Text('Solicitudes y revisión'),
          ),
          if (s.hasError)
            TourNotice(
              tourError(s.error!),
              onRetry: () => setState(() => _items = _load()),
            )
          else if (!s.hasData)
            const LinearProgressIndicator()
          else if (s.data!.isEmpty)
            const TourNotice('Todavía no tienes recorridos.')
          else
            for (final t in s.data!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(tourStateLabel(t.state)),
                      if (t.publicRevisionId != null)
                        const Text(
                          'La versión pública se conserva mientras editas.',
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await context.push('/tours/${t.id}/edit');
                              if (mounted) setState(() => _items = _load());
                            },
                            child: const Text('Editar borrador'),
                          ),
                          if (t.publicRevisionId != null)
                            TextButton(
                              onPressed: () => context.push('/tours/${t.id}'),
                              child: const Text('Ver recorrido'),
                            ),
                          if (t.publicRevisionId != null)
                            TextButton(
                              onPressed: () async {
                                try {
                                  await widget.controller.tourRepository!.pause(
                                    t.id,
                                    t.state != 'paused',
                                  );
                                  if (mounted) setState(() => _items = _load());
                                } catch (e) {
                                  if (c.mounted) {
                                    ScaffoldMessenger.of(c).showSnackBar(
                                      SnackBar(content: Text(tourError(e))),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                t.state == 'paused' ? 'Reanudar' : 'Pausar',
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class TourRequestsScreen extends StatefulWidget {
  const TourRequestsScreen({required this.controller, super.key});
  final AppSessionController controller;
  @override
  State<TourRequestsScreen> createState() => _TourRequestsScreenState();
}

class _TourRequestsScreenState extends State<TourRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _items = widget
      .controller
      .tourRepository!
      .requests();
  Future<void> _review(Map<String, dynamic> item, bool approve) async {
    final reason = approve
        ? 'Aprobado'
        : await tourTextDialog(context, 'Qué debe corregirse');
    if (reason == null) return;
    try {
      await widget.controller.tourRepository!.review(
        item['id'] as String,
        approve,
        reason,
      );
      if (mounted) {
        setState(() => _items = widget.controller.tourRepository!.requests());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tourError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const TourBackButton(fallback: '/tours'),
      title: const Text('Solicitudes y revisión'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _items,
      builder: (c, s) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'La autorización del espacio y la del contenido se revisan por separado.',
          ),
          if (s.hasError)
            TourNotice(
              tourError(s.error!),
              onRetry: () => setState(
                () => _items = widget.controller.tourRepository!.requests(),
              ),
            )
          else if (!s.hasData)
            const LinearProgressIndicator()
          else if (s.data!.isEmpty)
            const TourNotice('No hay solicitudes pendientes.')
          else
            for (final r in s.data!)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${r['title'] ?? r['kind'] ?? 'Solicitud'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${r['reason'] ?? (r['space'] is Map ? r['space']['context'] : null) ?? ''}',
                      ),
                      Text(
                        '${r['kind'] == 'link'
                            ? 'Permiso del autor'
                            : r['kind'] == 'space'
                            ? 'Responsabilidad del espacio'
                            : 'Publicación'} · ${r['status'] ?? ''}',
                      ),
                      if (r['kind'] == 'link')
                        Text(
                          '${jsonMap(jsonMap(r['payload'])['link'])['title'] ?? 'Contenido vinculado'}',
                        ),
                      for (final path in jsonList(r['evidence_paths']))
                        FutureBuilder<String>(
                          future: widget.controller.tourRepository!.assetUrl(
                            path as String,
                          ),
                          builder: (c, s) => s.hasData
                              ? SizedBox(
                                  height: 160,
                                  child: Image.network(
                                    s.data!,
                                    errorBuilder: (_, e, st) =>
                                        const Text('Evidencia no disponible'),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      if (r['tour'] is Map)
                        TextButton(
                          onPressed: () {
                            final record = TourRecord.fromJson(r['tour']);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TourVisitScreen(
                                  controller: widget.controller,
                                  tourId: record.id,
                                  preview: true,
                                  reviewRecord: record,
                                ),
                              ),
                            );
                          },
                          child: const Text('Ver versión enviada'),
                        ),
                      if (r['status'] == 'approved' &&
                          (r['kind'] == 'link' || r['kind'] == 'space') &&
                          r['requester_id'] != widget.controller.profile?.id &&
                          (r['reviewer_id'] == widget.controller.profile?.id ||
                              widget.controller.profile?.role ==
                                  ProfileRole.admin))
                        OutlinedButton(
                          onPressed: () async {
                            try {
                              await widget.controller.tourRepository!
                                  .revokePermission(r['id'] as String);
                              if (mounted) {
                                setState(
                                  () => _items = widget
                                      .controller
                                      .tourRepository!
                                      .requests(),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tourError(e))),
                                );
                              }
                            }
                          },
                          child: Text(
                            r['kind'] == 'space'
                                ? 'Retirar permiso y pausar recorrido'
                                : 'Retirar permiso del contenido',
                          ),
                        ),
                      if ((r['state'] == 'pending' ||
                              r['status'] == 'pending') &&
                          r['requester_id'] != widget.controller.profile?.id &&
                          (r['reviewer_id'] == widget.controller.profile?.id ||
                              widget.controller.profile?.role ==
                                  ProfileRole.admin))
                        Wrap(
                          spacing: 12,
                          children: [
                            FilledButton(
                              onPressed: () => _review(r, true),
                              child: const Text('Aprobar'),
                            ),
                            OutlinedButton(
                              onPressed: () => _review(r, false),
                              child: const Text('Pedir cambios'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    ),
  );
}

class ProfileTourCard extends StatefulWidget {
  const ProfileTourCard({
    required this.controller,
    required this.profileId,
    super.key,
  });
  final AppSessionController controller;
  final String profileId;
  @override
  State<ProfileTourCard> createState() => _ProfileTourCardState();
}

class _ProfileTourCardState extends State<ProfileTourCard> {
  late Future<List<TourRecord>> _items = widget.controller.tourRepository!
      .publicList(widget.profileId);
  @override
  void didUpdateWidget(ProfileTourCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId ||
        oldWidget.controller != widget.controller) {
      _items = widget.controller.tourRepository!.publicList(widget.profileId);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<TourRecord>>(
    future: _items,
    builder: (c, s) {
      final tours = (s.data ?? [])
          .where((t) => t.state == 'published' && t.publicRevisionId != null)
          .toList();
      if (tours.isEmpty) return const SizedBox.shrink();
      return Column(
        children: [
          for (final t in tours)
            Card(
              child: ListTile(
                leading: const Icon(Icons.panorama_photosphere_outlined),
                title: const Text('Explorar el local'),
                subtitle: Text('${t.title} · Recorrido 360°'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/tours/${t.id}'),
              ),
            ),
        ],
      );
    },
  );
}
