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

part 'full_screen_image_geometry.dart';
part 'full_screen_image_painter.dart';

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
    _controllerReset = AnimationController(vsync: this);
    _controllerZoomIn = AnimationController(vsync: this);
    _currentImage = widget.image;
    _preloadImage();
  }

  Future<void> _preloadImage() async {
    try {
      _currentImage.evict();
      if (_currentImage is FileImage) {
        final fileImage = _currentImage as FileImage;
        _currentImage = FileImage(fileImage.file);
      }
      final imageStream = _currentImage.resolve(const ImageConfiguration());
      final completer = Completer<ui.Image>();
      imageStream.addListener(
        ImageStreamListener((info, _) => completer.complete(info.image)),
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

  void _animateZoomInStop() {
    _controllerZoomIn.stop();
    _animationZoomIn?.removeListener(_onAnimateZoomIn);
    _animationZoomIn = null;
    _controllerZoomIn.reset();
  }

  void _onInteractionStart(ScaleStartDetails details) {
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
          final double targetScale = currentScale * widget.doubleTapScale;
          final double translateX =
              tapPosition.dx * (1 - targetScale / currentScale);
          final double translateY =
              tapPosition.dy * (1 - targetScale / currentScale);
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
          final Offset targetCenter = Offset(size.width / 2, size.height / 2);
          final double translateX =
              targetCenter.dx - tapPosition.dx * (targetScale / currentScale);
          final double translateY =
              targetCenter.dy - tapPosition.dy * (targetScale / currentScale);
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
    if (_isFlipping || !mounted) return;
    setState(() => _isFlipping = true);
    try {
      if (_currentImage is! FileImage) return;
      final fileImage = _currentImage as FileImage;
      final imageBytes = await fileImage.file.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null || !mounted) return;
      final img.Image flippedImage = horizontal
          ? img.flipHorizontal(decodedImage)
          : img.flipVertical(decodedImage);
      if (!mounted) return;
      final flippedBytes = Uint8List.fromList(img.encodePng(flippedImage));
      if (horizontal) {
        widget.onFlipHorizontal?.call(flippedBytes);
      } else {
        widget.onFlipVertical?.call(flippedBytes);
      }
    } catch (e) {
      if (mounted) setState(() => _isFlipping = false);
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

  GlobalKey childKey = GlobalKey();

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
          if (_isFlipping) return;
          final renderBox =
              childKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox == null) {
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              Navigator.maybePop(context);
            }
            return;
          }
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
      canPop: !_isFlipping,
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
      ),
    );
  }

  Rect get _boundaryRect {
    assert(childKey.currentContext != null);
    final childRB = childKey.currentContext!.findRenderObject()! as RenderBox;
    return widget.boundaryMargin.inflateRect(Offset.zero & childRB.size);
  }

  Rect get _viewport =>
      Offset.zero & (context.findRenderObject()! as RenderBox).size;

  Matrix4 _fixMatrix(Matrix4 matrix) =>
      _fixMatrixForBounds(matrix, _boundaryRect, _viewport);
}
