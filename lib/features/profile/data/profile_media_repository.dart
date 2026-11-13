import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:marea/core/localization/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:file_selector/file_selector.dart' as files;
import 'package:image_picker/image_picker.dart';
import 'package:marea/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileMediaRepository {
  Future<String> upload(Uint8List png);
  Future<void> remove(String path);
  Future<String> signedUrl(String path);
}

class SupabaseProfileMediaRepository implements ProfileMediaRepository {
  SupabaseClient get _client => Supabase.instance.client;
  @override
  Future<String> upload(Uint8List png) async {
    try {
      final response = await _client.functions.invoke(
        'profile-media',
        body: png,
        headers: {'Content-Type': 'image/png'},
      );
      return (response.data as Map)['path'] as String;
    } catch (error) {
      throw AppFailureMapper.from(error);
    }
  }

  @override
  Future<void> remove(String path) async {
    await _client.functions.invoke(
      'profile-media',
      method: HttpMethod.delete,
      body: {'path': path},
    );
  }

  @override
  Future<String> signedUrl(String path) =>
      _client.storage.from('profile-media').createSignedUrl(path, 600);
}

enum ProfilePhotoSource { gallery, camera, files }

abstract final class ProfileImagePicker {
  static Future<Uint8List?> pick({
    required bool avatar,
    ProfilePhotoSource source = ProfilePhotoSource.gallery,
  }) async {
    final XFile? file;
    try {
      file = source == ProfilePhotoSource.files
          ? await files.openFile(
              acceptedTypeGroups: [
                files.XTypeGroup(
                  label: AppLocalizations.tr('Imágenes'),
                  extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
                  mimeTypes: [
                    'image/jpeg',
                    'image/png',
                    'image/webp',
                    'image/heic',
                    'image/heif',
                  ],
                  uniformTypeIdentifiers: ['public.image'],
                ),
              ],
            )
          : await ImagePicker().pickImage(
              source: source == ProfilePhotoSource.camera
                  ? ImageSource.camera
                  : ImageSource.gallery,
              requestFullMetadata: false,
            );
    } on PlatformException catch (error) {
      if (error.code.contains('denied') || error.code.contains('restricted')) {
        throw const AppFailure(
          'Permite el acceso a la cámara o a tus fotos en los ajustes del dispositivo para continuar.',
        );
      }
      throw const AppFailure(
        'No pudimos abrir esa opción. Prueba Galería o Explorar archivos.',
      );
    } on UnsupportedError {
      throw const AppFailure(
        'Esta opción no está disponible en tu dispositivo. Prueba Explorar archivos.',
      );
    }
    if (file == null) return null;
    if (await file.length() > 10 * 1024 * 1024) {
      throw const AppFailure('Elige una imagen de menos de 10 MB.');
    }
    final bytes = await file.readAsBytes();
    return prepare(bytes, avatar: avatar);
  }

  static Future<Uint8List> prepare(
    Uint8List bytes, {
    required bool avatar,
  }) async {
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw const AppFailure('Elige una imagen de menos de 10 MB.');
    }
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      final int width;
      final int height;
      if (kIsWeb) {
        // Encoded ImageDescriptor dimensions are unsupported in Flutter Web.
        // Decode through the browser-supported codec to obtain image dimensions.
        codec = await ui.instantiateImageCodec(bytes);
        image = (await codec.getNextFrame()).image;
        width = image.width;
        height = image.height;
      } else {
        buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        width = descriptor.width;
        height = descriptor.height;
      }
      if (width * height > 24000000) {
        throw const AppFailure(
          'La imagen es demasiado grande. Elige una de hasta 24 megapíxeles.',
        );
      }
      final maxSide = avatar ? 640 : 1600;
      final scale = (maxSide / (width > height ? width : height)).clamp(
        0.0,
        1.0,
      );
      final targetWidth = (width * scale).round().clamp(1, maxSide);
      final targetHeight = (height * scale).round().clamp(1, maxSide);
      if (image == null || width != targetWidth || height != targetHeight) {
        image?.dispose();
        image = null;
        codec?.dispose();
        codec = null;
        codec = kIsWeb
            ? await ui.instantiateImageCodec(
                bytes,
                targetWidth: targetWidth,
                targetHeight: targetHeight,
                allowUpscaling: false,
              )
            : await descriptor!.instantiateCodec(
                targetWidth: targetWidth,
                targetHeight: targetHeight,
              );
        image = (await codec.getNextFrame()).image;
      }
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null || data.lengthInBytes > 4194304) {
        throw const AppFailure(
          'La imagen sigue siendo demasiado pesada. Prueba otra más pequeña.',
        );
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (error) {
      if (error is AppFailure) rethrow;
      throw const AppFailure(
        'No pudimos leer esa imagen. Prueba con JPG, PNG o WebP.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }
}
