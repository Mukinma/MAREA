import 'dart:math';
import 'dart:typed_data';

import 'package:marea/core/errors/app_failure.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CommunityRepository {
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  });
  Future<CommunityPost?> post(String id);
  Future<void> savePost(PostInput input, {String? id});
  Future<void> deletePost(String id);
  Future<Set<String>> savedPostIds();
  Future<void> setSaved(String postId, bool saved);
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  });
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  });
  Future<Mission?> mission(String id);
  Future<String> createMission(MissionInput input);
  Future<void> updateMission(String id, MissionInput input);
  Future<void> setMissionStatus(String id, String status, {String? reason});
  Future<List<MissionApplication>> applications({String? missionId});
  Future<void> apply(String missionId, String message);
  Future<void> withdraw(String applicationId);
  Future<void> review(String applicationId, String decision);
  Future<List<MissionDraft>> missionDrafts();
  Future<MissionDraft?> missionDraft(String id);
  Future<String> saveMissionDraft(
    Map<String, dynamic> data, {
    required String id,
  });
  Future<String> publishMissionDraft(String id, MissionInput input);
  Future<void> deleteMissionDraft(String id);
  Future<List<Mission>> savedMissions({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  });
  Future<Set<String>> savedMissionIds();
  Future<void> setMissionSaved(String id, bool saved);
  Future<String> submitApplication(
    String missionId,
    MissionApplicationInput input,
  );
  Future<Set<String>> missionFinalists(String missionId);
  Future<void> setMissionFinalist(
    String missionId,
    String applicationId,
    bool finalist,
  );
  Future<void> confirmMissionSelection(
    String missionId,
    List<String> applicationIds,
  );
  Future<void> report({
    String? postId,
    String? missionId,
    required String reason,
  });
  Future<List<ContentReport>> reports({int offset = 0});
  Future<void> moderate(String id, {required bool mission, required bool hide});
  Future<String> uploadImage(Uint8List png);
  Future<String> imageUrl(String path);
  Future<void> removeImage(String path);
  Future<String> uploadMissionImage(Uint8List png);
  Future<String> missionImageUrl(String path);
  Future<void> removeMissionImage(String path);
}

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client);
  final SupabaseClient _client;
  static const pageSize = 30;

  String get _userId =>
      _client.auth.currentUser?.id ??
      (throw const AppFailure(
        'Inicia sesión nuevamente para continuar.',
        kind: AppFailureKind.invalidSession,
      ));

  Future<T> _run<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw communityFailure(error);
    }
  }

  @override
  Future<List<CommunityPost>> posts({
    String? authorId,
    String query = '',
    String? category,
    bool savedOnly = false,
    int offset = 0,
  }) => _run(() async {
    var request = _client.from('posts').select();
    if (authorId != null) request = request.eq('author_id', authorId);
    if (category != null) request = request.eq('category', category);
    if (query.trim().isNotEmpty) {
      // Quote the entire value so punctuation cannot change PostgREST filters.
      final pattern = query
          .trim()
          .replaceAll(r'\', r'\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll('"', r'\"');
      request = request.or('title.ilike."%$pattern%",body.ilike."%$pattern%"');
    }
    if (savedOnly) {
      final ids = await savedPostIds();
      if (ids.isEmpty) return <CommunityPost>[];
      request = request.inFilter('id', ids.toList());
    }
    final start = max(0, offset);
    final rows = await request
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(start, start + pageSize - 1);
    return rows.map(CommunityPost.fromJson).toList();
  });

  @override
  Future<CommunityPost?> post(String id) => _run(() async {
    final row = await _client.from('posts').select().eq('id', id).maybeSingle();
    return row == null ? null : CommunityPost.fromJson(row);
  });

  @override
  Future<void> savePost(PostInput input, {String? id}) => _run(() async {
    final error = input.validate();
    if (error != null) throw AppFailure(error);
    if (id == null) {
      await _client.from('posts').insert(input.toJson());
    } else {
      await _client
          .from('posts')
          .update({...input.toJson()}..remove('kind'))
          .eq('id', id)
          .eq('author_id', _userId)
          .select('id')
          .single();
    }
  });

  @override
  Future<void> deletePost(String id) => _run(() async {
    await _client
        .from('posts')
        .delete()
        .eq('id', id)
        .eq('author_id', _userId)
        .select('id')
        .single();
  });

  @override
  Future<Set<String>> savedPostIds() => _run(() async {
    final rows = await _client
        .from('post_saves')
        .select('post_id')
        .eq('user_id', _userId);
    return rows.map((row) => row['post_id'] as String).toSet();
  });

  @override
  Future<void> setSaved(String postId, bool saved) => _run(() async {
    if (saved) {
      await _client
          .from('post_saves')
          .upsert(
            {'post_id': postId},
            onConflict: 'user_id,post_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('post_saves')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', _userId);
    }
  });

  @override
  Future<List<CommunityProfile>> profiles({
    List<String>? ids,
    String query = '',
  }) => _run(() async {
    if (ids != null && ids.isEmpty) return <CommunityProfile>[];
    final uniqueIds = ids?.toSet().toList();
    final batches = uniqueIds == null
        ? <List<String>?>[null]
        : <List<String>?>[
            for (var offset = 0; offset < uniqueIds.length; offset += 100)
              uniqueIds.sublist(offset, min(offset + 100, uniqueIds.length)),
          ];
    final profiles = <CommunityProfile>[];
    for (final batch in batches) {
      final rows = await _client.rpc(
        'community_profiles',
        params: {'profile_ids': batch, 'query_text': query.trim()},
      );
      profiles.addAll(
        (rows as List).map(
          (row) =>
              CommunityProfile.fromJson(Map<String, dynamic>.from(row as Map)),
        ),
      );
    }
    return profiles;
  });

  @override
  Future<List<Mission>> missions({
    String? authorId,
    String query = '',
    String? category,
    UserType? targetType,
    String scope = 'all',
    int offset = 0,
  }) => _run(() async {
    final rows = await _client.rpc(
      'list_missions',
      params: {
        'author_filter': authorId,
        'query_text': query.trim(),
        'category_filter': category,
        'target_filter': targetType?.databaseValue,
        'scope_filter': scope,
        'page_offset': max(0, offset),
      },
    );
    return (rows as List)
        .map((row) => Mission.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  });

  @override
  Future<Mission?> mission(String id) => _run(() async {
    final rows =
        await _client.rpc('list_missions', params: {'mission_filter': id})
            as List;
    return rows.isEmpty
        ? null
        : Mission.fromJson(Map<String, dynamic>.from(rows.first as Map));
  });

  @override
  Future<String> createMission(MissionInput input) => _run(() async {
    final error = input.validate();
    if (error != null) throw AppFailure(error);
    return await _client.rpc(
          'create_mission',
          params: {'mission_input': input.toJson()},
        )
        as String;
  });

  @override
  Future<void> updateMission(String id, MissionInput input) => _run(() async {
    final error = input.validate(allowPast: true);
    if (error != null) throw AppFailure(error);
    await _client.rpc(
      'update_mission',
      params: {'mission_id': id, 'mission_input': input.toJson()},
    );
  });

  @override
  Future<void> setMissionStatus(
    String id,
    String status, {
    String? reason,
  }) => _run(() async {
    if (!{'open', 'closed', 'cancelled', 'completed'}.contains(status)) {
      throw const AppFailure('Elige un estado válido.');
    }
    final cancellationReason = reason?.trim();
    if (status == 'cancelled' &&
        (cancellationReason == null ||
            cancellationReason.length < 5 ||
            cancellationReason.length > 500)) {
      throw const AppFailure(
        'Describe el motivo de cancelación usando entre 5 y 500 caracteres.',
      );
    }
    await _client.rpc(
      'set_mission_status',
      params: {
        'mission_id': id,
        'new_status': status,
        'cancellation_reason': status == 'cancelled'
            ? cancellationReason
            : null,
      },
    );
  });

  @override
  Future<List<MissionApplication>> applications({String? missionId}) =>
      _run(() async {
        var request = _client.from('mission_applications').select();
        request = missionId == null
            ? request.eq('applicant_id', _userId)
            : request.eq('mission_id', missionId);
        final rows = await request
            .order('created_at', ascending: false)
            .order('id', ascending: false);
        return rows.map(MissionApplication.fromJson).toList();
      });

  @override
  Future<void> apply(String missionId, String message) => _run(() async {
    if (message.trim().isEmpty || message.trim().length > 1000) {
      throw const AppFailure(
        'Cuenta por qué quieres participar usando entre 1 y 1000 caracteres.',
      );
    }
    await _client.rpc(
      'apply_to_mission',
      params: {'mission_id': missionId, 'application_message': message.trim()},
    );
  });

  @override
  Future<void> withdraw(String applicationId) => _run(() async {
    await _client.rpc(
      'withdraw_application',
      params: {'application_id': applicationId},
    );
  });

  @override
  Future<void> review(String applicationId, String decision) => _run(() async {
    if (!{'accepted', 'rejected'}.contains(decision)) {
      throw const AppFailure('Elige aceptar o rechazar la solicitud.');
    }
    await _client.rpc(
      'review_application',
      params: {'application_id': applicationId, 'decision': decision},
    );
  });

  @override
  Future<List<MissionDraft>> missionDrafts() => _run(() async {
    final rows = await _client
        .from('mission_drafts')
        .select()
        .isFilter('published_at', null)
        .order('updated_at', ascending: false);
    return rows.map(MissionDraft.fromJson).toList();
  });
  @override
  Future<MissionDraft?> missionDraft(String id) => _run(() async {
    final row = await _client
        .from('mission_drafts')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : MissionDraft.fromJson(row);
  });
  @override
  Future<String> saveMissionDraft(
    Map<String, dynamic> data, {
    required String id,
  }) => _run(
    () async =>
        await _client.rpc(
              'save_mission_draft',
              params: {'draft_id': id, 'draft_input': data},
            )
            as String,
  );
  @override
  Future<String> publishMissionDraft(String id, MissionInput input) =>
      _run(() async {
        final error = input.validate();
        if (error != null) throw AppFailure(error);
        return await _client.rpc(
              'publish_mission_draft',
              params: {'draft_id': id, 'mission_input': input.toJson()},
            )
            as String;
      });
  @override
  Future<void> deleteMissionDraft(String id) => _run(() async {
    final draft = await missionDraft(id);
    await _client.rpc('delete_mission_draft', params: {'draft_id': id});
    final image = draft?.data['image_path'] as String?;
    if (image != null) {
      try {
        await removeMissionImage(image);
      } catch (_) {
        // Storage refuses removal while another draft or mission references it.
      }
    }
  });
  @override
  Future<List<Mission>> savedMissions({
    String query = '',
    String? category,
    UserType? targetType,
    int offset = 0,
  }) => _run(() async {
    final rows =
        await _client.rpc(
              'list_saved_missions',
              params: {
                'query_text': query.trim(),
                'category_filter': category,
                'target_filter': targetType?.databaseValue,
                'page_offset': max(0, offset),
              },
            )
            as List;
    return rows
        .map((row) => Mission.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList();
  });
  @override
  Future<Set<String>> savedMissionIds() => _run(() async {
    final rows = await _client.from('mission_saves').select('mission_id');
    return rows.map((r) => r['mission_id'] as String).toSet();
  });
  @override
  Future<void> setMissionSaved(String id, bool saved) => _run(() async {
    await _client.rpc(
      'set_mission_saved',
      params: {'mission_id': id, 'is_saved': saved},
    );
  });
  @override
  Future<String> submitApplication(
    String missionId,
    MissionApplicationInput input,
  ) => _run(() async {
    final error = input.validate();
    if (error != null) throw AppFailure(error);
    return await _client.rpc(
          'submit_mission_application',
          params: {
            'mission_id': missionId,
            'application_input': input.toJson(),
          },
        )
        as String;
  });
  @override
  Future<Set<String>> missionFinalists(String missionId) => _run(() async {
    final rows = await _client
        .from('mission_finalists')
        .select('application_id')
        .eq('mission_id', missionId);
    return rows.map((r) => r['application_id'] as String).toSet();
  });
  @override
  Future<void> setMissionFinalist(
    String missionId,
    String applicationId,
    bool finalist,
  ) => _run(() async {
    await _client.rpc(
      'set_mission_finalist',
      params: {
        'mission_id': missionId,
        'application_id': applicationId,
        'is_finalist': finalist,
      },
    );
  });
  @override
  Future<void> confirmMissionSelection(
    String missionId,
    List<String> applicationIds,
  ) => _run(() async {
    if (applicationIds.isEmpty ||
        applicationIds.length > 100 ||
        applicationIds.toSet().length != applicationIds.length) {
      throw const AppFailure(
        'Selecciona entre 1 y 100 candidaturas distintas.',
      );
    }
    await _client.rpc(
      'confirm_mission_selection',
      params: {'mission_id': missionId, 'application_ids': applicationIds},
    );
  });

  @override
  Future<void> report({
    String? postId,
    String? missionId,
    required String reason,
  }) => _run(() async {
    if ((postId == null) == (missionId == null)) {
      throw const AppFailure('Selecciona el contenido que deseas reportar.');
    }
    if (reason.trim().length < 5 || reason.trim().length > 500) {
      throw const AppFailure(
        'Describe el motivo usando entre 5 y 500 caracteres.',
      );
    }
    await _client.from('content_reports').insert({
      'post_id': postId,
      'mission_id': missionId,
      'reason': reason.trim(),
    });
  });

  @override
  Future<List<ContentReport>> reports({int offset = 0}) => _run(() async {
    final rows = await _client
        .from('content_reports')
        .select()
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(max(0, offset), max(0, offset) + pageSize - 1);
    return rows.map(ContentReport.fromJson).toList();
  });

  @override
  Future<void> moderate(
    String id, {
    required bool mission,
    required bool hide,
  }) => _run(() async {
    await _client.rpc(
      'moderate_content',
      params: {
        'content_id': id,
        'content_kind': mission ? 'mission' : 'post',
        'hide_content': hide,
      },
    );
  });

  @override
  Future<String> uploadImage(Uint8List png) => _uploadImage(png, 'post-images');

  @override
  Future<String> uploadMissionImage(Uint8List png) =>
      _uploadImage(png, 'mission-images');

  Future<String> _uploadImage(Uint8List png, String bucket) => _run(() async {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (png.length < signature.length ||
        png.length > 4 * 1024 * 1024 ||
        List.generate(
          signature.length,
          (i) => png[i] == signature[i],
        ).contains(false)) {
      throw const AppFailure('Elige una imagen PNG de hasta 4 MB.');
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    final uuid =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    final path = '$_userId/$uuid.png';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          png,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: false,
          ),
        );
    return path;
  });

  @override
  Future<String> imageUrl(String path) => _run(
    () => _client.storage.from('post-images').createSignedUrl(path, 600),
  );

  @override
  Future<String> missionImageUrl(String path) => _run(
    () => _client.storage.from('mission-images').createSignedUrl(path, 600),
  );

  @override
  Future<void> removeImage(String path) => _removeImage(path, 'post-images');

  @override
  Future<void> removeMissionImage(String path) =>
      _removeImage(path, 'mission-images');

  Future<void> _removeImage(String path, String bucket) => _run(() async {
    if (!path.startsWith('$_userId/')) {
      throw const AppFailure('Solo puedes eliminar tus propias imágenes.');
    }
    await _client.storage.from(bucket).remove([path]);
  });
}

AppFailure communityFailure(Object error) {
  final message = error.toString().toLowerCase();
  if (message.contains('pgrst202') ||
      message.contains('pgrst205') ||
      message.contains('42p01') ||
      message.contains('schema cache') ||
      message.contains('bucket not found')) {
    return const AppFailure(
      'La comunidad todavía no está disponible. Falta activar la migración de comunidad en Supabase.',
    );
  }
  if (message.contains('authentication_required') ||
      message.contains('account_required')) {
    return const AppFailure(
      'Inicia sesión nuevamente para continuar.',
      kind: AppFailureKind.invalidSession,
    );
  }
  if (message.contains('mission_compensation_locked')) {
    return const AppFailure(
      'La compensación queda fija desde la primera candidatura.',
    );
  }
  if (message.contains('invalid_application_evidence')) {
    return const AppFailure(
      'Revisa las muestras: deben ser fichas propias publicadas o enlaces HTTPS válidos.',
    );
  }
  if (message.contains('application_operation_conflict')) {
    return const AppFailure(
      'Este envío ya se guardó con otros datos. Consulta Mis candidaturas.',
    );
  }
  if (message.contains('draft_already_published')) {
    return const AppFailure(
      'Este borrador ya fue publicado. Abre la misión desde Mis misiones.',
    );
  }
  if (message.contains('mission_unavailable')) {
    return const AppFailure('Esta misión ya no está disponible.');
  }
  if (message.contains('mission_conditions_locked')) {
    return const AppFailure(
      'Las condiciones ya fueron aceptadas y no pueden modificarse.',
    );
  }
  if (message.contains('mission_capacity_cannot_decrease')) {
    return const AppFailure('Solo puedes aumentar el cupo de esta misión.');
  }
  if (message.contains('mission_terminal')) {
    return const AppFailure(
      'Una misión cancelada o completada ya no puede modificarse.',
    );
  }
  if (message.contains('mission_not_started')) {
    return const AppFailure(
      'Puedes completar la misión después de su fecha de inicio.',
    );
  }
  if (message.contains('mission_must_be_future')) {
    return const AppFailure(
      'Elige una fecha y hora futuras para abrir la misión.',
    );
  }
  if (message.contains('application_withdrawn')) {
    return const AppFailure(
      'Esta solicitud fue retirada y ya no puede revisarse.',
    );
  }
  if (message.contains('invalid_cancellation_reason')) {
    return const AppFailure(
      'Describe el motivo de cancelación usando entre 5 y 500 caracteres.',
    );
  }
  if (message.contains('mission_image_in_use') ||
      message.contains('mission_image_immutable')) {
    return const AppFailure(
      'La imagen está vinculada a una misión. Cambia primero la imagen de la misión.',
    );
  }
  if (message.contains('invalid_mission_image') ||
      message.contains('invalid_post_image')) {
    return const AppFailure(
      'No pudimos validar la imagen. Vuelve a seleccionarla e inténtalo de nuevo.',
    );
  }
  if (message.contains('post_image_in_use') ||
      message.contains('post_image_immutable')) {
    return const AppFailure(
      'La imagen está vinculada a una publicación. Cambia primero la imagen de la publicación.',
    );
  }
  if (message.contains('mission_full')) {
    return const AppFailure('Esta misión ya alcanzó su cupo.');
  }
  if (message.contains('mission_closed') ||
      message.contains('mission_started')) {
    return const AppFailure('Esta misión ya no recibe solicitudes.');
  }
  if (message.contains('target_type') || message.contains('target_mismatch')) {
    return const AppFailure('Esta misión busca otro tipo de perfil.');
  }
  if (message.contains('post_kind') ||
      message.contains('kind_not_allowed') ||
      message.contains('role_restriction')) {
    return const AppFailure(
      'Este tipo de publicación no está disponible para tu perfil.',
    );
  }
  if (message.contains('own_mission') || message.contains('self_application')) {
    return const AppFailure(
      'No puedes solicitar participar en tu propia misión.',
    );
  }
  if (message.contains('23505') || message.contains('already_applied')) {
    return const AppFailure(
      'Ya registraste esta solicitud. Actualiza la pantalla para verla.',
    );
  }
  if (message.contains('owner_required') ||
      message.contains('admin_required') ||
      message.contains('42501') ||
      message.contains('forbidden') ||
      message.contains('row-level security')) {
    return const AppFailure(
      'No tienes permiso para realizar esta acción. Actualiza tu sesión e inténtalo de nuevo.',
    );
  }
  if (message.contains('pgrst116') || message.contains('not_found')) {
    return const AppFailure(
      'Este contenido ya no está disponible. Actualiza la pantalla.',
    );
  }
  if (message.contains('23514') || message.contains('invalid_')) {
    return const AppFailure('Revisa los datos e inténtalo nuevamente.');
  }
  return AppFailureMapper.from(error);
}
