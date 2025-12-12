import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_layout.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';

class InviteToCircleContactItem extends StatelessWidget
    with MainLayout, InviteToCircleLayout {
  const InviteToCircleContactItem({
    required this.contact,
    required this.onTap,
    super.key,
  });

  final ContactModel contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalMargin,
        ),
        child: Row(
          children: [
            ProfileImage(
              username: contact.displayName,
              size: 40.0,
              showLoading: false,
            ),
            SizedBox(width: horizontalPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.tertiaryFixedDim,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.primaryPhoneNumber != null) ...[
                    Text(
                      contact.primaryPhoneNumber!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.scrim,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
