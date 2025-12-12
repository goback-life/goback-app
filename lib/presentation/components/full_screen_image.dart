import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/full_screen_image_flip_menu.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

class FullScreenImage extends StatefulWidget {
  const FullScreenImage({
    required this.image,
    this.maxScale = 5,
    this.onTap,
    this.doubleTapScale = 2.5,
    this.boundaryMargin = EdgeInsets.zero,
    this.centerTappedPosition = false,
    this.enableDoubleTap = true,
    this.showFlipMenu = false,
    this.onFlipHorizontal,
    this.onFlipVertical,
    super.key,
  });

  final ImageProvider image;
  final double maxScale;
  final double doubleTapScale;
  final VoidCallback? onTap;
  final EdgeInsets boundaryMargin;
  final bool centerTappedPosition;
  final bool enableDoubleTap;
  final bool showFlipMenu;
  final void Function(Uint8List flippedImageBytes)? onFlipHorizontal;
  final void Function(Uint8List flippedImageBytes)? onFlipVertical;

  static Future<T?> show<T>({
    required BuildContext context,
    required ImageProvider image,
    double maxScale = 5,
    VoidCallback? onTap,
    double doubleTapScale = 2.5,
    EdgeInsets boundaryMargin = EdgeInsets.zero,
    bool centerTappedPosition = false,
    bool enableDoubleTap = true,
    bool showFlipMenu = false,
    void Function(Uint8List flippedImageBytes)? onFlipHorizontal,
    void Function(Uint8List flippedImageBytes)? onFlipVertical,
  }) => showDialog<T>(
    useSafeArea: false,
    barrierDismissible: false, // Changed to false to prevent unwanted dismissal
    context: context,
    barrierColor: Colors.transparent,
    builder: (context) => FullScreenImage(
      image: image,
      maxScale: maxScale,
      onTap: onTap,
      doubleTapScale: doubleTapScale,
      boundaryMargin: boundaryMargin,
      centerTappedPosition: centerTappedPosition,
      enableDoubleTap: enableDoubleTap,
      showFlipMenu: showFlipMenu,
      onFlipHorizontal: onFlipHorizontal,
      onFlipVertical: onFlipVertical,
    ),
  );

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

// ignore: one_class_per_file
class _FullScreenImageState extends State<FullScreenImage>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  Animation<Matrix4>? _animationReset;
  late final AnimationController _controllerReset;

  Animation<Matrix4>? _animationZoomIn;
  late final AnimationController _controllerZoomIn;

  late ImageProvider _currentImage;
  bool _isFlipping = false;
  ui.Image? _cachedImage; // Pre-loaded image for faster flipping
  ui.Image? _flippedRawImage; // Store flipped ui.Image for direct display

  @override
  void initState() {
    super.initState();
    // always initialize controllers here because just delaying their creation with
    // late AnimationController x = AnimationController(vsync: this); might cause them
    // to be accessed for the FIRST time (and therefore BE CREATED) in `dispose` which will throw an exception
    _controllerReset = AnimationController(vsync: this);
    _controllerZoomIn = AnimationController(vsync: this);
    _currentImage = widget.image;

    // Pre-load image for faster flipping
    _preloadImage();
  }

  Future<void> _preloadImage() async {
    try {
      // Evict cache to ensure we load the latest version from disk
      _currentImage.evict();

      // Create a NEW FileImage instance to force reload from disk
      if (_currentImage is FileImage) {
        final fileImage = _currentImage as FileImage;
        final file = fileImage.file;
        _currentImage = FileImage(file);
      }

      final imageStream = _currentImage.resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();

      imageStream.addListener(
        ImageStreamListener((info, _) {
          completer.complete(info.image);
        }),
      );

      _cachedImage = await completer.future;
    } catch (e) {
      // Silently fail - image will be loaded on demand
    }
  }

  @override
  void dispose() {
    _cachedImage?.dispose();
    _transformationController.dispose();
    _controllerReset.dispose();
    _controllerZoomIn.dispose();
    super.dispose();
  }

  void _onAnimateReset() {
    _transformationController.value = _animationReset!.value;
    if (!_controllerReset.isAnimating) {
      _animationReset!.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset.reset();
    }
  }

  void _animateResetInitialize() {
    _controllerReset.reset();
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(_controllerReset);
    _animationReset!.addListener(_onAnimateReset);
    _controllerReset.animateTo(
      1,
      curve: Easing.emphasizedDecelerate,
      duration: Durations.medium1,
    );
  }

  // Stop a running reset to home transform animation.
  void _animateResetStop() {
    _controllerReset.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset.reset();
  }

  void _onAnimateZoomIn() {
    _transformationController.value = _animationZoomIn!.value;
    if (!_controllerZoomIn.isAnimating) {
      _animationZoomIn!.removeListener(_onAnimateZoomIn);
      _animationZoomIn = null;
      _controllerZoomIn.reset();
    }
  }

  void _animateZoomInInitialize(Matrix4 newMatrix) {
    _controllerZoomIn.reset();
    _animationZoomIn = Matrix4Tween(
      begin: _transformationController.value,
      end: newMatrix,
    ).animate(_controllerZoomIn);
    _animationZoomIn!.addListener(_onAnimateZoomIn);
    _controllerZoomIn.animateTo(
      1,
      curve: Easing.emphasizedDecelerate,
      duration: Durations.medium1,
    );
  }

  // Stop a running ZoomIn transform animation.
  void _animateZoomInStop() {
    _controllerZoomIn.stop();
    _animationZoomIn?.removeListener(_onAnimateZoomIn);
    _animationZoomIn = null;
    _controllerZoomIn.reset();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_controllerReset.status == AnimationStatus.forward) {
      _animateResetStop();
    }
    if (_controllerZoomIn.status == AnimationStatus.forward) {
      _animateZoomInStop();
    }
  }

  TapDownDetails? _doubleTapDetails;

  void onDoubleTapStandard() {
    switch (_doubleTapDetails) {
      case null:
        return;
      case final TapDownDetails details:
        if (_transformationController.value == Matrix4.identity()) {
          final Matrix4 currentMatrix = _transformationController.value;
          final Offset tapPosition = details.localPosition;
          final double currentScale = currentMatrix.getMaxScaleOnAxis();

          // Define the desired zoom scale (e.g., zoom in by 2x).
          final double targetScale = currentScale * widget.doubleTapScale;

          // Calculate the translation needed to center the zoom around the tap.
          final double translateX =
              tapPosition.dx * (1 - targetScale / currentScale);
          final double translateY =
              tapPosition.dy * (1 - targetScale / currentScale);

          // Create the new transformation matrix.
          final Matrix4 newMatrix = Matrix4.identity()
            ..translateByVector3(Vector3(translateX, translateY, 0))
            ..scaleByVector3(Vector3(targetScale, targetScale, 1));

          _animateZoomInInitialize(newMatrix);
        } else {
          _animateResetInitialize();
        }
    }
  }

  void onDoubleTapCenter() {
    switch (_doubleTapDetails) {
      case null:
        return;
      case final TapDownDetails details:
        if (_transformationController.value == Matrix4.identity()) {
          final RenderBox? renderBox = switch (context.findRenderObject()) {
            final RenderBox box => box,
            _ => null,
          };
          final Size? size = renderBox?.size;
          if (size == null) {
            onDoubleTapStandard();
            return;
          }
          final Offset tapPosition = details.localPosition;
          final Matrix4 currentMatrix = _transformationController.value;
          final double currentScale = currentMatrix.getMaxScaleOnAxis();
          final double targetScale = currentScale * widget.doubleTapScale;

          // Calculate the point in the widget's coordinate system that should be at the center.
          final Offset targetCenter = Offset(size.width / 2, size.height / 2);

          // Calculate the translation needed to move the tapped point to the center
          final double translateX =
              targetCenter.dx - tapPosition.dx * (targetScale / currentScale);
          final double translateY =
              targetCenter.dy - tapPosition.dy * (targetScale / currentScale);

          // Create the new transformation matrix.
          final Matrix4 newMatrix = Matrix4.identity()
            ..translateByVector3(Vector3(translateX, translateY, 0))
            ..scaleByVector3(Vector3(targetScale, targetScale, 1));

          _animateZoomInInitialize(_fixMatrix(newMatrix));
        } else {
          _animateResetInitialize();
        }
    }
  }

  // ignore: use_setters_to_change_properties
  void onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void onDoubleTap() {
    return widget.centerTappedPosition
        ? onDoubleTapCenter()
        : onDoubleTapStandard();
  }

  Future<void> _flipImage(bool horizontal) async {
    if (_isFlipping) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isFlipping = true;
    });

    try {
      // Get the file path from current image
      if (_currentImage is! FileImage) {
        return;
      }

      final fileImage = _currentImage as FileImage;
      final file = fileImage.file;

      final imageBytes = await file.readAsBytes();

      // Decode image using the image package (handles EXIF correctly)
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      // Apply flip transformation
      final img.Image flippedImage;
      if (horizontal) {
        flippedImage = img.flipHorizontal(decodedImage);
      } else {
        flippedImage = img.flipVertical(decodedImage);
      }

      // Check if widget is still mounted before continuing
      if (!mounted) {
        return;
      }

      // Encode flipped image to PNG bytes
      final flippedBytes = Uint8List.fromList(img.encodePng(flippedImage));

      // Call the appropriate callback with flipped bytes
      if (horizontal) {
        if (widget.onFlipHorizontal != null) {
          widget.onFlipHorizontal!(flippedBytes);
        }
      } else {
        if (widget.onFlipVertical != null) {
          widget.onFlipVertical!(flippedBytes);
        }
      }
    } catch (e) {
      // Log error for debugging if needed
      if (mounted) {
        setState(() {
          _isFlipping = false;
        });
      }
    }
  }

  void _showFlipMenu() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 20,
              child: Center(
                child: FullScreenImageFlipMenu(
                  onFlipHorizontal: () async {
                    Navigator.of(dialogContext).pop();
                    await _flipImage(true);
                  },
                  onFlipVertical: () async {
                    Navigator.of(dialogContext).pop();
                    await _flipImage(false);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget gesturesWrapper({required Widget child, required bool enabled}) {
      final bool doubleTapEnabled = enabled && widget.enableDoubleTap;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTapDown: doubleTapEnabled ? onDoubleTapDown : null,
        onDoubleTap: doubleTapEnabled ? onDoubleTap : null,
        onTap: enabled && widget.onTap != null ? widget.onTap : null,
        onTapDown: (TapDownDetails details) {
          // Prevent closing dialog while flipping
          if (_isFlipping) {
            return;
          }

          final renderBox =
              childKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) {
            // fallback: use provided callback or pop
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              Navigator.maybePop(context);
            }
            return;
          }

          // convert global tap position to the child's local coordinates
          final local = renderBox.globalToLocal(details.globalPosition);
          final inside =
              local.dx >= 0 &&
              local.dy >= 0 &&
              local.dx <= renderBox.size.width &&
              local.dy <= renderBox.size.height;

          if (!inside) {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              Navigator.maybePop(context);
            }
          }
        },
        child: child,
      );
    }

    Widget zoomWrapper({required Widget child}) => InteractiveViewer(
      constrained: true,
      boundaryMargin: widget.boundaryMargin,
      transformationController: _transformationController,
      maxScale: widget.maxScale,
      minScale: 1,
      panEnabled: true,
      onInteractionStart: _onInteractionStart,
      child: child,
    );

    final child = Center(
      child: Builder(
        key: childKey,
        builder: (context) {
          // Use CustomPaint to draw flipped ui.Image directly
          if (_flippedRawImage != null) {
            return CustomPaint(
              painter: _UiImagePainter(_flippedRawImage!),
              size: Size.infinite,
            );
          }
          return Image(image: _currentImage, fit: BoxFit.contain);
        },
      ),
    );

    return PopScope(
      canPop: !_isFlipping, // Prevent closing dialog while flipping
      child: Container(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: gesturesWrapper(
                  enabled: true,
                  child: Container(
                    color: Colors.transparent,
                    child: zoomWrapper(child: child),
                  ),
                ),
              ),
              // Loading overlay during flip
              if (_isFlipping)
                Positioned.fill(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _isFlipping
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showFlipMenu &&
                  widget.onFlipHorizontal != null &&
                  widget.onFlipVertical != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _isFlipping ? null : _showFlipMenu,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: _isFlipping
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 24,
                                width: 24,
                                child: Center(
                                  child: Assets.svg.menu.render(
                                    colorFilter: Theme.of(
                                      context,
                                    ).colorScheme.surface.asSrcIn,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ), // Close PopScope
    );
  }

  GlobalKey childKey = GlobalKey();

  // The _boundaryRect is calculated by adding the boundaryMargin to the size of
  // the child.
  Rect get _boundaryRect {
    assert(childKey.currentContext != null, 'Child context must not be null');
    assert(
      !widget.boundaryMargin.left.isNaN,
      'Left boundary margin must be a number',
    );
    assert(
      !widget.boundaryMargin.right.isNaN,
      'Right boundary margin must be a number',
    );
    assert(
      !widget.boundaryMargin.top.isNaN,
      'Top boundary margin must be a number',
    );
    assert(
      !widget.boundaryMargin.bottom.isNaN,
      'Bottom boundary margin must be a number',
    );

    final RenderBox childRenderBox =
        childKey.currentContext!.findRenderObject()! as RenderBox;
    final Size childSize = childRenderBox.size;
    final Rect boundaryRect = widget.boundaryMargin.inflateRect(
      Offset.zero & childSize,
    );
    assert(
      !boundaryRect.isEmpty,
      "InteractiveViewer's child must have nonzero dimensions.",
    );
    // Boundaries that are partially infinite are not allowed because Matrix4's
    // rotation and translation methods don't handle infinites well.
    assert(
      boundaryRect.isFinite ||
          (boundaryRect.left.isInfinite &&
              boundaryRect.top.isInfinite &&
              boundaryRect.right.isInfinite &&
              boundaryRect.bottom.isInfinite),
      'boundaryRect must either be infinite in all directions or finite in all directions.',
    );
    return boundaryRect;
  }

  // The Rect representing the child's parent.
  Rect get _viewport {
    final RenderBox parentRenderBox = context.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  // Return a new matrix representing the given matrix after applying the given
  // translation.
  Matrix4 _fixMatrix(Matrix4 matrix) {
    final Matrix4 nextMatrix = matrix.clone();

    // Transform the viewport to determine where its four corners will be after
    // the child has been transformed.
    final Quad nextViewport = _transformViewport(nextMatrix, _viewport);

    // If the boundaries are infinite, then no need to check if the translation
    // fits within them.
    if (_boundaryRect.isInfinite) {
      return nextMatrix;
    }

    // Expand the boundaries with rotation. This prevents the problem where a
    // mismatch in orientation between the viewport and boundaries effectively
    // limits translation. With this approach, all points that are visible with
    // no rotation are visible after rotation.
    final Quad boundariesAabbQuad = _getAxisAlignedBoundingBoxWithRotation(
      _boundaryRect,
      0,
    );

    // If the given translation fits completely within the boundaries, allow it.
    final Offset offendingDistance = _exceedsBy(
      boundariesAabbQuad,
      nextViewport,
    );
    if (offendingDistance == Offset.zero) {
      return nextMatrix;
    }

    // Desired translation goes out of bounds, so translate to the nearest
    // in-bounds point instead.
    final Offset nextTotalTranslation = _getMatrixTranslation(nextMatrix);
    final double currentScale = matrix.getMaxScaleOnAxis();
    final Offset correctedTotalTranslation = Offset(
      nextTotalTranslation.dx - offendingDistance.dx * currentScale,
      nextTotalTranslation.dy - offendingDistance.dy * currentScale,
    );
    // idea is that the boundaries are axis aligned (boundariesAabbQuad), but
    // calculating the translation to put the viewport inside that Quad is more
    // complicated than this when rotated.
    // https://github.com/flutter/flutter/issues/57698
    final Matrix4 correctedMatrix = matrix.clone()
      ..setTranslation(
        Vector3(
          correctedTotalTranslation.dx,
          correctedTotalTranslation.dy,
          0.0,
        ),
      );

    // Double check that the corrected translation fits.
    final Quad correctedViewport = _transformViewport(
      correctedMatrix,
      _viewport,
    );
    final Offset offendingCorrectedDistance = _exceedsBy(
      boundariesAabbQuad,
      correctedViewport,
    );
    if (offendingCorrectedDistance == Offset.zero) {
      return correctedMatrix;
    }

    // If the corrected translation doesn't fit in either direction, don't allow
    // any translation at all. This happens when the viewport is larger than the
    // entire boundary.
    if (offendingCorrectedDistance.dx != 0.0 &&
        offendingCorrectedDistance.dy != 0.0) {
      return matrix.clone();
    }

    // Otherwise, allow translation in only the direction that fits. This
    // happens when the viewport is larger than the boundary in one direction.
    final Offset unidirectionalCorrectedTotalTranslation = Offset(
      offendingCorrectedDistance.dx == 0.0 ? correctedTotalTranslation.dx : 0.0,
      offendingCorrectedDistance.dy == 0.0 ? correctedTotalTranslation.dy : 0.0,
    );
    return matrix.clone()..setTranslation(
      Vector3(
        unidirectionalCorrectedTotalTranslation.dx,
        unidirectionalCorrectedTotalTranslation.dy,
        0.0,
      ),
    );
  }
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

/// CustomPainter to draw a ui.Image directly
class _UiImagePainter extends CustomPainter {
  _UiImagePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the scale to fit the image in the available space
    final double imageAspectRatio = image.width / image.height;
    final double canvasAspectRatio = size.width / size.height;

    double drawWidth;
    double drawHeight;

    if (imageAspectRatio > canvasAspectRatio) {
      // Image is wider than canvas
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
    } else {
      // Image is taller than canvas
      drawHeight = size.height;
      drawWidth = size.height * imageAspectRatio;
    }

    // Center the image
    final double offsetX = (size.width - drawWidth) / 2;
    final double offsetY = (size.height - drawHeight) / 2;

    final Rect srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect dstRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);

    canvas.drawImageRect(image, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(_UiImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
