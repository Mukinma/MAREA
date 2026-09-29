import 'package:marea/features/profile/models/profile_preferences.dart';
export 'package:marea/features/profile/models/profile_preferences.dart';

const _unset = Object();

enum UserType {
  general('Usuario general'),
  creator('Artista / creador'),
  entrepreneur('Emprendedor'),
  business('Negocio');

  const UserType(this.databaseValue);

  final String databaseValue;

  static UserType fromDatabase(String value) {
    return UserType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => UserType.general,
    );
  }
}

enum ProfileRole {
  user('user'),
  admin('admin');

  const ProfileRole(this.databaseValue);

  final String databaseValue;

  static ProfileRole fromDatabase(String value) {
    return ProfileRole.values.firstWhere(
      (role) => role.databaseValue == value,
      orElse: () => ProfileRole.user,
    );
  }
}

class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.userType,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    this.avatarUrl,
    this.avatarPath,
    this.coverPath,
    this.coverPreset = 'marea',
    this.website,
    this.interests = const [],
    this.goals = const [],
    this.onboardingStatus = OnboardingStatus.pending,
    this.initialProfileCompletedAt,
    this.contactUrl,
    this.openToCollaboration = false,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.locationPrecision,
    this.businessHours = const {},
    this.setupStep = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      userType: UserType.fromDatabase(json['user_type'] as String),
      role: ProfileRole.fromDatabase(json['role'] as String),
      avatarUrl: json['avatar_url'] as String?,
      avatarPath: json['avatar_path'] as String?,
      coverPath: json['cover_path'] as String?,
      coverPreset: json['cover_preset'] as String? ?? 'marea',
      website: json['website'] as String?,
      interests: List<String>.from(json['interests'] as List? ?? []),
      goals: List<String>.from(json['goals'] as List? ?? []),
      onboardingStatus: OnboardingStatus.values.firstWhere(
        (s) => s.name == json['onboarding_status'],
        orElse: () => OnboardingStatus.pending,
      ),
      initialProfileCompletedAt: DateTime.tryParse(
        json['initial_profile_completed_at'] as String? ?? '',
      ),
      contactUrl: json['contact_url'] as String?,
      openToCollaboration: json['open_to_collaboration'] as bool? ?? false,
      location: json['location'] as String?,
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      locationPrecision: json['location_precision'] as String?,
      setupStep: json['setup_step'] as int? ?? 0,
      businessHours: Map<String, String?>.from(
        json['business_hours'] as Map? ?? {},
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String fullName;
  final String username;
  final String? bio;
  final UserType userType;
  final ProfileRole role;
  final String? avatarUrl;
  final String? avatarPath;
  final String? coverPath;
  final String coverPreset;
  final String? website;
  final List<String> interests;
  final List<String> goals;
  final OnboardingStatus onboardingStatus;
  final DateTime? initialProfileCompletedAt;
  final String? contactUrl, location, locationPrecision;
  final bool openToCollaboration;
  final double? locationLatitude, locationLongitude;
  final Map<String, String?> businessHours;
  final int setupStep;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'setup_step': setupStep,
    ...toUpdateJson(),
    'role': role.databaseValue,
    'user_type': userType.databaseValue,
    'interests': interests,
    'goals': goals,
    'onboarding_status': onboardingStatus.name,
    'initial_profile_completed_at': initialProfileCompletedAt
        ?.toUtc()
        .toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  ProfileUpdateInput get updateInput => updateWith();

  ProfileUpdateInput updateWith({
    List<String>? interests,
    List<String>? goals,
    int? setupStep,
  }) => ProfileUpdateInput(
    fullName: fullName,
    username: username,
    bio: bio,
    avatarUrl: avatarUrl,
    avatarPath: avatarPath,
    coverPath: coverPath,
    coverPreset: coverPreset,
    website: website,
    contactUrl: contactUrl,
    openToCollaboration: openToCollaboration,
    location: location,
    locationLatitude: locationLatitude,
    locationLongitude: locationLongitude,
    locationPrecision: locationPrecision,
    businessHours: businessHours,
    interests: interests,
    goals: goals,
    setupStep: setupStep,
  );

  Map<String, dynamic> toUpdateJson() => updateInput.toJson();

  Profile copyWith({
    String? fullName,
    String? username,
    Object? bio = _unset,
    UserType? userType,
    Object? avatarUrl = _unset,
    Object? avatarPath = _unset,
    Object? coverPath = _unset,
    Object? website = _unset,
    String? coverPreset,
    List<String>? interests,
    List<String>? goals,
    OnboardingStatus? onboardingStatus,
    Object? initialProfileCompletedAt = _unset,
    Object? contactUrl = _unset,
    bool? openToCollaboration,
    Object? location = _unset,
    Object? locationLatitude = _unset,
    Object? locationLongitude = _unset,
    Object? locationPrecision = _unset,
    Map<String, String?>? businessHours,
    int? setupStep,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: identical(bio, _unset) ? this.bio : bio as String?,
      userType: userType ?? this.userType,
      role: role,
      avatarUrl: identical(avatarUrl, _unset)
          ? this.avatarUrl
          : avatarUrl as String?,
      avatarPath: identical(avatarPath, _unset)
          ? this.avatarPath
          : avatarPath as String?,
      coverPath: identical(coverPath, _unset)
          ? this.coverPath
          : coverPath as String?,
      website: identical(website, _unset) ? this.website : website as String?,
      coverPreset: coverPreset ?? this.coverPreset,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      initialProfileCompletedAt: identical(initialProfileCompletedAt, _unset)
          ? this.initialProfileCompletedAt
          : initialProfileCompletedAt as DateTime?,
      contactUrl: identical(contactUrl, _unset)
          ? this.contactUrl
          : contactUrl as String?,
      openToCollaboration: openToCollaboration ?? this.openToCollaboration,
      location: identical(location, _unset)
          ? this.location
          : location as String?,
      locationLatitude: identical(locationLatitude, _unset)
          ? this.locationLatitude
          : locationLatitude as double?,
      locationLongitude: identical(locationLongitude, _unset)
          ? this.locationLongitude
          : locationLongitude as double?,
      locationPrecision: identical(locationPrecision, _unset)
          ? this.locationPrecision
          : locationPrecision as String?,
      businessHours: businessHours ?? this.businessHours,
      setupStep: setupStep ?? this.setupStep,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class ProfileUpdateInput {
  const ProfileUpdateInput({
    required this.fullName,
    required this.username,
    required this.bio,
    this.avatarUrl,
    this.avatarPath,
    this.coverPath,
    this.coverPreset = 'marea',
    this.website,
    this.contactUrl,
    this.openToCollaboration = false,
    this.location,
    this.locationLatitude,
    this.locationLongitude,
    this.locationPrecision,
    this.businessHours = const {},
    this.interests,
    this.goals,
    this.setupStep,
  });
  final String fullName, username, coverPreset;
  final String? bio,
      avatarUrl,
      avatarPath,
      coverPath,
      website,
      contactUrl,
      location,
      locationPrecision;
  final double? locationLatitude, locationLongitude;
  final bool openToCollaboration;
  final Map<String, String?> businessHours;
  final List<String>? interests, goals;
  final int? setupStep;
  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'username': username.trim().toLowerCase(),
    'bio': _text(bio),
    'avatar_path': avatarPath,
    'cover_path': coverPath,
    'cover_preset': coverPreset,
    'website': _text(website),
    'contact_url': _text(contactUrl),
    'open_to_collaboration': openToCollaboration,
    'location': _text(location),
    'location_latitude': locationLatitude,
    'location_longitude': locationLongitude,
    'location_precision': locationPrecision,
    'business_hours': businessHours,
    if (interests != null)
      'interests': ProfilePreferences.normalizeInterests(interests!),
    if (goals != null) 'goals': ProfilePreferences.normalizeGoals(goals!),
    if (setupStep != null) 'setup_step': setupStep,
  };
  static String? _text(String? value) =>
      value?.trim().isEmpty ?? true ? null : value!.trim();
}

class InitialProfileInput {
  const InitialProfileInput({
    required this.userType,
    required this.interests,
    required this.goals,
  });
  final UserType userType;
  final List<String> interests, goals;
  String? validate() {
    try {
      ProfilePreferences.normalizeInterests(interests);
      ProfilePreferences.normalizeGoals(goals);
    } on ArgumentError {
      return 'Elige opciones válidas de los intereses y objetivos.';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'profile_type': userType.databaseValue,
    'selected_interests': ProfilePreferences.normalizeInterests(interests),
    'selected_goals': ProfilePreferences.normalizeGoals(goals),
  };
}
