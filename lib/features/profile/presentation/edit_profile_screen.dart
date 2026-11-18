import 'dart:convert';
import 'dart:typed_data';

import 'package:marea/core/localization/app_localizations.dart';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/features/profile/presentation/wave_color_editor.dart';
import 'package:marea/features/profile/presentation/cover_photo_editor.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/theme/app_radius.dart';
import 'package:marea/core/theme/app_spacing.dart';
import 'package:marea/core/theme/category_visuals.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/features/profile/presentation/profile_form_widgets.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/community/models/community_models.dart';

import 'package:marea/shared/widgets/marea_panel.dart';
import 'package:marea/shared/widgets/marea_tabs.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/session_feedback.dart';

enum _CoverChoice { gallery, styles, remove }

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
  final _feedback = GlobalKey();
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
  late List<int>? _waveColors = _original?.waveColors;
  late String _preset = _original?.coverPreset ?? 'marea';
  late String? _avatarPath = _original?.avatarPath,
      _coverPath = _original?.coverPath;
  Uint8List? _avatarBytes, _coverBytes;
  late final Set<String> _interests = {...?_original?.interests};
  bool _saving = false, _allowPop = false, _discarding = false;
  bool get _busy => _saving || widget.controller.isBusy;
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
    waveColors: _waveColors,
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
    if (_busy || _discarding) return;
    if (_dirty) {
      _discarding = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(AppLocalizations.tr('¿Descartar tus cambios?')),
          content: Text(
            AppLocalizations.tr(
              'Si sales ahora, perderás los cambios de esta edición.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Descartar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.tr('Seguir editando')),
            ),
          ],
        ),
      );
      _discarding = false;
      if (discard != true || !mounted) return;
    }
    _returnToOrigin();
  }

  void _returnToOrigin() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.canPop() ? context.pop() : context.go('/profile');
    });
  }

  Future<void> _chooseCoverPhoto() async {
    FocusScope.of(context).unfocus();
    final choice = await showMareaBottomSheet<_CoverChoice>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProfileSheetContent(
        title: AppLocalizations.tr('Cambiar foto de portada'),
        children: [
          ProfileMenuSection(
            children: [
              ProfileMenuRow(
                icon: Icons.photo_library_outlined,
                title: AppLocalizations.tr('Galería'),
                onTap: () => Navigator.pop(ctx, _CoverChoice.gallery),
              ),
              ProfileMenuRow(
                icon: Icons.landscape_outlined,
                title: AppLocalizations.tr('Estilos de MAREA'),
                onTap: () => Navigator.pop(ctx, _CoverChoice.styles),
              ),
              if (_coverPath != null || _coverBytes != null)
                ProfileMenuRow(
                  icon: Icons.delete_outline_rounded,
                  title: AppLocalizations.tr('Quitar portada'),
                  destructive: true,
                  chevron: false,
                  onTap: () => Navigator.pop(ctx, _CoverChoice.remove),
                ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('Cancelar')),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _CoverChoice.styles:
        await _chooseCover();
      case _CoverChoice.gallery:
        await _pick(false);
      case _CoverChoice.remove:
        setState(() {
          _coverPath = null;
          _coverBytes = null;
        });
    }
  }

  Future<void> _pick(bool avatar) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var bytes = await ProfileImagePicker.pick(avatar: avatar);
      if (!avatar && bytes != null && mounted) {
        final selected = bytes;
        bytes = await showMareaBottomSheet<Uint8List>(
          context: context,
          isScrollControlled: true,
          constraints: const BoxConstraints(maxWidth: 560),
          builder: (_) => CoverPhotoEditor(
            bytes: selected,
            waveColors: _waveColors ?? ProfileWaves.defaultColors,
          ),
        );
      }
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
              : AppLocalizations.tr(
                  'No pudimos abrir tus fotos. Inténtalo nuevamente.',
                ),
        );
        _revealFeedback();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _draft == null) return;
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
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
          );
        }
      });
      return;
    }
    FocusScope.of(context).unfocus();
    widget.controller.clearFeedback();
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
      if (!saved) {
        if (mounted) _revealFeedback();
        return;
      }
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
      if (mounted) _returnToOrigin();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : AppLocalizations.tr(
                  'No pudimos guardar las imágenes. Tus cambios siguen aquí para reintentar.',
                ),
        );
        _revealFeedback();
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

  void _revealFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_feedback.currentContext case final context?) {
        Scrollable.ensureVisible(context);
      }
    });
  }

  Widget _mediaEditor() => ProfileFormSection(
    key: const Key('edit-media'),
    children: [
      LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth * .42).clamp(144.0, 220.0),
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 30,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _coverPreview(),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 64,
                        child: ProfileWaves(
                          colors: _waveColors ?? ProfileWaves.defaultColors,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 0,
                width: 84,
                height: 84,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: ProfileImage(
                        path: _avatarPath,
                        preview: _avatarBytes,
                        repository: _media,
                        fallback: SocialAvatar(
                          initials: _draft?.initials ?? 'M',
                          size: 76,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          TextButton.icon(
            key: const Key('edit-avatar-action'),
            onPressed: _busy ? null : () => _pick(true),
            icon: const Icon(Icons.photo_camera_outlined, size: 19),
            label: Text(AppLocalizations.tr('Cambiar foto de perfil')),
          ),
          if (_avatarPath != null || _avatarBytes != null)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _avatarPath = null;
                      _avatarBytes = null;
                    }),
              child: Text(AppLocalizations.tr('Quitar foto')),
            ),
        ],
      ),
      ProfileMenuSection(
        children: [
          ProfileMenuRow(
            key: const Key('edit-cover-action'),
            icon: Icons.add_photo_alternate_outlined,
            title: AppLocalizations.tr('Cambiar foto de portada'),
            subtitle: AppLocalizations.tr('Galería o estilos de MAREA'),
            onTap: _busy ? null : _chooseCoverPhoto,
          ),
          ProfileMenuRow(
            icon: Icons.waves_rounded,
            title: AppLocalizations.tr('Personalizar olitas'),
            subtitle: AppLocalizations.tr('Colores de tu portada'),
            onTap: _busy ? null : _customizeWaves,
          ),
        ],
      ),
    ],
  );

  Widget _coverPreview() => ProfileImage(
    path: _coverPath,
    preview: _coverBytes,
    repository: _media,
    fallback: ProfileCover(preset: _preset),
  );

  Future<void> _editInterests() async {
    FocusScope.of(context).unfocus();
    var selected = {..._interests};
    final result = await showMareaBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => ProfileSheetContent(
          title: AppLocalizations.tr('Me mueve'),
          children: [
            Text(
              AppLocalizations.tr(
                'Elige los intereses que quieres mostrar en tu perfil.',
              ),
            ),
            PreferenceChips(
              catalog: ProfilePreferences.interests,
              selected: selected,
              onChanged: (values) => update(() => selected = values),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(AppLocalizations.tr('Listo')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.tr('Cancelar')),
            ),
          ],
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

  Future<void> _customizeWaves() async {
    FocusScope.of(context).unfocus();
    final colors = await showMareaBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: .94,
        child: WaveColorEditor(
          colors: _waveColors ?? ProfileWaves.defaultColors,
          cover: _coverPreview(),
        ),
      ),
    );
    if (colors != null && mounted) setState(() => _waveColors = colors);
  }

  Future<void> _chooseCover() async {
    final value = await showMareaBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ProfileSheetContent(
        title: AppLocalizations.tr('Estilos de MAREA'),
        children: [
          ProfileMenuSection(
            children: [
              for (final entry in ProfilePreferences.covers.entries)
                ListTile(
                  minTileHeight: 56,
                  selected:
                      _coverPath == null &&
                      _coverBytes == null &&
                      _preset == entry.key,
                  selectedTileColor: AppColors.mist,
                  title: Text(entry.value),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    child: SizedBox(
                      width: 48,
                      height: 32,
                      child: ProfileCover(preset: entry.key),
                    ),
                  ),
                  trailing:
                      _coverPath == null &&
                          _coverBytes == null &&
                          _preset == entry.key
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(ctx, entry.key),
                ),
            ],
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.tr('Cancelar')),
          ),
        ],
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
    FocusScope.of(context).unfocus();
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

  Widget _interestsSection() => ProfileFormSection(
    title: AppLocalizations.tr('Me mueve'),
    children: [
      if (_interests.isEmpty)
        Text(
          AppLocalizations.tr(
            'Elige los intereses que quieres mostrar en tu perfil.',
          ),
        )
      else
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final interest in _interests) _interestChip(interest),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _busy ? null : _editInterests,
          icon: const Icon(Icons.edit_outlined, size: 19),
          label: Text(AppLocalizations.tr('Editar intereses')),
        ),
      ),
    ],
  );

  Widget _interestChip(String interest) {
    final visual = CategoryVisuals.forProfileInterest(interest);
    return Chip(
      avatar: ExcludeSemantics(
        child: Icon(visual.icon, size: 18, color: AppColors.brandNavy),
      ),
      backgroundColor: visual.color,
      side: BorderSide.none,
      label: Text(ProfilePreferences.interests[interest] ?? interest),
    );
  }

  Widget _identityFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.lg,
    children: [
      _mediaEditor(),
      ProfileFormSection(
        key: const Key('edit-identity'),
        title: AppLocalizations.tr('Tu información pública'),
        children: [
          MareaTextField(
            key: const ValueKey('edit-field-Nombre completo'),
            controller: _name,
            label: AppLocalizations.tr('Nombre completo'),
            textInputAction: TextInputAction.next,
            validator: FormValidators.fullName,
          ),
          MareaTextField(
            key: const ValueKey('edit-field-Nombre de usuario'),
            controller: _username,
            label: AppLocalizations.tr('Nombre de usuario'),
            prefixText: '@',
            textInputAction: TextInputAction.next,
            validator: FormValidators.username,
          ),
          MareaTextField(
            key: const ValueKey('edit-field-Sobre mí'),
            controller: _bio,
            label: AppLocalizations.tr('Sobre mí'),
            hint: AppLocalizations.tr('¿Qué haces y qué te mueve?'),
            maxLength: 160,
            maxLines: 3,
            validator: FormValidators.bio,
          ),
          MareaTextField(
            key: const ValueKey('edit-field-Sitio web'),
            controller: _website,
            label: AppLocalizations.tr('Sitio web'),
            hint: 'https://tusitio.com',
            keyboardType: TextInputType.url,
            validator: ProfilePreferences.websiteError,
          ),
          ProfileMenuSection(
            children: [
              ProfileMenuRow(
                icon: Icons.badge_outlined,
                title: AppLocalizations.tr('Tipo de perfil'),
                subtitle: _profile.userType.databaseValue,
                onTap: null,
              ),
              if (_profile.userType != UserType.business)
                ProfileMenuRow(
                  icon: Icons.location_on_outlined,
                  title: AppLocalizations.tr('Ubicación'),
                  subtitle:
                      _location ?? AppLocalizations.tr('Añadir ubicación'),
                  onTap: _busy ? null : _chooseLocation,
                ),
            ],
          ),
        ],
      ),
      _interestsSection(),
    ],
  );

  Widget _professionalFields() => ProfileFormSection(
    key: const Key('edit-professional'),
    title: AppLocalizations.tr('Información profesional'),
    children: [
      MareaTextField(
        key: const ValueKey('edit-field-Enlace de contacto'),
        controller: _contact,
        label: AppLocalizations.tr('Enlace de contacto'),
        hint: AppLocalizations.tr('https://wa.me/... o tu página de contacto'),
        keyboardType: TextInputType.url,
        validator: ProfilePreferences.websiteError,
      ),
      if (_profile.userType == UserType.creator)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.tr('Disponible para colaborar')),
          value: _collaboration,
          onChanged: _busy
              ? null
              : (value) => setState(() => _collaboration = value),
        ),
      if (_profile.userType == UserType.business) ...[
        ProfileMenuRow(
          icon: Icons.location_on_outlined,
          title: AppLocalizations.tr('Ubicación del negocio'),
          subtitle: _location ?? AppLocalizations.tr('Añadir ubicación'),
          onTap: _busy ? null : _chooseLocation,
        ),
        if (_location != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _location = null;
                      _coordinates = null;
                    }),
              icon: const Icon(Icons.close_rounded),
              label: Text(AppLocalizations.tr('Quitar ubicación')),
            ),
          ),
        Text(
          AppLocalizations.tr('Horarios semanales · hora local del negocio'),
        ),
        Text(
          AppLocalizations.tr(
            'Usa 09:00-18:00. Escribe «cerrado» para un día sin atención o déjalo vacío para ocultarlo.',
          ),
        ),
        for (final day in ProfilePreferences.weekdays.entries)
          MareaTextField(
            key: ValueKey('edit-field-${day.value}'),
            controller: _hours[day.key]!,
            label: day.value,
            hint: AppLocalizations.tr('09:00-18:00 o cerrado'),
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
  );

  Widget _formSections() => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Column(
          key: _feedback,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    error,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            if (widget.controller.failure != null)
              SessionFeedback(controller: widget.controller),
          ],
        ),
        if (_profile.userType != UserType.general)
          MareaTabs(
            options: {
              'identity': AppLocalizations.tr('Identidad'),
              'professional': AppLocalizations.tr('Profesional'),
            },
            value: _section,
            onChanged: (value) {
              if (_busy) return;
              FocusScope.of(context).unfocus();
              setState(() => _section = value);
            },
          ),
        Visibility(
          maintainState: true,
          visible: _section == 'identity',
          child: _identityFields(),
        ),
        if (_profile.userType != UserType.general)
          Visibility(
            maintainState: true,
            visible: _section == 'professional',
            child: _professionalFields(),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    AppLocalizations.of(context);
    if (_original == null) {
      return ProfilePage(
        title: AppLocalizations.tr('Editar perfil'),
        body: ProfilePageFrame(
          child: Text(
            AppLocalizations.tr(
              'No pudimos cargar tu perfil. Regresa para reintentar.',
            ),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => PopScope(
        canPop: _allowPop || (!_dirty && !_busy),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: ProfilePage(
          title: AppLocalizations.tr('Editar perfil'),
          onBack: _leave,
          body: AbsorbPointer(
            absorbing: _busy,
            child: SingleChildScrollView(
              child: ProfilePageFrame(child: _formSections()),
            ),
          ),
          action: FilledButton.icon(
            key: const Key('edit-save-button'),
            onPressed: _dirty && !_busy ? _save : null,
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text(
              _busy
                  ? AppLocalizations.tr('Guardando…')
                  : AppLocalizations.tr('Guardar cambios'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
