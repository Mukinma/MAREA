import 'package:marea/shared/widgets/marea_skeleton.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/l10n/app_localizations.dart';
import 'package:marea/l10n/app_localizations_es.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';

import 'package:marea/core/localization/app_localizations.dart' as core_l10n;
class ShowcaseComposerScreen extends StatefulWidget {
  const ShowcaseComposerScreen({
    required this.controller,
    this.itemId,
    this.initialKind,
    super.key,
  });
  final AppSessionController controller;
  final String? itemId;
  final ShowcaseKind? initialKind;
  @override
  State<ShowcaseComposerScreen> createState() => _ShowcaseComposerScreenState();
}

class _PhotoDraft {
  _PhotoDraft({this.path, this.bytes});
  final String? path;
  final Uint8List? bytes;
}

class _ShowcaseComposerScreenState extends State<ShowcaseComposerScreen> {
  final _title = TextEditingController(),
      _body = TextEditingController(),
      _price = TextEditingController(),
      _link = TextEditingController();
  final List<_PhotoDraft> _photos = [];
  ShowcaseKind? _kind;
  ShowcaseStatus _status = ShowcaseStatus.draft;
  String _category = 'otros';
  bool _available = true,
      _busy = false,
      _loading = false,
      _dirty = false,
      _allowPop = false;
  String? _error;
  AppLocalizations get _l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEs();
  String _validationError(String error) => switch (error) {
    'Este apartado no está disponible para tu tipo de perfil.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorFichaTipoPerfil),
    'Escribe un título de 3 a 100 caracteres.' => core_l10n.AppLocalizations.tr(_l10n.errorTituloFicha),
    'Agrega una descripción de hasta 3000 caracteres.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorDescripcionFicha),
    'Elige una categoría válida.' => core_l10n.AppLocalizations.tr(_l10n.errorCategoriaFicha),
    'Elige hasta seis fotografías distintas.' => core_l10n.AppLocalizations.tr(_l10n.errorFotosFicha),
    'Agrega al menos una fotografía para publicar.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorFotoRequeridaFicha),
    'Usa un precio válido en MXN para productos o servicios.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorPrecioFicha),
    'El enlace de proyecto solo está disponible para obras.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorEnlaceSoloObras),
    'Usa un enlace completo y seguro, por ejemplo https://tusitio.com.' =>
      core_l10n.AppLocalizations.tr(_l10n.errorEnlaceSeguro),
    _ => error,
  };
  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    for (final c in [_title, _body, _price, _link]) {
      c.addListener(_changed);
    }
    if (widget.itemId != null) {
      _loading = true;
      _load();
    }
  }

  void _changed() {
    if (mounted) setState(() => _dirty = true);
  }

  Future<void> _load() async {
    try {
      final item = await widget.controller.showcaseRepository?.item(
        widget.itemId!,
      );
      if (!mounted) return;
      if (item == null || item.ownerId != widget.controller.profile?.id) {
        throw StateError('Ficha no disponible para editar');
      }
      _title.text = item.title;
      _body.text = item.body;
      _price.text = item.price?.toStringAsFixed(2) ?? '';
      _link.text = item.projectUrl ?? '';
      setState(() {
        _kind = item.kind;
        _status = item.status;
        _category = item.category;
        _available = item.available;
        _photos.addAll(item.imagePaths.map((path) => _PhotoDraft(path: path)));
        _dirty = false;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = core_l10n.AppLocalizations.tr(_l10n.errorCargarFicha);
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _price, _link]) {
      c.removeListener(_changed);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (_dirty) {
      final l10n = _l10n;
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(core_l10n.AppLocalizations.tr(l10n.descartarCambios)),
          content: Text(core_l10n.AppLocalizations.tr(l10n.cambiosNoGuardados)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(core_l10n.AppLocalizations.tr(l10n.seguirEditando)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(core_l10n.AppLocalizations.tr(l10n.descartar)),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.canPop() ? context.pop() : context.go('/profile');
    });
  }

  Future<void> _pick() async {
    if (_busy || _photos.length >= 6) return;
    setState(() => _busy = true);
    try {
      final bytes = await ProfileImagePicker.pick(avatar: false);
      if (bytes != null && mounted) {
        setState(() {
          _photos.add(_PhotoDraft(bytes: bytes));
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = communityError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _loading) return;
    final repo = widget.controller.showcaseRepository;
    final profile = widget.controller.profile;
    if (repo == null || profile == null) return;
    final kind = _kind ?? profile.userType.showcaseKinds.first;
    final priceText = _price.text.trim();
    final price = priceText.isEmpty
        ? null
        : double.tryParse(priceText.replaceAll(',', '.'));
    if (kind != ShowcaseKind.project && priceText.isNotEmpty && price == null) {
      setState(() => _error = core_l10n.AppLocalizations.tr(_l10n.errorPrecioInvalidoMxn));
      return;
    }
    final title = _title.text,
        body = _body.text,
        category = _category,
        status = _status,
        available = _available,
        link = _link.text;
    ShowcaseInput input(List<String> paths) => ShowcaseInput(
      kind: kind,
      title: title,
      body: body,
      category: category,
      status: status,
      available: available,
      price: kind == ShowcaseKind.project ? null : price,
      projectUrl: kind == ShowcaseKind.project ? link : null,
      imagePaths: paths,
    );
    final error = input(
      List.generate(_photos.length, (i) => _photos[i].path ?? 'pending-$i'),
    ).validate(userType: widget.itemId == null ? profile.userType : null);
    if (error != null) {
      setState(() => _error = _validationError(error));
      return;
    }
    final staged = <String>[];
    var saved = false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paths = <String>[];
      for (final photo in _photos) {
        if (photo.path != null) {
          paths.add(photo.path!);
        } else {
          final path = await repo.upload(photo.bytes!);
          staged.add(path);
          paths.add(path);
        }
      }
      if (widget.controller.profile?.id != profile.id) {
        throw AppFailure(core_l10n.AppLocalizations.tr(_l10n.sesionCambioGuardarFicha));
      }
      await repo.save(input(paths), id: widget.itemId);
      saved = true;
      if (mounted) {
        setState(() {
          _dirty = false;
          _allowPop = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(core_l10n.AppLocalizations.tr(_l10n.fichaGuardada))));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.canPop() ? context.pop() : context.go('/profile');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = core_l10n.AppLocalizations.tr(
            _l10n.errorGuardarFicha(communityError(e)),
          ),
        );
      }
    } finally {
      if (!saved) {
        for (final path in staged) {
          try {
            await repo.removeImage(path);
          } catch (_) {
            /* Preserve form and let account cleanup recover unused uploads. */
          }
        }
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _composerBody(ShowcaseKind kind, List<ShowcaseKind> kinds) {
    final l10n = _l10n;
    final fields = ProfileFormSection(
      title: core_l10n.AppLocalizations.tr(l10n.informacion),
      icon: Icons.notes_outlined,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.itemId == null && kinds.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final option in kinds)
                    ChoiceChip(
                      label: Text(localizedShowcaseKindLabel(context, option)),
                      selected: kind == option,
                      onSelected: (_) => setState(() {
                        _kind = option;
                        _dirty = true;
                      }),
                    ),
                ],
              ),
            _ShowcaseTextField(
              controller: _title,
              maxLength: 100,
              decoration: InputDecoration(labelText: core_l10n.AppLocalizations.tr(l10n.titulo)),
            ),
            const SizedBox(height: 16),
            _ShowcaseTextField(
              controller: _body,
              minLines: 3,
              maxLines: 8,
              maxLength: 3000,
              decoration: InputDecoration(labelText: core_l10n.AppLocalizations.tr(l10n.descripcion)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              itemHeight: null,
              initialValue: _category,
              decoration: InputDecoration(labelText: core_l10n.AppLocalizations.tr(l10n.categoria)),
              items: [
                for (final entry in communityCategories.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      localizedShowcaseCategoryLabel(context, entry.key),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _category = v!;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 16),
            if (kind != ShowcaseKind.project) ...[
              _ShowcaseTextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: core_l10n.AppLocalizations.tr(l10n.precioMxnOpcional),
                  helperText: core_l10n.AppLocalizations.tr(l10n.sinPrecioConsultar),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(core_l10n.AppLocalizations.tr(l10n.disponible)),
                subtitle: Text(core_l10n.AppLocalizations.tr(l10n.fichasNoDisponiblesAdministracion)),
                value: _available,
                onChanged: (v) => setState(() {
                  _available = v;
                  _dirty = true;
                }),
              ),
            ] else
              _ShowcaseTextField(
                controller: _link,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: core_l10n.AppLocalizations.tr(l10n.enlaceProyectoOpcional),
                  hintText: 'https://...',
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ShowcaseStatus>(
              isExpanded: true,
              itemHeight: null,
              initialValue: _status,
              decoration: InputDecoration(labelText: core_l10n.AppLocalizations.tr(l10n.estadoFicha)),
              items: [
                for (final status in ShowcaseStatus.values)
                  if (status != ShowcaseStatus.archived ||
                      widget.itemId != null)
                    DropdownMenuItem(
                      value: status,
                      child: Text(
                        localizedShowcaseStatusLabel(context, status),
                      ),
                    ),
              ],
              onChanged: (v) => setState(() {
                _status = v!;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 12),
            Text(core_l10n.AppLocalizations.tr(l10n.borradoresArchivadosSoloVisibles)),
            if (_error != null) CommunityNotice(message: _error!),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
    final photos = ProfileFormSection(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              core_l10n.AppLocalizations.tr(
                l10n.fotografiasCount(_photos.length),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _photos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _photos[i].bytes != null
                          ? Image.memory(
                              _photos[i].bytes!,
                              height: 200,
                              fit: BoxFit.contain,
                            )
                          : ShowcasePhoto(
                              path: _photos[i].path!,
                              repository: widget.controller.showcaseRepository!,
                              height: 200,
                            ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton(
                          tooltip: core_l10n.AppLocalizations.tr(l10n.moverFotografiaAntes),
                          onPressed: i == 0
                              ? null
                              : () => setState(() {
                                  final p = _photos.removeAt(i);
                                  _photos.insert(i - 1, p);
                                  _dirty = true;
                                }),
                          icon: const Icon(Icons.arrow_upward),
                        ),
                        IconButton(
                          tooltip: core_l10n.AppLocalizations.tr(l10n.moverFotografiaDespues),
                          onPressed: i == _photos.length - 1
                              ? null
                              : () => setState(() {
                                  final p = _photos.removeAt(i);
                                  _photos.insert(i + 1, p);
                                  _dirty = true;
                                }),
                          icon: const Icon(Icons.arrow_downward),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _photos.removeAt(i);
                            _dirty = true;
                          }),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(core_l10n.AppLocalizations.tr(l10n.quitarFotografia)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: _photos.length >= 6 ? null : _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(core_l10n.AppLocalizations.tr(l10n.agregarFotografia)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1024;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: photos),
                        const SizedBox(width: 24),
                        Expanded(child: fields),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fields,
                        const SizedBox(height: 16),
                        photos,
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final profile = widget.controller.profile;
    final kinds = profile?.userType.showcaseKinds ?? [];
    if (profile == null || (kinds.isEmpty && widget.itemId == null)) {
      return Scaffold(
        appBar: AppBar(title: Text(core_l10n.AppLocalizations.tr(l10n.tuApartado))),
        body: CommunityNotice(message: core_l10n.AppLocalizations.tr(l10n.perfilSinApartadoProfesional)),
      );
    }
    final kind = _kind ?? (kinds.isEmpty ? ShowcaseKind.project : kinds.first);
    return PopScope(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.itemId == null
                ? localizedShowcaseKindAction(context, kind)
                : core_l10n.AppLocalizations.tr(l10n.editarFicha),
          ),
          leading: BackButton(onPressed: _leave),
        ),
        bottomNavigationBar: ProfileActionBar(
          child: FilledButton.icon(
            onPressed:
                _busy || _loading || (widget.itemId != null && _kind == null)
                ? null
                : _save,
            icon: const Icon(Icons.check),
            label: Text(_busy ? core_l10n.AppLocalizations.tr(l10n.guardando) : core_l10n.AppLocalizations.tr(l10n.guardarFicha)),
          ),
        ),
        body: _loading
            ? const Center(child: MareaSkeleton(kind: SkeletonKind.form))
            : widget.itemId != null && _kind == null
            ? CommunityNotice(
                message: _error ?? core_l10n.AppLocalizations.tr(l10n.fichaNoDisponible),
                onRetry: _load,
              )
            : AbsorbPointer(
                absorbing: _busy,
                child: _composerBody(kind, kinds),
              ),
      ),
    );
  }
}

class _ShowcaseTextField extends StatelessWidget {
  const _ShowcaseTextField({
    required this.controller,
    required this.decoration,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType,
  });
  final TextEditingController controller;
  final InputDecoration decoration;
  final int? maxLength, minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => MareaSurface(
    inset: true,
    radius: 16,
    child: TextField(
      controller: controller,
      decoration: decoration.copyWith(filled: false),
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
    ),
  );
}
