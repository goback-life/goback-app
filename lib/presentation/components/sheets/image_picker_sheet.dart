import 'package:cloudless/core/features/post/domain/providers/parent_post_reference_notifier_provider.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/form_field/image_picker_sheet_layout.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSheet extends HookConsumerWidget
    with MainLayout, ImagePickerSheetLayout {
  const ImagePickerSheet({
    required this.allowCamera,
    required this.allowGallery,
    super.key,
  });

  final bool allowCamera;
  final bool allowGallery;

  static Future<dynamic> show(
    BuildContext context, {
    bool allowCamera = true,
    bool allowGallery = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ImagePickerSheet(
        allowCamera: allowCamera,
        allowGallery: allowGallery,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parentPost = ref.watch(parentPostReferenceNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(sheetBorderRadius),
        ),
      ),
      padding: EdgeInsets.all(verticalSpacing),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(sheetHandleRadius),
              ),
            ),
            SizedBox(height: verticalSpacing),
            Text(
              translator.translate('components.image_picker_sheet.title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: verticalSpacing),
            if (parentPost != null) ...[
              ParentPostPreview(parentPost: parentPost),
              SizedBox(height: verticalSpacing),
            ],
            if (allowCamera)
              _buildActionButton(
                context,
                icon: Assets.svg.camera.render(
                  colorFilter: colorScheme.primary.asSrcIn,
                ),
                label: translator.translate(
                  'components.image_picker_sheet.camera',
                ),
                onTap: () => _selectImageSource(context, ImageSource.camera),
              ),
            if (allowGallery)
              _buildActionButton(
                context,
                icon: Assets.svg.gallery.render(
                  colorFilter: colorScheme.primary.asSrcIn,
                ),
                label: translator.translate(
                  'components.image_picker_sheet.gallery',
                ),
                onTap: () => _selectImageSource(context, ImageSource.gallery),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: sheetActionButtonBottomSpacing),
      child: CallToAction.filled.primary(
        action: onTap,
        icon: icon,
        label: Text(label),
      ),
    );
  }

  void _selectImageSource(BuildContext context, ImageSource source) {
    Navigator.of(context).pop(source);
  }
}
