import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:marea/features/community/data/community_repository.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/home_feed/data/stories_repository.dart';
import 'package:marea/features/home_feed/models/story.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class LocalOnlyClient extends http.BaseClient {
  final http.Client inner = http.Client();
  final int port;
  LocalOnlyClient(this.port);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.scheme != 'http' || request.url.host != '127.0.0.1' || request.url.port != port || request.url.userInfo.isNotEmpty) {
      throw StateError('Foreign destination rejected');
    }
    request.followRedirects = false;
    return inner.send(request);
  }
  @override
  void close() => inner.close();
}
void main() {
  HttpOverrides.global = null;
  final runtime = Platform.environment['MAREA_LOCAL_RUNTIME'];
  if (runtime == null) throw StateError('Explicit local runtime required');
  final marker = jsonDecode(File('$runtime/.marea-task001.json').readAsStringSync()) as Map;
  final keys = jsonDecode(File('$runtime/local-keys-private.json').readAsStringSync()) as Map;
  final fixtures = jsonDecode(File('$runtime/fixtures-private.json').readAsStringSync()) as Map;
  final port = marker['api_port'] as int;
  final base = 'http://127.0.0.1:$port';
  if (keys['API_URL'] != base || marker['version'] != 2) throw StateError('Local identity mismatch');
  late SupabaseClient owner, candidate, third;
  late SupabaseCommunityRepository ownRepo, candidateRepo, thirdRepo;
  String? mission;
  final suffix = const Uuid().v4();
  setUpAll(() async {
    Future<SupabaseClient> client(String name) async {
      final user = fixtures['users'][name] as Map;
      final client = SupabaseClient(base, keys['ANON_KEY'] as String,
          httpClient: LocalOnlyClient(port), authOptions: const AuthClientOptions(autoRefreshToken: false));
      await client.auth.signInWithPassword(email: user['email'] as String, password: user['password'] as String);
      return client;
    }
    owner = await client('owner'); candidate = await client('candidateA'); third = await client('third');
    ownRepo = SupabaseCommunityRepository(owner); candidateRepo = SupabaseCommunityRepository(candidate); thirdRepo = SupabaseCommunityRepository(third);
  });
  tearDownAll(() async {await owner.dispose();await candidate.dispose();await third.dispose();});
  test('DART-01 actual community_profiles parameters and decoded response', () async {
    final profiles = await ownRepo.profiles(ids: [fixtures['users']['owner']['id'] as String]);
    expect(profiles, hasLength(1));expect(profiles.single.id, fixtures['users']['owner']['id']);
  });
  test('DART-02 actual create_mission and list_missions contracts', () async {
    mission = await ownRepo.createMission(MissionInput(title:'Synthetic Dart $suffix',body:'Synthetic local mission',category:'arte',location:'Synthetic test location',startsAt:DateTime.now().add(const Duration(hours:1)),capacity:2,compensationType:'unpaid'));
    final row = await ownRepo.mission(mission!);expect(row, isNotNull);expect(row!.id, mission);
    final raw = await owner.from('missions').select('author_id').eq('id',mission!).single();expect(raw['author_id'],fixtures['users']['owner']['id']);
  });
  test('DART-03 actual submit_mission_application and idempotent return', () async {
    final input=MissionApplicationInput(message:'Synthetic Dart application',availabilityConfirmed:true,operationId:const Uuid().v4());
    final id=await candidateRepo.submitApplication(mission!,input);final retry=await candidateRepo.submitApplication(mission!,input);expect(id,retry);
    final rows=await candidateRepo.applications(missionId:mission);expect(rows,hasLength(1));expect(rows.single.id,id);
  });
  test('DART-04 actual foreign review rejected and state preserved', () async {
    final rows=await candidateRepo.applications(missionId:mission);final id=rows.single.id;
    await expectLater(thirdRepo.review(id,'accepted'),throwsA(isA<Object>()));
    final raw=await candidate.from('mission_applications').select('status').eq('id',id).single();expect(raw['status'],'pending');
  });
  test('DART-05 actual draft/save RPCs and private response mapping', () async {
    final id=const Uuid().v4();expect(await ownRepo.saveMissionDraft({'title':'Synthetic Dart draft'},id:id),id);
    expect((await ownRepo.missionDraft(id))!.title,'Synthetic Dart draft');expect(await thirdRepo.missionDraft(id),isNull);
    await ownRepo.setMissionSaved(mission!,true);expect(await ownRepo.savedMissionIds(),contains(mission));expect(await thirdRepo.savedMissionIds(),isNot(contains(mission)));
  });
  test('DART-06 actual story publication and server-clock response', () async {
    final repo=SupabaseStoriesRepository(owner),id=const Uuid().v4();
    await repo.publish(StoryInput(id:id,text:'Synthetic Dart story'));final batch=await repo.stories();
    expect(batch.stories.any((s)=>s.id==id),isTrue);expect(batch.serverTime.toUtc().difference(DateTime.now().toUtc()).inSeconds.abs(),lessThan(10));
  });
}
