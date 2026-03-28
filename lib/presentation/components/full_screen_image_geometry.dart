part of 'package:cloudless/presentation/components/full_screen_image.dart';

/// Clamp [matrix] so the viewport stays within [boundaryRect].
/// Pure function — no widget state dependency.
Matrix4 _fixMatrixForBounds(
  Matrix4 matrix,
  Rect boundaryRect,
  Rect viewport,
) {
  final nextMatrix = matrix.clone();
  final nextViewport = _transformViewport(nextMatrix, viewport);
  if (boundaryRect.isInfinite) return nextMatrix;
  final aabb = _getAxisAlignedBoundingBoxWithRotation(boundaryRect, 0);
  final offending = _exceedsBy(aabb, nextViewport);
  if (offending == Offset.zero) return nextMatrix;

  final nextTranslation = _getMatrixTranslation(nextMatrix);
  final scale = matrix.getMaxScaleOnAxis();
  final corrected = Offset(
    nextTranslation.dx - offending.dx * scale,
    nextTranslation.dy - offending.dy * scale,
  );
  final correctedMatrix = matrix.clone()
    ..setTranslation(Vector3(corrected.dx, corrected.dy, 0));
  final correctedVp = _transformViewport(correctedMatrix, viewport);
  final offCorrected = _exceedsBy(aabb, correctedVp);
  if (offCorrected == Offset.zero) return correctedMatrix;
  if (offCorrected.dx != 0.0 && offCorrected.dy != 0.0) {
    return matrix.clone();
  }
  final uni = Offset(
    offCorrected.dx == 0.0 ? corrected.dx : 0.0,
    offCorrected.dy == 0.0 ? corrected.dy : 0.0,
  );
  return matrix.clone()..setTranslation(Vector3(uni.dx, uni.dy, 0));
}

// Find the axis aligned bounding box for the rect rotated about its center by
// the given amount.
Quad _getAxisAlignedBoundingBoxWithRotation(Rect rect, double rotation) {
  final Matrix4 rotationMatrix = Matrix4.identity()
    ..translateByVector3(Vector3(rect.size.width / 2, rect.size.height / 2, 0))
    ..rotateZ(rotation)
    ..translateByVector3(
      Vector3(-rect.size.width / 2, -rect.size.height / 2, 0),
    );
  final Quad boundariesRotated = Quad.points(
    rotationMatrix.transform3(Vector3(rect.left, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.top, 0.0)),
    rotationMatrix.transform3(Vector3(rect.right, rect.bottom, 0.0)),
    rotationMatrix.transform3(Vector3(rect.left, rect.bottom, 0.0)),
  );
  return _getAxisAlignedBoundingBox(boundariesRotated);
}

// Return the translation from the given Matrix4 as an Offset.
Offset _getMatrixTranslation(Matrix4 matrix) {
  final Vector3 nextTranslation = matrix.getTranslation();
  return Offset(nextTranslation.x, nextTranslation.y);
}

// Return the amount that viewport lies outside of boundary. If the viewport
// is completely contained within the boundary (inclusively), then returns
// Offset.zero.
Offset _exceedsBy(Quad boundary, Quad viewport) {
  final List<Vector3> viewportPoints = <Vector3>[
    viewport.point0,
    viewport.point1,
    viewport.point2,
    viewport.point3,
  ];
  Offset largestExcess = Offset.zero;
  for (final Vector3 point in viewportPoints) {
    final Vector3 pointInside = _getNearestPointInside(point, boundary);
    final Offset excess = Offset(
      pointInside.x - point.x,
      pointInside.y - point.y,
    );
    if (excess.dx.abs() > largestExcess.dx.abs()) {
      largestExcess = Offset(excess.dx, largestExcess.dy);
    }
    if (excess.dy.abs() > largestExcess.dy.abs()) {
      largestExcess = Offset(largestExcess.dx, excess.dy);
    }
  }

  return _round(largestExcess);
}

// Transform the four corners of the viewport by the inverse of the given
// matrix. This gives the viewport after the child has been transformed by the
// given matrix. The viewport transforms as the inverse of the child (i.e.
// moving the child left is equivalent to moving the viewport right).
Quad _transformViewport(Matrix4 matrix, Rect viewport) {
  final Matrix4 inverseMatrix = matrix.clone()..invert();
  return Quad.points(
    inverseMatrix.transform3(
      Vector3(viewport.topLeft.dx, viewport.topLeft.dy, 0.0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.topRight.dx, viewport.topRight.dy, 0.0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.bottomRight.dx, viewport.bottomRight.dy, 0.0),
    ),
    inverseMatrix.transform3(
      Vector3(viewport.bottomLeft.dx, viewport.bottomLeft.dy, 0.0),
    ),
  );
}

// Round the output values. This works around a precision problem where
// values that should have been zero were given as within 10^-10 of zero.
Offset _round(Offset offset) {
  return Offset(
    double.parse(offset.dx.toStringAsFixed(9)),
    double.parse(offset.dy.toStringAsFixed(9)),
  );
}

/// Get the point inside (inclusively) the given Quad that is nearest to the
/// given Vector3.
Vector3 _getNearestPointInside(Vector3 point, Quad quad) {
  // If the point is inside the axis aligned bounding box, then it's ok where
  // it is.
  if (_pointIsInside(point, quad)) {
    return point;
  }

  // Otherwise, return the nearest point on the quad.
  final List<Vector3> closestPoints = <Vector3>[
    _getNearestPointOnLine(point, quad.point0, quad.point1),
    _getNearestPointOnLine(point, quad.point1, quad.point2),
    _getNearestPointOnLine(point, quad.point2, quad.point3),
    _getNearestPointOnLine(point, quad.point3, quad.point0),
  ];
  double minDistance = double.infinity;
  late Vector3 closestOverall;
  for (final Vector3 closePoint in closestPoints) {
    final double distance = math.sqrt(
      math.pow(point.x - closePoint.x, 2) + math.pow(point.y - closePoint.y, 2),
    );
    if (distance < minDistance) {
      minDistance = distance;
      closestOverall = closePoint;
    }
  }
  return closestOverall;
}

/// Returns true iff the point is inside the rectangle given by the Quad,
/// inclusively.
/// Algorithm from https://math.stackexchange.com/a/190373.
bool _pointIsInside(Vector3 point, Quad quad) {
  final Vector3 aM = point - quad.point0;
  final Vector3 aB = quad.point1 - quad.point0;
  final Vector3 aD = quad.point3 - quad.point0;

  final double aMAB = aM.dot(aB);
  final double aBAB = aB.dot(aB);
  final double aMAD = aM.dot(aD);
  final double aDAD = aD.dot(aD);

  return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
}

/// Returns the closest point to the given point on the given line segment.
Vector3 _getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
  final double lengthSquared =
      math.pow(l2.x - l1.x, 2.0).toDouble() +
      math.pow(l2.y - l1.y, 2.0).toDouble();

  // In this case, l1 == l2.
  if (lengthSquared == 0) {
    return l1;
  }

  // Calculate how far down the line segment the closest point is and return
  // the point.
  final Vector3 l1P = point - l1;
  final Vector3 l1L2 = l2 - l1;
  final double fraction = clampDouble(l1P.dot(l1L2) / lengthSquared, 0.0, 1.0);
  return l1 + l1L2 * fraction;
}

/// Given a quad, return its axis aligned bounding box.
Quad _getAxisAlignedBoundingBox(Quad quad) {
  final double minX = math.min(
    quad.point0.x,
    math.min(quad.point1.x, math.min(quad.point2.x, quad.point3.x)),
  );
  final double minY = math.min(
    quad.point0.y,
    math.min(quad.point1.y, math.min(quad.point2.y, quad.point3.y)),
  );
  final double maxX = math.max(
    quad.point0.x,
    math.max(quad.point1.x, math.max(quad.point2.x, quad.point3.x)),
  );
  final double maxY = math.max(
    quad.point0.y,
    math.max(quad.point1.y, math.max(quad.point2.y, quad.point3.y)),
  );
  return Quad.points(
    Vector3(minX, minY, 0),
    Vector3(maxX, minY, 0),
    Vector3(maxX, maxY, 0),
    Vector3(minX, maxY, 0),
  );
}
