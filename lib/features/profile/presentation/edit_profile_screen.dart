import 'package:marea/shared/widgets/marea_tabs.dart';

import 'dart:convert';
import 'package:marea/features/profile/presentation/profile_waves.dart';
import 'package:marea/features/profile/presentation/wave_color_editor.dart';
import 'package:marea/features/profile/presentation/cover_photo_editor.dart';
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
import 'package:marea/features/profile/presentation/profile_sections.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/community/models/community_models.dart';

import 'package:marea/shared/widgets/social_avatar.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/session_feedback.dart';
import 'package:marea/l10n/app_localizations.dart' as gen;
import 'package:marea/l10n/app_localizations_es.dart' as gen;
import 'package:marea/core/localization/app_localizations.dart';

enum _CoverChoice { gallery, styles }

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
  gen.AppLocalizations get _l10n =>
      gen.AppLocalizations.of(context) ?? gen.AppLocalizationsEs();
  String _tr(String value) => AppLocalizations.tr(value);

  String _weekdayLabel(String weekday) => switch (weekday) {
    'mon' => _tr(_l10n.lunes),
    'tue' => _tr(_l10n.martes),
    'wed' => _tr(_l10n.miercoles),
    'thu' => _tr(_l10n.jueves),
    'fri' => _tr(_l10n.viernes),
    'sat' => _tr(_l10n.sabado),
    'sun' => _tr(_l10n.domingo),
    _ => weekday,
  };

  String _coverLabel(String cover) => switch (cover) {
    'marea' => _tr(_l10n.marea),
    'lavanda' => _tr(_l10n.lavanda),
    'durazno' => _tr(_l10n.durazno),
    'menta' => _tr(_l10n.menta),
    _ => cover,
  };

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
            ? AppLocalizations.tr('cerrado')
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
          day: _isClosedHours(_hours[day]!.text)
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

  bool _isClosedHours(String value) =>
      const {'cerrado', 'closed'}.contains(value.trim().toLowerCase());
  String? _translatedError(String? error) =>
      error == null ? null : _tr(error);
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
          title: Text(_tr(_l10n.descartarCambios)),
          content: Text(_tr(_l10n.cambiosNoGuardados)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_tr(_l10n.seguirEditando)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_tr(_l10n.descartar)),
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

  Future<void> _chooseCoverPhoto() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<_CoverChoice>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  _tr(_l10n.cambiarFotoPortada),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_tr(_l10n.galeria)),
                onTap: () => Navigator.pop(ctx, _CoverChoice.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.landscape_outlined),
                title: Text(_tr(_l10n.estilosMarea)),
                onTap: () => Navigator.pop(ctx, _CoverChoice.styles),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_tr(_l10n.cancelar)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == _CoverChoice.styles) {
      await _chooseCover();
    } else {
      await _pick(false, source: ProfilePhotoSource.gallery);
    }
  }

  Future<void> _pick(
    bool avatar, {
    ProfilePhotoSource source = ProfilePhotoSource.gallery,
  }) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var bytes = await ProfileImagePicker.pick(avatar: avatar, source: source);
      if (!avatar && bytes != null && mounted) {
        final selected = bytes;
        bytes = await showModalBottomSheet<Uint8List>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => SingleChildScrollView(
            child: CoverPhotoEditor(
              bytes: selected,
              waveColors: _waveColors ?? ProfileWaves.defaultColors,
            ),
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
              ? _tr(e.message)
              : _tr(_l10n.errorAbrirFotos),
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
          () =>
              _error = e is AppFailure
                  ? _tr(e.message)
                  : _tr(_l10n.errorGuardarImagenes),
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
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProfileImage(
                  path: _coverPath,
                  preview: _coverBytes,
                  repository: _media,
                  fallback: ProfileCover(preset: _preset),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 65,
                  child: ProfileWaves(
                    colors: _waveColors ?? ProfileWaves.defaultColors,
                  ),
                ),
              ],
            ),
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
              label: Text(_tr(_l10n.cambiarFotoPerfil)),
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
                Text(
                  _tr(_l10n.meMueve),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in ProfilePreferences.interests.entries)
                      FilterChip(
                        label: Text(
                          localizedProfileInterestLabel(context, entry.key),
                        ),
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
                  child: Text(_tr(_l10n.listo)),
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

  Future<void> _customizeWaves() async {
    FocusScope.of(context).unfocus();
    final colors = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .94,
        child: WaveColorEditor(
          colors: _waveColors ?? ProfileWaves.defaultColors,
          cover: ProfileImage(
            path: _coverPath,
            preview: _coverBytes,
            repository: _media,
            fallback: ProfileCover(preset: _preset),
          ),
        ),
      ),
    );
    if (colors != null && mounted) setState(() => _waveColors = colors);
  }

  Future<void> _chooseCover() async {
    FocusScope.of(context).unfocus();
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(_tr(_l10n.estilosMarea)),
              ),
              for (final entry in ProfilePreferences.covers.entries)
                ListTile(
                  title: Text(_coverLabel(entry.key)),
                  leading: ClipOval(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: ProfileCover(preset: entry.key),
                    ),
                  ),
                  trailing:
                      _coverPath == null &&
                          _coverBytes == null &&
                          _preset == entry.key
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.pop(ctx, entry.key),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_tr(_l10n.cancelar)),
              ),
            ],
          ),
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

  static ({IconData icon, Color foreground, Color background}) _interestStyle(
    String interest,
  ) => switch (interest) {
    'musica' => (
      icon: Icons.music_note_outlined,
      foreground: const Color(0xFF7044E8),
      background: const Color(0xFFEDE4FF),
    ),
    'arte' => (
      icon: Icons.palette_outlined,
      foreground: const Color(0xFFFA624E),
      background: const Color(0xFFFFE6DE),
    ),
    'moda' => (
      icon: Icons.checkroom_outlined,
      foreground: const Color(0xFFEC3884),
      background: const Color(0xFFFFE4EF),
    ),
    'digital' => (
      icon: Icons.devices_outlined,
      foreground: const Color(0xFF1463ED),
      background: const Color(0xFFDEEEFF),
    ),
    'gastronomia' => (
      icon: Icons.restaurant_outlined,
      foreground: const Color(0xFFE88B14),
      background: const Color(0xFFFFF4D9),
    ),
    'escritura' => (
      icon: Icons.edit_outlined,
      foreground: const Color(0xFFE88B14),
      background: const Color(0xFFFFF4D9),
    ),
    'fotografia' => (
      icon: Icons.camera_alt_outlined,
      foreground: const Color(0xFF168D91),
      background: const Color(0xFFDFF3F3),
    ),
    'diseno' => (
      icon: Icons.design_services_outlined,
      foreground: const Color(0xFF398569),
      background: const Color(0xFFE4F3E9),
    ),
    _ => (
      icon: Icons.palette_outlined,
      foreground: const Color(0xFFFA624E),
      background: const Color(0xFFFFE6DE),
    ),
  };

  Widget _preferences() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListTile(
        key: const Key('edit-cover-action'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.add_photo_alternate_outlined),
        title: Text(_tr(_l10n.cambiarFotoPortada)),
        subtitle: Text(_tr(_l10n.elegirFotoOPreset)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _saving ? null : _chooseCoverPhoto,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 48,
          height: 32,
          child: ProfileWaves(
            colors: _waveColors ?? ProfileWaves.defaultColors,
          ),
        ),
        title: Text(_tr(_l10n.personalizarOlitas)),
        subtitle: Text(_tr(_l10n.coloresIndependientesFoto)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _saving ? null : _customizeWaves,
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: Text(
              _tr(_l10n.meMueve),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _editInterests,
                child: Text(
                  _tr(_l10n.editarIntereses),
                  textAlign: TextAlign.end,
                ),
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
            tooltip: _tr(_l10n.anadirIntereses),
            icon: const Icon(Icons.add, size: 18),
          ),
          for (final interest in _interests)
            Chip(
              avatar: Icon(
                _interestStyle(interest).icon,
                size: 16,
                color: _interestStyle(interest).foreground,
              ),
              backgroundColor: _interestStyle(interest).background,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              visualDensity: VisualDensity.compact,
              labelStyle: const TextStyle(fontSize: 11),
              label: Text(localizedProfileInterestLabel(context, interest)),
            ),
        ],
      ),
      if (_avatarPath != null ||
          _avatarBytes != null ||
          _coverPath != null ||
          _coverBytes != null)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            _tr(_l10n.opcionesImagenes),
            style: const TextStyle(fontSize: 14),
          ),
          children: [
            if (_avatarPath != null || _avatarBytes != null)
              TextButton(
                onPressed: () => setState(() {
                  _avatarPath = null;
                  _avatarBytes = null;
                }),
                child: Text(_tr(_l10n.quitarFoto)),
              ),
            if (_coverPath != null || _coverBytes != null)
              TextButton(
                onPressed: () => setState(() {
                  _coverPath = null;
                  _coverBytes = null;
                }),
                child: Text(_tr(_l10n.quitarPortada)),
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
                    label: _tr(_l10n.nombreCompleto),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        _translatedError(FormValidators.fullName(value)),
                  ),
                  _summaryField(
                    _tr(_l10n.tipoPerfil),
                    localizedProfileUserTypeLabel(context, _profile.userType),
                  ),
                  _summaryField(
                    _tr(_l10n.ubicacion),
                    _location ?? _tr(_l10n.agregarUbicacion),
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
                    label: _tr(_l10n.sobreMi),
                    hint: _tr(_l10n.hintSobreMi),
                    maxLength: 160,
                    maxLines: 3,
                    validator: (value) =>
                        _translatedError(FormValidators.bio(value)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _preferences(),
              const SizedBox(height: 24),
              _EditorSection(
                title: _tr(_l10n.masInformacion),
                children: [
                  _EditorField(
                    controller: _username,
                    label: _tr(_l10n.nombreUsuario),
                    prefixText: '@',
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        _translatedError(FormValidators.username(value)),
                  ),
                  Text(
                    AppLocalizations.trTemplate(
                      'Tipo de perfil: {type}',
                      {
                        'type': localizedProfileUserTypeLabel(
                          context,
                          _profile.userType,
                        ),
                      },
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(_tr(_l10n.elegidoAlCrearPerfil)),
                  _EditorField(
                    controller: _website,
                    label: _tr(_l10n.sitioWeb),
                    hint: 'https://tusitio.com',
                    keyboardType: TextInputType.url,
                    validator: (value) => _translatedError(
                      ProfilePreferences.websiteError(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_profile.userType != UserType.general)
          MareaTabs(
            options: {
              'identity': _tr(_l10n.identidad),
              'professional': _tr(_l10n.profesional),
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
              title: _tr(_l10n.informacionProfesional),
              children: [
                _EditorField(
                  controller: _contact,
                  label: _tr(_l10n.enlaceContacto),
                  hint: _tr(_l10n.hintEnlaceContacto),
                  keyboardType: TextInputType.url,
                  validator: (value) => _translatedError(
                    ProfilePreferences.websiteError(value),
                  ),
                ),
                if (_profile.userType == UserType.creator)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_tr(_l10n.disponibleColaborar)),
                    value: _collaboration,
                    onChanged: (v) => setState(() => _collaboration = v),
                  ),
                if (_profile.userType == UserType.business) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_tr(_l10n.ubicacionNegocio)),
                    subtitle: Text(_location ?? _tr(_l10n.sinUbicacion)),
                    trailing: IconButton(
                      tooltip: _tr(_l10n.quitarUbicacion),
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
                  Text(_tr(_l10n.horariosSemanales)),
                  Text(_tr(_l10n.horariosInstruccion)),
                  for (final day in ProfilePreferences.weekdays.entries)
                    _EditorField(
                      controller: _hours[day.key]!,
                      label: _weekdayLabel(day.key),
                      hint: _tr(_l10n.horarioEjemplo),
                      validator: (value) => _translatedError(
                        ProfilePreferences.hoursError({
                          day.key: value?.trim().isEmpty ?? true
                              ? null
                              : _isClosedHours(value!)
                              ? null
                              : value.trim(),
                        }),
                      ),
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
        appBar: AppBar(title: Text(_tr(_l10n.editarPerfil))),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/profile'),
            child: Text(_tr(_l10n.errorCargarPerfil)),
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
          title: Text(
            _tr(_l10n.editarPerfil),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
              child: Text(_tr(_l10n.guardar)),
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
                          ? _tr(_l10n.guardando)
                          : _tr(_l10n.guardarCambios),
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
