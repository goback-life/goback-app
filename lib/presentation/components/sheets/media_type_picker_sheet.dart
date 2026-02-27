import 'package:cloudless/core/features/media/domain/enums/media_type.dart';
import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/form_field/image_picker_sheet_layout.dart';
import 'package:cloudless/presentation/components/parent_post_preview/parent_post_preview.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class MediaTypePickerSheet extends HookConsumerWidget
    with MainLayout, ImagePickerSheetLayout {
  const MediaTypePickerSheet({this.parentPost, super.key});

  final ParentPostReferenceModel? parentPost;

  static Future<MediaType?> show(
    BuildContext context, {
    ParentPostReferenceModel? parentPost,
  }) {
    return showModalBottomSheet<MediaType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaTypePickerSheet(parentPost: parentPost),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              translator.translate('components.media_type_picker_sheet.title'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: verticalSpacing),
            if (parentPost != null) ...[
              ParentPostPreview(parentPost: parentPost!),
              SizedBox(height: verticalSpacing),
            ],
            _buildActionButton(
              context,
              icon: Assets.svg.camera.render(
                colorFilter: colorScheme.primary.asSrcIn,
              ),
              label: translator.translate(
                'components.media_type_picker_sheet.photo',
              ),
              onTap: () => Navigator.of(context).pop(MediaType.photo),
            ),
            _buildActionButton(
              context,
              icon: Assets.svg.gallery.render(
                colorFilter: colorScheme.primary.asSrcIn,
              ),
              label: translator.translate(
                'components.media_type_picker_sheet.video',
              ),
              onTap: () => Navigator.of(context).pop(MediaType.video),
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
}
