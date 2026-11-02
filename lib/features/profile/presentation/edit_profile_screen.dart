import 'package:marea/shared/widgets/marea_tabs.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/community/models/community_models.dart';

import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.controller,
    this.mediaRepository,
    this.initialSection,
    super.key,
  });
  final AppSessionController controller;
  final ProfileMediaRepository? mediaRepository;
  final String? initialSection;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late String _section =
      widget.initialSection == 'professional' &&
          widget.controller.profile?.userType != UserType.general
      ? 'professional'
      : 'identity';
  late final Profile? _original = widget.controller.profile;
  late final _name = TextEditingController(text: _original?.fullName);
  late final _username = TextEditingController(text: _original?.username);
  late final _bio = TextEditingController(text: _original?.bio);
  late final _website = TextEditingController(text: _original?.website);
  late final _contact = TextEditingController(text: _original?.contactUrl);
  late bool _collaboration = _original?.openToCollaboration ?? false;
  late final Map<String, TextEditingController> _hours = {
    for (final day in ProfilePreferences.weekdays.keys)
      day: TextEditingController(
        text:
            _original?.businessHours.containsKey(day) == true &&
                _original?.businessHours[day] == null
            ? 'cerrado'
            : _original?.businessHours[day],
      ),
  };
  late String? _location = _original?.location;
  late PostCoordinates? _coordinates = _original?.locationLatitude == null
      ? null
      : PostCoordinates(
          latitude: _original!.locationLatitude!,
          longitude: _original.locationLongitude!,
          precision: PostLocationPrecision.values.byName(
            _original.locationPrecision ?? 'exact',
          ),
        );
  late String _preset = _original?.coverPreset ?? 'marea';
  late String? _avatarPath = _original?.avatarPath,
      _coverPath = _original?.coverPath;
  Uint8List? _avatarBytes, _coverBytes;
  late final Set<String> _interests = {...?_original?.interests};
  bool _saving = false, _allowPop = false;
  String? _error;
  late final ProfileMediaRepository _media =
      widget.mediaRepository ??
      widget.controller.mediaRepository ??
      SupabaseProfileMediaRepository();
  Profile get _profile => _original!;
  Profile? get _draft => _original?.copyWith(
    fullName: _name.text.trim(),
    username: FormValidators.normalizeUsername(_username.text),
    bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
    website: _website.text.trim().isEmpty ? null : _website.text.trim(),
    contactUrl: _contact.text,
    openToCollaboration: _collaboration,
    location: _location,
    locationLatitude: _coordinates?.latitude,
    locationLongitude: _coordinates?.longitude,
    locationPrecision: _coordinates?.precision.name,
    businessHours: {
      for (final day in _hours.keys)
        if (_hours[day]!.text.trim().isNotEmpty)
          day: _hours[day]!.text.trim().toLowerCase() == 'cerrado'
              ? null
              : _hours[day]!.text.trim(),
    },
    avatarPath: _avatarPath,
    coverPath: _coverPath,
    coverPreset: _preset,
  );
  bool get _dirty =>
      _avatarBytes != null ||
      _coverBytes != null ||
      (_interests.length != _original!.interests.length ||
          !_interests.containsAll(_original.interests)) ||
      jsonEncode(_draft?.toUpdateJson()) !=
          jsonEncode(_original.toUpdateJson());
  @override
  void initState() {
    super.initState();
    for (final c in [
      _name,
      _username,
      _bio,
      _website,
      _contact,
      ..._hours.values,
    ]) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _username,
      _bio,
      _website,
      _contact,
      ..._hours.values,
    ]) {
      c.removeListener(_changed);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving) return;
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

  Future<void> _pick(bool avatar) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final bytes = await ProfileImagePicker.pick(avatar: avatar);
      if (mounted && bytes != null) {
        setState(() {
          if (avatar) {
            _avatarBytes = bytes;
          } else {
            _coverBytes = bytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : 'No pudimos abrir tus fotos. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_saving || widget.controller.isBusy || _draft == null) return;
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      var section = 'identity';
      field.context.visitAncestorElements((element) {
        if (element.widget.key == const Key('edit-professional')) {
          section = 'professional';
        }
        return true;
      });
      setState(() => _section = section);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && field.mounted) {
          Scrollable.ensureVisible(
            field.context,
            alignment: .15,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final staged = <String>[];
    bool saved = false;
    try {
      var draft = _draft!;
      if (_avatarBytes != null) {
        final path = await _media.upload(_avatarBytes!);
        staged.add(path);
        draft = draft.copyWith(avatarPath: path);
      }
      if (_coverBytes != null) {
        final path = await _media.upload(_coverBytes!);
        staged.add(path);
        draft = draft.copyWith(coverPath: path);
      }
      saved = await widget.controller.updateProfile(
        draft.updateWith(interests: _interests.toList()),
      );
      if (!saved) return;
      for (final old in [
        _original?.avatarPath,
        _original?.coverPath,
      ].whereType<String>().toSet()) {
        if (old != draft.avatarPath && old != draft.coverPath) {
          try {
            await _media.remove(old);
          } catch (_) {
            /* Retried by next-upload stale-draft cleanup or account deletion. */
          }
        }
      }
      if (mounted) {
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.canPop() ? context.pop() : context.go('/profile');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : 'No pudimos guardar las imágenes. Tus cambios siguen aquí para reintentar.',
        );
      }
    } finally {
      if (!saved) {
        for (final path in staged) {
          try {
            await _media.remove(path);
          } catch (_) {
            /* Never delete referenced media; the server checks before removing. */
          }
        }
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _mediaEditor() => SizedBox(
    key: const Key('edit-media'),
    height: MediaQuery.textScalerOf(context).scale(12) > 18 ? 186 : 146,
    child: Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 94,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProfileImage(
              path: _coverPath,
              preview: _coverBytes,
              repository: _media,
              fallback: ProfileCover(preset: _preset),
            ),
          ),
        ),
        Positioned(
          top: 44,
          right: 12,
          child: _MediaAction(
            key: const Key('edit-cover-action'),
            icon: Icons.photo_camera_outlined,
            label: 'Cambiar portada',
            onPressed: _saving ? null : () => _pick(false),
          ),
        ),
        Positioned(
          left: 14,
          top: 54,
          width: 88,
          height: 88,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: ProfileImage(
                path: _avatarPath,
                preview: _avatarBytes,
                repository: _media,
                fallback: SocialAvatar(
                  initials: _draft?.initials ?? 'M',
                  size: 80,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 110,
          right: 0,
          top: 94,
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('edit-avatar-action'),
              onPressed: _saving ? null : () => _pick(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF009FC2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: const TextStyle(
                  fontFamily: 'NunitoSans',
                  fontSize: 12,
                ),
              ),
              icon: const Icon(Icons.photo_camera_outlined, size: 16),
              label: const Text('Cambiar foto de perfil'),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _editInterests() async {
    FocusScope.of(context).unfocus();
    final selected = {..._interests};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Me mueve', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in ProfilePreferences.interests.entries)
                      FilterChip(
                        label: Text(entry.value),
                        selected: selected.contains(entry.key),
                        onSelected: (value) => update(() {
                          value
                              ? selected.add(entry.key)
                              : selected.remove(entry.key);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('Listo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _interests
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _chooseCover() async {
    FocusScope.of(context).unfocus();
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Estilo de portada'),
            ),
            for (final entry in ProfilePreferences.covers.entries)
              ListTile(
                title: Text(entry.value),
                leading: ClipOval(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: ProfileCover(preset: entry.key),
                  ),
                ),
                trailing: _preset == entry.key ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );
    if (value != null && mounted) {
      setState(() {
        _preset = value;
        _coverPath = null;
        _coverBytes = null;
      });
    }
  }

  Future<void> _chooseLocation() async {
    final value = await showCommunityLocationPicker(
      context,
      repository: widget.controller.locationRepository,
      initial: _location == null || _coordinates == null
          ? null
          : PostLocationSelection(
              label: _location!,
              coordinates: _coordinates!,
            ),
    );
    if (value != null && mounted) {
      setState(() {
        _location = value.label;
        _coordinates = value.coordinates;
      });
    }
  }

  Widget _summaryField(
    String label,
    String value, {
    VoidCallback? onTap,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: Color(0xFF07345C)),
      ),
      const SizedBox(height: 8),
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFD5E7F1)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF07345C)),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _preferences() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Estilo de portada', style: TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD5E7F1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: ClipOval(
            child: SizedBox(
              width: 30,
              height: 30,
              child: ProfileCover(preset: _preset),
            ),
          ),
          title: Text(
            ProfilePreferences.covers[_preset] ?? 'Marea',
            style: const TextStyle(fontSize: 14),
          ),
          trailing: TextButton(
            onPressed: _chooseCover,
            child: const Text('Cambiar'),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          const Expanded(
            child: Text('Me mueve', style: TextStyle(fontSize: 14)),
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _editInterests,
                child: const Text('Editar intereses', textAlign: TextAlign.end),
              ),
            ),
          ),
        ],
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          IconButton.outlined(
            onPressed: _editInterests,
            tooltip: 'Añadir intereses',
            icon: const Icon(Icons.add, size: 18),
          ),
          for (final interest in _interests)
            Chip(
              avatar: Icon(
                interest == 'musica'
                    ? Icons.music_note_outlined
                    : interest == 'moda'
                    ? Icons.checkroom_outlined
                    : Icons.palette_outlined,
                size: 16,
                color: const Color(0xFF7044E8),
              ),
              backgroundColor: AppColors.lavender,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(fontSize: 11),
              label: Text(ProfilePreferences.interests[interest] ?? interest),
            ),
        ],
      ),
      if (_avatarPath != null ||
          _avatarBytes != null ||
          _coverPath != null ||
          _coverBytes != null)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text(
            'Opciones de imágenes',
            style: TextStyle(fontSize: 14),
          ),
          children: [
            if (_avatarPath != null || _avatarBytes != null)
              TextButton(
                onPressed: () => setState(() {
                  _avatarPath = null;
                  _avatarBytes = null;
                }),
                child: const Text('Quitar foto'),
              ),
            if (_coverPath != null || _coverBytes != null)
              TextButton(
                onPressed: () => setState(() {
                  _coverPath = null;
                  _coverBytes = null;
                }),
                child: const Text('Quitar portada'),
              ),
          ],
        ),
    ],
  );

  Widget _formSections() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          _EditorNotice(message: _error!, error: true),
          const SizedBox(height: AppSpacing.md),
        ],
        SessionFeedback(controller: widget.controller),
        const SizedBox(height: 12),
        Visibility(
          maintainState: true,
          visible: _section == 'identity',
          child: Column(
            children: [
              _EditorSection(
                key: const Key('edit-identity'),

                children: [
                  _EditorField(
                    controller: _name,
                    label: 'Nombre completo',
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.fullName,
                  ),
                  _summaryField(
                    'Tipo de perfil',
                    _profile.userType.databaseValue,
                  ),
                  _summaryField(
                    'Ubicación',
                    _location ?? 'Añadir ubicación',
                    onTap: _chooseLocation,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _EditorSection(
                key: const Key('edit-about'),

                children: [
                  _EditorField(
                    controller: _bio,
                    label: 'Sobre mí',
                    hint: '¿Qué haces y qué te mueve?',
                    maxLength: 160,
                    maxLines: 3,
                    validator: FormValidators.bio,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _preferences(),
              const SizedBox(height: 24),
              _EditorSection(
                title: 'Más información',
                children: [
                  _EditorField(
                    controller: _username,
                    label: 'Nombre de usuario',
                    prefixText: '@',
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.username,
                  ),
                  Text(
                    'Tipo de perfil: ${_profile.userType.databaseValue}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text('Elegido al crear tu perfil.'),
                  _EditorField(
                    controller: _website,
                    label: 'Sitio web',
                    hint: 'https://tusitio.com',
                    keyboardType: TextInputType.url,
                    validator: ProfilePreferences.websiteError,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_profile.userType != UserType.general)
          MareaTabs(
            options: const {
              'identity': 'Identidad',
              'professional': 'Profesional',
            },
            value: _section,
            onChanged: (value) {
              FocusScope.of(context).unfocus();
              setState(() => _section = value);
            },
          ),
        if (_profile.userType != UserType.general)
          Visibility(
            maintainState: true,
            visible: _section == 'professional',
            child: _EditorSection(
              key: const Key('edit-professional'),
              title: 'Información profesional',
              children: [
                _EditorField(
                  controller: _contact,
                  label: 'Enlace de contacto',
                  hint: 'https://wa.me/... o tu página de contacto',
                  keyboardType: TextInputType.url,
                  validator: ProfilePreferences.websiteError,
                ),
                if (_profile.userType == UserType.creator)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible para colaborar'),
                    value: _collaboration,
                    onChanged: (v) => setState(() => _collaboration = v),
                  ),
                if (_profile.userType == UserType.business) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ubicación del negocio'),
                    subtitle: Text(_location ?? 'Sin ubicación'),
                    trailing: IconButton(
                      tooltip: 'Quitar ubicación',
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _location = null;
                        _coordinates = null;
                      }),
                    ),
                    onTap: () async {
                      final value = await showCommunityLocationPicker(
                        context,
                        repository: widget.controller.locationRepository,
                        initial: _location == null || _coordinates == null
                            ? null
                            : PostLocationSelection(
                                label: _location!,
                                coordinates: _coordinates!,
                              ),
                      );
                      if (value != null && mounted) {
                        setState(() {
                          _location = value.label;
                          _coordinates = value.coordinates;
                        });
                      }
                    },
                  ),
                  const Text('Horarios semanales · hora local del negocio'),
                  const Text(
                    'Usa 09:00-18:00. Escribe cerrado para un día sin atención; vacío si no quieres mostrarlo.',
                  ),
                  for (final day in ProfilePreferences.weekdays.entries)
                    _EditorField(
                      controller: _hours[day.key]!,
                      label: day.value,
                      hint: '09:00-18:00 o cerrado',
                      validator: (value) => ProfilePreferences.hoursError({
                        day.key: value?.trim().isEmpty ?? true
                            ? null
                            : value!.trim().toLowerCase() == 'cerrado'
                            ? null
                            : value.trim(),
                      }),
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (_original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/profile'),
            child: const Text(
              'No pudimos cargar tu perfil. Volver a intentarlo.',
            ),
          ),
        ),
      );
    }
    return PopScope(
      canPop: _allowPop || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FBFE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF4FBFE),
          titleSpacing: 0,
          title: const Text(
            'Editar perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: _leave,
              style: IconButton.styleFrom(backgroundColor: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _dirty && !_saving ? _save : null,
              child: const Text('Guardar'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _mediaEditor(),
                        const SizedBox(height: AppSpacing.lg),
                        _formSections(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('edit-save-button'),
                    onPressed: _dirty && !_saving && !widget.controller.isBusy
                        ? _save
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF08BFC1),
                      foregroundColor: const Color(0xFF07345C),
                      disabledBackgroundColor: const Color(0xFF08BFC1),
                      disabledForegroundColor: const Color(0xFF07345C),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(48, 56),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _saving || widget.controller.isBusy
                          ? 'Guardando...'
                          : 'Guardar cambios',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({required this.children, this.title, super.key});
  final List<Widget> children;
  final String? title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null) ...[
        Text(
          title!,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
      ],
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        children[i],
      ],
    ],
  );
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.prefixText,
    this.keyboardType,
    this.textInputAction,
  });
  final TextEditingController controller;
  final String label;
  final String? hint, prefixText;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, color: Color(0xFF07345C)),
      ),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: TextFormField(
          key: ValueKey('edit-field-$label'),
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Color(0xFF07345C),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            floatingLabelStyle: const TextStyle(
              fontSize: 16,
              color: Color(0xFF07345C),
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD5E7F1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF009FC2)),
            ),
          ),
        ),
      ),
    ],
  );
}

class _MediaAction extends StatelessWidget {
  const _MediaAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 36),
      shape: const StadiumBorder(),
      backgroundColor: Colors.white,
      foregroundColor: AppColors.brandNavy,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontFamily: 'NunitoSans', fontSize: 11),
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: 16),
    label: Text(label),
  );
}

class _EditorNotice extends StatelessWidget {
  const _EditorNotice({required this.message, required this.error});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      message,
      style: TextStyle(color: error ? AppColors.error : AppColors.success),
    ),
  );
}
