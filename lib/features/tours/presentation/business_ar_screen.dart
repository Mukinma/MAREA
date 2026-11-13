import 'dart:async';

import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/social_avatar.dart';

import '../data/tour_local_store.dart';
import '../data/tour_repository.dart';
import '../models/business_ar_target.dart';
import '../models/tour_models.dart';
import 'tour_widgets.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;

class BusinessARAction extends StatefulWidget {
  const BusinessARAction({
    required this.ownerId,
    required this.repository,
    required this.onOpen,
    super.key,
  });
  final String ownerId;
  final TourRepository repository;
  final ValueChanged<BusinessARTarget> onOpen;
  @override
  State<BusinessARAction> createState() => _BusinessARActionState();
}

class _BusinessARActionState extends State<BusinessARAction> {
  late Future<List<BusinessARTarget>> _targets = _load();
  Future<List<BusinessARTarget>> _load() async =>
      BusinessARTarget.fromPublicTours(
        await widget.repository.publicList(widget.ownerId),
        widget.ownerId,
      );
  @override
  void didUpdateWidget(BusinessARAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerId != widget.ownerId ||
        oldWidget.repository != widget.repository) {
      _targets = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return FutureBuilder<List<BusinessARTarget>>(
      future: _targets,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(() {
              _targets = _load();
            }),
            child: Text(
              core_l10n.AppLocalizations.tr(l10n.reintentarConsultaRa),
            ),
          );
        }
        final targets = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        if (targets == null || targets.isEmpty) {
          return const SizedBox.shrink();
        }
        return OutlinedButton.icon(
          icon: const Icon(Icons.view_in_ar),
          label: Text(core_l10n.AppLocalizations.tr(l10n.explorarEnRa)),
          onPressed: () async {
            final target = targets.length == 1
                ? targets.first
                : await showModalBottomSheet<BusinessARTarget>(
                    context: context,
                    builder: (context) => SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            title: Text(
                              core_l10n.AppLocalizations.tr(
                                l10n.eligeImagenBuscar,
                              ),
                            ),
                          ),
                          for (final target in targets)
                            ListTile(
                              title: Text(target.point.name),
                              subtitle: Text(target.tour.title),
                              onTap: () => Navigator.pop(context, target),
                            ),
                        ],
                      ),
                    ),
                  );
            if (mounted && target != null) {
              widget.onOpen(target);
            }
          },
        );
      },
    );
  }
}

class BusinessARScreen extends StatefulWidget {
  const BusinessARScreen({
    required this.controller,
    required this.ownerId,
    required this.tourId,
    required this.pointId,
    this.referenceLoader,
    this.localStore,
    this.cameraBuilder,
    super.key,
  });
  final AppSessionController controller;
  final String ownerId, tourId, pointId;
  final Future<Uint8List> Function(String)? referenceLoader;
  final TourLocalStore? localStore;
  final Widget Function(Map<String, dynamic>)? cameraBuilder;
  @override
  State<BusinessARScreen> createState() => _BusinessARScreenState();
}

class _BusinessARScreenState extends State<BusinessARScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('marea/tour_ar');
  static const _events = EventChannel('marea/tour_ar/events');
  static const _cardSize = Size(280, 120);
  late final String? _account;
  BusinessARTarget? _target;
  CommunityProfile? _profile;
  String? _referenceUrl, _error;
  List<Map<String, dynamic>> _references = [];
  StreamSubscription<dynamic>? _tracking;
  Timer? _watchdog;
  dynamic _quad;
  bool _loading = true, _busy = false, _scanning = false, _supported = false;
  bool _foreground = true;
  bool _routeVisible = true;
  bool _initialLoadStarted = false;
  int _generation = 0;
  String? _scanId;
  bool get _current =>
      mounted && _account != null && widget.controller.profile?.id == _account;
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  bool _valid(int generation) =>
      _current && _foreground && _routeVisible && generation == _generation;

  @override
  void initState() {
    super.initState();
    _account = widget.controller.profile?.id;
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_accountChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeVisible = ModalRoute.of(context)?.isCurrent ?? true;
    if (!_initialLoadStarted) {
      _initialLoadStarted = true;
      _load();
    }
    if (!_routeVisible && (_scanning || _busy)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _stop();
        }
      });
    }
  }

  void _accountChanged() {
    if (!_current) {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && !_loading) {
      _stop();
    }
  }

  Future<void> _load() async {
    final l10n = _l10n;
    // A reference-image retry can also happen while a download is pending.
    // Cancel that preparation before resolving the public revision again.
    await _stop();
    if (!_current) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _profile = null;
      _target = null;
      _referenceUrl = null;
    });
    final generation = ++_generation;
    try {
      final repo = widget.controller.tourRepository;
      final community = widget.controller.communityRepository;
      if (repo == null || community == null) {
        throw StateError(core_l10n.AppLocalizations.tr(l10n.raNoDisponible));
      }
      // Always resolve the public revision, including when the viewer owns a draft.
      final targets = BusinessARTarget.fromPublicTours(
        await repo.publicList(widget.ownerId),
        widget.ownerId,
      );
      final target = targets
          .where(
            (t) => t.tour.id == widget.tourId && t.point.id == widget.pointId,
          )
          .firstOrNull;
      if (target == null) {
        throw StateError(
          core_l10n.AppLocalizations.tr(l10n.experienciaRaNoDisponible),
        );
      }
      final profiles = await community.profiles(ids: [widget.ownerId]);
      final profile = profiles.where((p) => p.id == widget.ownerId).firstOrNull;
      if (profile == null) {
        throw StateError(
          core_l10n.AppLocalizations.tr(l10n.perfilNoDisponible),
        );
      }
      final url = await repo.assetUrl(
        target.point.ar!['reference_path'] as String,
      );
      bool supported = false;
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          supported = await _channel.invokeMethod<bool>('supported') ?? false;
        } on PlatformException {
          supported = false;
        } on MissingPluginException {
          supported = false;
        }
      }
      if (!_current || generation != _generation) {
        return;
      }
      setState(() {
        _target = target;
        _profile = profile;
        _referenceUrl = url;
        _supported = supported;
      });
    } catch (e) {
      if (_current && generation == _generation) {
        setState(() => _error = tourError(e, l10n: _l10n));
      }
    } finally {
      if (_current && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _stop() async {
    ++_generation;
    _watchdog?.cancel();
    _watchdog = null;
    final subscription = _tracking;
    _tracking = null;
    if (mounted) {
      setState(() {
        _scanning = false;
        _busy = false;
        _quad = null;
        _scanId = null;
      });
    }
    await subscription?.cancel();
  }

  Future<void> _scan() async {
    final l10n = _l10n;
    if (mounted) {
      _routeVisible = ModalRoute.of(context)?.isCurrent ?? true;
    }
    if (!_current || !_foreground || !_routeVisible || !_supported || _busy) {
      return;
    }
    await _stop();
    if (!_current || !_foreground || !_routeVisible) {
      return;
    }
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Refresh availability and signed URL before each new native camera session.
      final repo = widget.controller.tourRepository!;
      final targets = BusinessARTarget.fromPublicTours(
        await repo.publicList(widget.ownerId),
        widget.ownerId,
      );
      final target = targets
          .where(
            (t) => t.tour.id == widget.tourId && t.point.id == widget.pointId,
          )
          .firstOrNull;
      if (target == null) {
        throw StateError(
          core_l10n.AppLocalizations.tr(l10n.experienciaRaNoDisponible),
        );
      }
      final url = await repo.assetUrl(
        target.point.ar!['reference_path'] as String,
      );
      final Uint8List bytes;
      if (widget.referenceLoader != null) {
        bytes = await widget.referenceLoader!(url);
      } else {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 25));
        if (response.statusCode != 200) {
          throw StateError(
            core_l10n.AppLocalizations.tr(l10n.errorDescargarImagen),
          );
        }
        bytes = response.bodyBytes;
      }
      if (!_valid(generation)) {
        return;
      }
      final path = await (widget.localStore ?? TourLocalStore()).saveBytes(
        _account!,
        tourId(),
        bytes,
      );
      if (!_valid(generation)) {
        return;
      }
      final scanId = tourId();
      _references = [
        {
          'id': target.point.id,
          'path': path,
          'widthMeters': (target.point.ar!['width_cm'] as num).toDouble() / 100,
        },
      ];
      _scanId = scanId;
      _tracking = _events.receiveBroadcastStream().listen(
        (dynamic event) {
          if (!_valid(generation) ||
              event is! Map ||
              event['sessionId'] != scanId) {
            return;
          }
          if (event['state'] == 'error') {
            final message =
                event['message'] as String? ??
                core_l10n.AppLocalizations.tr(l10n.errorIniciarCamara);
            unawaited(_stop());
            setState(() => _error = message);
            return;
          }
          if (event['id'] != target.point.id) {
            return;
          }
          if (event['state'] == 'tracking' && event['quad'] == null) {
            return;
          }
          _watchdog?.cancel();
          setState(
            () => _quad = event['state'] == 'tracking' ? event['quad'] : null,
          );
          // Never leave a card visible when the native stream stalls.
          _watchdog = Timer(const Duration(milliseconds: 600), () {
            if (_valid(generation)) {
              setState(() => _quad = null);
            }
          });
        },
        onError: (Object error) {
          if (!_valid(generation)) {
            return;
          }
          unawaited(_stop());
          setState(
            () => _error = core_l10n.AppLocalizations.tr(
              l10n.errorCamaraInterrumpida,
            ),
          );
        },
      );
      setState(() {
        _target = target;
        _scanning = true;
      });
    } catch (e) {
      if (_valid(generation)) {
        setState(() => _error = tourError(e, l10n: _l10n));
      }
    } finally {
      if (_valid(generation)) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _information() async {
    if (_quad == null || !_current) {
      return;
    }
    await _stop();
    if (!mounted || !_current) {
      return;
    }
    final route = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .75,
        child: _BusinessInformation(
          profile: _profile!,
          repository: widget.controller.communityRepository!,
        ),
      ),
    );
    if (!mounted || !_current) {
      return;
    }
    if (route != null) {
      await context.push(route);
      if (!mounted || !_current) {
        return;
      }
    }
    await _scan();
  }

  @override
  void dispose() {
    ++_generation;
    _watchdog?.cancel();
    _tracking?.cancel();
    widget.controller.removeListener(_accountChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(core_l10n.AppLocalizations.tr(_l10n.explorarEnRa)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_current
          ? Center(
              child: Text(
                core_l10n.AppLocalizations.tr(_l10n.sesionCambioExperiencia),
              ),
            )
          : _scanning
          ? Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final transform = arCardTransform(
                        _quad,
                        constraints.biggest,
                        _cardSize,
                      );
                      final params = {
                        'references': _references,
                        'projectedCard': true,
                        'sessionId': _scanId,
                      };
                      return ClipRect(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: widget.cameraBuilder != null
                                  ? widget.cameraBuilder!(
                                      Map<String, dynamic>.from(params),
                                    )
                                  : defaultTargetPlatform ==
                                        TargetPlatform.android
                                  ? AndroidView(
                                      key: ValueKey(_scanId),
                                      viewType: 'marea/tour_ar_view',
                                      creationParams: params,
                                      creationParamsCodec:
                                          const StandardMessageCodec(),
                                    )
                                  : UiKitView(
                                      key: ValueKey(_scanId),
                                      viewType: 'marea/tour_ar_view',
                                      creationParams: params,
                                      creationParamsCodec:
                                          const StandardMessageCodec(),
                                    ),
                            ),
                            if (transform != null && profile != null)
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Transform(
                                  transform: transform,
                                  child: SizedBox.fromSize(
                                    size: _cardSize,
                                    child: Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                        onTap: _information,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              SizedBox.square(
                                                dimension: 52,
                                                child: ClipOval(
                                                  child: ProfileImage(
                                                    path: profile.avatarPath,
                                                    repository: widget
                                                        .controller
                                                        .mediaRepository,
                                                    fallback: SocialAvatar(
                                                      initials:
                                                          profile.initials,
                                                      size: 52,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      profile.fullName,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      profile
                                                          .userType
                                                          .databaseValue,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      core_l10n
                                                          .AppLocalizations.tr(
                                                        _l10n.tocaVerMas,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 12,
                              right: 12,
                              top: 12,
                              child: IgnorePointer(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      transform == null
                                          ? core_l10n.AppLocalizations.tr(
                                              _l10n.buscaImagenReferencia,
                                            )
                                          : core_l10n.AppLocalizations.tr(
                                              _l10n.imagenReconocidaTocaTarjeta,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                TextButton(
                  onPressed: _stop,
                  child: Text(
                    core_l10n.AppLocalizations.tr(_l10n.cerrarCamara),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null) TourNotice(_error!),
                if (profile != null) ...[
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    core_l10n.AppLocalizations.tr(
                      _l10n.buscaImagenLugarTarjeta,
                    ),
                  ),
                  if (_referenceUrl != null)
                    Image.network(
                      _referenceUrl!,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => Column(
                        children: [
                          TourNotice(
                            core_l10n.AppLocalizations.tr(
                              _l10n.referenciaNoMostrar,
                            ),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: Text(
                              core_l10n.AppLocalizations.tr(
                                _l10n.reintentarImagen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(_target!.point.name),
                  if (!_supported)
                    TourNotice(
                      core_l10n.AppLocalizations.tr(_l10n.camaraCompatibleAr),
                    ),
                  if (!_supported)
                    TextButton(
                      onPressed: _load,
                      child: Text(
                        core_l10n.AppLocalizations.tr(
                          _l10n.comprobarCompatibilidad,
                        ),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _supported && !_busy ? _scan : null,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _busy
                          ? core_l10n.AppLocalizations.tr(
                              _l10n.preparandoCamara,
                            )
                          : core_l10n.AppLocalizations.tr(_l10n.abrirCamara),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/people/${widget.ownerId}'),
                    child: Text(core_l10n.AppLocalizations.tr(_l10n.verPerfil)),
                  ),
                ],
                if (_error != null)
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: Text(
                      core_l10n.AppLocalizations.tr(_l10n.reintentar),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BusinessInformation extends StatefulWidget {
  const _BusinessInformation({required this.profile, required this.repository});
  final CommunityProfile profile;
  final CommunityRepository repository;
  @override
  State<_BusinessInformation> createState() => _BusinessInformationState();
}

class _BusinessInformationState extends State<_BusinessInformation> {
  final _missions = <Mission>[];
  int _offset = 0;
  bool _busy = false, _more = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await widget.repository.missions(
        authorId: widget.profile.id,
        offset: _offset,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _offset += page.length;
        _more = page.length >= 30;
        for (final mission in page) {
          if (mission.authorId == widget.profile.id &&
              mission.isOpen &&
              !mission.isExpired &&
              !_missions.any((m) => m.id == mission.id)) {
            _missions.add(mission);
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = (AppLocalizations.of(context) ?? AppLocalizationsEs())
              .errorConsultarMisiones,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.profile.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: core_l10n.AppLocalizations.tr(l10n.volverCamara),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(widget.profile.userType.databaseValue),
          if (widget.profile.bio?.trim().isNotEmpty ?? false)
            Text(widget.profile.bio!),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, '/people/${widget.profile.id}'),
            child: Text(core_l10n.AppLocalizations.tr(l10n.verPerfil)),
          ),
          if (_missions.isNotEmpty)
            Text(
              core_l10n.AppLocalizations.tr(l10n.misionesActivas),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          for (final mission in _missions)
            ListTile(
              title: Text(mission.title),
              subtitle: Text(mission.location),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, '/missions/${mission.id}'),
            ),
          if (!_busy && _error == null && !_more && _missions.isEmpty)
            Text(
              core_l10n.AppLocalizations.tr(l10n.sinMisionesActivasOrganizador),
            ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(core_l10n.AppLocalizations.tr(_error!)),
          if (!_busy && (_more || _error != null))
            TextButton(
              onPressed: _load,
              child: Text(
                _error == null
                    ? core_l10n.AppLocalizations.tr(l10n.consultarMasMisiones)
                    : core_l10n.AppLocalizations.tr(l10n.reintentarMisiones),
              ),
            ),
        ],
      ),
    );
  }
}
