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
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.controller,
    this.mediaRepository,
    super.key,
  });
  final AppSessionController controller;
  final ProfileMediaRepository? mediaRepository;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final Profile? _original = widget.controller.profile;
  late final _name = TextEditingController(text: _original?.fullName);
  late final _username = TextEditingController(text: _original?.username);
  late final _bio = TextEditingController(text: _original?.bio);
  late final _website = TextEditingController(text: _original?.website);
  late UserType _type = _original?.userType ?? UserType.general;
  late String _preset = _original?.coverPreset ?? 'marea';
  late String? _avatarPath = _original?.avatarPath,
      _coverPath = _original?.coverPath;
  late Set<String> _interests = {...?_original?.interests},
      _goals = {...?_original?.goals};
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
    userType: _type,
    interests: _interests.toList(),
    goals: _goals.toList(),
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
    for (final c in [_name, _username, _bio, _website]) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _username, _bio, _website]) {
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
    if (_saving ||
        widget.controller.isBusy ||
        !_form.currentState!.validate() ||
        _draft == null) {
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
    return Container(
      key: const Key('edit-media'),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.softBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: compact ? 148 : 184,
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
                bottom: -46,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
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
                            size: 96,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 2,
                      child: IconButton.filled(
                        key: const Key('edit-avatar-action'),
                        tooltip: 'Cambiar foto de perfil',
                        onPressed: _saving ? null : () => _pick(true),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 58, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.text.trim().isEmpty ? 'Tu nombre' : _name.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  'JPG o PNG. MAREA elimina la ubicación de la imagen.',
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
        _EditorSection(
          key: const Key('edit-identity'),
          icon: Icons.badge_outlined,
          title: 'Tu identidad',
          description: 'Así te encontrarán y reconocerán otras personas.',
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
            DropdownButtonFormField<UserType>(
              isExpanded: true,
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo de perfil'),
              items: [
                for (final value in UserType.values)
                  DropdownMenuItem(
                    value: value,
                    child: Text(value.databaseValue),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _type = value ?? _type),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorSection(
          key: const Key('edit-about'),
          icon: Icons.auto_awesome_outlined,
          title: 'Sobre ti',
          description: 'Cuenta lo esencial y agrega dónde conocer tu trabajo.',
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
              label: 'Portafolio o sitio web',
              hint: 'https://tusitio.com',
              keyboardType: TextInputType.url,
              validator: ProfilePreferences.websiteError,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorSection(
          key: const Key('edit-interests'),
          icon: Icons.favorite_border_rounded,
          title: 'Intereses',
          description:
              'Ayudan a que tu perfil conecte con la comunidad correcta.',
          children: [
            PreferenceChips(
              catalog: ProfilePreferences.interests,
              selected: _interests,
              enabled: !_saving,
              onChanged: (value) => setState(() => _interests = value),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorSection(
          key: const Key('edit-goals'),
          icon: Icons.explore_outlined,
          title: 'Lo que buscas',
          description: 'Sólo tú puedes ver estas preferencias.',
          children: [
            PreferenceChips(
              catalog: ProfilePreferences.goals,
              selected: _goals,
              enabled: !_saving,
              onChanged: (value) => setState(() => _goals = value),
            ),
          ],
        ),
        const SizedBox(height: 104),
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
              final wide = constraints.maxWidth >= 960;
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
                                children: [
                                  Text(
                                    'Así se verá tu perfil',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'La vista cambia contigo mientras editas.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _mediaEditor(compact: false),
                                ],
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
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            key: const Key('edit-save-bar'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.softBorder)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x120B255E),
                  blurRadius: 18,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.center,
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : _leave,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
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
          ),
        ),
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: Icon(icon, color: AppColors.actionBlue, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            children[index],
          ],
        ],
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
        minimumSize: const Size(0, 40),
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
