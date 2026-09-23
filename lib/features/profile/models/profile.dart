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
    ...toUpdateJson(),
    'role': role.databaseValue,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  ProfileUpdateInput get updateInput => ProfileUpdateInput(
    fullName: fullName,
    username: username,
    bio: bio,
    userType: userType,
    avatarUrl: avatarUrl,
    avatarPath: avatarPath,
    coverPath: coverPath,
    coverPreset: coverPreset,
    website: website,
    interests: interests,
    goals: goals,
    onboardingStatus: onboardingStatus,
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
    required this.userType,
    required this.avatarUrl,
    this.avatarPath,
    this.coverPath,
    this.coverPreset = 'marea',
    this.website,
    this.interests = const [],
    this.goals = const [],
    this.onboardingStatus = OnboardingStatus.pending,
  });

  final String fullName;
  final String username;
  final String? bio;
  final UserType userType;
  final String? avatarUrl;
  final String? avatarPath;
  final String? coverPath;
  final String coverPreset;
  final String? website;
  final List<String> interests;
  final List<String> goals;
  final OnboardingStatus onboardingStatus;

  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'username': username.trim().toLowerCase(),
    'bio': bio?.trim().isEmpty ?? true ? null : bio!.trim(),
    'user_type': userType.databaseValue,
    'avatar_path': avatarPath,
    'cover_path': coverPath,
    'cover_preset': coverPreset,
    'website': website?.trim().isEmpty ?? true ? null : website!.trim(),
    'interests': ProfilePreferences.normalizeInterests(interests),
    'goals': ProfilePreferences.normalizeGoals(goals),
    'onboarding_status': onboardingStatus.name,
  };
}
