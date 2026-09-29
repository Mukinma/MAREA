import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/core/session/app_session_controller.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/core/utils/form_validators.dart';
import 'package:marea/features/auth/presentation/profile_type_picker.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/community/presentation/post_location_picker.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/profile/presentation/onboarding_screen.dart';
import 'package:marea/shared/widgets/auth_layout.dart';
import 'package:marea/shared/widgets/marea_surface.dart';
import 'package:marea/shared/widgets/marea_text_field.dart';
import 'package:marea/shared/widgets/primary_button.dart';
import 'package:marea/shared/widgets/profile_image.dart';
import 'package:marea/shared/widgets/session_feedback.dart';
import 'package:marea/shared/widgets/social_avatar.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({
    required this.controller,
    this.preferencesOnly = false,
    super.key,
  });
  final AppSessionController controller;
  final bool preferencesOnly;
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final String _accountId;
  late final UserType _type;
  late final TextEditingController _name, _bio, _contact;
  late final Map<String, TextEditingController> _hours;
  late bool _collaboration;
  late final Set<String> _interests, _goals;
  String? _location;
  PostCoordinates? _coordinates;
  late int _step;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile!;
    _accountId = profile.id;
    _type = profile.userType;
    _name = TextEditingController(text: profile.fullName);
    _bio = TextEditingController(text: profile.bio);
    _contact = TextEditingController(text: profile.contactUrl);
    _hours = {
      for (final day in ProfilePreferences.weekdays.keys)
        day: TextEditingController(
          text: profile.businessHours.containsKey(day)
              ? profile.businessHours[day] ?? 'cerrado'
              : '',
        ),
    };
    _collaboration = profile.openToCollaboration;
    _interests = {...profile.interests};
    _goals = {...profile.goals};
    _location = profile.location;
    _coordinates = profile.locationLatitude == null
        ? null
        : PostCoordinates(
            latitude: profile.locationLatitude!,
            longitude: profile.locationLongitude!,
            precision: PostLocationPrecision.values.byName(
              profile.locationPrecision!,
            ),
          );
    _step = math.min(profile.setupStep, _type.setupSteps - 1);
  }

  Uint8List? _photo;
  bool _saving = false;
  String? _error;
  bool get _busy => _saving || widget.controller.isBusy;
  bool get _preferences =>
      widget.preferencesOnly || (_type == UserType.general && _step == 1);
  bool get _last => _step == _type.setupSteps - 1;
  String get _title => _preferences
      ? 'Tus intereses'
      : _step == 0
      ? (_type == UserType.general || _type == UserType.creator
            ? 'Tu imagen'
            : 'Tu marca')
      : _type == UserType.business && _step == 2
      ? 'Dónde y cuándo'
      : _last
      ? 'Tu primera ficha'
      : _type == UserType.creator
      ? 'Tu trabajo'
      : 'Tu contacto';
  ProfileMediaRepository get _media =>
      widget.controller.mediaRepository ?? SupabaseProfileMediaRepository();
  @override
  void dispose() {
    for (final c in [_name, _bio, _contact, ..._hours.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final bytes = await ProfileImagePicker.pick(avatar: true);
      if (mounted &&
          widget.controller.profile?.id == _accountId &&
          bytes != null) {
        setState(() => _photo = bytes);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppFailureMapper.from(error).message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save({String? route}) async {
    final before = widget.controller.profile;
    if (_busy ||
        before == null ||
        before.id != _accountId ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    String? staged;
    bool saved = false;
    try {
      var draft = before;
      if (!widget.preferencesOnly && _step == 0) {
        if (_photo != null) staged = await _media.upload(_photo!);
        draft = draft.copyWith(
          fullName: _name.text,
          bio: _bio.text,
          avatarPath: staged ?? before.avatarPath,
        );
      } else if (!_preferences && _step == 1) {
        draft = draft.copyWith(
          bio: _bio.text,
          contactUrl: _contact.text,
          openToCollaboration: _type == UserType.creator
              ? _collaboration
              : false,
        );
      } else if (!_preferences && _type == UserType.business && _step == 2) {
        draft = draft.copyWith(
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
        );
      }
      if (!mounted || widget.controller.profile?.id != before.id) return;
      saved = await widget.controller.updateProfile(
        draft.updateWith(
          interests: _preferences ? _interests.toList() : null,
          goals: _preferences ? _goals.toList() : null,
          setupStep: widget.preferencesOnly
              ? null
              : math.max(before.setupStep, _step + 1),
        ),
      );
      if (!saved || !mounted || widget.controller.profile?.id != _accountId) {
        return;
      }
      _photo = null;
      if (staged != null &&
          before.avatarPath != null &&
          before.avatarPath != staged) {
        try {
          await _media.remove(before.avatarPath!);
        } catch (_) {
          /* Server cleanup retries abandoned media. */
        }
      }
      if (!mounted) return;
      if (route != null) {
        context.go(route);
      } else if (widget.preferencesOnly || _last) {
        context.go('/profile');
      } else {
        setState(() => _step++);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppFailureMapper.from(error).message);
      }
    } finally {
      if (!saved && staged != null) {
        try {
          await _media.remove(staged);
        } catch (_) {
          /* Cleanup retries on next upload. */
        }
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _identity(Profile profile) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Column(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: MareaSurface(
                radius: 48,
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: ProfileImage(
                    path: profile.avatarPath,
                    preview: _photo,
                    repository: widget.controller.mediaRepository,
                    fallback: SocialAvatar(
                      initials: profile.initials,
                      size: 88,
                    ),
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Elegir foto'),
            ),
            if (_photo != null)
              TextButton(
                onPressed: _busy ? null : () => setState(() => _photo = null),
                child: const Text('Descartar foto'),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      MareaTextField(
        controller: _name,
        label: _type.nameLabel,
        enabled: !_busy,
        validator: FormValidators.fullName,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      MareaTextField(
        controller: _bio,
        label: 'Bio',
        enabled: !_busy,
        maxLines: 3,
        maxLength: 160,
        validator: FormValidators.bio,
      ),
    ],
  );
  Widget _contactFields() => Column(
    children: [
      if (_type == UserType.creator) ...[
        MareaTextField(
          controller: _bio,
          label: 'Bio',
          maxLines: 3,
          maxLength: 160,
          enabled: !_busy,
          validator: FormValidators.bio,
        ),
        const SizedBox(height: 16),
      ],
      MareaTextField(
        controller: _contact,
        label: 'Contacto',
        hint: 'https://...',
        enabled: !_busy,
        keyboardType: TextInputType.url,
        validator: ProfilePreferences.websiteError,
      ),
      if (_type == UserType.creator)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('Disponible para colaborar'),
          value: _collaboration,
          onChanged: _busy
              ? null
              : (v) => setState(() => _collaboration = v ?? false),
        ),
    ],
  );
  Widget _businessFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MareaSurface(
        inset: true,
        radius: 16,
        child: ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: const Text('Ubicación'),
          subtitle: Text(_location ?? 'Opcional'),
          trailing: _location == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  tooltip: 'Quitar ubicación',
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _location = null;
                          _coordinates = null;
                        }),
                  icon: const Icon(Icons.close),
                ),
          onTap: _busy
              ? null
              : () async {
                  final selection = await showCommunityLocationPicker(
                    context,
                    initial: _location == null || _coordinates == null
                        ? null
                        : PostLocationSelection(
                            label: _location!,
                            coordinates: _coordinates!,
                          ),
                  );
                  if (selection != null &&
                      mounted &&
                      widget.controller.profile?.id == _accountId) {
                    setState(() {
                      _location = selection.label;
                      _coordinates = selection.coordinates;
                    });
                  }
                },
        ),
      ),
      const SizedBox(height: 20),
      const Text('Horarios', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text(
        'Hora local · vacío para omitir',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      for (final day in ProfilePreferences.weekdays.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MareaTextField(
            controller: _hours[day.key]!,
            label: day.value,
            hint: '09:00-18:00 o cerrado',
            enabled: !_busy,
            validator: (v) =>
                v == null ||
                    v.trim().isEmpty ||
                    v.trim().toLowerCase() == 'cerrado'
                ? null
                : ProfilePreferences.hoursError({day.key: v.trim()}),
          ),
        ),
    ],
  );
  Widget _preferenceFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PreferenceChips(
        catalog: ProfilePreferences.interests,
        selected: _interests,
        enabled: !_busy,
        onChanged: (v) => setState(() {
          _interests
            ..clear()
            ..addAll(v);
        }),
      ),
      const SizedBox(height: 24),
      const Text('¿Qué buscas?', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      PreferenceChips(
        catalog: ProfilePreferences.goals,
        selected: _goals,
        enabled: !_busy,
        onChanged: (v) => setState(() {
          _goals
            ..clear()
            ..addAll(v);
        }),
      ),
    ],
  );
  Widget _firstItem() {
    final kind = _type == UserType.creator
        ? 'project'
        : _type == UserType.entrepreneur
        ? 'product'
        : 'service';
    final title = _type == UserType.creator
        ? 'Crear mi primera obra'
        : _type == UserType.entrepreneur
        ? 'Crear mi primera ficha'
        : 'Crear mi primer servicio';
    return Column(
      children: [
        ProfileTypeIcon(type: _type),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => _save(route: '/showcase/new?kind=$kind'),
          icon: const Icon(Icons.add_rounded),
          label: Text(title),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final profile = widget.controller.profile;
      if (profile == null || profile.id != _accountId) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return PopScope(
        canPop: !_busy,
        child: AuthLayout(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Atrás',
                    onPressed: _busy
                        ? null
                        : () {
                            if (!widget.preferencesOnly && _step > 0) {
                              setState(() => _step--);
                            } else {
                              context.go('/profile');
                            }
                          },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  if (!widget.preferencesOnly)
                    Text(
                      '${_step + 1} de ${_type.setupSteps}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              if (!widget.preferencesOnly) ...[
                Text(
                  _type.label,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: profile.setupStep / _type.setupSteps,
                  color: AppColors.aquaDark,
                  backgroundColor: AppColors.mint,
                ),
              ],
              const SizedBox(height: 24),
              Form(
                key: _form,
                child: _preferences
                    ? _preferenceFields()
                    : _step == 0
                    ? _identity(profile)
                    : _last
                    ? _firstItem()
                    : _type == UserType.business && _step == 2
                    ? _businessFields()
                    : _contactFields(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              SessionFeedback(controller: widget.controller),
              const SizedBox(height: 24),
              PrimaryButton(
                key: const Key('setup-save'),
                label: widget.preferencesOnly
                    ? 'Guardar'
                    : _last
                    ? 'Terminar'
                    : 'Guardar y continuar',
                isLoading: _busy,
                onPressed: _busy ? null : _save,
              ),
              TextButton(
                key: const Key('setup-skip'),
                onPressed: _busy ? null : () => context.go('/profile'),
                child: Text(widget.preferencesOnly ? 'Cancelar' : 'Ahora no'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
