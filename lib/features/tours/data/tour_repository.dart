import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour_models.dart';
import 'tus_uploader.dart';

abstract class TourRepository {
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  });
  Future<List<TourRecord>> publicList(String owner);
  Future<TourRecord?> get(String id, {bool edit = false});
  Future<TourRecord> save(
    String? id,
    String title,
    Map<String, dynamic> space,
    TourDocument document,
  );
  Future<TourRecord> submit(String id);
  Future<void> pause(String id, bool paused);
  Future<List<Map<String, dynamic>>> requests();
  Future<void> review(String request, bool approve, String reason);
  Future<List<Map<String, dynamic>>> searchLinks(String query);
  Future<void> requestLink(String tour, String point);
  Future<void> revokePermission(String request);
  Future<TourProgress> progress(
    String tour,
    String revision, {
    TourProgress? save,
  });
  Future<String> beginCapture(String tour, String scene, String mode);
  Future<TourJob> submitCapture(String capture, Map<String, dynamic> manifest);
  Future<TourJob> job(String id);
  Future<void> cancelJob(String id);
  Future<TourRecord> attach(String tour, String scene, String job);
  Future<String> assetUrl(String path);
  Future<String> uploadReference(
    String owner,
    String reference,
    Uint8List bytes,
  );
  Future<TourRecord> reportAR(
    String tour,
    String point,
    String version,
    String platform,
    int seconds,
  );
  TourTusUploader uploader();
}

class SupabaseTourRepository implements TourRepository {
  SupabaseTourRepository(this.client, this.url);
  final SupabaseClient client;
  final String url;
  Future<dynamic> _rpc(String name, [Map<String, dynamic>? params]) =>
      client.rpc(name, params: params);
  @override
  Future<List<TourRecord>> list({
    String? owner,
    double? latitude,
    double? longitude,
  }) async => jsonList(
    await _rpc('tours_list', {
      'p_owner': owner,
      'p_lat': latitude,
      'p_lng': longitude,
    }),
  ).map(TourRecord.fromJson).toList();
  @override
  Future<List<TourRecord>> publicList(String owner) async => jsonList(
    await _rpc('tours_public_list', {'p_owner': owner}),
  ).map(TourRecord.fromJson).toList();
  @override
  Future<TourRecord?> get(String id, {bool edit = false}) async {
    final value = await _rpc('tours_get', {'p_tour': id, 'p_edit': edit});
    return value == null ? null : TourRecord.fromJson(value);
  }

  @override
  Future<TourRecord> save(
    String? id,
    String title,
    Map<String, dynamic> space,
    TourDocument document,
  ) async => TourRecord.fromJson(
    await _rpc('tours_save', {
      'p_tour': id,
      'p_title': title,
      'p_space': space,
      'p_document': document.data,
    }),
  );
  @override
  Future<TourRecord> submit(String id) async =>
      TourRecord.fromJson(await _rpc('tours_submit', {'p_tour': id}));
  @override
  Future<void> pause(String id, bool paused) async {
    await _rpc('tours_pause', {'p_tour': id, 'p_paused': paused});
  }

  @override
  Future<List<Map<String, dynamic>>> requests() async =>
      jsonList(await _rpc('tours_requests')).map(jsonMap).toList();
  @override
  Future<void> review(String request, bool approve, String reason) async {
    await _rpc('tours_review', {
      'p_request': request,
      'p_approve': approve,
      'p_reason': reason,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> searchLinks(String query) async =>
      jsonList(
        await _rpc('tours_link_search', {'p_query': query}),
      ).map(jsonMap).toList();
  @override
  Future<void> revokePermission(String request) async {
    await _rpc('tours_permission_revoke', {'p_request': request});
  }

  @override
  Future<void> requestLink(String tour, String point) async {
    await _rpc('tours_link_request', {'p_tour': tour, 'p_point': point});
  }

  @override
  Future<TourProgress> progress(
    String tour,
    String revision, {
    TourProgress? save,
  }) async => TourProgress.fromJson(
    revision,
    await _rpc('tours_progress', {
          'p_tour': tour,
          'p_revision': revision,
          'p_progress': save?.toJson(),
        })
        as Map<String, dynamic>?,
  );
  @override
  Future<String> beginCapture(String tour, String scene, String mode) async =>
      (await _rpc('tours_capture_begin', {
            'p_tour': tour,
            'p_scene': scene,
            'p_mode': mode,
          }))['id']
          as String;
  @override
  Future<TourJob> submitCapture(
    String capture,
    Map<String, dynamic> manifest,
  ) async {
    final j = TourJob(
      jsonMap(
        await _rpc('tours_capture_submit', {
          'p_capture': capture,
          'p_manifest': manifest,
        }),
      ),
    );
    // Server trigger/cron wakes the private dispatcher after this commit.
    return j;
  }

  @override
  Future<TourJob> job(String id) async =>
      TourJob(jsonMap(await _rpc('tours_job_get', {'p_job': id})));
  @override
  Future<void> cancelJob(String id) async {
    await _rpc('tours_job_cancel', {'p_job': id});
  }

  @override
  Future<TourRecord> attach(String tour, String scene, String job) async =>
      TourRecord.fromJson(
        await _rpc('tours_attach_result', {
          'p_tour': tour,
          'p_scene': scene,
          'p_job': job,
        }),
      );
  @override
  Future<String> assetUrl(String path) =>
      client.storage.from('tour-assets').createSignedUrl(path, 600);
  @override
  Future<String> uploadReference(
    String owner,
    String reference,
    Uint8List bytes,
  ) async {
    final path = '$owner/references/$reference.jpg';
    await client.storage
        .from('tour-assets')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<TourRecord> reportAR(
    String tour,
    String point,
    String version,
    String platform,
    int seconds,
  ) async => TourRecord.fromJson(
    await _rpc('tours_ar_report_test', {
      'p_tour': tour,
      'p_point': point,
      'p_reference_version': version,
      'p_platform': platform,
      'p_tracking_seconds': seconds,
    }),
  );
  @override
  TourTusUploader uploader() {
    final base = Uri.parse(url);
    final endpoint = base.replace(
      host: base.host.endsWith('.supabase.co')
          ? base.host.replaceFirst('.supabase.co', '.storage.supabase.co')
          : base.host,
      path: '/storage/v1/upload/resumable',
      query: null,
    );
    return TourTusUploader(
      endpoint: endpoint,
      headers: () => {
        ...client.headers,
        'Authorization':
            'Bearer ${client.auth.currentSession?.accessToken ?? ''}',
      },
    );
  }
}
