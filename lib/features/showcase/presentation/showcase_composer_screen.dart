import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/showcase/models/showcase.dart';
import 'package:marea/features/showcase/presentation/showcase_widgets.dart';

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
          _error = 'No pudimos cargar esta ficha. Puedes reintentar.';
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
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Descartar tus cambios?'),
          content: const Text('Los cambios todavía no se han guardado.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar'),
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
      setState(() => _error = 'Escribe un precio válido en MXN.');
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
      setState(() => _error = error);
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
        throw const AppFailure(
          'Tu sesión cambió. Vuelve a entrar antes de guardar.',
        );
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
        ).showSnackBar(const SnackBar(content: Text('Ficha guardada.')));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.canPop() ? context.pop() : context.go('/profile');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              '${communityError(e)} Tus cambios siguen aquí para reintentar.',
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
    final fields = ProfileFormSection(
      title: 'Información',
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
                      label: Text(option.label),
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
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 16),
            _ShowcaseTextField(
              controller: _body,
              minLines: 3,
              maxLines: 8,
              maxLength: 3000,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              itemHeight: null,
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final entry in communityCategories.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
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
                decoration: const InputDecoration(
                  labelText: 'Precio en MXN (opcional)',
                  helperText: 'Sin precio se mostrará “Consultar precio”.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible'),
                subtitle: const Text(
                  'Las fichas no disponibles solo aparecen en tu administración.',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Enlace del proyecto (opcional)',
                  hintText: 'https://...',
                ),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ShowcaseStatus>(
              isExpanded: true,
              itemHeight: null,
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado de la ficha',
              ),
              items: [
                for (final status in ShowcaseStatus.values)
                  if (status != ShowcaseStatus.archived ||
                      widget.itemId != null)
                    DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (v) => setState(() {
                _status = v!;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 12),
            const Text(
              'Los borradores y las fichas archivadas solo son visibles para ti.',
            ),
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
              'Fotografías · ${_photos.length} de 6',
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
                          tooltip: 'Mover fotografía antes',
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
                          tooltip: 'Mover fotografía después',
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
                          label: const Text('Quitar fotografía'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: _photos.length >= 6 ? null : _pick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Agregar fotografía'),
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
    final profile = widget.controller.profile;
    final kinds = profile?.userType.showcaseKinds ?? [];
    if (profile == null || (kinds.isEmpty && widget.itemId == null)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tu apartado')),
        body: const CommunityNotice(
          message: 'Este tipo de perfil no tiene un apartado profesional.',
        ),
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
          title: Text(widget.itemId == null ? kind.action : 'Editar ficha'),
          leading: BackButton(onPressed: _leave),
        ),
        bottomNavigationBar: ProfileActionBar(
          child: FilledButton.icon(
            onPressed:
                _busy || _loading || (widget.itemId != null && _kind == null)
                ? null
                : _save,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_busy ? 'Guardando…' : 'Guardar ficha'),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : widget.itemId != null && _kind == null
            ? CommunityNotice(
                message: _error ?? 'Ficha no disponible.',
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
