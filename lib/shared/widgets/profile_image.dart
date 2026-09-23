import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:marea/features/profile/data/profile_media_repository.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/shared/widgets/creative_artwork.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({
    required this.path,
    required this.fallback,
    this.repository,
    this.preview,
    super.key,
  });
  final String? path;
  final Widget fallback;
  final ProfileMediaRepository? repository;
  final Uint8List? preview;
  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  Future<String>? _url;
  Timer? _refresh;
  void _load() {
    _refresh?.cancel();
    _url = widget.path == null
        ? null
        : (widget.repository ?? SupabaseProfileMediaRepository()).signedUrl(
            widget.path!,
          );
    if (widget.path != null) {
      _refresh = Timer(const Duration(minutes: 9), () {
        if (mounted) setState(_load);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preview != null) {
      return Image.memory(
        widget.preview!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_url == null) return widget.fallback;
    return FutureBuilder<String>(
      future: _url,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Stack(
            fit: StackFit.expand,
            children: [
              widget.fallback,
              Center(
                child: IconButton.filledTonal(
                  tooltip: 'Volver a cargar imagen',
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
            ],
          );
        }
        if (!snapshot.hasData) return widget.fallback;
        return Image.network(
          snapshot.data!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}

class ProfileCover extends StatelessWidget {
  const ProfileCover({this.preset = 'marea', super.key});
  final String preset;
  @override
  Widget build(BuildContext context) => preset == 'marea'
      ? const MareaCover()
      : ColoredBox(
          color: switch (preset) {
            'durazno' => AppColors.peach,
            'menta' => AppColors.mint,
            _ => AppColors.lavender,
          },
        );
}
