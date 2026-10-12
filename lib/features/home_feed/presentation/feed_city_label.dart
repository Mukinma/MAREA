import 'package:flutter/material.dart';
import 'package:marea/core/theme/app_colors.dart';
import 'package:marea/features/community/models/community_models.dart';
import 'package:marea/features/location/data/location_repository.dart';
import 'package:marea/features/location/models/location_models.dart';

/// Resolves the content point lazily while its card remains usable.
class FeedCityLabel extends StatefulWidget {
  const FeedCityLabel({
    required this.contentKind,
    required this.contentId,
    required this.onTap,
    this.city,
    this.coordinates,
    this.repository,
    this.color = AppColors.textSecondary,
    super.key,
  });
  final String contentKind, contentId;
  final LocationCity? city;
  final PostCoordinates? coordinates;
  final LocationRepository? repository;
  final VoidCallback onTap;
  final Color color;
  @override
  State<FeedCityLabel> createState() => _FeedCityLabelState();
}

class _FeedCityLabelState extends State<FeedCityLabel> {
  LocationCity? _city;
  bool _failed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _city = widget.city;
    _resolve();
  }

  @override
  void didUpdateWidget(FeedCityLabel old) {
    super.didUpdateWidget(old);
    if (old.contentId != widget.contentId ||
        old.contentKind != widget.contentKind ||
        old.city != widget.city ||
        old.repository != widget.repository ||
        old.coordinates?.latitude != widget.coordinates?.latitude ||
        old.coordinates?.longitude != widget.coordinates?.longitude) {
      ++_generation;
      _city = widget.city;
      _failed = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (_city != null ||
        widget.repository == null ||
        widget.coordinates == null) {
      return;
    }
    final generation = ++_generation;
    try {
      final city = await widget.repository!.resolveContentCity(
        contentKind: widget.contentKind,
        contentId: widget.contentId,
        coordinates: widget.coordinates!,
      );
      if (mounted && generation == _generation) {
        setState(() {
          _city = city;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 16, color: widget.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _city?.name ?? 'Ver ubicación',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: widget.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_failed)
        IconButton(
          tooltip: 'Reintentar ciudad',
          onPressed: _resolve,
          icon: Icon(Icons.refresh, size: 18, color: widget.color),
        ),
    ],
  );
}
