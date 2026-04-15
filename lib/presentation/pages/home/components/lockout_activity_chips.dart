import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Preset activity definitions: key → (label, icon builder).
const _presets = <String, ({String label, IconData icon})>{
  'sport': (label: 'Sport', icon: Icons.directions_run_rounded),
  'music': (label: 'Music', icon: Icons.music_note_rounded),
  'friends': (label: 'Friends', icon: Icons.people_outline_rounded),
  'relax': (label: 'Relax', icon: Icons.spa_outlined),
  'studying': (label: 'Study', icon: Icons.menu_book_rounded),
};

class LockoutActivityChips extends HookWidget {
  const LockoutActivityChips({
    super.key,
    required this.selectedPreset,
    required this.customText,
    required this.onPresetSelected,
    required this.onCustomTextChanged,
  });

  final String? selectedPreset;
  final String? customText;
  final ValueChanged<String?> onPresetSelected;
  final ValueChanged<String?> onCustomTextChanged;

  @override
  Widget build(BuildContext context) {
    final isCustomExpanded = useState(false);
    final customController = useTextEditingController(text: customText);
    final customFocus = useFocusNode();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        ..._presets.entries.map(
          (e) => _PresetChip(
            label: e.value.label,
            icon: e.value.icon,
            isSelected: selectedPreset == e.key,
            onTap: () {
              // Collapse custom if open
              if (isCustomExpanded.value) {
                isCustomExpanded.value = false;
                customController.clear();
                onCustomTextChanged(null);
              }
              // Toggle selection
              onPresetSelected(selectedPreset == e.key ? null : e.key);
            },
          ),
        ),
        _CustomChip(
          isExpanded: isCustomExpanded.value,
          controller: customController,
          focusNode: customFocus,
          onTap: () {
            if (!isCustomExpanded.value) {
              isCustomExpanded.value = true;
              onPresetSelected(null);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                customFocus.requestFocus();
              });
            }
          },
          onChanged: (text) {
            onCustomTextChanged(text.isEmpty ? null : text);
          },
          onClear: () {
            isCustomExpanded.value = false;
            customController.clear();
            onCustomTextChanged(null);
          },
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = MainColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: label.length > 5 ? 82 : 76,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accent : Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected
                      ? accent
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomChip extends StatelessWidget {
  const _CustomChip({
    required this.isExpanded,
    required this.controller,
    required this.focusNode,
    required this.onTap,
    required this.onChanged,
    required this.onClear,
  });

  final bool isExpanded;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isExpanded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: isExpanded ? 150 : 42,
        height: 42,
        decoration: BoxDecoration(
          color: isExpanded
              ? MainColors.accent.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded
                ? MainColors.accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.08),
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: isExpanded
            ? OverflowBox(
                maxWidth: 150,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: MainColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLength: 20,
                        onChanged: onChanged,
                        style: TextStyle(
                          fontSize: 13,
                          color: MainColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
      ),
    );
  }
}
