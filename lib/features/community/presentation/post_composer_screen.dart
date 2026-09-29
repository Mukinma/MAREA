import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/community_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';

class PostComposerScreen extends StatefulWidget {
  const PostComposerScreen({required this.controller, this.postId, super.key});
  final AppSessionController controller;
  final String? postId;
  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),
      _body = TextEditingController(),
      _location = TextEditingController(),
      _price = TextEditingController();
  PostKind? _kind;
  PostCoordinates? _coordinates;
  String _category = 'otros';
  Uint8List? _image;
  String? _imagePath, _originalImagePath, _imageUrl, _error;
  bool _allowsCollaboration = false;
  bool _busy = false, _loading = false, _dirty = false;
  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = widget.controller.communityRepository;
      if (repo == null) throw StateError('repository unavailable');
      final post = await repo.post(widget.postId!);
      if (!mounted) return;
      if (post == null || post.authorId != widget.controller.profile?.id) {
        setState(() {
          _error = 'Esta publicación no está disponible para editar.';
          _loading = false;
        });
        return;
      }
      _title.text = post.title;
      _body.text = post.body;
      _location.text = post.location ?? '';
      _coordinates = post.coordinates;
      _price.text = post.price?.toString() ?? '';
      _kind = post.kind;
      _allowsCollaboration = post.allowsCollaboration;
      _category = post.category;
      _imagePath = post.imagePath;
      _originalImagePath = post.imagePath;
      if (_imagePath != null) _imageUrl = await repo.imageUrl(_imagePath!);
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = communityError(error);
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _body, _location, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final image = await ProfileImagePicker.pick(avatar: false);
      if (mounted && image != null) {
        setState(() {
          _image = image;
          _dirty = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = communityError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseLocation() async {
    if (_busy) return;
    final current = _coordinates == null || _location.text.trim().isEmpty
        ? null
        : PostLocationSelection(
            label: _location.text.trim(),
            coordinates: _coordinates!,
          );
    final selection = await showCommunityLocationPicker(
      context,
      initial: current,
    );
    if (!mounted || selection == null) return;
    setState(() {
      _location.text = selection.label;
      _coordinates = selection.coordinates;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_busy || _loading || !(_form.currentState?.validate() ?? false)) return;
    final repo = widget.controller.communityRepository;
    final profile = widget.controller.profile;
    if (repo == null || profile == null) {
      setState(
        () => _error =
            'No pudimos conectar con las publicaciones. Vuelve a intentarlo.',
      );
      return;
    }
    final kind = _kind ?? profile.userType.postKinds.first;
    // Freeze the submitted values before upload: navigation may dispose this form.
    final allowsCollaboration = _allowsCollaboration;
    final title = _title.text.trim();
    final body = _body.text.trim();
    final category = _category;
    final location = _location.text.trim();
    final coordinates = _coordinates;
    final price = kind == PostKind.product || kind == PostKind.service
        ? double.tryParse(_price.text.replaceAll(',', '.'))
        : null;
    final image = _image;
    final existingImagePath = _imagePath;
    final originalImagePath = _originalImagePath;
    PostInput input(String? imagePath) => PostInput(
      kind: kind,
      title: title,
      body: body,
      category: category,
      location: location.isEmpty ? null : location,
      coordinates: coordinates,
      price: price,
      imagePath: imagePath,
      allowsCollaboration: allowsCollaboration,
    );
    final validation = input(
      _imagePath,
    ).validate(userType: widget.postId == null ? profile.userType : null);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? uploaded;
    var persisted = false;
    try {
      if (image != null) uploaded = await repo.uploadImage(image);
      await repo.savePost(
        input(uploaded ?? existingImagePath),
        id: widget.postId,
      );
      persisted = true;
      // Old assets can only be removed after the row stops referencing them.
      if (originalImagePath != null &&
          originalImagePath != (uploaded ?? existingImagePath)) {
        try {
          await repo.removeImage(originalImagePath);
        } catch (_) {
          /* Account deletion also cleans unused images. */
        }
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.postId == null
                ? 'Tu publicación ya está en MAREA.'
                : 'Publicación actualizada.',
          ),
        ),
      );
      if (widget.postId != null && context.canPop()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop(true);
        });
      } else {
        context.go('/home');
      }
    } catch (error) {
      if (uploaded != null && !persisted) {
        try {
          await repo.removeImage(uploaded);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _error = communityError(error);
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile;
    if (profile == null) {
      return const CommunityNotice(message: 'Carga tu perfil para publicar.');
    }
    final kinds = profile.userType.postKinds;
    final kind = _kind ?? kinds.first;
    final commercial = kind == PostKind.product || kind == PostKind.service;
    return PopScope(
      canPop: !_busy && !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _busy || !_dirty) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Descartar borrador?'),
            content: const Text('Los cambios todavía no se han publicado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Seguir editando'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          setState(() => _dirty = false);
          context.go('/home');
        }
      },
      child: CommunityPage(
        title: widget.postId == null
            ? 'Comparte con MAREA'
            : 'Editar publicación',
        subtitle: profile.userType.description,
        action: widget.postId == null
            ? OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final id = await context.push<String>('/missions/new');
                        if (!context.mounted || id == null) return;
                        await context.push('/missions/$id');
                      },
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text('Crear misión'),
              )
            : null,
        children: [
          SwitchListTile.adaptive(
            value: _allowsCollaboration,
            onChanged: _busy || _loading
                ? null
                : (value) => setState(() {
                    _allowsCollaboration = value;
                    _dirty = true;
                  }),
            title: const Text('Invitar a colaborar'),
            subtitle: const Text(
              'Recibe mensajes privados de interés para esta publicación.',
            ),
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (widget.postId != null && _kind == null)
            CommunityNotice(
              message: _error ?? 'No encontramos la publicación.',
              onRetry: _load,
            )
          else
            Form(
              key: _form,
              onChanged: () {
                if (!_dirty) setState(() => _dirty = true);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Publicas como ${profile.userType.databaseValue}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in {
                        ...kinds,
                        if (widget.postId != null) kind,
                      })
                        ChoiceChip(
                          label: Text(option.label),
                          selected: kind == option,
                          onSelected: _busy || widget.postId != null
                              ? null
                              : (_) => setState(() {
                                  _kind = option;
                                  _dirty = true;
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(kind.description),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _title,
                    enabled: !_busy,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => (v?.trim().length ?? 0) < 3
                        ? 'Escribe al menos 3 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _body,
                    enabled: !_busy,
                    maxLength: 3000,
                    minLines: 4,
                    maxLines: 10,
                    decoration: InputDecoration(
                      labelText: switch (kind) {
                        PostKind.project => 'Cuéntanos sobre tu proyecto',
                        PostKind.product => 'Describe tu producto',
                        PostKind.service => '¿Qué servicio ofreces?',
                        PostKind.space => 'Describe tu espacio',
                        PostKind.event => 'Detalles del evento',
                        _ => '¿Qué quieres compartir?',
                      },
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Agrega una descripción.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final entry in {
                        ...ProfilePreferences.interests,
                        'otros': 'Otros',
                      }.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() {
                            _category = v!;
                            _dirty = true;
                          }),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _location,
                    enabled: !_busy,
                    maxLength: 180,
                    onChanged: (_) {
                      if (_coordinates != null) {
                        setState(() => _coordinates = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText:
                          kind == PostKind.space || kind == PostKind.event
                          ? 'Ubicación del espacio o evento'
                          : 'Ubicación (opcional)',
                      hintText: 'Escribe una dirección o elige en el mapa',
                      suffixIcon: IconButton(
                        tooltip: 'Elegir ubicación en el mapa',
                        onPressed: _busy ? null : _chooseLocation,
                        icon: const Icon(Icons.map_outlined),
                      ),
                    ),
                    validator: (v) =>
                        (kind == PostKind.space || kind == PostKind.event) &&
                            (v?.trim().isEmpty ?? true)
                        ? 'Indica dónde se encuentra.'
                        : null,
                  ),
                  if (commercial) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _price,
                      enabled: !_busy,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Precio en MXN (opcional)',
                        prefixText: '\$ ',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        return n == null || !n.isFinite || n < 0 || n > 99999999
                            ? 'Escribe un precio entre 0 y 99,999,999.'
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_image != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        _image!,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                    )
                  else if (_imageUrl != null)
                    Image.network(
                      _imageUrl!,
                      height: 240,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('No pudimos cargar la imagen.'),
                    ),
                  Wrap(
                    spacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pick,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _image != null || _imagePath != null
                              ? 'Cambiar fotografía'
                              : 'Agregar fotografía',
                        ),
                      ),
                      if (_image != null || _imagePath != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _image = null;
                                  _imagePath = null;
                                  _imageUrl = null;
                                  _dirty = true;
                                }),
                          child: const Text('Quitar fotografía'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu publicación será visible para las personas con cuenta en MAREA.',
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _busy
                          ? 'Guardando…'
                          : widget.postId == null
                          ? 'Publicar'
                          : 'Guardar cambios',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
