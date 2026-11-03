import 'package:flutter/material.dart';

import 'tour_models.dart';

/// Only the public revision returned by publicList can be a map AR target.
class BusinessARTarget {
  const BusinessARTarget(this.tour, this.point);
  final TourRecord tour;
  final TourPoint point;

  static List<BusinessARTarget> fromPublicTours(
    List<TourRecord> tours,
    String owner,
  ) => [
    for (final tour in tours)
      if (tour.ownerId == owner && tour.state == 'published')
        for (final point in tour.document.points)
          if (isTestedReference(point.ar)) BusinessARTarget(tour, point),
  ];

  static bool isTestedReference(Map<String, dynamic>? ar) {
    if (ar == null) {
      return false;
    }
    final version = ar['reference_version'];
    final width = ar['width_cm'];
    return version is String &&
        version.isNotEmpty &&
        ar['tested_version'] == version &&
        ar['reference_path'] is String &&
        (ar['reference_path'] as String).isNotEmpty &&
        width is num &&
        width.isFinite &&
        width > 0;
  }
}

/// Native image corners, clockwise from top left, normalized to the viewport.
/// This homography keeps both painting and tap hit testing on the image plane.
Matrix4? arCardTransform(dynamic value, Size viewport, Size card) {
  if (value is! List || value.length != 8) {
    return null;
  }
  if (value.any((v) => v is! num || !v.isFinite)) {
    return null;
  }
  final p = List<double>.generate(
    8,
    (i) =>
        (value[i] as num).toDouble() *
        (i.isEven ? viewport.width : viewport.height),
  );
  final dx1 = p[2] - p[4], dx2 = p[6] - p[4];
  final dy1 = p[3] - p[5], dy2 = p[7] - p[5];
  final dx3 = p[0] - p[2] + p[4] - p[6];
  final dy3 = p[1] - p[3] + p[5] - p[7];
  final det = dx1 * dy2 - dx2 * dy1;
  if (det.abs() < .001 || card.isEmpty || viewport.isEmpty) {
    return null;
  }
  final g = (dx3 * dy2 - dx2 * dy3) / det;
  final h = (dx1 * dy3 - dx3 * dy1) / det;
  // Reject a plane crossing the camera / a degenerate quadrilateral.
  if ([1.0, 1 + g, 1 + h, 1 + g + h].any((v) => v <= .001)) {
    return null;
  }
  return Matrix4.fromList([
    (p[2] - p[0] + g * p[2]) / card.width,
    (p[3] - p[1] + g * p[3]) / card.width,
    0,
    g / card.width,
    (p[6] - p[0] + h * p[6]) / card.height,
    (p[7] - p[1] + h * p[7]) / card.height,
    0,
    h / card.height,
    0,
    0,
    1,
    0,
    p[0],
    p[1],
    0,
    1,
  ]);
}
