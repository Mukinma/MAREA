import 'dart:async';
import 'dart:typed_data';
import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'fakes.dart';

Mission missionFixture({
  String? author,
  UserType? target,
  String status = 'open',
  bool past = false,
  bool locked = false,
  int accepted = 0,
  String title = 'Pintemos el barrio',
}) => Mission(
  id: 'mission-1',
  authorId: author ?? 'organizer',
  title: title,
  body: 'Una jornada para pintar juntos y transformar el centro cultural.',
  category: 'arte',
  location: 'Centro cultural de Manzanillo',
  startsAt: DateTime.now().add(Duration(days: past ? -5 : 5)),
  capacity: 2,
  createdAt: DateTime.now(),
  targetType: target,
  status: status,
  conditionsLockedAt: locked ? DateTime.now() : null,
  acceptedCount: accepted,
  pendingCount: 1,
  organizerName: 'Ana López',
);
MissionApplication application({
  String applicant = 'applicant',
  String status = 'pending',
}) => MissionApplication(
  id: 'application-1',
  missionId: 'mission-1',
  applicantId: applicant,
  message: 'Quiero aportar mi experiencia.',
  status: status,
  createdAt: DateTime.now(),
);

class MissionRepositoryFake implements CommunityRepository {
  Mission value = missionFixture();
  final drafts = <String, MissionDraft>{};
  final missionSaves = <String>{};
  final finalists = <String>{};
  final publishedDrafts = <String, String>{};
  @override
  Future<List<MissionDraft>> missionDrafts() async =>
      drafts.values.where((d) => !d.isPublished).toList();
  @override
  Future<MissionDraft?> missionDraft(String id) async => drafts[id];
  @override
  Future<String> saveMissionDraft(
    Map<String, dynamic> data, {
    required String id,
  }) async {
    if (failSave) throw const AppFailure('Sin conexión. Inténtalo nuevamente.');
    drafts[id] = MissionDraft(
      id: id,
      data: Map.from(data),
      updatedAt: DateTime.now(),
    );
    return id;
  }

  @override
  Future<String> publishMissionDraft(String id, MissionInput input) async {
    if (publishedDrafts.containsKey(id)) return publishedDrafts[id]!;
    final missionId = await createMission(input);
    publishedDrafts[id] = missionId;
    drafts[id] = MissionDraft(
      id: id,
      data: input.toJson(),
      updatedAt: DateTime.now(),
      publishedMissionId: missionId,
      publishedAt: DateTime.now(),
    );
    return missionId;
  }

  @override
  Future<void> deleteMissionDraft(String id) async {
    drafts.remove(id);
  }

  @override
  Future<List<Mission>> savedMissions({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) async => offset == 0 && missionSaves.contains(value.id) ? [value] : [];
  @override
  Future<Set<String>> savedMissionIds() async => Set.from(missionSaves);
  @override
  Future<void> setMissionSaved(String id, bool saved) async {
    saved ? missionSaves.add(id) : missionSaves.remove(id);
  }

  @override
  Future<String> submitApplication(
    String id,
    MissionApplicationInput input,
  ) async {
    if (failSave) throw const AppFailure('Sin conexión. Inténtalo nuevamente.');
    requests = [
      MissionApplication(
        id: 'application-1',
        missionId: id,
        applicantId: sampleProfile.id,
        message: input.message,
        status: 'pending',
        createdAt: DateTime.now(),
        availabilityConfirmed: input.availabilityConfirmed,
        evidence: input.evidence,
      ),
    ];
    return 'application-1';
  }

  @override
  Future<Set<String>> missionFinalists(String id) async => Set.from(finalists);
  @override
  Future<void> setMissionFinalist(
    String missionId,
    String id,
    bool finalist,
  ) async {
    finalist ? finalists.add(id) : finalists.remove(id);
  }

  @override
  Future<void> confirmMissionSelection(String id, List<String> ids) async {
    for (final appId in ids) {
      await review(appId, 'accepted');
    }
  }

  List<MissionApplication> requests = [];
  String? reviewed, lastScope, lastQuery, lastCategory;
  UserType? lastTarget;
  int withdrawals = 0, creations = 0, updates = 0, listings = 0;
  bool full = false, unavailable = false, failSave = false;
  Completer<void>? saveGate;
  MissionInput? saved;
  @override
  Future<Mission?> mission(String id) async => unavailable ? null : value;
  @override
  Future<List<Mission>> missions({
    String? authorId,
    int offset = 0,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
  }) async {
    listings++;
    lastScope = scope;
    lastQuery = query;
    lastCategory = category;
    lastTarget = targetType;
    return offset == 0 ? [value] : [];
  }

  @override
  Future<List<MissionApplication>> applications({String? missionId}) async =>
      requests;
  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) async => [
    CommunityProfile(
      id: value.authorId,
      fullName: 'Ana López',
      username: 'ana',
      userType: UserType.creator,
    ),
    const CommunityProfile(
      id: 'applicant',
      fullName: 'Mariana Torres',
      username: 'marianatorres',
      userType: UserType.creator,
    ),
  ];
  @override
  Future<String> createMission(MissionInput input) async {
    creations++;
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw const AppFailure('Sin conexión. Inténtalo nuevamente.');
    saved = input;
    value = _from(input);
    return value.id;
  }

  @override
  Future<void> updateMission(String id, MissionInput input) async {
    updates++;
    saved = input;
    if (failSave) throw const AppFailure('Sin conexión. Inténtalo nuevamente.');
    value = _from(input);
  }

  Mission _from(MissionInput i) => Mission(
    id: value.id,
    authorId: sampleProfile.id,
    title: i.title,
    body: i.body,
    category: i.category,
    location: i.location,
    startsAt: i.startsAt,
    capacity: i.capacity,
    createdAt: value.createdAt,
    targetType: i.targetType,
    imagePath: i.imagePath,
    coordinates: i.coordinates,
    compensationType: i.compensationType,
    compensationAmountCents: i.compensationAmountCents,
    conditions: i.conditions,
    requirements: i.requirements,
    conditionsLockedAt: value.conditionsLockedAt,
    organizerName: 'Ana López',
  );
  @override
  Future<void> setMissionStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    value = Mission(
      id: value.id,
      authorId: value.authorId,
      title: value.title,
      body: value.body,
      category: value.category,
      location: value.location,
      startsAt: value.startsAt,
      capacity: value.capacity,
      createdAt: value.createdAt,
      status: status,
      cancellationReason: reason,
    );
  }

  @override
  Future<void> withdraw(String id) async {
    withdrawals++;
    requests = [
      for (final a in requests)
        if (a.id == id)
          application(applicant: a.applicantId, status: 'withdrawn')
        else
          a,
    ];
  }

  @override
  Future<void> apply(String id, String message) async {
    requests = [application(applicant: sampleProfile.id)];
  }

  @override
  Future<void> review(String id, String decision) async {
    if (full) throw const AppFailure('Esta misión ya alcanzó su cupo.');
    reviewed = decision;
    requests = [
      for (final a in requests)
        if (a.id == id)
          application(applicant: a.applicantId, status: decision)
        else
          a,
    ];
  }

  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) async => [];
  @override
  Future<Set<String>> savedPostIds() async => {};
  @override
  Future<String> uploadMissionImage(Uint8List png) async =>
      '${sampleProfile.id}/cover.png';
  @override
  Future<String> missionImageUrl(String path) async => 'data:image/png;base64,';
  @override
  Future<void> removeMissionImage(String path) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
