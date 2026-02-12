import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class HomeCreateContentButton extends StatefulWidget
    with MainLayout, HomeLayout {
  const HomeCreateContentButton({
    super.key,
    this.onPressed,
    this.isRefreshing = false,
  });
  final VoidCallback? onPressed;
  final bool isRefreshing;

  @override
  State<HomeCreateContentButton> createState() =>
      _HomeCreateContentButtonState();
}

class _HomeCreateContentButtonState extends State<HomeCreateContentButton>
    with SingleTickerProviderStateMixin, MainLayout, HomeLayout {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Start animation if already refreshing when widget is created
    if (widget.isRefreshing) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(HomeCreateContentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _rotationController.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: AppGlassContainer(
              config: GlassConfig(
                variant: GlassVariant.regular,
                cornerRadius: createContentButtonSize / 2,
              ),
              child: SizedBox(
                width: createContentButtonSize,
                height: createContentButtonSize,
                child: Padding(
                  padding: EdgeInsets.all(feedPostImageBorderRadius),
                  child: Assets.svg.plus.render(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
