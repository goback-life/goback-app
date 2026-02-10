import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/profile_image/profile_image.dart';
import 'package:flutter/material.dart';

/// Overlay that displays the mention autocomplete suggestions.
class MentionOverlay extends StatelessWidget {
  const MentionOverlay({
    required this.layerLink,
    required this.users,
    required this.onUserSelected,
    super.key,
  });

  final LayerLink layerLink;
  final List<ProfileModel> users;
  final ValueChanged<ProfileModel> onUserSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Positioned(
      width: 250,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, -8),
        followerAnchor: Alignment.bottomLeft,
        targetAnchor: Alignment.topLeft,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surface,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return InkWell(
                  onTap: () => onUserSelected(user),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: ProfileImage(
                            imageUrl: user.avatarUrl,
                            isEditable: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '@${user.username}',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
