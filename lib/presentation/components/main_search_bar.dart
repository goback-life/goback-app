import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/search_input_decoration.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:flutter/material.dart';

class MainSearchBar extends HookConsumerWidget with MainLayout {
  const MainSearchBar({
    required this.searchQuery,
    required this.onSearchChanged,
    this.onTap,
    this.onSubmitted,
    this.onTapOutside,
    super.key,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onTap;
  final void Function(String value)? onSubmitted;
  final void Function(PointerDownEvent event)? onTapOutside;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final controller = useTextEditingController(text: searchQuery);

    useEffect(() {
      if (controller.text != searchQuery) {
        controller.text = searchQuery;
      }
      return null;
    }, [searchQuery]);

    void clearSearch() {
      controller.clear();
      onSearchChanged('');
    }

    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: 10,
        tint: MainColors.accent,
      ),
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        autocorrect: false,
        controller: controller,
        onChanged: onSearchChanged,
        style: textTheme.bodyMedium,
        cursorColor: colorScheme.tertiary,
        onTap: onTap,
        onTapOutside: onTapOutside ?? (event) => context.unfocus(),
        onSubmitted: onSubmitted,
        decoration: searchInputDecoration(
          context,
          null,
          searchQuery,
          clearSearch,
        ),
      ),
    );
  }
}
