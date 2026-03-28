import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';

/// Shared search text field used by both Invite and Search tabs
/// in the tutorial friend adder.
class TutorialSearchField extends StatelessWidget {
  const TutorialSearchField({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        onChanged: onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        cursorColor: MainColors.dark,
        style: const TextStyle(color: MainColors.dark, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: MainColors.grey500,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: MainColors.grey500,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: MainColors.grey300.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: MainColors.grey300.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: MainColors.accent),
          ),
        ),
      ),
    );
  }
}
