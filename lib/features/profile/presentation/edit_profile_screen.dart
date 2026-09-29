import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/shared/widgets/marea_tabs.dart';
import 'package:marea/core/theme/app_depth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
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
  bool _saving = false, _allowPop = false;
  String? _error;
  late final ProfileMediaRepository _media =
      widget.mediaRepository ??
      widget.controller.mediaRepository ??
      SupabaseProfileMediaRepository();
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
      jsonEncode(_draft?.toUpdateJson()) !=
          jsonEncode(_original?.toUpdateJson());
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
      saved = await widget.controller.updateProfile(draft.updateInput);
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

  Widget _mediaEditor({required bool compact}) {
    final username = FormValidators.normalizeUsername(_username.text);
    final coverHeight = compact ? 80.0 : 100.0;
    return Container(
      key: const Key('edit-media'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppDepth.raised,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.softBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: coverHeight + 46,
            child: Stack(
              children: [
                SizedBox(
                  height: coverHeight,
                  width: double.infinity,
                  child: ProfileImage(
                    path: _coverPath,
                    preview: _coverBytes,
                    repository: _media,
                    fallback: ProfileCover(preset: _preset),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MediaAction(
                    key: const Key('edit-cover-action'),
                    icon: Icons.photo_camera_outlined,
                    label: 'Portada',
                    onPressed: _saving ? null : () => _pick(false),
                  ),
                ),
                Positioned(
                  left: 22,
                  top: coverHeight - 34,
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: ProfileImage(
                            path: _avatarPath,
                            preview: _avatarBytes,
                            repository: _media,
                            fallback: SocialAvatar(
                              initials: _draft?.initials ?? 'M',
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton(
                          key: const Key('edit-avatar-action'),
                          tooltip: 'Cambiar foto de perfil',
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 48,
                          ),
                          onPressed: _saving ? null : () => _pick(true),
                          icon: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: AppColors.actionBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.surface,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.text.trim().isEmpty ? 'Tu nombre' : _name.text.trim(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  username.isEmpty ? '@tu_usuario' : '@$username',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (_avatarPath != null || _avatarBytes != null)
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _avatarPath = null;
                                _avatarBytes = null;
                              }),
                        icon: const Icon(
                          Icons.person_remove_outlined,
                          size: 18,
                        ),
                        label: const Text('Quitar foto'),
                      ),
                    if (_coverPath != null || _coverBytes != null)
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => setState(() {
                                _coverPath = null;
                                _coverBytes = null;
                              }),
                        icon: const Icon(Icons.hide_image_outlined, size: 18),
                        label: const Text('Quitar portada'),
                      ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Text(
                  'Estilo de portada',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry
                          in ProfilePreferences.covers.entries) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected:
                              _preset == entry.key &&
                              _coverPath == null &&
                              _coverBytes == null,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() {
                                  _preset = entry.key;
                                  _coverPath = null;
                                  _coverBytes = null;
                                }),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'JPG o PNG · sin datos de ubicación',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        if (_original!.userType != UserType.general)
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
        const SizedBox(height: 12),
        Visibility(
          maintainState: true,
          visible: _section == 'identity',
          child: Column(
            children: [
              ProfileFormSection(
                key: const Key('edit-identity'),
                icon: Icons.badge_outlined,
                title: 'Tu identidad',
                children: [
                  MareaTextField(
                    controller: _name,
                    label: 'Nombre completo',
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.fullName,
                  ),
                  MareaTextField(
                    controller: _username,
                    label: 'Nombre de usuario',
                    prefixText: '@',
                    textInputAction: TextInputAction.next,
                    validator: FormValidators.username,
                  ),
                  Text(
                    'Tipo de perfil: ${_original.userType.databaseValue}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text('Elegido al crear tu perfil.'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ProfileFormSection(
                key: const Key('edit-about'),
                icon: Icons.auto_awesome_outlined,
                title: 'Sobre ti',
                children: [
                  MareaTextField(
                    controller: _bio,
                    label: 'Bio',
                    hint: '¿Qué haces y qué te mueve?',
                    maxLength: 160,
                    maxLines: 4,
                    validator: FormValidators.bio,
                  ),
                  MareaTextField(
                    controller: _website,
                    label: 'Sitio web',
                    hint: 'https://tusitio.com',
                    keyboardType: TextInputType.url,
                    validator: ProfilePreferences.websiteError,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (_original.userType != UserType.general)
          Visibility(
            maintainState: true,
            visible: _section == 'professional',
            child: ProfileFormSection(
              key: const Key('edit-professional'),
              icon: Icons.work_outline,
              title: 'Información profesional',
              children: [
                MareaTextField(
                  controller: _contact,
                  label: 'Enlace de contacto',
                  hint: 'https://wa.me/... o tu página de contacto',
                  keyboardType: TextInputType.url,
                  validator: ProfilePreferences.websiteError,
                ),
                if (_original.userType == UserType.creator)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible para colaborar'),
                    value: _collaboration,
                    onChanged: (v) => setState(() => _collaboration = v),
                  ),
                if (_original.userType == UserType.business) ...[
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
                    MareaTextField(
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
        appBar: AppBar(
          title: const Text('Editar perfil'),
          leading: BackButton(onPressed: _leave),
          actions: [
            if (_dirty)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'Sin guardar',
                    style: TextStyle(
                      color: AppColors.aquaDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: AbsorbPointer(
          absorbing: _saving,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1024;
              if (wide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xxl,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                        0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxl,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [_mediaEditor(compact: false)],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxl,
                              ),
                              child: _formSections(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _mediaEditor(compact: true),
                    const SizedBox(height: AppSpacing.lg),
                    _formSections(),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: ProfileActionBar(
          key: const Key('edit-save-bar'),
          child: Row(
            children: [
              TextButton(
                onPressed: _saving ? null : _leave,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  key: const Key('edit-save-button'),
                  label: _dirty ? 'Guardar cambios' : 'Todo guardado',
                  icon: _dirty ? Icons.check_rounded : null,
                  isLoading: _saving || widget.controller.isBusy,
                  onPressed: _dirty ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        backgroundColor: AppColors.surface.withValues(alpha: .94),
        foregroundColor: AppColors.brandNavy,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _EditorNotice extends StatelessWidget {
  const _EditorNotice({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
