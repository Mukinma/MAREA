import 'package:marea/core/localization/app_localizations.dart' as legacy;
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/profile/models/profile.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';
import 'tour_visit_screen.dart';

String _tourText(String value) => legacy.AppLocalizations.tr(value);

String _tourStateLabel(AppLocalizations l10n, String state) =>
    _tourText(switch (state) {
      'published' => legacy.AppLocalizations.tr(l10n.estadoPublicado),
      'paused' => legacy.AppLocalizations.tr(l10n.estadoPausado),
      'in_review' || 'submitted' => legacy.AppLocalizations.tr(l10n.estadoEnRevision),
      'changes_requested' ||
      'needs_changes' ||
      'rejected' => legacy.AppLocalizations.tr(l10n.estadoRequiereCambios),
      'expired' => legacy.AppLocalizations.tr(l10n.estadoFinalizado),
      _ => legacy.AppLocalizations.tr(l10n.estadoBorrador),
    });

String _requestStatusLabel(AppLocalizations l10n, Object? status) {
  final value = status is String ? status : '';
  return switch (value) {
    'approved' => _tourText(legacy.AppLocalizations.tr(l10n.estadoAprobado)),
    'pending' => _tourText(legacy.AppLocalizations.tr(l10n.pendiente)),
    'rejected' => _tourText(legacy.AppLocalizations.tr(l10n.estadoRechazado)),
    'superseded' => _tourText(legacy.AppLocalizations.tr(l10n.solicitudSustituida)),
    'revoked' => _tourText(legacy.AppLocalizations.tr(l10n.estadoRevocado)),
    _ => value,
  };
}

String _requestKindLabel(AppLocalizations l10n, Object? kind) =>
    _tourText(switch (kind) {
      'link' => legacy.AppLocalizations.tr(l10n.permisoAutor),
      'space' => legacy.AppLocalizations.tr(l10n.responsabilidadEspacio),
      'publication' => legacy.AppLocalizations.tr(l10n.publicacion),
      _ => legacy.AppLocalizations.tr(l10n.solicitud),
    });

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
  void _reload() {
    setState(() {
      _items = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return Scaffold(
      appBar: AppBar(
        leading: const TourBackButton(fallback: '/profile'),
        title: Text(_tourText(legacy.AppLocalizations.tr(l10n.tusRecorridos))),
      ),
      body: FutureBuilder<List<TourRecord>>(
        future: _items,
        builder: (c, s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              _tourText(legacy.AppLocalizations.tr(l10n.muestraTuLocal360)),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(_tourText(legacy.AppLocalizations.tr(l10n.capturaConectaPanoramas))),
            const SizedBox(height: 16),
            if (widget.controller.profile?.userType != null &&
                widget.controller.profile!.userType != UserType.general)
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/tours/new');
                  if (mounted) _reload();
                },
                icon: const Icon(Icons.add),
                label: Text(_tourText(legacy.AppLocalizations.tr(l10n.crearRecorrido))),
              ),
            OutlinedButton(
              onPressed: () => context.push('/tours/requests'),
              child: Text(_tourText(legacy.AppLocalizations.tr(l10n.solicitudesRevision))),
            ),
            if (s.hasError)
              TourNotice(
                _tourText(tourError(s.error!, l10n: l10n)),
                onRetry: _reload,
              )
            else if (!s.hasData)
              const LinearProgressIndicator()
            else if (s.data!.isEmpty)
              TourNotice(_tourText(legacy.AppLocalizations.tr(l10n.todaviaSinRecorridos)))
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
                        Text(_tourStateLabel(l10n, t.state)),
                        if (t.publicRevisionId != null)
                          Text(_tourText(legacy.AppLocalizations.tr(l10n.versionPublicaConserva))),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: () async {
                                await context.push('/tours/${t.id}/edit');
                                if (mounted) _reload();
                              },
                              child: Text(_tourText(legacy.AppLocalizations.tr(l10n.editarBorrador))),
                            ),
                            if (t.publicRevisionId != null)
                              TextButton(
                                onPressed: () => context.push('/tours/${t.id}'),
                                child: Text(_tourText(legacy.AppLocalizations.tr(l10n.verRecorrido))),
                              ),
                            if (t.publicRevisionId != null)
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await widget.controller.tourRepository!
                                        .pause(t.id, t.state != 'paused');
                                    if (mounted) _reload();
                                  } catch (e) {
                                    if (c.mounted) {
                                      ScaffoldMessenger.of(c).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _tourText(tourError(e, l10n: l10n)),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  t.state == 'paused'
                                      ? _tourText(legacy.AppLocalizations.tr(l10n.reanudar))
                                      : _tourText(legacy.AppLocalizations.tr(l10n.pausar)),
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
  void _reload() {
    setState(() {
      _items = widget.controller.tourRepository!.requests();
    });
  }

  Future<void> _review(Map<String, dynamic> item, bool approve) async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    final reason = approve
        ? legacy.AppLocalizations.tr(l10n.estadoAprobado)
        : await tourTextDialog(context, _tourText(legacy.AppLocalizations.tr(l10n.queDebeCorregirse)));
    if (reason == null) return;
    try {
      await widget.controller.tourRepository!.review(
        item['id'] as String,
        approve,
        reason,
      );
      if (mounted) {
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tourText(tourError(e, l10n: l10n)))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return Scaffold(
      appBar: AppBar(
        leading: const TourBackButton(fallback: '/tours'),
        title: Text(_tourText(legacy.AppLocalizations.tr(l10n.solicitudesRevision))),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _items,
        builder: (c, s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(_tourText(legacy.AppLocalizations.tr(l10n.autorizacionEspacioContenido))),
            if (s.hasError)
              TourNotice(
                _tourText(tourError(s.error!, l10n: l10n)),
                onRetry: _reload,
              )
            else if (!s.hasData)
              const LinearProgressIndicator()
            else if (s.data!.isEmpty)
              TourNotice(_tourText(legacy.AppLocalizations.tr(l10n.sinSolicitudesPendientes)))
            else
              for (final r in s.data!)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${r['title'] ?? _requestKindLabel(l10n, r['kind'])}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${r['reason'] ?? (r['space'] is Map ? r['space']['context'] : null) ?? ''}',
                        ),
                        Text(
                          legacy.AppLocalizations.trTemplate(
                            '{kind} · {status}',
                            {
                              'kind': _requestKindLabel(l10n, r['kind']),
                              'status': _requestStatusLabel(l10n, r['status']),
                            },
                          ),
                        ),
                        if (r['kind'] == 'link')
                          Text(
                            '${jsonMap(jsonMap(r['payload'])['link'])['title'] ?? _tourText(legacy.AppLocalizations.tr(l10n.contenidoVinculado))}',
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
                                      errorBuilder: (_, e, st) => Text(
                                        _tourText(legacy.AppLocalizations.tr(l10n.evidenciaNoDisponible)),
                                      ),
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
                            child: Text(_tourText(legacy.AppLocalizations.tr(l10n.verVersionEnviada))),
                          ),
                        if (r['status'] == 'approved' &&
                            (r['kind'] == 'link' || r['kind'] == 'space') &&
                            r['requester_id'] !=
                                widget.controller.profile?.id &&
                            (r['reviewer_id'] ==
                                    widget.controller.profile?.id ||
                                widget.controller.profile?.role ==
                                    ProfileRole.admin))
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await widget.controller.tourRepository!
                                    .revokePermission(r['id'] as String);
                                if (mounted) {
                                  _reload();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _tourText(tourError(e, l10n: l10n)),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Text(
                              r['kind'] == 'space'
                                  ? _tourText(legacy.AppLocalizations.tr(l10n.retirarPermisoPausar))
                                  : _tourText(legacy.AppLocalizations.tr(l10n.retirarPermisoContenido)),
                            ),
                          ),
                        if ((r['state'] == 'pending' ||
                                r['status'] == 'pending') &&
                            r['requester_id'] !=
                                widget.controller.profile?.id &&
                            (r['reviewer_id'] ==
                                    widget.controller.profile?.id ||
                                widget.controller.profile?.role ==
                                    ProfileRole.admin))
                          Wrap(
                            spacing: 12,
                            children: [
                              FilledButton(
                                onPressed: () => _review(r, true),
                                child: Text(_tourText(legacy.AppLocalizations.tr(l10n.aprobar))),
                              ),
                              OutlinedButton(
                                onPressed: () => _review(r, false),
                                child: Text(_tourText(legacy.AppLocalizations.tr(l10n.pedirCambios))),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return FutureBuilder<List<TourRecord>>(
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
                  title: Text(_tourText(legacy.AppLocalizations.tr(l10n.explorarLocal))),
                  subtitle: Text(
                    '${t.title} · ${_tourText(legacy.AppLocalizations.tr(l10n.recorrido360))}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tours/${t.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
